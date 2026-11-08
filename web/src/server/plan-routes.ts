import { empty, json, queryOptionalInt, readJson, requireSession, routeId, withErrors } from "@/lib/http";
import {
  annualSchema,
  createAnnual,
  createDaily,
  createWeekly,
  dailySchema,
  deleteAnnual,
  deleteDaily,
  deleteWeekly,
  listAnnual,
  listDaily,
  listPeriods,
  listWeekly,
  periodSchema,
  upsertPeriod,
  weeklySchema,
} from "@/server/plans";
import {
  createEvent,
  createMentorshipNote,
  createMentorshipReport,
  createNotebook,
  deleteEvent,
  deleteNotebook,
  eventSchema,
  linkMentorshipClass,
  listEvents,
  listMentorshipClasses,
  listMentorshipNotes,
  listMentorshipReports,
  listNotebook,
  mentorshipNoteSchema,
  mentorshipReportSchema,
  notebookSchema,
} from "@/server/mentorship";
import { ApiError } from "@/lib/http";
import { z } from "zod";

const classLinkSchema = z.object({ rosterClassId: z.number().int().positive() });

export const planRoutes = {
  periods: withErrors(async (req) => json({ data: await listPeriods(await requireSession(req)) })),
  upsertPeriod: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await upsertPeriod(session, await readJson(req, periodSchema)) });
  }),
  weekly: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await listWeekly(session, queryOptionalInt(new URL(req.url), "rosterClassId")) });
  }),
  createWeekly: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createWeekly(session, await readJson(req, weeklySchema)) }, 201);
  }),
  deleteWeekly: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteWeekly(session, await routeId(ctx));
    return empty();
  }),
  daily: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await listDaily(session, new URL(req.url).searchParams.get("date") ?? undefined) });
  }),
  createDaily: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createDaily(session, await readJson(req, dailySchema)) }, 201);
  }),
  deleteDaily: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteDaily(session, await routeId(ctx));
    return empty();
  }),
  annual: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await listAnnual(session, new URL(req.url).searchParams.get("academicYear") ?? undefined) });
  }),
  createAnnual: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createAnnual(session, await readJson(req, annualSchema)) }, 201);
  }),
  deleteAnnual: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteAnnual(session, await routeId(ctx));
    return empty();
  }),
};

export const mentorshipRoutes = {
  classes: withErrors(async (req) => json({ data: await listMentorshipClasses(await requireSession(req)) })),
  linkClass: withErrors(async (req) => {
    const session = await requireSession(req);
    const body = await readJson(req, classLinkSchema);
    return json({ data: await linkMentorshipClass(session, body.rosterClassId) }, 201);
  }),
  events: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await listEvents(session, queryOptionalInt(new URL(req.url), "rosterClassId")) });
  }),
  createEvent: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createEvent(session, await readJson(req, eventSchema)) }, 201);
  }),
  deleteEvent: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteEvent(session, await routeId(ctx));
    return empty();
  }),
  notes: withErrors(async (req) => {
    const session = await requireSession(req);
    const studentId = queryOptionalInt(new URL(req.url), "studentId");
    if (!studentId) throw new ApiError(400, "validation_error", "studentId is required");
    return json({ data: await listMentorshipNotes(session, studentId) });
  }),
  createNote: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createMentorshipNote(session, await readJson(req, mentorshipNoteSchema)) }, 201);
  }),
  reports: withErrors(async (req) => {
    const session = await requireSession(req);
    const studentId = queryOptionalInt(new URL(req.url), "studentId");
    if (!studentId) throw new ApiError(400, "validation_error", "studentId is required");
    return json({ data: await listMentorshipReports(session, studentId) });
  }),
  createReport: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createMentorshipReport(session, await readJson(req, mentorshipReportSchema)) }, 201);
  }),
  notebook: withErrors(async (req) => {
    const session = await requireSession(req);
    const rosterClassId = queryOptionalInt(new URL(req.url), "rosterClassId");
    if (!rosterClassId) throw new ApiError(400, "validation_error", "rosterClassId is required");
    return json({ data: await listNotebook(session, rosterClassId) });
  }),
  createNotebook: withErrors(async (req) => {
    const session = await requireSession(req);
    return json({ data: await createNotebook(session, await readJson(req, notebookSchema)) }, 201);
  }),
  deleteNotebook: withErrors(async (req, ctx) => {
    const session = await requireSession(req);
    await deleteNotebook(session, await routeId(ctx));
    return empty();
  }),
};
