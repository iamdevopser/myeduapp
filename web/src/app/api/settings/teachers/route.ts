import { json, requireSession, withErrors } from "@/lib/http";
import { listTeachersForPick } from "@/server/settings";

export const GET = withErrors(async (req) => {
  const session = await requireSession(req);
  return json({ data: await listTeachersForPick(session) });
});
