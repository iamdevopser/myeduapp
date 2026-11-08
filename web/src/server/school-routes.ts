import { AnnouncementStatus } from "@prisma/client";
import { empty, json, queryInt, queryOptionalInt, readJson, requireSession, routeId, withErrors } from "@/lib/http";
import { ApiError } from "@/lib/http";
import {
  announcementPatchSchema,
  announcementSchema,
  createAnnouncement,
  getAnnouncement,
  listAnnouncements,
  updateAnnouncement,
} from "@/server/announcements";
import {
  attendanceBatchSchema,
  attendanceUpsertSchema,
  listAttendance,
  upsertAttendance,
  upsertAttendanceBatch,
} from "@/server/attendance";
import {
  addFolderItem,
  archiveDocument,
  createDocument,
  createFolder,
  deleteDocument,
  deleteFolder,
  documentPatchSchema,
  documentSchema,
  folderItemSchema,
  folderSchema,
  getDocument,
  listDocuments,
  listFolders,
  removeFolderItem,
  updateDocument,
} from "@/server/documents";
import {
  behaviorRecordSchema,
  columnNoteSchema,
  createBehaviorRecord,
  createScoreColumn,
  deleteScoreColumn,
  gradeCellSchema,
  listBehaviorRecords,
  listBehaviors,
  listGradeCells,
  listScoreColumns,
  scoreColumnSchema,
  upsertColumnNote,
  upsertGradeCell,
} from "@/server/grades";
import {
  createLink,
  createParent,
  createRosterClass,
  createStudent,
  deleteLink,
  deleteRosterClass,
  deleteStudent,
  linkSchema,
  listCategories,
  listLinks,
  listParents,
  listRosterClasses,
  listStudents,
  parentPatchSchema,
  parentSchema,
  rosterClassSchema,
  studentPatchSchema,
  studentSchema,
  updateParent,
  updateRosterClass,
  updateStudent,
  getStudent,
  categorySchema,
  createCategory,
} from "@/server/roster";

const announcementStatuses = new Set<AnnouncementStatus>(["draft", "published", "unpublished"]);

export const rosterRoutes = {
  list: withErrors(async (req) => json({ data: await listRosterClasses(await requireSession(req)) })),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createRosterClass(session, await readJson(req, rosterClassSchema)) }, 201);
  }),
  update: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({
      data: await updateRosterClass(session, await routeId(ctx), await readJson(req, rosterClassSchema.partial())),
    });
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteRosterClass(session, await routeId(ctx));
    return empty();
  }),
};

export const studentRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    const url = new URL(req.url);
    return json({
      data: await listStudents(session, queryOptionalInt(url, "rosterClassId"), url.searchParams.get("search") ?? undefined),
    });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createStudent(session, await readJson(req, studentSchema)) }, 201);
  }),
  get: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await getStudent(session, await routeId(ctx)) });
  }),
  update: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await updateStudent(session, await routeId(ctx), await readJson(req, studentPatchSchema)) });
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteStudent(session, await routeId(ctx));
    return empty();
  }),
};

export const parentRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await listParents(session, new URL(req.url).searchParams.get("search") ?? undefined) });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createParent(session, await readJson(req, parentSchema)) }, 201);
  }),
  update: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await updateParent(session, await routeId(ctx), await readJson(req, parentPatchSchema)) });
  }),
};

export const linkRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await listLinks(session, queryOptionalInt(new URL(req.url), "studentId")) });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createLink(session, await readJson(req, linkSchema)) }, 201);
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteLink(session, await routeId(ctx));
    return empty();
  }),
};

export const categoryRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    const rosterClassId = queryOptionalInt(new URL(req.url), "rosterClassId");
    if (!rosterClassId) throw new ApiError(400, "validation_error", "rosterClassId is required");
    return json({ data: await listCategories(session, rosterClassId) });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createCategory(session, await readJson(req, categorySchema)) }, 201);
  }),
};

