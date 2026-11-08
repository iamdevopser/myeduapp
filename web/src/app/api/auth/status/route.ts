import { prisma } from "@/lib/db";
import { json, withErrors } from "@/lib/http";

export const GET = withErrors(async () => {
  const admins = await prisma.account.count({ where: { role: "admin", active: true } });
  return json({ data: { hasAdmin: admins > 0 } });
});
