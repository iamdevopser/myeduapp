import { AppRole } from "@prisma/client";
import { json, queryInt, readJson, requireSession, withErrors } from "@/lib/http";
import { ApiError } from "@/lib/http";
import { createStaffAccount, createStaffSchema, listAccounts } from "@/server/accounts";

const roles = new Set<AppRole>(["teacher", "student", "secretary", "parent", "admin"]);

export const GET = withErrors(async (req) => {
  const session = await requireSession(req);
  const url = new URL(req.url);
  const roleRaw = url.searchParams.get("role");
  if (roleRaw && !roles.has(roleRaw as AppRole)) {
    throw new ApiError(400, "validation_error", "Unknown role");
  }
  const activeRaw = url.searchParams.get("active");
  const data = await listAccounts(session, {
    role: roleRaw ? (roleRaw as AppRole) : undefined,
    search: url.searchParams.get("search") ?? undefined,
    active: activeRaw == null ? undefined : activeRaw === "true",
    take: queryInt(url, "take", 50, 1, 200),
    skip: queryInt(url, "skip", 0, 0, 100000),
  });
  return json(data);
});

export const POST = withErrors(async (req) => {
  const session = await requireSession(req);
  const body = await readJson(req, createStaffSchema);
  const data = await createStaffAccount(session, body);
  return json({ data }, 201);
});
