import { ParentRelation, Prisma } from "@prisma/client";
import { z } from "zod";
import {
  assertStudentVisible,
  assertTeacherOrSecretary,
  canCreateParent,
  canCreateStudent,
  canDeleteStudent,
  forbidden,
  linkedStudentIds,
  notFound,
} from "@/lib/access";
import { prisma } from "@/lib/db";
import { ApiError, Session } from "@/lib/http";
import { createDomainAccount } from "@/server/accounts";

const passwordSchema = z.string().min(8).max(128);
const usernameSchema = z.string().trim().min(3).max(64);

export const rosterClassSchema = z.object({
  name: z.string().trim().min(1).max(120),
  year: z.string().trim().min(4).max(32),
  section: z.string().trim().max(8).nullable().optional(),
});

export const studentSchema = z.object({
  rosterClassId: z.number().int().positive(),
  number: z.number().int().positive(),
  fullName: z.string().trim().min(1).max(160),
  email: z.string().trim().email().nullable().optional(),
  username: usernameSchema,
  password: passwordSchema,
});

export const studentPatchSchema = z.object({
  rosterClassId: z.number().int().positive().optional(),
  number: z.number().int().positive().optional(),
  fullName: z.string().trim().min(1).max(160).optional(),
  email: z.string().trim().email().nullable().optional(),
});

export const parentSchema = z.object({
  fullName: z.string().trim().min(1).max(160),
  phone: z.string().trim().max(40).nullable().optional(),
  email: z.string().trim().email().nullable().optional(),
  address: z.string().trim().max(300).nullable().optional(),
  notes: z.string().trim().max(2000).nullable().optional(),
  username: usernameSchema,
  password: passwordSchema,
});

export const parentPatchSchema = parentSchema.omit({ username: true, password: true }).partial();

export const linkSchema = z.object({
  studentId: z.number().int().positive(),
  parentId: z.number().int().positive(),
  relation: z.enum(["anne", "baba", "diger"]),
  isPrimary: z.boolean().default(false),
});

export const categorySchema = z.object({
  rosterClassId: z.number().int().positive(),
  name: z.string().trim().min(1).max(80),
  code: z.string().trim().min(1).max(40),
  order: z.number().int().min(0),
  active: z.boolean().default(true),
});

async function visibleStudentFilter(session: Session) {
  const scope = await linkedStudentIds(session);
  if (scope === "all") return {};
  return { id: { in: scope } };
}

export async function listRosterClasses(session: Session) {
  assertTeacherOrSecretary(session);
  return prisma.rosterClass.findMany({
    orderBy: [{ year: "desc" }, { name: "asc" }],
    include: { _count: { select: { students: true } } },
  });
}

export async function createRosterClass(session: Session, input: z.infer<typeof rosterClassSchema>) {
  if (!canCreateStudent(session)) throw forbidden();
  return prisma.rosterClass.create({
    data: { name: input.name, year: input.year, section: input.section ?? null },
  });
}

export async function updateRosterClass(session: Session, id: number, input: Partial<z.infer<typeof rosterClassSchema>>) {
  if (!canCreateStudent(session)) throw forbidden();
  return prisma.rosterClass.update({
    where: { id },
    data: { name: input.name, year: input.year, section: input.section },
  });
}

export async function deleteRosterClass(session: Session, id: number) {
  if (!canDeleteStudent(session)) throw forbidden();
  const students = await prisma.student.findMany({ where: { rosterClassId: id }, select: { id: true } });
  await prisma.$transaction([
    prisma.account.deleteMany({
      where: { domainType: "student", domainId: { in: students.map((student) => student.id) } },
    }),
    prisma.rosterClass.delete({ where: { id } }),
  ]);
}

export async function listStudents(session: Session, rosterClassId?: number, search?: string) {
  if (session.role !== "teacher" && session.role !== "secretary" && session.role !== "parent" && session.role !== "student") {
    throw forbidden();
  }
  const visibility = await visibleStudentFilter(session);
  return prisma.student.findMany({
    where: {
      ...visibility,
      rosterClassId,
      fullName: search ? { contains: search, mode: "insensitive" } : undefined,
    },
    include: { rosterClass: true },
    orderBy: [{ rosterClassId: "asc" }, { number: "asc" }],
  });
}

export async function getStudent(session: Session, id: number) {
  await assertStudentVisible(session, id);
  const student = await prisma.student.findUnique({ where: { id }, include: { rosterClass: true } });
  if (!student) throw notFound("Student not found");
  return student;
}

