import { AnnouncementStatus, AnnouncementTarget } from "@prisma/client";
import { z } from "zod";
import {
  canManageAnnouncements,
  forbidden,
  gradeFromClassName,
  linkedStudentIds,
  notFound,
} from "@/lib/access";
import { prisma } from "@/lib/db";
import { ApiError, Session } from "@/lib/http";
import { fanoutAnnouncement } from "@/server/notifications";

export const announcementSchema = z.object({
  title: z.string().trim().min(1).max(200),
  body: z.string().trim().min(1),
  status: z.enum(["draft", "published", "unpublished"]).optional(),
  targetType: z.enum(["all_school", "grade", "section"]).optional(),
  rosterClassId: z.number().int().positive().nullable().optional(),
  targetGradeLevel: z.number().int().min(1).max(12).nullable().optional(),
  lessonId: z.number().int().positive().nullable().optional(),
  courseLabel: z.string().trim().max(160).nullable().optional(),
  teacherName: z.string().trim().max(120).nullable().optional(),
  coverImageKey: z.string().trim().max(300).nullable().optional(),
});

export const announcementPatchSchema = announcementSchema.partial();

function assertTarget(input: {
  targetType?: "all_school" | "grade" | "section";
  rosterClassId?: number | null;
  targetGradeLevel?: number | null;
}) {
  if (input.targetType === "section" && !input.rosterClassId) {
    throw new ApiError(400, "validation_error", "A section target requires rosterClassId");
  }
  if (input.targetType === "grade" && !input.targetGradeLevel) {
    throw new ApiError(400, "validation_error", "A grade target requires targetGradeLevel");
  }
}

export async function listAnnouncements(
  session: Session,
  filters: { status?: AnnouncementStatus; search?: string; take: number; skip: number },
) {
  if (session.role === "admin") throw forbidden();
  if (session.role === "teacher" || session.role === "secretary") {
    const where = {
      status: filters.status,
      title: filters.search ? { contains: filters.search, mode: "insensitive" as const } : undefined,
    };
    const [total, data] = await prisma.$transaction([
      prisma.announcement.count({ where }),
      prisma.announcement.findMany({
        where,
        orderBy: { createdAt: "desc" },
        take: filters.take,
        skip: filters.skip,
      }),
    ]);
    return { total, data };
  }
  const scope = await linkedStudentIds(session);
  if (scope !== "all" && scope.length === 0) return { total: 0, data: [] };
  const students =
    scope === "all"
      ? []
      : await prisma.student.findMany({
          where: { id: { in: scope } },
          include: { rosterClass: true },
        });
  const classIds = new Set(students.map((student) => student.rosterClassId));
  const grades = new Set(students.map((student) => gradeFromClassName(student.rosterClass.name)));
  const published = await prisma.announcement.findMany({
    where: { status: "published" },
    orderBy: { publishedAt: "desc" },
  });
  const matched = published.filter((row) => {
    if (row.targetType === AnnouncementTarget.all_school) return true;
    if (row.targetType === AnnouncementTarget.section) {
      return row.rosterClassId != null && classIds.has(row.rosterClassId);
    }
    return row.targetGradeLevel != null && grades.has(row.targetGradeLevel);
  });
  return { total: matched.length, data: matched.slice(filters.skip, filters.skip + filters.take) };
}

export async function getAnnouncement(session: Session, id: number) {
  if (session.role === "teacher" || session.role === "secretary") {
    const row = await prisma.announcement.findUnique({ where: { id } });
    if (!row) throw notFound("Announcement not found");
    return row;
  }
  const result = await listAnnouncements(session, { take: 1000, skip: 0 });
  const found = result.data.find((row) => row.id === id);
  if (!found) throw notFound("Announcement not found");
  return found;
}

export async function createAnnouncement(session: Session, input: z.infer<typeof announcementSchema>) {
  if (!canManageAnnouncements(session)) throw forbidden();
  const status = input.status ?? "draft";
  const targetType = input.targetType ?? "all_school";
  assertTarget({
    targetType,
    rosterClassId: input.rosterClassId,
    targetGradeLevel: input.targetGradeLevel,
  });
  const now = new Date();
  const created = await prisma.announcement.create({
    data: {
      title: input.title,
      body: input.body,
      status: status as AnnouncementStatus,
      targetType: targetType as AnnouncementTarget,
      rosterClassId: targetType === "section" ? input.rosterClassId ?? null : null,
      targetGradeLevel: targetType === "grade" ? input.targetGradeLevel ?? null : null,
      lessonId: input.lessonId ?? null,
      courseLabel: input.courseLabel ?? null,
      teacherName: input.teacherName ?? null,
      coverImageKey: input.coverImageKey ?? null,
      publishedAt: status === "published" ? now : null,
    },
  });
  if (created.status === "published") await fanoutAnnouncement(created.id);
  return created;
}

export async function updateAnnouncement(
  session: Session,
  id: number,
  input: z.infer<typeof announcementPatchSchema>,
) {
  if (!canManageAnnouncements(session)) throw forbidden();
  const current = await prisma.announcement.findUnique({ where: { id } });
  if (!current) throw notFound("Announcement not found");
  const targetType = input.targetType ?? current.targetType;
  assertTarget({
    targetType,
    rosterClassId: input.rosterClassId === undefined ? current.rosterClassId : input.rosterClassId,
    targetGradeLevel: input.targetGradeLevel === undefined ? current.targetGradeLevel : input.targetGradeLevel,
  });
  const nextStatus = (input.status ?? current.status) as AnnouncementStatus;
  const updated = await prisma.announcement.update({
    where: { id },
    data: {
      title: input.title,
      body: input.body,
      status: input.status as AnnouncementStatus | undefined,
      targetType: input.targetType as AnnouncementTarget | undefined,
      rosterClassId: targetType === "section" ? (input.rosterClassId ?? current.rosterClassId) : null,
      targetGradeLevel: targetType === "grade" ? (input.targetGradeLevel ?? current.targetGradeLevel) : null,
      lessonId: input.lessonId,
      courseLabel: input.courseLabel,
      teacherName: input.teacherName,
      coverImageKey: input.coverImageKey,
      publishedAt: nextStatus === "published" ? current.publishedAt ?? new Date() : current.publishedAt,
    },
  });
  if (current.status !== "published" && updated.status === "published") {
    await fanoutAnnouncement(updated.id);
  }
  return updated;
}
