import { AppRole, Prisma } from "@prisma/client";
import { ZodTypeAny, z } from "zod";
import { prisma } from "@/lib/db";
import { readCookie, readSessionToken, SESSION_COOKIE } from "@/lib/session";

export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
  ) {
    super(message);
  }
}

export type Session = {
  accountId: number;
  role: AppRole;
  domainType: string | null;
  domainId: number | null;
  mustChangePassword: boolean;
  username: string;
  fullName: string;
};

const PASSWORD_EXEMPT = new Set([
  "/api/auth/session",
  "/api/auth/logout",
  "/api/auth/change-password",
]);

export type RouteContext = {
  params: Promise<Record<string, string | string[]>>;
};

export function json(data: unknown, status = 200, headers?: HeadersInit): Response {
  return Response.json(data, { status, headers });
}

export function empty(status = 204, headers?: HeadersInit): Response {
  return new Response(null, { status, headers });
}

export function withErrors(
  handler: (req: Request, ctx: RouteContext) => Promise<Response>,
): (req: Request, ctx: RouteContext) => Promise<Response> {
  return async (req, ctx) => {
    try {
      return await handler(req, ctx);
    } catch (error) {
      if (error instanceof ApiError) {
        return json({ error: { code: error.code, message: error.message } }, error.status);
      }
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === "P2002") {
          return json(
            { error: { code: "conflict", message: "Unique value already exists" } },
            409,
          );
        }
        if (error.code === "P2025") {
          return json({ error: { code: "not_found", message: "Record not found" } }, 404);
        }
      }
      console.error(error);
      return json({ error: { code: "internal", message: "Internal server error" } }, 500);
    }
  };
}

export async function readJson<S extends ZodTypeAny>(req: Request, schema: S): Promise<z.output<S>> {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    throw new ApiError(400, "invalid_json", "Request body must be JSON");
  }
  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    const message = parsed.error.issues
      .map((issue) => `${issue.path.join(".") || "body"}: ${issue.message}`)
      .join("; ");
    throw new ApiError(400, "validation_error", message);
  }
  return parsed.data;
}

export async function routeId(ctx: RouteContext, name = "id"): Promise<number> {
  const params = await ctx.params;
  const raw = params[name];
  const value = Array.isArray(raw) ? raw[0] : raw;
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0) {
    throw new ApiError(400, "invalid_id", "Invalid id");
  }
  return id;
}

export async function requireSession(req: Request): Promise<Session> {
  const token = readCookie(req, SESSION_COOKIE);
  if (!token) {
    throw new ApiError(401, "unauthenticated", "Authentication required");
  }
  let accountId: number;
  try {
    accountId = (await readSessionToken(token)).accountId;
  } catch {
    throw new ApiError(401, "unauthenticated", "Authentication required");
  }
  const account = await prisma.account.findUnique({ where: { id: accountId } });
  if (!account || !account.active) {
    throw new ApiError(401, "unauthenticated", "Authentication required");
  }
  const path = new URL(req.url).pathname;
  if (account.mustChangePassword && !PASSWORD_EXEMPT.has(path)) {
    throw new ApiError(403, "password_change_required", "Password change required");
  }
  return {
    accountId: account.id,
    role: account.role,
    domainType: account.domainType,
    domainId: account.domainId,
    mustChangePassword: account.mustChangePassword,
    username: account.username,
    fullName: account.fullName,
  };
}

export function queryInt(url: URL, name: string, fallback: number, min: number, max: number): number {
  const raw = url.searchParams.get(name);
  if (raw == null || raw === "") return fallback;
  const value = Number(raw);
  if (!Number.isInteger(value) || value < min || value > max) {
    throw new ApiError(400, "validation_error", `${name} must be an integer between ${min} and ${max}`);
  }
  return value;
}

export function queryOptionalInt(url: URL, name: string): number | undefined {
  const raw = url.searchParams.get(name);
  if (raw == null || raw === "") return undefined;
  const value = Number(raw);
  if (!Number.isInteger(value) || value <= 0) {
    throw new ApiError(400, "validation_error", `${name} must be a positive integer`);
  }
  return value;
}
