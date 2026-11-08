import { json, readJson, withErrors } from "@/lib/http";
import { sessionCookie, signSession } from "@/lib/session";
import { bootstrapAdmin, bootstrapSchema, publicAccount } from "@/server/accounts";

export const POST = withErrors(async (req) => {
  const body = await readJson(req, bootstrapSchema);
  const account = await bootstrapAdmin(body);
  const token = await signSession(account.id);
  return json({ data: publicAccount(account) }, 201, { "Set-Cookie": sessionCookie(token) });
});
