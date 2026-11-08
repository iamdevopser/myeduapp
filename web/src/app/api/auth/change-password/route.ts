import { empty, readJson, requireSession, withErrors } from "@/lib/http";
import { changePassword, changePasswordSchema } from "@/server/accounts";

export const POST = withErrors(async (req) => {
  const session = await requireSession(req);
  const body = await readJson(req, changePasswordSchema);
  await changePassword(session, body);
  return empty();
});