export const attendanceRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    const url = new URL(req.url);
    return json({
      data: await listAttendance(session, {
        date: url.searchParams.get("date") ?? undefined,
        rosterClassId: queryOptionalInt(url, "rosterClassId"),
        studentId: queryOptionalInt(url, "studentId"),
      }),
    });
  }),
  upsert: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await upsertAttendance(session, await readJson(req, attendanceUpsertSchema)) });
  }),
  batch: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await upsertAttendanceBatch(session, await readJson(req, attendanceBatchSchema)) });
  }),
};

export const announcementRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    const url = new URL(req.url);
    const status = url.searchParams.get("status");
    if (status && !announcementStatuses.has(status as AnnouncementStatus)) {
      throw new ApiError(400, "validation_error", "Unknown status");
    }
    return json(
      await listAnnouncements(session, {
        status: status ? (status as AnnouncementStatus) : undefined,
        search: url.searchParams.get("search") ?? undefined,
        take: queryInt(url, "take", 50, 1, 200),
        skip: queryInt(url, "skip", 0, 0, 100000),
      }),
    );
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createAnnouncement(session, await readJson(req, announcementSchema)) }, 201);
  }),
  get: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await getAnnouncement(session, await routeId(ctx)) });
  }),
  update: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await updateAnnouncement(session, await routeId(ctx), await readJson(req, announcementPatchSchema)) });
  }),
};

export const documentRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await listDocuments(session, new URL(req.url).searchParams.get("search") ?? undefined) });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createDocument(session, await readJson(req, documentSchema)) }, 201);
  }),
  get: withErrors(async (req, ctx) => json({ data: await getDocument(await requireSession(req), await routeId(ctx)) })),
  update: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await updateDocument(session, await routeId(ctx), await readJson(req, documentPatchSchema)) });
  }),
  archive: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    return json({ data: await archiveDocument(session, await routeId(ctx)) });
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteDocument(session, await routeId(ctx));
    return empty();
  }),
};

export const folderRoutes = {
  list: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await listFolders(session, queryOptionalInt(new URL(req.url), "parentId")) });
  }),
  create: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createFolder(session, await readJson(req, folderSchema)) }, 201);
  }),
  remove: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteFolder(session, await routeId(ctx));
    return empty();
  }),
  addItem: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    const body = await readJson(req, folderItemSchema);
    return json({ data: await addFolderItem(session, await routeId(ctx), body.contentId) }, 201);
  }),
  removeItem: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    const contentId = queryOptionalInt(new URL(req.url), "contentId");
    if (!contentId) throw new ApiError(400, "validation_error", "contentId is required");
    await removeFolderItem(session, await routeId(ctx), contentId);
    return empty();
  }),
};

export const gradeRoutes = {
  columns: withErrors(async (req) => {
    const session = await requireSession(req);
    const rosterClassId = queryOptionalInt(new URL(req.url), "rosterClassId");
    if (!rosterClassId) throw new ApiError(400, "validation_error", "rosterClassId is required");
    return json({ data: await listScoreColumns(session, rosterClassId) });
  }),
  createColumn: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createScoreColumn(session, await readJson(req, scoreColumnSchema)) }, 201);
  }),
  deleteColumn: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteScoreColumn(session, await routeId(ctx));
    return empty();
  }),
  cells: withErrors(async (req) => {
    const session = await requireSession(req);
    const url = new URL(req.url);
    return json({
      data: await listGradeCells(session, {
        studentId: queryOptionalInt(url, "studentId"),
        columnId: queryOptionalInt(url, "columnId"),
      }),
    });
  }),
  upsertCell: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await upsertGradeCell(session, await readJson(req, gradeCellSchema)) });
  }),
  note: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await upsertColumnNote(session, await readJson(req, columnNoteSchema)) });
  }),
  behaviors: withErrors(async (req) => {
    await requireSession(req);
    return json({ data: await listBehaviors() });
  }),
  behaviorRecords: withErrors(async (req) => {
    const session = await requireSession(req);
    const studentId = queryOptionalInt(new URL(req.url), "studentId");
    if (!studentId) throw new ApiError(400, "validation_error", "studentId is required");
    return json({ data: await listBehaviorRecords(session, studentId) });
  }),
  createBehavior: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createBehaviorRecord(session, await readJson(req, behaviorRecordSchema)) }, 201);
  }),
};
