import { AppRole, Prisma } from "@prisma/client";
import { z } from "zod";
import { assertAdmin, forbidden } from "@/lib/access";
import { prisma } from "@/lib/db";
import { ApiError, Session } from "@/lib/http";
import { hashPassword, verifyPassword } from "@/lib/password";

const usernameSchema = z.string().trim().min(3).max(64);
const passwordSchema = z.string().min(8).max(128);
const emailSchema = z.string().trim().email().max(254).optional().nullable();

export const loginSchema = z.object({
  login: z.string().trim().min(1).max(254),
  password: z.string().min(1).max(128),
});

export const bootstrapSchema = z.object({
  username: usernameSchema,
  password: passwordSchema,
  fullName: z.string().trim().min(1).max(120),
  email: emailSchema,
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1).max(128),
  newPassword: passwordSchema,
});

export const createStaffSchema = z.object({
  username: usernameSchema,
  password: passwordSchema,
  fullName: z.string().trim().min(1).max(120),
  email: emailSchema,
  role: z.enum(["teacher", "secretary"]),
  mustChangePassword: z.boolean().default(true),
});

export const updateAccountSchema = z.object({
  fullName: z.string().trim().min(1).max(120).optional(),
  email: emailSchema,
  active: z.boolean().optional(),
  role: z.enum(["teacher", "secretary", "admin"]).optional(),
  mustChangePassword: z.boolean().optional(),
});

export function publicAccount(account: {
  id: number;
  username: string;
  email: string | null;
  fullName: string;
  role: AppRole;
  active: boolean;
  domainType: string | null;
  domainId: number | null;
  mustChangePassword: boolean;
  createdAt: Date;
  updatedAt: Date;
  lastLoginAt: Date | null;
}) {
  return {
    id: account.id,
    username: account.username,
    email: account.email,
    fullName: account.fullName,
    role: account.role,
    active: account.active,
    domainType: account.domainType,
    domainId: account.domainId,
    mustChangePassword: account.mustChangePassword,
    createdAt: account.createdAt.toISOString(),
    updatedAt: account.updatedAt.toISOString(),
    lastLoginAt: account.lastLoginAt?.toISOString() ?? null,
  };
}

async function writeAudit(input: {
  accountId?: number | null;
  actorAccountId?: number | null;
  action: string;
  detail?: string;
}) {
  await prisma.accountAudit.create({
    data: {
      accountId: input.accountId ?? null,
      actorAccountId: input.actorAccountId ?? null,
      action: input.action,
      detail: input.detail,
    },
  });
}

export async function login(input: { login: string; password: string }) {
  const loginValue = input.login.trim();
  const account = await prisma.account.findFirst({
    where: {
      OR: [
        { username: { equals: loginValue, mode: "insensitive" } },
        { email: { equals: loginValue, mode: "insensitive" } },
      ],
    },
  });
  if (!account || !account.active) {
    throw new ApiError(401, "invalid_credentials", "Invalid username or password");
  }
  const verified = await verifyPassword(input.password, account.passwordHash);
  if (!verified.ok) {
    throw new ApiError(401, "invalid_credentials", "Invalid username or password");
  }
  const passwordHash = verified.rehash ? await hashPassword(input.password) : account.passwordHash;
  const updated = await prisma.account.update({
    where: { id: account.id },
    data: { passwordHash, lastLoginAt: new Date() },
  });
  await writeAudit({ accountId: account.id, actorAccountId: account.id, action: "login" });
  return updated;
}

export async function bootstrapAdmin(input: z.infer<typeof bootstrapSchema>) {
  const existing = await prisma.account.count({ where: { role: "admin", active: true } });
  if (existing > 0) {
    throw forbidden("An active administrator already exists");
  }
  const account = await prisma.account.create({
    data: {
      username: input.username,
      email: input.email || null,
      fullName: input.fullName,
      role: "admin",
      passwordHash: await hashPassword(input.password),
      mustChangePassword: false,
      preference: { create: {} },
    },
  });
  await writeAudit({ accountId: account.id, action: "bootstrap_admin" });
  return account;
}

