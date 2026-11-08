import { documentVisibleToClass } from "@/lib/access";
import { prisma } from "@/lib/db";
import { ApiError, json, requireSession, withErrors } from "@/lib/http";
import { putObject, readObject } from "@/lib/storage";
import { linkedStudentIds } from "@/lib/access";

async function canReadKey(session: Awaited<ReturnType<typeof requireSession>>, key: string): Promise<boolean> {
  if (session.role === "teacher" || session.role === "secretary") return true;
  const content = await prisma.content.findFirst({ where: { storageKey: key } });
  if (!content || content.archived) return false;
  if (!content.isSchoolDocument) {
    return session.role === "student" || session.role === "parent";
  }
  const scope = await linkedStudentIds(session);
  if (scope === "all" || scope.length === 0) return false;
  const students = await prisma.student.findMany({
    where: { id: { in: scope } },
    include: { rosterClass: true },
  });
  return students.some((student) =>
    documentVisibleToClass({
      scope: content.scope,
      classId: student.rosterClassId,
      className: student.rosterClass.name,
      section: student.rosterClass.section,
    }),
  );
}

export const POST = withErrors(async (req) => {
  const session = await requireSession(req);
  if (session.role !== "teacher" && session.role !== "secretary") {
    throw new ApiError(403, "forbidden", "Forbidden");
  }
  const form = await req.formData();
  const file = form.get("file");
  if (!(file instanceof File)) {
    throw new ApiError(400, "validation_error", "file field is required");
  }
  const bytes = Buffer.from(await file.arrayBuffer());
  const stored = await putObject({
    bytes,
    contentType: file.type || "application/octet-stream",
    originalName: file.name || "file",
  });
  return json({ data: stored }, 201);
});

export const GET = withErrors(async (req) => {
  const session = await requireSession(req);
  const key = new URL(req.url).searchParams.get("key");
  if (!key) throw new ApiError(400, "validation_error", "key is required");
  if (!(await canReadKey(session, key))) {
    throw new ApiError(403, "forbidden", "Forbidden");
  }
  const object = await readObject(key);
  const filename = object.originalName.replace(/["\r\n]/g, "");
  return new Response(new Uint8Array(object.bytes), {
    headers: {
      "Content-Type": object.contentType,
      "Content-Disposition": `inline; filename="${filename}"`,
      "Cache-Control": "private, max-age=60",
    },
  });
});
