"use client";

import { useQuery } from "@tanstack/react-query";
import { FormEvent, useEffect, useState } from "react";
import { Button, Empty, Field, Input, Modal, PageTitle, Panel, Select, Table, Td, Textarea, Th } from "@/components/ui";
import { useT } from "@/i18n/use-t";
import type { MessageKey } from "@/i18n/messages";
import { api, uploadFile } from "@/lib/api";
import { useSession } from "@/lib/session-store";
import { useUi } from "@/lib/ui-store";
import { useSave } from "@/lib/use-save";

const days = ["monday", "tuesday", "wednesday", "thursday", "friday"] as const;

type Announcement = {
  id: number;
  title: string;
  body: string;
  status: "draft" | "published" | "unpublished";
  targetType: "all_school" | "grade" | "section";
};
type DocumentRow = {
  id: number;
  name: string;
  description: string | null;
  storageKey: string;
  critical: boolean;
  archived: boolean;
};
type Student = { id: number; fullName: string; number: number; rosterClassId: number };
type Attendance = { id: number; studentId: number; date: string; status: "present" | "absent" | "excused"; student?: { fullName: string } };
type Weekly = {
  id: number;
  day: number;
  period: number;
  start: string;
  end: string;
  topicText: string;
  lesson: { name: string } | null;
  rosterClass: { name: string; section: string | null } | null;
};

