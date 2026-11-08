import { json, readJson, requireSession, withErrors } from "@/lib/http";
import { academicYearsSchema, getAcademicYears, updateAcademicYears } from "@/server/settings";

export const GET = withErrors(async (req) => {
  const session = await requireSession(req);
  return json({ data: await getAcademicYears(session) });
});

export const PATCH = withErrors(async (req) => {
  const session = await requireSession(req);
  const data = await updateAcademicYears(session, await readJson(req, academicYearsSchema));
  return json({ data });
});
