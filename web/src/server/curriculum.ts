import { ContentType, Prisma, QuestionType } from "@prisma/client";
import { z } from "zod";
import { assertTeacher, notFound, recordTeacherActivity } from "@/lib/access";
import { compareCurriculumClassNames } from "@/lib/curriculum-sort";
import { prisma } from "@/lib/db";
import { ApiError, Session } from "@/lib/http";

const contentTypes = z.enum([
  "text",
  "pdf",
  "ppt",
  "word",
  "image",
  "video",
  "audio",
  "link",
  "homework",
  "question",
  "exam",
]);
const questionTypes = z.enum(["text", "image", "mcq"]);

export const curriculumClassSchema = z.object({ name: z.string().trim().min(1).max(120) });
export const lessonSchema = z.object({
  curriculumClassId: z.number().int().positive(),
  name: z.string().trim().min(1).max(160),
  order: z.number().int().min(0).optional(),
  academicYear: z.string().trim().max(32).optional(),
  imageKey: z.string().trim().max(300).nullable().optional(),
  teacherName: z.string().trim().max(120).nullable().optional(),
});
export const unitSchema = z.object({
  lessonId: z.number().int().positive(),
  name: z.string().trim().min(1).max(160),
  number: z.number().int().min(1).optional(),
  order: z.number().int().min(0).optional(),
  imageKey: z.string().trim().max(300).nullable().optional(),
});
export const topicSchema = z.object({
  lessonId: z.number().int().positive(),
  unitId: z.number().int().positive().nullable().optional(),
  name: z.string().trim().min(1).max(160),
  order: z.number().int().min(0).optional(),
  imageKey: z.string().trim().max(300).nullable().optional(),
});
export const contentSchema = z.object({
  lessonId: z.number().int().positive(),
  topicId: z.number().int().positive().nullable().optional(),
  name: z.string().trim().min(1).max(200),
  type: contentTypes,
  storageKey: z.string().trim().min(1).max(300),
  order: z.number().int().min(0).optional(),
  tagIds: z.array(z.number().int().positive()).optional(),
});
export const contentPatchSchema = contentSchema.partial().extend({
  archived: z.boolean().optional(),
});
export const tagSchema = z.object({ name: z.string().trim().min(1).max(60) });
export const examSchema = z.object({
  lessonId: z.number().int().positive(),
  topicId: z.number().int().positive().nullable().optional(),
  name: z.string().trim().min(1).max(200),
  questions: z
    .array(
      z.object({
        prompt: z.string().trim().min(1),
        type: questionTypes.default("text"),
        options: z.array(z.string()).default([]),
        correctOptionIndex: z.number().int().min(0).nullable().optional(),
        audioKey: z.string().trim().max(300).nullable().optional(),
        order: z.number().int().min(0),
      }),
    )
    .default([]),
});
export const questionBankSchema = z.object({
  prompt: z.string().trim().min(1),
  type: questionTypes,
  options: z.array(z.string()).default([]),
  correctOptionIndex: z.number().int().min(0).nullable().optional(),
  imageKey: z.string().trim().max(300).nullable().optional(),
  audioKey: z.string().trim().max(300).nullable().optional(),
  tags: z.string().trim().max(300).nullable().optional(),
});
export const readingSchema = z.object({
  lastPage: z.number().int().min(1),
  extraJson: z.string().max(4000).nullable().optional(),
});
export const lessonNoteSchema = z.object({
  lessonId: z.number().int().positive(),
  topicId: z.number().int().positive().nullable().optional(),
  text: z.string().trim().min(1),
});

function viewerCanReadCurriculum(session: Session): boolean {
  return session.role === "teacher" || session.role === "student" || session.role === "parent" || session.role === "secretary";
}

export async function listCurriculumClasses(session: Session) {
  if (!viewerCanReadCurriculum(session)) throw notFound();
  const rows = await prisma.curriculumClass.findMany();
  return rows.sort((a, b) => compareCurriculumClassNames(a.name, b.name));
}

export async function createCurriculumClass(session: Session, input: { name: string }) {
  assertTeacher(session);
  const created = await prisma.curriculumClass.create({ data: { name: input.name } });
  await recordTeacherActivity(session, { type: "curriculum_class", title: created.name, targetType: "curriculum_class", targetId: created.id });
  return created;
}

export async function updateCurriculumClass(session: Session, id: number, input: { name: string }) {
  assertTeacher(session);
  return prisma.curriculumClass.update({ where: { id }, data: { name: input.name } });
}

export async function deleteCurriculumClass(session: Session, id: number) {
  assertTeacher(session);
  await prisma.curriculumClass.delete({ where: { id } });
}

export async function listLessons(session: Session, curriculumClassId?: number) {
  if (!viewerCanReadCurriculum(session)) throw notFound();
  return prisma.lesson.findMany({
    where: curriculumClassId ? { curriculumClassId } : undefined,
    orderBy: [{ order: "asc" }, { name: "asc" }],
  });
}