export function AnnouncementsView() {
  const t = useT();
  const role = useSession((state) => state.user?.role);
  const [open, setOpen] = useState(false);
  const list = useQuery({
    queryKey: ["announcements", role],
    queryFn: () => api<{ data: Announcement[] }>("/api/announcements?take=100"),
  });
  const classes = useQuery({
    queryKey: ["roster-classes"],
    enabled: role === "secretary",
    queryFn: () => api<{ data: { id: number; name: string }[] }>("/api/roster-classes"),
  });
  const save = useSave((body: object) => api("/api/announcements", { method: "POST", body: JSON.stringify(body) }), ["announcements"]);
  const patch = useSave(
    (input: { id: number; status: string }) =>
      api(`/api/announcements/${input.id}`, { method: "PATCH", body: JSON.stringify({ status: input.status }) }),
    ["announcements"],
  );

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const targetType = String(form.get("targetType"));
    await save.mutateAsync({
      title: String(form.get("title")),
      body: String(form.get("body")),
      status: String(form.get("status")),
      targetType,
      rosterClassId: targetType === "section" ? Number(form.get("rosterClassId")) : null,
      targetGradeLevel: targetType === "grade" ? Number(form.get("grade")) : null,
    });
    setOpen(false);
  }

  return (
    <div className="grid gap-4">
      <PageTitle title={t("announcements")} />
      {role === "secretary" ? <Button onClick={() => setOpen(true)}>{t("create")}</Button> : null}
      <div className="grid gap-3">
        {(list.data?.data ?? []).map((item) => (
          <article key={item.id} className="rounded-2xl bg-white p-4 ring-1 ring-slate-200 dark:bg-slate-900 dark:ring-slate-800">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <h2 className="font-semibold">{item.title}</h2>
              <span className="text-xs text-slate-500">{t(item.status)}</span>
            </div>
            <p className="mt-2 whitespace-pre-wrap text-sm text-slate-600 dark:text-slate-300">{item.body}</p>
            {role === "secretary" ? (
              <div className="mt-3 flex gap-2">
                <Button onClick={() => patch.mutate({ id: item.id, status: "published" })}>{t("publish")}</Button>
                <Button variant="soft" onClick={() => patch.mutate({ id: item.id, status: "unpublished" })}>{t("unpublish")}</Button>
              </div>
            ) : null}
          </article>
        ))}
        {(list.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
      </div>
      <Modal open={open} title={t("announcements")} onClose={() => setOpen(false)}>
        <form className="grid gap-3" onSubmit={onSubmit}>
          <Field label={t("title")}><Input name="title" required /></Field>
          <Field label={t("body")}><Textarea name="body" required /></Field>
          <Field label={t("status")}>
            <Select name="status" defaultValue="draft">
              <option value="draft">{t("draft")}</option>
              <option value="published">{t("published")}</option>
            </Select>
          </Field>
          <Field label={t("target")}>
            <Select name="targetType" defaultValue="all_school">
              <option value="all_school">{t("allSchool")}</option>
              <option value="grade">{t("gradeLevel")}</option>
              <option value="section">{t("sectionTarget")}</option>
            </Select>
          </Field>
          <Field label={t("gradeLevel")}><Input name="grade" type="number" min={1} max={12} /></Field>
          <Field label={t("classes")}>
            <Select name="rosterClassId">
              {(classes.data?.data ?? []).map((row) => (
                <option key={row.id} value={row.id}>{row.name}</option>
              ))}
            </Select>
          </Field>
          <Button type="submit">{t("save")}</Button>
        </form>
      </Modal>
    </div>
  );
}

export function DocumentsView() {
  const t = useT();
  const role = useSession((state) => state.user?.role);
  const [open, setOpen] = useState(false);
  const list = useQuery({
    queryKey: ["documents"],
    queryFn: () => api<{ data: DocumentRow[] }>("/api/documents"),
  });
  const save = useSave((body: object) => api("/api/documents", { method: "POST", body: JSON.stringify(body) }), ["documents"]);
  const archive = useSave((id: number) => api(`/api/documents/${id}/archive`, { method: "POST" }), ["documents"]);
  const remove = useSave((id: number) => api(`/api/documents/${id}`, { method: "DELETE" }), ["documents"], "deleted");

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const file = form.get("file");
    if (!(file instanceof File) || file.size === 0) return;
    const storageKey = await uploadFile(file);
    const ext = file.name.split(".").pop()?.toLowerCase();
    const type = ext === "pdf" ? "pdf" : ext === "doc" || ext === "docx" ? "word" : ext === "png" || ext === "jpg" || ext === "jpeg" ? "image" : "text";
    await save.mutateAsync({
      name: String(form.get("name") || file.name),
      type,
      storageKey,
      description: String(form.get("description") ?? "") || null,
      category: String(form.get("category") ?? "") || null,
      scope: String(form.get("scope") ?? "") || null,
      critical: form.get("critical") === "on",
    });
    setOpen(false);
  }

  return (
    <div className="grid gap-4">
      <PageTitle title={t("documents")} subtitle={role === "secretary" ? t("scopeHint") : undefined} />
      {role === "secretary" ? <Button onClick={() => setOpen(true)}>{t("upload")}</Button> : null}
      <div className="grid gap-3">
        {(list.data?.data ?? []).map((doc) => (
          <article key={doc.id} className="rounded-2xl bg-white p-4 ring-1 ring-slate-200 dark:bg-slate-900 dark:ring-slate-800">
            <h2 className="font-semibold">{doc.name}</h2>
            {doc.description ? <p className="mt-1 text-sm text-slate-600">{doc.description}</p> : null}
            <div className="mt-3 flex flex-wrap gap-2">
              <a className="rounded-lg bg-brand px-3 py-2 text-sm text-white" href={`/api/files?key=${encodeURIComponent(doc.storageKey)}`} target="_blank" rel="noreferrer">
                {t("download")}
              </a>
              {role === "secretary" && !doc.critical ? (
                <Button variant="soft" onClick={() => archive.mutate(doc.id)}>{t("archive")}</Button>
              ) : null}
              {role === "teacher" && !doc.critical ? (
                <Button variant="danger" onClick={() => remove.mutate(doc.id)}>{t("delete")}</Button>
              ) : null}
            </div>
          </article>
        ))}
        {(list.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
      </div>
      <Modal open={open} title={t("upload")} onClose={() => setOpen(false)}>
        <form className="grid gap-3" onSubmit={onSubmit}>
          <Field label={t("name")}><Input name="name" /></Field>
          <Field label={t("file")}><Input name="file" type="file" required /></Field>
          <Field label={t("description")}><Textarea name="description" /></Field>
          <Field label={t("category")}><Input name="category" /></Field>
          <Field label={t("scope")}><Input name="scope" placeholder={t("scopeHint")} /></Field>
          <label className="flex items-center gap-2 text-sm">
            <input name="critical" type="checkbox" /> {t("critical")}
          </label>
          <Button type="submit">{t("save")}</Button>
        </form>
      </Modal>
    </div>
  );
}

export function AttendanceView() {
  const t = useT();
  const role = useSession((state) => state.user?.role);
  const selectedStudentId = useUi((state) => state.selectedStudentId);
  const [classId, setClassId] = useState<number | "">("");
  const [date, setDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [marks, setMarks] = useState<Record<number, "present" | "absent" | "excused">>({});
  const classes = useQuery({
    queryKey: ["roster-classes"],
    enabled: role === "secretary" || role === "teacher",
    queryFn: () => api<{ data: { id: number; name: string; section: string | null }[] }>("/api/roster-classes"),
  });
  const students = useQuery({
    queryKey: ["students", classId],
    enabled: role === "secretary" && classId !== "",
    queryFn: () => api<{ data: Student[] }>(`/api/students?rosterClassId=${classId}`),
  });
  const existing = useQuery({
    queryKey: ["attendance", role, classId, date, selectedStudentId],
    queryFn: () => {
      const params = new URLSearchParams();
      if (role === "secretary" || role === "teacher") {
        if (date) params.set("date", date);
        if (classId) params.set("rosterClassId", String(classId));
      } else if (selectedStudentId) params.set("studentId", String(selectedStudentId));
      return api<{ data: Attendance[] }>(`/api/attendance?${params.toString()}`);
    },
  });
  const save = useSave(
    (body: object) => api("/api/attendance/batch", { method: "PUT", body: JSON.stringify(body) }),
    ["attendance"],
  );

  const labels: Record<Attendance["status"], MessageKey> = { present: "present", absent: "absent", excused: "excused" };

  return (
    <div className="grid gap-4">
      <PageTitle title={t("attendance")} />
      {role === "secretary" ? (
        <Panel title={t("attendance")}>
          <div className="grid gap-3 sm:grid-cols-2">
            <Field label={t("classes")}>
              <Select value={classId} onChange={(event) => setClassId(event.target.value ? Number(event.target.value) : "")}>
                <option value="">{t("selectClass")}</option>
                {(classes.data?.data ?? []).map((row) => (
                  <option key={row.id} value={row.id}>{row.name}{row.section ? `-${row.section}` : ""}</option>
                ))}
              </Select>
            </Field>
            <Field label={t("date")}>
              <Input type="date" value={date} onChange={(event) => setDate(event.target.value)} />
            </Field>
          </div>
          <div className="mt-4 grid gap-2">
            {(students.data?.data ?? []).map((student) => (
              <label key={student.id} className="grid grid-cols-[1fr_8rem] items-center gap-2 text-sm">
                <span>{student.number} · {student.fullName}</span>
                <Select
                  value={marks[student.id] ?? "present"}
                  onChange={(event) => setMarks((current) => ({ ...current, [student.id]: event.target.value as Attendance["status"] }))}
                >
                  <option value="present">{t("present")}</option>
                  <option value="absent">{t("absent")}</option>
                  <option value="excused">{t("excused")}</option>
                </Select>
              </label>
            ))}
          </div>
          <Button
            className="mt-4"
            disabled={classId === "" || save.isPending}
            onClick={() =>
              save.mutate({
                date,
                rosterClassId: classId,
                rows: (students.data?.data ?? []).map((student) => ({
                  studentId: student.id,
                  status: marks[student.id] ?? "present",
                })),
              })
            }
          >
            {t("save")}
          </Button>
        </Panel>
      ) : null}
      <Panel title={t("attendance")}>
        <Table>
          <thead>
            <tr>
              <Th>{t("date")}</Th>
              <Th>{t("fullName")}</Th>
              <Th>{t("status")}</Th>
            </tr>
          </thead>
          <tbody>
            {(existing.data?.data ?? []).map((row) => (
              <tr key={row.id}>
                <Td>{row.date}</Td>
                <Td>{row.student?.fullName ?? row.studentId}</Td>
                <Td>{t(labels[row.status])}</Td>
              </tr>
            ))}
          </tbody>
        </Table>
        {(existing.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
      </Panel>
    </div>
  );
}

export function ScheduleView() {
  const t = useT();
  const list = useQuery({
    queryKey: ["weekly"],
    queryFn: () => api<{ data: Weekly[] }>("/api/academic-plans/weekly"),
  });
  return (
    <div className="grid gap-4">
      <PageTitle title={t("schedule")} />
      <div className="grid gap-3 md:grid-cols-5">
        {days.map((day, index) => (
          <section key={day} className="rounded-2xl bg-white p-3 ring-1 ring-slate-200 dark:bg-slate-900 dark:ring-slate-800">
            <h2 className="mb-2 text-sm font-semibold">{t(day)}</h2>
            {(list.data?.data ?? [])
              .filter((row) => row.day === index + 1)
              .map((row) => (
                <article key={row.id} className="mb-2 rounded-lg bg-slate-50 p-2 text-xs dark:bg-slate-800">
                  <p className="font-medium">{row.period}. {row.start}–{row.end}</p>
                  <p>{row.lesson?.name || row.topicText || "—"}</p>
                  <p className="text-slate-500">{row.rosterClass ? `${row.rosterClass.name}${row.rosterClass.section ? `-${row.rosterClass.section}` : ""}` : ""}</p>
                </article>
              ))}
          </section>
        ))}
      </div>
      {(list.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
    </div>
  );
}

export function GradesView() {
  const t = useT();
  const role = useSession((state) => state.user?.role);
  const selected = useUi((state) => state.selectedStudentId);
  const setSelected = useUi((state) => state.setSelectedStudentId);
  const domainId = useSession((state) => state.user?.domainId);
  const studentId = role === "student" ? domainId : selected;
  const [classId, setClassId] = useState<number | "">("");
  const classes = useQuery({
    queryKey: ["roster-classes"],
    enabled: role === "teacher",
    queryFn: () => api<{ data: { id: number; name: string }[] }>("/api/roster-classes"),
  });
  const students = useQuery({
    queryKey: ["students", classId || "grades"],
    enabled: role === "teacher" || role === "parent",
    queryFn: () => api<{ data: Student[] }>(role === "teacher" && classId ? `/api/students?rosterClassId=${classId}` : "/api/students"),
  });
  useEffect(() => {
    if (role === "parent" && selected == null && students.data?.data[0]) {
      setSelected(students.data.data[0].id);
    }
  }, [role, selected, students.data, setSelected]);
  const columns = useQuery({
    queryKey: ["columns", classId],
    enabled: role === "teacher" && classId !== "",
    queryFn: () => api<{ data: { id: number; name: string; type: string }[] }>(`/api/grades/columns?rosterClassId=${classId}`),
  });
  const cells = useQuery({
    queryKey: ["cells", studentId],
    enabled: studentId != null,
    queryFn: () => api<{ data: { studentId: number; columnId: number; date: string; score: number | null; column?: { name: string } }[] }>(`/api/grades/cells?studentId=${studentId}`),
  });
  const behaviors = useQuery({
    queryKey: ["behaviors"],
    enabled: role === "teacher",
    queryFn: () => api<{ data: { id: number; name: string; kind: string }[] }>("/api/behaviors"),
  });
  const saveColumn = useSave((body: object) => api("/api/grades/columns", { method: "POST", body: JSON.stringify(body) }), ["columns"]);
  const saveCell = useSave((body: object) => api("/api/grades/cells", { method: "PUT", body: JSON.stringify(body) }), ["cells"]);
  const saveBehavior = useSave((body: object) => api("/api/behaviors/records", { method: "POST", body: JSON.stringify(body) }), ["behaviors"]);

  function onColumn(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    saveColumn.mutate({ rosterClassId: Number(classId), name: String(form.get("name")), type: String(form.get("type")) });
    event.currentTarget.reset();
  }
  function onCell(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    saveCell.mutate({
      studentId: Number(form.get("studentId")),
      columnId: Number(form.get("columnId")),
      date: String(form.get("date")),
      score: form.get("score") === "" ? null : Number(form.get("score")),
      absent: form.get("absent") === "on",
    });
  }
  function onBehavior(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    saveBehavior.mutate({
      studentId: Number(form.get("studentId")),
      behaviorId: Number(form.get("behaviorId")),
      date: String(form.get("date")),
      visibleToStudent: form.get("visible") === "on",
    });
  }

  return (
    <div className="grid gap-4">
      <PageTitle title={t("grades")} />
      {role === "parent" ? (
        <Field label={t("child")}>
          <Select value={selected ?? ""} onChange={(event) => setSelected(event.target.value ? Number(event.target.value) : null)}>
            <option value="">{t("selectStudent")}</option>
            {(students.data?.data ?? []).map((student) => (
              <option key={student.id} value={student.id}>{student.fullName}</option>
            ))}
          </Select>
        </Field>
      ) : null}
      {role === "teacher" ? (
        <Panel title={t("column")}>
          <Field label={t("classes")}>
            <Select value={classId} onChange={(event) => setClassId(event.target.value ? Number(event.target.value) : "")}>
              <option value="">{t("selectClass")}</option>
              {(classes.data?.data ?? []).map((row) => (
                <option key={row.id} value={row.id}>{row.name}</option>
              ))}
            </Select>
          </Field>
          <form className="mt-3 grid gap-3 sm:grid-cols-3" onSubmit={onColumn}>
            <Field label={t("name")}><Input name="name" required /></Field>
            <Field label={t("type")}><Input name="type" required placeholder="exam" /></Field>
            <div className="self-end"><Button type="submit">{t("create")}</Button></div>
          </form>
          <ul className="mt-3 text-sm">
            {(columns.data?.data ?? []).map((column) => (
              <li key={column.id}>{column.name} · {column.type}</li>
            ))}
          </ul>
          <form className="mt-4 grid gap-3 sm:grid-cols-2" onSubmit={onCell}>
            <Field label={t("students")}>
              <Select name="studentId" required>
                {(students.data?.data ?? []).map((student) => (
                  <option key={student.id} value={student.id}>{student.fullName}</option>
                ))}
              </Select>
            </Field>
            <Field label={t("column")}>
              <Select name="columnId" required>
                {(columns.data?.data ?? []).map((column) => (
                  <option key={column.id} value={column.id}>{column.name}</option>
                ))}
              </Select>
            </Field>
            <Field label={t("date")}><Input name="date" type="date" required /></Field>
            <Field label={t("score")}><Input name="score" type="number" min={0} max={100} /></Field>
            <label className="flex items-center gap-2 text-sm"><input name="absent" type="checkbox" /> {t("absent")}</label>
            <Button type="submit">{t("save")}</Button>
          </form>
          <form className="mt-4 grid gap-3 sm:grid-cols-2" onSubmit={onBehavior}>
            <Field label={t("students")}>
              <Select name="studentId" required>
                {(students.data?.data ?? []).map((student) => (
                  <option key={student.id} value={student.id}>{student.fullName}</option>
                ))}
              </Select>
            </Field>
            <Field label={t("behavior")}>
              <Select name="behaviorId" required>
                {(behaviors.data?.data ?? []).map((item) => (
                  <option key={item.id} value={item.id}>{item.name}</option>
                ))}
              </Select>
            </Field>
            <Field label={t("date")}><Input name="date" type="date" required /></Field>
            <label className="flex items-center gap-2 text-sm"><input name="visible" type="checkbox" /> {t("visible")}</label>
            <Button type="submit">{t("save")}</Button>
          </form>
        </Panel>
      ) : null}
      <Panel title={t("grades")}>
        <Table>
          <thead>
            <tr>
              <Th>{t("date")}</Th>
              <Th>{t("column")}</Th>
              <Th>{t("score")}</Th>
            </tr>
          </thead>
          <tbody>
            {(cells.data?.data ?? []).map((cell) => (
              <tr key={`${cell.columnId}-${cell.date}`}>
                <Td>{cell.date}</Td>
                <Td>{cell.column?.name ?? cell.columnId}</Td>
                <Td>{cell.score ?? "—"}</Td>
              </tr>
            ))}
          </tbody>
        </Table>
        {(cells.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
      </Panel>
    </div>
  );
}
