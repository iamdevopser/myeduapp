import { AppRole, AnnouncementTarget, Prisma } from "@prisma/client";
import { documentVisibleToClass, gradeFromClassName } from "@/lib/access";
import { prisma } from "@/lib/db";
import { Session } from "@/lib/http";

const ANNOUNCEMENT_REF = "announcement";
const DOCUMENT_REF = "content";

function preview(text: string): string {
  const trimmed = text.trim();
  return trimmed.length > 120 ? `${trimmed.slice(0, 120)}…` : trimmed;
}

async function notify(input: {
  role: AppRole;
  recipientId: number;
  title: string;
  body: string;
  type: string;
  referenceType: string;
  referenceId: number;
  dedupKey: string;
}) {
  await prisma.notification.upsert({
    where: { dedupKey: input.dedupKey },
    update: {},
    create: {
      recipientRole: input.role,
      recipientId: input.recipientId,
      title: input.title,
      body: input.body,
      type: input.type,
      referenceType: input.referenceType,
      referenceId: input.referenceId,
      dedupKey: input.dedupKey,
      status: "unread",
    },
  });
}

export async function fanoutAnnouncement(announcementId: number): Promise<void> {
  const announcement = await prisma.announcement.findUnique({ where: { id: announcementId } });
  if (!announcement || announcement.status !== "published") return;
  const students = await prisma.student.findMany({
    include: { rosterClass: true, parentLinks: { select: { parentId: true } } },
  });
  const notifiedParents = new Set<number>();
  for (const student of students) {
    const grade = gradeFromClassName(student.rosterClass.name);
    const matches =
      announcement.targetType === AnnouncementTarget.all_school ||
      (announcement.targetType === AnnouncementTarget.section &&
        announcement.rosterClassId === student.rosterClassId) ||
      (announcement.targetType === AnnouncementTarget.grade &&
        announcement.targetGradeLevel === grade);
    if (!matches) continue;
    await notify({
      role: "student",
      recipientId: student.id,
      title: announcement.title,
      body: preview(announcement.body),
      type: "announcement",
      referenceType: ANNOUNCEMENT_REF,
      referenceId: announcementId,
      dedupKey: `announcement:${announcementId}:student:${student.id}`,
    });
    for (const link of student.parentLinks) {
      if (notifiedParents.has(link.parentId)) continue;
      notifiedParents.add(link.parentId);
      await notify({
        role: "parent",
        recipientId: link.parentId,
        title: announcement.title,
        body: preview(announcement.body),
        type: "announcement",
        referenceType: ANNOUNCEMENT_REF,
        referenceId: announcementId,
        dedupKey: `announcement:${announcementId}:parent:${link.parentId}`,
      });
    }
  }
}

export async function fanoutDocument(documentId: number): Promise<void> {
  const document = await prisma.content.findUnique({ where: { id: documentId } });
  if (!document || !document.isSchoolDocument || document.archived) return;
  const body = preview(document.description ?? "");
  await notify({
    role: "teacher",
    recipientId: 0,
    title: document.name,
    body,
    type: "document",
    referenceType: DOCUMENT_REF,
    referenceId: documentId,
    dedupKey: `document:${documentId}:teacher:0`,
  });
  await notify({
    role: "secretary",
    recipientId: 0,
    title: document.name,
    body,
    type: "document",
    referenceType: DOCUMENT_REF,
    referenceId: documentId,
    dedupKey: `document:${documentId}:secretary:0`,
  });
  const students = await prisma.student.findMany({
    include: { rosterClass: true, parentLinks: { select: { parentId: true } } },
  });
  const notifiedParents = new Set<number>();
  for (const student of students) {
    if (
      !documentVisibleToClass({
        scope: document.scope,
        classId: student.rosterClassId,
        className: student.rosterClass.name,
        section: student.rosterClass.section,
      })
    ) {
      continue;
    }
    await notify({
      role: "student",
      recipientId: student.id,
      title: document.name,
      body,
      type: "document",
      referenceType: DOCUMENT_REF,
      referenceId: documentId,
      dedupKey: `document:${documentId}:student:${student.id}`,
    });
    for (const link of student.parentLinks) {
      if (notifiedParents.has(link.parentId)) continue;
      notifiedParents.add(link.parentId);
      await notify({
        role: "parent",
        recipientId: link.parentId,
        title: document.name,
        body,
        type: "document",
        referenceType: DOCUMENT_REF,
        referenceId: documentId,
        dedupKey: `document:${documentId}:parent:${link.parentId}`,
      });
    }
  }
}

function recipientWhere(session: Session): Prisma.NotificationWhereInput {
  if (session.role === "teacher" || session.role === "secretary" || session.role === "admin") {
    const ids = [0];
    if (session.domainId != null) ids.push(session.domainId);
    return { recipientRole: session.role, recipientId: { in: ids } };
  }
  return {
    recipientRole: session.role,
    recipientId: session.domainId ?? -1,
  };
}

export async function listNotifications(session: Session, take: number, skip: number) {
  const where = recipientWhere(session);
  const [total, unread, rows] = await prisma.$transaction([
    prisma.notification.count({ where }),
    prisma.notification.count({ where: { ...where, status: "unread" } }),
    prisma.notification.findMany({
      where,
      orderBy: { createdAt: "desc" },
      take,
      skip,
    }),
  ]);
  return {
    total,
    unread,
    data: rows.map((row) => ({
      id: row.id,
      title: row.title,
      body: row.body,
      type: row.type,
      referenceType: row.referenceType,
      referenceId: row.referenceId,
      createdAt: row.createdAt.toISOString(),
      readAt: row.readAt?.toISOString() ?? null,
      status: row.status,
    })),
  };
}

export async function markNotificationRead(session: Session, id: number) {
  const where = recipientWhere(session);
  const existing = await prisma.notification.findFirst({ where: { id, ...where } });
  if (!existing) {
    return null;
  }
  return prisma.notification.update({
    where: { id },
    data: { status: "read", readAt: existing.readAt ?? new Date() },
  });
}
