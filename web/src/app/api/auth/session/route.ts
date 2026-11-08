import { json, requireSession, withErrors } from "@/lib/http";
import { prisma } from "@/lib/db";
import { publicAccount } from "@/server/accounts";

export const GET = withErrors(async (req) => {
  const session = await requireSession(req);
  const account = await prisma.account.findUniqueOrThrow({ where: { id: session.accountId } });
  return json({ data: publicAccount(account) });
});