export async function createLesson(session: Session, input: z.infer<typeof lessonSchema>) {
  assertTeacher(session);
  return prisma.lesson.create({
    data: {
      curriculumClassId: input.curriculumClassId,
      name: input.name,
      order: input.order ?? 0,
      academicYear: input.academicYear ?? "",
      imageKey: input.imageKey ?? null,
      teacherName: input.teacherName ?? null,
    },
  });
}

export async function updateLesson(session: Session, id: number, input: Partial<z.infer<typeof lessonSchema>>) {
  assertTeacher(session);
  return prisma.lesson.update({
    where: { id },
    data: {
      curriculumClassId: input.curriculumClassId,
      name: input.name,
      order: input.order,
      academicYear: input.academicYear,
      imageKey: input.imageKey,
      teacherName: input.teacherName,
    },
  });
}

export async function deleteLesson(session: Session, id: number) {
  assertTeacher(session);
  await prisma.lesson.delete({ where: { id } });
}

export async function listUnits(session: Session, lessonId?: number) {
  if (!viewerCanReadCurriculum(session)) throw notFound();
  return prisma.unit.findMany({
    where: lessonId ? { lessonId } : undefined,
    orderBy: [{ order: "asc" }, { number: "asc" }],
  });
}

export async function createUnit(session: Session, input: z.infer<typeof unitSchema>) {
  assertTeacher(session);
  return prisma.unit.create({
    data: {
      lessonId: input.lessonId,
      name: input.name,
      number: input.number ?? 1,
      order: input.order ?? 0,
      imageKey: input.imageKey ?? null,
    },
  });
}

export async function updateUnit(session: Session, id: number, input: Partial<z.infer<typeof unitSchema>>) {
  assertTeacher(session);
  return prisma.unit.update({
    where: { id },
    data: {
      name: input.name,
      number: input.number,
      order: input.order,
      imageKey: input.imageKey,
    },
  });
}

export async function deleteUnit(session: Session, id: number) {
  assertTeacher(session);
  await prisma.unit.delete({ where: { id } });
}

export async function listTopics(session: Session, filters: { lessonId?: number; unitId?: number }) {
  if (!viewerCanReadCurriculum(session)) throw notFound();
  return prisma.topic.findMany({
    where: { lessonId: filters.lessonId, unitId: filters.unitId },
    orderBy: [{ order: "asc" }, { name: "asc" }],
  });
}

export async function createTopic(session: Session, input: z.infer<typeof topicSchema>) {
  assertTeacher(session);
  return prisma.topic.create({
    data: {
      lessonId: input.lessonId,
      unitId: input.unitId ?? null,
      name: input.name,
      order: input.order ?? 0,
      imageKey: input.imageKey ?? null,
    },
  });
}

export async function updateTopic(session: Session, id: number, input: Partial<z.infer<typeof topicSchema>>) {
  assertTeacher(session);
  return prisma.topic.update({
    where: { id },
    data: {
      unitId: input.unitId,
      name: input.name,
      order: input.order,
      imageKey: input.imageKey,
    },
  });
}

export async function deleteTopic(session: Session, id: number) {
  assertTeacher(session);
  await prisma.topic.delete({ where: { id } });
}

function contentWhere(session: Session, filters: { lessonId?: number; topicId?: number; archived?: boolean }): Prisma.ContentWhereInput {
  const where: Prisma.ContentWhereInput = { isSchoolDocument: false };
  if (filters.lessonId) where.lessonId = filters.lessonId;
  if (filters.topicId) where.topicId = filters.topicId;
  if (session.role !== "teacher") where.archived = false;
  else if (filters.archived != null) where.archived = filters.archived;
  return where;
}

export async function listContents(
  session: Session,
  filters: { lessonId?: number; topicId?: number; archived?: boolean },
) {
  if (!viewerCanReadCurriculum(session)) throw notFound();
  const rows = await prisma.content.findMany({
    where: contentWhere(session, filters),
    include: { tags: { include: { tag: true } }, favorites: { where: { accountId: session.accountId } } },
    orderBy: [{ order: "asc" }, { name: "asc" }],
  });
  return rows.map((row) => ({
    id: row.id,
    lessonId: row.lessonId,
    topicId: row.topicId,
    name: row.name,
    type: row.type,
    storageKey: row.storageKey,
    order: row.order,
    archived: row.archived,
    createdAt: row.createdAt.toISOString(),
    favorite: row.favorites.length > 0,
    tags: row.tags.map((link) => ({ id: link.tag.id, name: link.tag.name })),
  }));
}

export async function createContent(session: Session, input: z.infer<typeof contentSchema>) {
  assertTeacher(session);
  return prisma.content.create({
    data: {
      lessonId: input.lessonId,
      topicId: input.topicId ?? null,
      name: input.name,
      type: input.type as ContentType,
      storageKey: input.storageKey,
      order: input.order ?? 0,
      tags: { create: (input.tagIds ?? []).map((tagId) => ({ tagId })) },
    },
  });
}

