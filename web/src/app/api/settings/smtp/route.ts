import { json, readJson, requireSession, withErrors } from "@/lib/http";
import { getSmtp, smtpSchema, updateSmtp } from "@/server/settings";

export const GET = withErrors(async (req) => {
  const session = await requireSession(req);
  return json({ data: await getSmtp(session) });
});

export const PATCH = withErrors(async (req) => {
  const session = await requireSession(req);
  return json({ data: await updateSmtp(session, await readJson(req, smtpSchema)) });
});
