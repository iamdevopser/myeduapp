import { AttendanceStatus } from "@prisma/client";
import { z } from "zod";
import {
  assertStudentVisible,
  assertTeacherOrSecretary,
  canCreateAttendance,
  forbidden,
  linkedStudentIds,
} from "@/lib/access";
import { prisma } from "@/lib/db";
import { Session } from "@/lib/http";

const dateKey = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

export const attendanceUpsertSchema = z.object({
  studentId: z.number().int().positive(),
  date: dateKey,
  status: z.enum(["present", "absent", "excused"]),
});

export const attendanceBatchSchema = z.object({
  date: dateKey,
  rosterClassId: z.number().int().positive(),
  rows: z.array(
    z.object({
      studentId: z.number().int().positive(),
      status: z.enum(["present", "absent", "excused"]),
    }),
  ),
});

export async function listAttendance(
  session: Session,
  filters: { date?: string; rosterClassId?: number; studentId?: number },
) {
  if (filters.studentId != null) {
    await assertStudentVisible(session, filters.studentId);
  } else if (session.role === "student" || session.role === "parent") {
    const scope = await linkedStudentIds(session);
    if (scope === "all" || scope.length === 0) return [];
    return prisma.attendanceRecord.findMany({
      where: {
        studentId: { in: scope },
        date: filters.date,
      },
      include: { student: true },
      orderBy: [{ date: "desc" }, { studentId: "asc" }],
    });
  } else {
    assertTeacherOrSecretary(session);
  }
  return prisma.attendanceRecord.findMany({
    where: {
      date: filters.date,
      studentId: filters.studentId,
      student: filters.rosterClassId ? { rosterClassId: filters.rosterClassId } : undefined,
    },
    include: { student: true },
    orderBy: [{ date: "desc" }, { studentId: "asc" }],
  });
}

export async function upsertAttendance(session: Session, input: z.infer<typeof attendanceUpsertSchema>) {
  if (!canCreateAttendance(session)) throw forbidden();
  return prisma.attendanceRecord.upsert({
    where: { studentId_date: { studentId: input.studentId, date: input.date } },
    create: {
      studentId: input.studentId,
      date: input.date,
      status: input.status as AttendanceStatus,
    },
    update: { status: input.status as AttendanceStatus },
  });
}

export async function upsertAttendanceBatch(session: Session, input: z.infer<typeof attendanceBatchSchema>) {
  if (!canCreateAttendance(session)) throw forbidden();
  const students = await prisma.student.findMany({
    where: { rosterClassId: input.rosterClassId },
    select: { id: true },
  });
  const allowed = new Set(students.map((student) => student.id));
  const rows = input.rows.filter((row) => allowed.has(row.studentId));
  await prisma.$transaction(
    rows.map((row) =>
      prisma.attendanceRecord.upsert({
        where: { studentId_date: { studentId: row.studentId, date: input.date } },
        create: {
          studentId: row.studentId,
          date: input.date,
          status: row.status as AttendanceStatus,
        },
        update: { status: row.status as AttendanceStatus },
      }),
    ),
  );
  return { saved: rows.length };
}
