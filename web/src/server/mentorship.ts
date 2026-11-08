import { z } from "zod";
import { assertStudentVisible, assertTeacher, notFound } from "@/lib/access";
import { prisma } from "@/lib/db";
import { Session } from "@/lib/http";

const dateKey = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

export const eventSchema = z.object({
  rosterClassId: z.number().int().positive(),
  type: z.string().trim().min(1).max(40),
  title: z.string().trim().min(1).max(200),
  description: z.string().trim().max(4000).nullable().optional(),
  date: dateKey,
  time: z.string().regex(/^\d{2}:\d{2}$/),
  status: z.string().trim().min(1).max(40),
  wholeClass: z.boolean().default(false),
  studentIds: z.array(z.number().int().positive()).default([]),
});

export const mentorshipNoteSchema = z.object({
  studentId: z.number().int().positive(),
  text: z.string().trim().min(1).max(4000),
});

export const mentorshipReportSchema = z.object({
  studentId: z.number().int().positive(),
  date: dateKey,
  type: z.string().trim().min(1).max(40),
  behavior: z.string().trim().max(200).nullable().optional(),
  description: z.string().trim().max(4000).nullable().optional(),
  level: z.string().trim().max(40).nullable().optional(),
  teacherNote: z.string().trim().max(4000).nullable().optional(),
});

export const notebookSchema = z.object({
  rosterClassId: z.number().int().positive(),
  text: z.string().trim().min(1).max(4000),
  noteDate: dateKey,
});

export async function linkMentorshipClass(session: Session, rosterClassId: number) {
  assertTeacher(session);
  return prisma.mentorshipClass.upsert({
    where: { rosterClassId },
    create: { rosterClassId },
    update: {},
  });
}

export async function listMentorshipClasses(session: Session) {
  assertTeacher(session);
  return prisma.mentorshipClass.findMany({
    include: { rosterClass: true },
    orderBy: { createdAt: "desc" },
  });
}

export async function listEvents(session: Session, rosterClassId?: number) {
  assertTeacher(session);
  return prisma.mentorshipEvent.findMany({
    where: rosterClassId ? { rosterClassId } : undefined,
    include: { students: true },
    orderBy: [{ date: "desc" }, { time: "asc" }],
  });
}

export async function createEvent(session: Session, input: z.infer<typeof eventSchema>) {
  assertTeacher(session);
  return prisma.mentorshipEvent.create({
    data: {
      rosterClassId: input.rosterClassId,
      type: input.type,
      title: input.title,
      description: input.description ?? null,
      date: input.date,
      time: input.time,
      status: input.status,
      wholeClass: input.wholeClass,
      students: {
        create: input.wholeClass ? [] : input.studentIds.map((studentId) => ({ studentId })),
      },
    },
    include: { students: true },
  });
}

export async function deleteEvent(session: Session, id: number) {
  assertTeacher(session);
  await prisma.mentorshipEvent.delete({ where: { id } });
}

export async function listMentorshipNotes(session: Session, studentId: number) {
  await assertStudentVisible(session, studentId);
  if (session.role !== "teacher") throw notFound();
  return prisma.mentorshipNote.findMany({
    where: { studentId },
    orderBy: { createdAt: "desc" },
  });
}

export async function createMentorshipNote(session: Session, input: z.infer<typeof mentorshipNoteSchema>) {
  assertTeacher(session);
  const student = await prisma.student.findUnique({ where: { id: input.studentId } });
  if (!student) throw notFound("Student not found");
  return prisma.mentorshipNote.create({
    data: {
      rosterClassId: student.rosterClassId,
      studentId: student.id,
      text: input.text,
    },
  });
}

export async function listMentorshipReports(session: Session, studentId: number) {
  assertTeacher(session);
  await assertStudentVisible(session, studentId);
  return prisma.mentorshipBehaviorReport.findMany({
    where: { studentId },
    orderBy: { date: "desc" },
  });
}

export async function createMentorshipReport(session: Session, input: z.infer<typeof mentorshipReportSchema>) {
  assertTeacher(session);
  const student = await prisma.student.findUnique({ where: { id: input.studentId } });
  if (!student) throw notFound("Student not found");
  return prisma.mentorshipBehaviorReport.create({
    data: {
      rosterClassId: student.rosterClassId,
      studentId: student.id,
      date: input.date,
      type: input.type,
      behavior: input.behavior ?? null,
      description: input.description ?? null,
      level: input.level ?? null,
      teacherNote: input.teacherNote ?? null,
    },
  });
}

export async function listNotebook(session: Session, rosterClassId: number) {
  assertTeacher(session);
  return prisma.classNotebookNote.findMany({
    where: { rosterClassId },
    orderBy: [{ noteDate: "desc" }, { id: "desc" }],
  });
}

export async function createNotebook(session: Session, input: z.infer<typeof notebookSchema>) {
  assertTeacher(session);
  return prisma.classNotebookNote.create({ data: input });
}

export async function deleteNotebook(session: Session, id: number) {
  assertTeacher(session);
  await prisma.classNotebookNote.delete({ where: { id } });
}
