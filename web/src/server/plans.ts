import { z } from "zod";
import { assertTeacher, linkedStudentIds } from "@/lib/access";
import { prisma } from "@/lib/db";
import { Session } from "@/lib/http";

const dateKey = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

export const periodSchema = z.object({
  period: z.number().int().min(1).max(12),
  start: z.string().regex(/^\d{2}:\d{2}$/),
  end: z.string().regex(/^\d{2}:\d{2}$/),
});

export const weeklySchema = z.object({
  day: z.number().int().min(1).max(5),
  period: z.number().int().min(1).max(12),
  start: z.string().regex(/^\d{2}:\d{2}$/),
  end: z.string().regex(/^\d{2}:\d{2}$/),
  lessonId: z.number().int().positive().nullable().optional(),
  rosterClassId: z.number().int().positive().nullable().optional(),
  topicText: z.string().max(300).default(""),
  classText: z.string().max(120).default(""),
});

export const dailySchema = z.object({
  date: dateKey,
  lessonId: z.number().int().positive().nullable().optional(),
  rosterClassId: z.number().int().positive().nullable().optional(),
  topicText: z.string().max(300).default(""),
  classText: z.string().max(120).default(""),
  topic: z.string().max(300).nullable().optional(),
  goals: z.string().max(2000).nullable().optional(),
  activities: z.string().max(2000).nullable().optional(),
  materials: z.string().max(2000).nullable().optional(),
  homework: z.string().max(2000).nullable().optional(),
  notes: z.string().max(2000).nullable().optional(),
});

export const annualSchema = z.object({
  academicYear: z.string().trim().min(4).max(32),
  lessonId: z.number().int().positive().nullable().optional(),
  rosterClassId: z.number().int().positive().nullable().optional(),
  topicText: z.string().max(300).default(""),
  classText: z.string().max(120).default(""),
  unitTopic: z.string().trim().min(1).max(300),
  plannedTerm: z.string().max(80).nullable().optional(),
  hours: z.number().int().min(0).nullable().optional(),
  goals: z.string().max(2000).nullable().optional(),
  notes: z.string().max(2000).nullable().optional(),
});

async function rosterScope(session: Session): Promise<number[] | "all"> {
  if (session.role === "teacher" || session.role === "secretary") return "all";
  const students = await linkedStudentIds(session);
  if (students === "all") return "all";
  if (students.length === 0) return [];
  const rows = await prisma.student.findMany({
    where: { id: { in: students } },
    select: { rosterClassId: true },
  });
  return [...new Set(rows.map((row) => row.rosterClassId))];
}

export async function listPeriods(session: Session) {
  if (session.role === "admin") return [];
  return prisma.periodSlot.findMany({ orderBy: { period: "asc" } });
}

export async function upsertPeriod(session: Session, input: z.infer<typeof periodSchema>) {
  assertTeacher(session);
  return prisma.periodSlot.upsert({
    where: { period: input.period },
    create: input,
    update: { start: input.start, end: input.end },
  });
}

export async function listWeekly(session: Session, rosterClassId?: number) {
  const scope = await rosterScope(session);
  if (scope !== "all" && scope.length === 0) return [];
  return prisma.weeklyLesson.findMany({
    where: {
      rosterClassId:
        rosterClassId != null
          ? rosterClassId
          : scope === "all"
            ? undefined
            : { in: scope },
    },
    include: {
      lesson: { select: { id: true, name: true } },
      rosterClass: { select: { id: true, name: true, section: true } },
    },
    orderBy: [{ day: "asc" }, { period: "asc" }],
  });
}

export async function createWeekly(session: Session, input: z.infer<typeof weeklySchema>) {
  assertTeacher(session);
  return prisma.weeklyLesson.create({
    data: {
      day: input.day,
      period: input.period,
      start: input.start,
      end: input.end,
      lessonId: input.lessonId ?? null,
      rosterClassId: input.rosterClassId ?? null,
      topicText: input.topicText,
      classText: input.classText,
    },
  });
}

export async function deleteWeekly(session: Session, id: number) {
  assertTeacher(session);
  await prisma.weeklyLesson.delete({ where: { id } });
}

export async function listDaily(session: Session, date?: string) {
  assertTeacher(session);
  return prisma.dailyPlan.findMany({
    where: date ? { date } : undefined,
    orderBy: { date: "desc" },
  });
}

export async function createDaily(session: Session, input: z.infer<typeof dailySchema>) {
  assertTeacher(session);
  return prisma.dailyPlan.create({
    data: {
      date: input.date,
      lessonId: input.lessonId ?? null,
      rosterClassId: input.rosterClassId ?? null,
      topicText: input.topicText,
      classText: input.classText,
      topic: input.topic ?? null,
      goals: input.goals ?? null,
      activities: input.activities ?? null,
      materials: input.materials ?? null,
      homework: input.homework ?? null,
      notes: input.notes ?? null,
    },
  });
}

export async function deleteDaily(session: Session, id: number) {
  assertTeacher(session);
  await prisma.dailyPlan.delete({ where: { id } });
}

export async function listAnnual(session: Session, academicYear?: string) {
  assertTeacher(session);
  return prisma.annualPlan.findMany({
    where: academicYear ? { academicYear } : undefined,
    orderBy: { id: "asc" },
  });
}

export async function createAnnual(session: Session, input: z.infer<typeof annualSchema>) {
  assertTeacher(session);
  return prisma.annualPlan.create({
    data: {
      academicYear: input.academicYear,
      lessonId: input.lessonId ?? null,
      rosterClassId: input.rosterClassId ?? null,
      topicText: input.topicText,
      classText: input.classText,
      unitTopic: input.unitTopic,
      plannedTerm: input.plannedTerm ?? null,
      hours: input.hours ?? null,
      goals: input.goals ?? null,
      notes: input.notes ?? null,
    },
  });
}

export async function deleteAnnual(session: Session, id: number) {
  assertTeacher(session);
  await prisma.annualPlan.delete({ where: { id } });
}
