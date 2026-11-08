import { AppRole } from "@prisma/client";
import { prisma } from "@/lib/db";
import { ApiError, Session } from "@/lib/http";

export function forbidden(message = "Forbidden"): ApiError {
  return new ApiError(403, "forbidden", message);
}

export function notFound(message = "Not found"): ApiError {
  return new ApiError(404, "not_found", message);
}

export function assertRole(session: Session, roles: AppRole[]): void {
  if (!roles.includes(session.role)) throw forbidden();
}

export function assertTeacher(session: Session): void {
  assertRole(session, ["teacher"]);
}

export function assertTeacherOrSecretary(session: Session): void {
  assertRole(session, ["teacher", "secretary"]);
}

export function assertAdmin(session: Session): void {
  assertRole(session, ["admin"]);
}

export const canCreateStudent = (session: Session) =>
  session.role === "teacher" || session.role === "secretary";

export const canDeleteStudent = (session: Session) => session.role === "teacher";

export const canCreateParent = (session: Session) => session.role === "secretary";

export const canCreateAttendance = (session: Session) => session.role === "secretary";

export const canManageAnnouncements = (session: Session) => session.role === "secretary";

export const canCreateDocument = (session: Session) => session.role === "secretary";

export const canArchiveDocument = (session: Session) => session.role === "secretary";

export const canDeleteDocument = (session: Session) => session.role === "teacher";

export async function assertStudentVisible(session: Session, studentId: number): Promise<void> {
  if (session.role === "teacher" || session.role === "secretary") return;
  if (session.role === "student") {
    if (session.domainType === "student" && session.domainId === studentId) return;
    throw forbidden();
  }
  if (session.role === "parent") {
    if (session.domainType !== "parent" || session.domainId == null) throw forbidden();
    const link = await prisma.studentParent.findFirst({
      where: { studentId, parentId: session.domainId },
      select: { id: true },
    });
    if (!link) throw forbidden();
    return;
  }
  throw forbidden();
}

export async function linkedStudentIds(session: Session): Promise<number[] | "all"> {
  if (session.role === "teacher" || session.role === "secretary") return "all";
  if (session.role === "student") {
    if (session.domainType !== "student" || session.domainId == null) return [];
    return [session.domainId];
  }
  if (session.role === "parent") {
    if (session.domainType !== "parent" || session.domainId == null) return [];
    const links = await prisma.studentParent.findMany({
      where: { parentId: session.domainId },
      select: { studentId: true },
    });
    return links.map((link) => link.studentId);
  }
  return [];
}

export function gradeFromClassName(name: string | null | undefined): number {
  const match = /^(\d+)/.exec((name ?? "").trim());
  if (!match) return 1;
  const grade = Number(match[1]);
  if (!Number.isInteger(grade) || grade < 1 || grade > 12) return 1;
  return grade;
}

export function documentVisibleToClass(input: {
  scope: string | null;
  classId: number;
  className: string;
  section: string | null;
}): boolean {
  const trimmed = input.scope?.trim();
  if (!trimmed) return true;
  const lower = trimmed.toLowerCase();
  if (lower.includes("tüm okul") || lower.includes("all school")) return true;
  if (trimmed.startsWith("sinif:")) {
    const id = Number(trimmed.slice(6).trim());
    return Number.isInteger(id) && id === input.classId;
  }
  const section = input.section?.trim();
  const display = section ? `${input.className}-${section}` : input.className;
  if (lower.includes(display.toLowerCase())) return true;
  return lower.includes(input.className.toLowerCase());
}

export async function recordTeacherActivity(
  session: Session,
  input: { type: string; title: string; targetType?: string; targetId?: number; extraData?: string },
): Promise<void> {
  if (session.role !== "teacher") return;
  await prisma.teacherActivity.create({
    data: {
      accountId: session.accountId,
      type: input.type,
      title: input.title,
      targetType: input.targetType,
      targetId: input.targetId,
      extraData: input.extraData,
    },
  });
  const stale = await prisma.teacherActivity.findMany({
    where: { accountId: session.accountId },
    orderBy: [{ createdAt: "desc" }, { id: "desc" }],
    skip: 100,
    select: { id: true },
  });
  if (stale.length > 0) {
    await prisma.teacherActivity.deleteMany({
      where: { id: { in: stale.map((row) => row.id) } },
    });
  }
}