export async function createStudent(session: Session, input: z.infer<typeof studentSchema>) {
  if (!canCreateStudent(session)) throw forbidden();
  const roster = await prisma.rosterClass.findUnique({ where: { id: input.rosterClassId } });
  if (!roster) throw notFound("Class not found");
  const student = await prisma.student.create({
    data: {
      rosterClassId: input.rosterClassId,
      number: input.number,
      fullName: input.fullName,
      email: input.email ?? null,
    },
  });
  try {
    await createDomainAccount({
      username: input.username,
      password: input.password,
      fullName: input.fullName,
      email: input.email,
      role: "student",
      domainType: "student",
      domainId: student.id,
      actorAccountId: session.accountId,
    });
    return student;
  } catch (error) {
    await prisma.student.delete({ where: { id: student.id } }).catch(() => undefined);
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
      throw new ApiError(409, "conflict", "Student number or username already exists");
    }
    throw error;
  }
}

export async function updateStudent(session: Session, id: number, input: z.infer<typeof studentPatchSchema>) {
  if (!canCreateStudent(session)) throw forbidden();
  const student = await prisma.student.update({
    where: { id },
    data: {
      rosterClassId: input.rosterClassId,
      number: input.number,
      fullName: input.fullName,
      email: input.email,
    },
  });
  if (input.fullName || input.email !== undefined) {
    await prisma.account.updateMany({
      where: { domainType: "student", domainId: id },
      data: {
        fullName: input.fullName,
        email: input.email === undefined ? undefined : input.email,
      },
    });
  }
  return student;
}

export async function deleteStudent(session: Session, id: number) {
  if (!canDeleteStudent(session)) throw forbidden();
  await prisma.$transaction([
    prisma.account.deleteMany({ where: { domainType: "student", domainId: id } }),
    prisma.student.delete({ where: { id } }),
  ]);
}

export async function listParents(session: Session, search?: string) {
  assertTeacherOrSecretary(session);
  return prisma.parent.findMany({
    where: search
      ? {
          OR: [
            { fullName: { contains: search, mode: "insensitive" } },
            { email: { contains: search, mode: "insensitive" } },
            { phone: { contains: search, mode: "insensitive" } },
          ],
        }
      : undefined,
    include: { _count: { select: { studentLinks: true } } },
    orderBy: { fullName: "asc" },
  });
}

export async function createParent(session: Session, input: z.infer<typeof parentSchema>) {
  if (!canCreateParent(session)) throw forbidden();
  const parent = await prisma.parent.create({
    data: {
      fullName: input.fullName,
      phone: input.phone ?? null,
      email: input.email ?? null,
      address: input.address ?? null,
      notes: input.notes ?? null,
    },
  });
  try {
    await createDomainAccount({
      username: input.username,
      password: input.password,
      fullName: input.fullName,
      email: input.email,
      role: "parent",
      domainType: "parent",
      domainId: parent.id,
      actorAccountId: session.accountId,
    });
  } catch (error) {
    await prisma.parent.delete({ where: { id: parent.id } }).catch(() => undefined);
    throw error;
  }
  return parent;
}

export async function updateParent(session: Session, id: number, input: z.infer<typeof parentPatchSchema>) {
  if (!canCreateParent(session)) throw forbidden();
  const parent = await prisma.parent.update({
    where: { id },
    data: {
      fullName: input.fullName,
      phone: input.phone,
      email: input.email,
      address: input.address,
      notes: input.notes,
    },
  });
  await prisma.account.updateMany({
    where: { domainType: "parent", domainId: id },
    data: {
      fullName: input.fullName,
      email: input.email === undefined ? undefined : input.email,
    },
  });
  return parent;
}

export async function listLinks(session: Session, studentId?: number) {
  if (studentId != null) await assertStudentVisible(session, studentId);
  else assertTeacherOrSecretary(session);
  return prisma.studentParent.findMany({
    where: studentId ? { studentId } : undefined,
    include: { parent: true, student: { include: { rosterClass: true } } },
    orderBy: { id: "asc" },
  });
}

export async function createLink(session: Session, input: z.infer<typeof linkSchema>) {
  if (!canCreateParent(session)) throw forbidden();
  return prisma.studentParent.create({
    data: {
      studentId: input.studentId,
      parentId: input.parentId,
      relation: input.relation as ParentRelation,
      isPrimary: input.isPrimary,
    },
  });
}

export async function deleteLink(session: Session, id: number) {
  if (!canCreateParent(session)) throw forbidden();
  await prisma.studentParent.delete({ where: { id } });
}

export async function listCategories(session: Session, rosterClassId: number) {
  assertTeacherOrSecretary(session);
  return prisma.studentCategory.findMany({
    where: { rosterClassId },
    orderBy: { order: "asc" },
  });
}

export async function createCategory(session: Session, input: z.infer<typeof categorySchema>) {
  if (session.role !== "teacher") throw forbidden();
  return prisma.studentCategory.create({
    data: {
      rosterClassId: input.rosterClassId,
      name: input.name,
      code: input.code,
      order: input.order,
      active: input.active,
    },
  });
}
