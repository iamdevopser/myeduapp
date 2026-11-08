import { json, queryInt, requireSession, withErrors } from "@/lib/http";
import { listNotifications } from "@/server/notifications";

export const GET = withErrors(async (req) => {
  const session = await requireSession(req);
  const url = new URL(req.url);
  return json(
    await listNotifications(session, queryInt(url, "take", 50, 1, 200), queryInt(url, "skip", 0, 0, 100000)),
  );
});
