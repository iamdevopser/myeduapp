import { json, requireSession, withErrors } from "@/lib/http";
import { assertTeacher } from "@/lib/access";
import { prisma } from "@/lib/db";

export const GET = withErrors(async (req) => {
  const session = await requireSession(req);
  assertTeacher(session);
  const data = await prisma.teacherActivity.findMany({
    where: { accountId: session.accountId },
    orderBy: [{ createdAt: "desc" }, { id: "desc" }],
    take: 20,
  });
  return json({ data });
});
