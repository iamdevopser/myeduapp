import { z } from "zod";
import { assertTeacher, forbidden } from "@/lib/access";
import { prisma } from "@/lib/db";
import { Session } from "@/lib/http";

const SMTP_KEYS = {
  host: "smtp_host",
  port: "smtp_port",
  username: "smtp_username",
  password: "smtp_password",
  fromEmail: "smtp_from_email",
  useSsl: "smtp_use_ssl",
} as const;

export const preferenceSchema = z.object({
  locale: z.enum(["tr", "en", "ro", "ru"]).optional(),
  themeMode: z.enum(["system", "light", "dark"]).optional(),
});

const ACADEMIC_YEARS_KEY = "academic_year_options";
const DEFAULT_ACADEMIC_YEARS = ["2024-25", "2025-26", "2026-27", "2027-28"];

export const academicYearsSchema = z.object({
  years: z.array(z.string().trim().min(4).max(32)).min(1).max(40),
});

export const smtpSchema = z.object({
  host: z.string().trim().max(200).optional(),
  port: z.number().int().min(1).max(65535).optional(),
  username: z.string().trim().max(200).optional(),
  password: z.string().max(200).optional(),
  fromEmail: z.string().trim().email().optional(),
  useSsl: z.boolean().optional(),
  clearPassword: z.boolean().optional(),
});

function canUsePreferences(session: Session): boolean {
  return session.role === "teacher" || session.role === "student" || session.role === "secretary" || session.role === "parent" || session.role === "admin";
}

export async function getPreferences(session: Session) {
  if (!canUsePreferences(session)) throw forbidden();
  const row = await prisma.accountPreference.upsert({
    where: { accountId: session.accountId },
    create: { accountId: session.accountId },
    update: {},
  });
  return { locale: row.locale, themeMode: row.themeMode };
}

export async function updatePreferences(session: Session, input: z.infer<typeof preferenceSchema>) {
  if (!canUsePreferences(session)) throw forbidden();
  return prisma.accountPreference.upsert({
    where: { accountId: session.accountId },
    create: {
      accountId: session.accountId,
      locale: input.locale ?? "tr",
      themeMode: input.themeMode ?? "system",
    },
    update: { locale: input.locale, themeMode: input.themeMode },
  });
}

async function readSetting(key: string): Promise<string | null> {
  const row = await prisma.appSetting.findUnique({ where: { key } });
  return row?.value ?? null;
}

async function writeSetting(key: string, value: string | null) {
  if (value == null) {
    await prisma.appSetting.deleteMany({ where: { key } });
    return;
  }
  await prisma.appSetting.upsert({
    where: { key },
    create: { key, value },
    update: { value },
  });
}

export async function getSmtp(session: Session) {
  assertTeacher(session);
  const [host, port, username, password, fromEmail, useSsl] = await Promise.all([
    readSetting(SMTP_KEYS.host),
    readSetting(SMTP_KEYS.port),
    readSetting(SMTP_KEYS.username),
    readSetting(SMTP_KEYS.password),
    readSetting(SMTP_KEYS.fromEmail),
    readSetting(SMTP_KEYS.useSsl),
  ]);
  return {
    host: host ?? "",
    port: port ? Number(port) : 587,
    username: username ?? "",
    fromEmail: fromEmail ?? "",
    useSsl: useSsl === "1",
    passwordSet: Boolean(password),
  };
}

export async function getAcademicYears(session: Session) {
  if (!canUsePreferences(session)) throw forbidden();
  const raw = await readSetting(ACADEMIC_YEARS_KEY);
  if (!raw) return { years: [...DEFAULT_ACADEMIC_YEARS] };
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!Array.isArray(parsed)) return { years: [...DEFAULT_ACADEMIC_YEARS] };
    const years = parsed.filter((item): item is string => typeof item === "string" && item.trim().length >= 4);
    return { years: years.length > 0 ? years : [...DEFAULT_ACADEMIC_YEARS] };
  } catch {
    return { years: [...DEFAULT_ACADEMIC_YEARS] };
  }
}

export async function updateAcademicYears(session: Session, input: z.infer<typeof academicYearsSchema>) {
  assertTeacher(session);
  const unique = [...new Set(input.years.map((year) => year.trim()))];
  await writeSetting(ACADEMIC_YEARS_KEY, JSON.stringify(unique));
  return { years: unique };
}

export async function listTeachersForPick(session: Session) {
  if (!canUsePreferences(session)) throw forbidden();
  const rows = await prisma.account.findMany({
    where: { role: "teacher", active: true },
    select: { fullName: true },
    orderBy: [{ fullName: "asc" }],
  });
  const names = [...new Set(rows.map((row) => row.fullName.trim()).filter(Boolean))];
  return { teachers: names };
}

export async function updateSmtp(session: Session, input: z.infer<typeof smtpSchema>) {
  assertTeacher(session);
  if (input.host != null) await writeSetting(SMTP_KEYS.host, input.host);
  if (input.port != null) await writeSetting(SMTP_KEYS.port, String(input.port));
  if (input.username != null) await writeSetting(SMTP_KEYS.username, input.username);
  if (input.fromEmail != null) await writeSetting(SMTP_KEYS.fromEmail, input.fromEmail);
  if (input.useSsl != null) await writeSetting(SMTP_KEYS.useSsl, input.useSsl ? "1" : "0");
  if (input.clearPassword) await writeSetting(SMTP_KEYS.password, null);
  else if (input.password) await writeSetting(SMTP_KEYS.password, input.password);
  return getSmtp(session);
}
