import { json, readJson, requireSession, routeId, withErrors } from "@/lib/http";
import { getAccount, updateAccount, updateAccountSchema } from "@/server/accounts";

export const GET = withErrors(async (req, ctx) => {
  const session = await requireSession(req);
  return json({ data: await getAccount(session, await routeId(ctx)) });
});

export const PATCH = withErrors(async (req, ctx) => {
  const session = await requireSession(req);
  const body = await readJson(req, updateAccountSchema);
  return json({ data: await updateAccount(session, await routeId(ctx), body) });
});
