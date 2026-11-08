import { json, readJson, requireSession, withErrors } from "@/lib/http";
import { getPreferences, preferenceSchema, updatePreferences } from "@/server/settings";

export const GET = withErrors(async (req) => {
  const session = await requireSession(req);
  return json({ data: await getPreferences(session) });
});

export const PATCH = withErrors(async (req) => {
  const session = await requireSession(req);
  const data = await updatePreferences(session, await readJson(req, preferenceSchema));
  return json({ data: { locale: data.locale, themeMode: data.themeMode } });
});
