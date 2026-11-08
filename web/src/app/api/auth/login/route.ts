import { json, readJson, withErrors } from "@/lib/http";
import { sessionCookie, signSession } from "@/lib/session";
import { login, loginSchema, publicAccount } from "@/server/accounts";

export const POST = withErrors(async (req) => {
  const body = await readJson(req, loginSchema);
  const account = await login(body);
  const token = await signSession(account.id);
  return json({ data: publicAccount(account) }, 200, { "Set-Cookie": sessionCookie(token) });
});
