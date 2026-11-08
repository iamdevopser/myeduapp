import { ContentType } from "@prisma/client";
import { z } from "zod";
import {
  assertTeacher,
  canArchiveDocument,
  canCreateDocument,
  canDeleteDocument,
  documentVisibleToClass,
  forbidden,
  linkedStudentIds,
  notFound,
} from "@/lib/access";
import { prisma } from "@/lib/db";
import { ApiError, Session } from "@/lib/http";
import { fanoutDocument } from "@/server/notifications";

const contentTypes = z.enum([
  "text",
  "pdf",
  "ppt",
  "word",
  "image",
  "video",
  "audio",
  "link",
  "homework",
  "question",
  "exam",
]);

export const documentSchema = z.object({
  name: z.string().trim().min(1).max(200),
  type: contentTypes,
  storageKey: z.string().trim().min(1).max(300),
  description: z.string().trim().max(4000).nullable().optional(),
  category: z.string().trim().max(80).nullable().optional(),
  scope: z.string().trim().max(200).nullable().optional(),
  critical: z.boolean().optional(),
});

export const documentPatchSchema = documentSchema.partial().omit({ storageKey: true, type: true });

export const folderSchema = z.object({
  name: z.string().trim().min(1).max(120),
  parentId: z.number().int().positive().nullable().optional(),
});

export const folderItemSchema = z.object({
  contentId: z.number().int().positive(),
});

async function visibleDocuments(session: Session) {
  if (session.role === "teacher" || session.role === "secretary") {
    return prisma.content.findMany({
      where: { isSchoolDocument: true },
      orderBy: { updatedAt: "desc" },
    });
  }
  const scope = await linkedStudentIds(session);
  if (scope === "all" || scope.length === 0) return [];
  const students = await prisma.student.findMany({
    where: { id: { in: scope } },
    include: { rosterClass: true },
  });
  const docs = await prisma.content.findMany({
    where: { isSchoolDocument: true, archived: false },
    orderBy: { updatedAt: "desc" },
  });
  return docs.filter((doc) =>
    students.some((student) =>
      documentVisibleToClass({
        scope: doc.scope,
        classId: student.rosterClassId,
        className: student.rosterClass.name,
        section: student.rosterClass.section,
      }),
    ),
  );
}

export async function listDocuments(session: Session, search?: string) {
  if (session.role === "admin") throw forbidden();
  const rows = await visibleDocuments(session);
  if (!search) return rows;
  const needle = search.toLowerCase();
  return rows.filter((row) => row.name.toLowerCase().includes(needle));
}

export async function getDocument(session: Session, id: number) {
  const rows = await listDocuments(session);
  const found = rows.find((row) => row.id === id);
  if (!found) throw notFound("Document not found");
  return found;
}

export async function createDocument(session: Session, input: z.infer<typeof documentSchema>) {
  if (!canCreateDocument(session)) throw forbidden();
  const created = await prisma.content.create({
    data: {
      name: input.name,
      type: input.type as ContentType,
      storageKey: input.storageKey,
      order: 0,
      isSchoolDocument: true,
      critical: input.critical ?? false,
      description: input.description ?? null,
      category: input.category ?? null,
      scope: input.scope ?? null,
    },
  });
  await fanoutDocument(created.id);
  return created;
}

export async function updateDocument(session: Session, id: number, input: z.infer<typeof documentPatchSchema>) {
  if (!canCreateDocument(session)) throw forbidden();
  const current = await prisma.content.findFirst({ where: { id, isSchoolDocument: true } });
  if (!current) throw notFound("Document not found");
  return prisma.content.update({
    where: { id },
    data: {
      name: input.name,
      description: input.description,
      category: input.category,
      scope: input.scope,
      critical: input.critical,
    },
  });
}

export async function archiveDocument(session: Session, id: number) {
  if (!canArchiveDocument(session)) throw forbidden();
  const current = await prisma.content.findFirst({ where: { id, isSchoolDocument: true } });
  if (!current) throw notFound("Document not found");
  if (current.critical) {
    throw new ApiError(409, "critical_document", "Critical documents cannot be archived");
  }
  return prisma.content.update({ where: { id }, data: { archived: true } });
}

export async function deleteDocument(session: Session, id: number) {
  if (!canDeleteDocument(session)) throw forbidden();
  const current = await prisma.content.findFirst({ where: { id, isSchoolDocument: true } });
  if (!current) throw notFound("Document not found");
  if (current.critical) {
    throw new ApiError(409, "critical_document", "Critical documents cannot be deleted");
  }
  await prisma.content.delete({ where: { id } });
}

export async function listFolders(session: Session, parentId?: number) {
  assertTeacher(session);
  return prisma.documentFolder.findMany({
    where: parentId == null ? { parentId: null } : { parentId },
    orderBy: [{ order: "asc" }, { name: "asc" }],
    include: { _count: { select: { items: true, children: true } } },
  });
}

export async function createFolder(session: Session, input: z.infer<typeof folderSchema>) {
  assertTeacher(session);
  const siblingCount = await prisma.documentFolder.count({
    where: { parentId: input.parentId ?? null },
  });
  return prisma.documentFolder.create({
    data: { name: input.name, parentId: input.parentId ?? null, order: siblingCount },
  });
}

export async function deleteFolder(session: Session, id: number) {
  assertTeacher(session);
  await prisma.documentFolder.delete({ where: { id } });
}

export async function addFolderItem(session: Session, folderId: number, contentId: number) {
  assertTeacher(session);
  const count = await prisma.documentFolderItem.count({ where: { folderId } });
  return prisma.documentFolderItem.create({
    data: { folderId, contentId, order: count },
  });
}

export async function removeFolderItem(session: Session, folderId: number, contentId: number) {
  assertTeacher(session);
  await prisma.documentFolderItem.delete({
    where: { folderId_contentId: { folderId, contentId } },
  });
}
