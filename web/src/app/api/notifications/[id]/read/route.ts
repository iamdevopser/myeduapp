import { json, requireSession, routeId, withErrors } from "@/lib/http";
import { ApiError } from "@/lib/http";
import { markNotificationRead } from "@/server/notifications";

export const POST = withErrors(async (req, ctx) => {
  const session = await requireSession(req);
  const updated = await markNotificationRead(session, await routeId(ctx));
  if (!updated) throw new ApiError(404, "not_found", "Notification not found");
  return json({ data: { id: updated.id, status: updated.status } });
});