export async function changePassword(session: Session, input: z.infer<typeof changePasswordSchema>) {
  const account = await prisma.account.findUnique({ where: { id: session.accountId } });
  if (!account) throw new ApiError(401, "unauthenticated", "Authentication required");
  const verified = await verifyPassword(input.currentPassword, account.passwordHash);
  if (!verified.ok) {
    throw new ApiError(400, "invalid_password", "Current password is wrong");
  }
  await prisma.account.update({
    where: { id: account.id },
    data: {
      passwordHash: await hashPassword(input.newPassword),
      mustChangePassword: false,
    },
  });
  await writeAudit({ accountId: account.id, actorAccountId: account.id, action: "change_password" });
}

export async function listAccounts(
  session: Session,
  query: { role?: AppRole; search?: string; active?: boolean; take: number; skip: number },
) {
  assertAdmin(session);
  const where: Prisma.AccountWhereInput = {};
  if (query.role) where.role = query.role;
  if (query.active != null) where.active = query.active;
  if (query.search) {
    where.OR = [
      { username: { contains: query.search, mode: "insensitive" } },
      { fullName: { contains: query.search, mode: "insensitive" } },
      { email: { contains: query.search, mode: "insensitive" } },
    ];
  }
  const [total, rows] = await prisma.$transaction([
    prisma.account.count({ where }),
    prisma.account.findMany({
      where,
      orderBy: [{ role: "asc" }, { username: "asc" }],
      take: query.take,
      skip: query.skip,
    }),
  ]);
  return { total, data: rows.map(publicAccount) };
}

export async function getAccount(session: Session, id: number) {
  assertAdmin(session);
  const account = await prisma.account.findUnique({ where: { id } });
  if (!account) throw new ApiError(404, "not_found", "Account not found");
  return publicAccount(account);
}

async function assertNotLastAdmin(accountId: number, next: { active?: boolean; role?: AppRole }) {
  const current = await prisma.account.findUnique({ where: { id: accountId } });
  if (!current || current.role !== "admin" || !current.active) return;
  const demoting = next.role != null && next.role !== "admin";
  const disabling = next.active === false;
  if (!demoting && !disabling) return;
  const others = await prisma.account.count({
    where: { role: "admin", active: true, id: { not: accountId } },
  });
  if (others === 0) {
    throw new ApiError(409, "last_admin", "The last active administrator cannot be removed");
  }
}

export async function createStaffAccount(session: Session, input: z.infer<typeof createStaffSchema>) {
  assertAdmin(session);
  const account = await prisma.account.create({
    data: {
      username: input.username,
      email: input.email || null,
      fullName: input.fullName,
      role: input.role,
      passwordHash: await hashPassword(input.password),
      mustChangePassword: input.mustChangePassword,
      preference: { create: {} },
    },
  });
  await writeAudit({
    accountId: account.id,
    actorAccountId: session.accountId,
    action: "create_staff",
    detail: input.role,
  });
  return publicAccount(account);
}

export async function updateAccount(
  session: Session,
  id: number,
  input: z.infer<typeof updateAccountSchema>,
) {
  assertAdmin(session);
  await assertNotLastAdmin(id, input);
  const account = await prisma.account.update({
    where: { id },
    data: {
      fullName: input.fullName,
      email: input.email === undefined ? undefined : input.email || null,
      active: input.active,
      role: input.role,
      mustChangePassword: input.mustChangePassword,
    },
  });
  await writeAudit({
    accountId: account.id,
    actorAccountId: session.accountId,
    action: "update_account",
  });
  return publicAccount(account);
}

export async function createDomainAccount(input: {
  username: string;
  password: string;
  fullName: string;
  email?: string | null;
  role: "student" | "parent";
  domainType: "student" | "parent";
  domainId: number;
  actorAccountId: number;
}) {
  const account = await prisma.account.create({
    data: {
      username: input.username,
      email: input.email || null,
      fullName: input.fullName,
      role: input.role,
      passwordHash: await hashPassword(input.password),
      domainType: input.domainType,
      domainId: input.domainId,
      mustChangePassword: true,
      preference: { create: {} },
    },
  });
  await writeAudit({
    accountId: account.id,
    actorAccountId: input.actorAccountId,
    action: "create_domain_account",
    detail: input.domainType,
  });
  return account;
}
