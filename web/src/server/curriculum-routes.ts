import { empty, json, queryOptionalInt, readJson, requireSession, routeId, withErrors } from "@/lib/http";
import {
  contentPatchSchema,
  contentSchema,
  createContent,
  createCurriculumClass,
  createExam,
  createLesson,
  createLessonNote,
  createQuestionBankItem,
  createTag,
  createTopic,
  createUnit,
  curriculumClassSchema,
  deleteContent,
  deleteCurriculumClass,
  deleteExam,
  deleteLesson,
  deleteLessonNote,
  deleteQuestionBankItem,
  deleteTag,
  deleteTopic,
  deleteUnit,
  examSchema,
  lessonNoteSchema,
  lessonSchema,
  listContents,
  listCurriculumClasses,
  listExams,
  listLessonNotes,
  listLessons,
  listQuestionBank,
  listTags,
  listTopics,
  listUnits,
  questionBankSchema,
  readingSchema,
  saveReadingProgress,
  tagSchema,
  topicSchema,
  toggleFavorite,
  unitSchema,
  updateContent,
  updateCurriculumClass,
  updateLesson,
  updateTopic,
  updateUnit,
} from "@/server/curriculum";

export const curriculumClassRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await listCurriculumClasses(session) });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    const body = await readJson(req, curriculumClassSchema);
    return json({ data: await createCurriculumClass(session, body) }, 201);
  }),
  update: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    const body = await readJson(req, curriculumClassSchema);
    return json({ data: await updateCurriculumClass(session, await routeId(ctx), body) });
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteCurriculumClass(session, await routeId(ctx));
    return empty();
  }),
};

export const lessonRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    const url = new URL(req.url);
    return json({ data: await listLessons(session, queryOptionalInt(url, "curriculumClassId")) });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createLesson(session, await readJson(req, lessonSchema)) }, 201);
  }),
  update: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await updateLesson(session, await routeId(ctx), await readJson(req, lessonSchema.partial())) });
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteLesson(session, await routeId(ctx));
    return empty();
  }),
};

export const unitRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    const url = new URL(req.url);
    return json({ data: await listUnits(session, queryOptionalInt(url, "lessonId")) });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createUnit(session, await readJson(req, unitSchema)) }, 201);
  }),
  update: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await updateUnit(session, await routeId(ctx), await readJson(req, unitSchema.partial())) });
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteUnit(session, await routeId(ctx));
    return empty();
  }),
};

export const topicRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    const url = new URL(req.url);
    return json({
      data: await listTopics(session, {
        lessonId: queryOptionalInt(url, "lessonId"),
        unitId: queryOptionalInt(url, "unitId"),
      }),
    });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createTopic(session, await readJson(req, topicSchema)) }, 201);
  }),
  update: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await updateTopic(session, await routeId(ctx), await readJson(req, topicSchema.partial())) });
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteTopic(session, await routeId(ctx));
    return empty();
  }),
};

export const contentRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    const url = new URL(req.url);
    const archived = url.searchParams.get("archived");
    return json({
      data: await listContents(session, {
        lessonId: queryOptionalInt(url, "lessonId"),
        topicId: queryOptionalInt(url, "topicId"),
        archived: archived == null ? undefined : archived === "true",
      }),
    });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createContent(session, await readJson(req, contentSchema)) }, 201);
  }),
  update: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await updateContent(session, await routeId(ctx), await readJson(req, contentPatchSchema)) });
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteContent(session, await routeId(ctx));
    return empty();
  }),
  favorite: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await toggleFavorite(session, await routeId(ctx)) });
  }),
  progress: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    const data = await saveReadingProgress(session, await routeId(ctx), await readJson(req, readingSchema));
    return json({ data });
  }),
};

export const tagRoutes = {
  list: withErrors(async (req) => json({ data: await listTags(await requireSession(req)) })),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createTag(session, await readJson(req, tagSchema)) }, 201);
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteTag(session, await routeId(ctx));
    return empty();
  }),
};

export const examRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    const url = new URL(req.url);
    return json({ data: await listExams(session, queryOptionalInt(url, "lessonId")) });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createExam(session, await readJson(req, examSchema)) }, 201);
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteExam(session, await routeId(ctx));
    return empty();
  }),
};

export const questionBankRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    const search = new URL(req.url).searchParams.get("search") ?? undefined;
    return json({ data: await listQuestionBank(session, search) });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createQuestionBankItem(session, await readJson(req, questionBankSchema)) }, 201);
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteQuestionBankItem(session, await routeId(ctx));
    return empty();
  }),
};

export const lessonNoteRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await listLessonNotes(session, queryOptionalInt(new URL(req.url), "lessonId")) });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createLessonNote(session, await readJson(req, lessonNoteSchema)) }, 201);
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteLessonNote(session, await routeId(ctx));
    return empty();
  }),
};
