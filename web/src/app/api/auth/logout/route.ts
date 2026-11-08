import { empty, withErrors } from "@/lib/http";
import { clearSessionCookie } from "@/lib/session";

export const POST = withErrors(async () => {
  return empty(204, { "Set-Cookie": clearSessionCookie() });
});