export async function updateContent(session: Session, id: number, input: z.infer<typeof contentPatchSchema>) {
  assertTeacher(session);
  return prisma.$transaction(async (tx) => {
    if (input.tagIds) {
      await tx.contentTag.deleteMany({ where: { contentId: id } });
      if (input.tagIds.length > 0) {
        await tx.contentTag.createMany({
          data: input.tagIds.map((tagId) => ({ contentId: id, tagId })),
        });
      }
    }
    return tx.content.update({
      where: { id },
      data: {
        lessonId: input.lessonId,
        topicId: input.topicId,
        name: input.name,
        type: input.type as ContentType | undefined,
        storageKey: input.storageKey,
        order: input.order,
        archived: input.archived,
      },
    });
  });
}

export async function deleteContent(session: Session, id: number) {
  assertTeacher(session);
  const content = await prisma.content.findUnique({ where: { id } });
  if (!content || content.isSchoolDocument) throw notFound();
  if (content.critical) {
    throw new ApiError(409, "critical_document", "Critical documents cannot be deleted");
  }
  await prisma.content.delete({ where: { id } });
}

export async function toggleFavorite(session: Session, contentId: number) {
  const content = await prisma.content.findUnique({ where: { id: contentId } });
  if (!content) throw notFound();
  const existing = await prisma.favorite.findUnique({
    where: { accountId_contentId: { accountId: session.accountId, contentId } },
  });
  if (existing) {
    await prisma.favorite.delete({
      where: { accountId_contentId: { accountId: session.accountId, contentId } },
    });
    return { favorite: false };
  }
  await prisma.favorite.create({ data: { accountId: session.accountId, contentId } });
  return { favorite: true };
}

export async function saveReadingProgress(session: Session, contentId: number, input: z.infer<typeof readingSchema>) {
  const content = await prisma.content.findUnique({ where: { id: contentId } });
  if (!content) throw notFound();
  return prisma.contentReadingProgress.upsert({
    where: { accountId_contentId: { accountId: session.accountId, contentId } },
    create: {
      accountId: session.accountId,
      contentId,
      lastPage: input.lastPage,
      extraJson: input.extraJson ?? null,
    },
    update: { lastPage: input.lastPage, extraJson: input.extraJson ?? null },
  });
}

export async function listTags(session: Session) {
  assertTeacher(session);
  return prisma.tag.findMany({ orderBy: { name: "asc" } });
}

export async function createTag(session: Session, input: { name: string }) {
  assertTeacher(session);
  return prisma.tag.create({ data: { name: input.name } });
}

export async function deleteTag(session: Session, id: number) {
  assertTeacher(session);
  await prisma.tag.delete({ where: { id } });
}

export async function listExams(session: Session, lessonId?: number) {
  if (session.role !== "teacher" && session.role !== "student") throw notFound();
  return prisma.exam.findMany({
    where: lessonId ? { lessonId } : undefined,
    include: { questions: { orderBy: { order: "asc" } } },
    orderBy: { createdAt: "desc" },
  });
}

export async function createExam(session: Session, input: z.infer<typeof examSchema>) {
  assertTeacher(session);
  return prisma.exam.create({
    data: {
      lessonId: input.lessonId,
      topicId: input.topicId ?? null,
      name: input.name,
      questions: {
        create: input.questions.map((question) => ({
          prompt: question.prompt,
          type: question.type as QuestionType,
          options: question.options,
          correctOptionIndex: question.correctOptionIndex ?? null,
          audioKey: question.audioKey ?? null,
          order: question.order,
        })),
      },
    },
    include: { questions: true },
  });
}

export async function deleteExam(session: Session, id: number) {
  assertTeacher(session);
  await prisma.exam.delete({ where: { id } });
}

export async function listQuestionBank(session: Session, search?: string) {
  assertTeacher(session);
  return prisma.questionBankItem.findMany({
    where: search ? { prompt: { contains: search, mode: "insensitive" } } : undefined,
    orderBy: { createdAt: "desc" },
    take: 200,
  });
}

export async function createQuestionBankItem(session: Session, input: z.infer<typeof questionBankSchema>) {
  assertTeacher(session);
  return prisma.questionBankItem.create({
    data: {
      prompt: input.prompt,
      type: input.type as QuestionType,
      options: input.options,
      correctOptionIndex: input.correctOptionIndex ?? null,
      imageKey: input.imageKey ?? null,
      audioKey: input.audioKey ?? null,
      tags: input.tags ?? null,
    },
  });
}

export async function deleteQuestionBankItem(session: Session, id: number) {
  assertTeacher(session);
  await prisma.questionBankItem.delete({ where: { id } });
}

export async function listLessonNotes(session: Session, lessonId?: number) {
  assertTeacher(session);
  return prisma.lessonNote.findMany({
    where: lessonId ? { lessonId } : undefined,
    orderBy: { createdAt: "desc" },
  });
}

export async function createLessonNote(session: Session, input: z.infer<typeof lessonNoteSchema>) {
  assertTeacher(session);
  return prisma.lessonNote.create({
    data: {
      lessonId: input.lessonId,
      topicId: input.topicId ?? null,
      text: input.text,
    },
  });
}

export async function deleteLessonNote(session: Session, id: number) {
  assertTeacher(session);
  await prisma.lessonNote.delete({ where: { id } });
}
