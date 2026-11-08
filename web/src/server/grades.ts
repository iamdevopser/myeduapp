import { BehaviorKind } from "@prisma/client";
import { z } from "zod";
import { assertStudentVisible, assertTeacher, assertTeacherOrSecretary, forbidden } from "@/lib/access";
import { prisma } from "@/lib/db";
import { Session } from "@/lib/http";

const dateKey = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

export const scoreColumnSchema = z.object({
  rosterClassId: z.number().int().positive(),
  name: z.string().trim().min(1).max(80),
  type: z.string().trim().min(1).max(40),
  teacherName: z.string().trim().max(120).nullable().optional(),
});

export const gradeCellSchema = z.object({
  studentId: z.number().int().positive(),
  columnId: z.number().int().positive(),
  date: dateKey,
  score: z.number().int().min(0).max(100).nullable().optional(),
  done: z.boolean().nullable().optional(),
  absent: z.boolean().default(false),
});

export const columnNoteSchema = z.object({
  columnId: z.number().int().positive(),
  date: dateKey,
  description: z.string().trim().min(1).max(500),
});

export const behaviorRecordSchema = z.object({
  studentId: z.number().int().positive(),
  behaviorId: z.number().int().positive(),
  date: dateKey,
  visibleToStudent: z.boolean().default(false),
});

export async function listScoreColumns(session: Session, rosterClassId: number) {
  assertTeacherOrSecretary(session);
  return prisma.scoreColumn.findMany({
    where: { rosterClassId },
    orderBy: { id: "asc" },
    include: { dateNotes: true },
  });
}

export async function createScoreColumn(session: Session, input: z.infer<typeof scoreColumnSchema>) {
  assertTeacher(session);
  return prisma.scoreColumn.create({
    data: {
      rosterClassId: input.rosterClassId,
      name: input.name,
      type: input.type,
      teacherName: input.teacherName ?? null,
    },
  });
}

export async function deleteScoreColumn(session: Session, id: number) {
  assertTeacher(session);
  await prisma.scoreColumn.delete({ where: { id } });
}

export async function listGradeCells(session: Session, filters: { studentId?: number; columnId?: number }) {
  if (filters.studentId != null) await assertStudentVisible(session, filters.studentId);
  else assertTeacherOrSecretary(session);
  return prisma.gradeCell.findMany({
    where: { studentId: filters.studentId, columnId: filters.columnId },
    include: { column: { select: { id: true, name: true, type: true } } },
    orderBy: { date: "desc" },
  });
}

export async function upsertGradeCell(session: Session, input: z.infer<typeof gradeCellSchema>) {
  assertTeacher(session);
  return prisma.gradeCell.upsert({
    where: {
      studentId_columnId_date: {
        studentId: input.studentId,
        columnId: input.columnId,
        date: input.date,
      },
    },
    create: {
      studentId: input.studentId,
      columnId: input.columnId,
      date: input.date,
      score: input.score ?? null,
      done: input.done ?? null,
      absent: input.absent,
    },
    update: {
      score: input.score ?? null,
      done: input.done ?? null,
      absent: input.absent,
    },
  });
}

export async function upsertColumnNote(session: Session, input: z.infer<typeof columnNoteSchema>) {
  assertTeacher(session);
  return prisma.scoreColumnDateNote.upsert({
    where: { columnId_date: { columnId: input.columnId, date: input.date } },
    create: input,
    update: { description: input.description },
  });
}

export async function listBehaviors() {
  return prisma.behaviorDefinition.findMany({ orderBy: { order: "asc" } });
}

export async function listBehaviorRecords(session: Session, studentId: number) {
  await assertStudentVisible(session, studentId);
  return prisma.behaviorRecord.findMany({
    where: {
      studentId,
      visibleToStudent: session.role === "student" || session.role === "parent" ? true : undefined,
    },
    include: { behavior: true },
    orderBy: { date: "desc" },
  });
}

export async function createBehaviorRecord(session: Session, input: z.infer<typeof behaviorRecordSchema>) {
  assertTeacher(session);
  const student = await prisma.student.findUnique({ where: { id: input.studentId } });
  if (!student) throw forbidden();
  const behavior = await prisma.behaviorDefinition.findUnique({ where: { id: input.behaviorId } });
  if (!behavior) throw forbidden();
  return prisma.behaviorRecord.upsert({
    where: {
      studentId_behaviorId_date: {
        studentId: input.studentId,
        behaviorId: input.behaviorId,
        date: input.date,
      },
    },
    create: {
      rosterClassId: student.rosterClassId,
      studentId: input.studentId,
      behaviorId: input.behaviorId,
      date: input.date,
      visibleToStudent: input.visibleToStudent,
    },
    update: { visibleToStudent: input.visibleToStudent },
  });
}

export function behaviorKindLabel(kind: BehaviorKind): string {
  return kind === "positive" ? "positive" : "needs_improvement";
}
