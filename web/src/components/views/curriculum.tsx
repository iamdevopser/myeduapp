"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
  ArrowDown,
  ArrowUp,
  BookOpen,
  ChevronDown,
  ClipboardList,
  FileText,
  GraduationCap,
  Image as ImageIcon,
  Layers,
  Link2,
  Pencil,
  Plus,
  StickyNote,
  Trash2,
  Video,
} from "lucide-react";
import { FormEvent, useEffect, useMemo, useState } from "react";
import { Button, Empty, Field, Input, Modal, PageTitle, Select, Skeleton, Textarea } from "@/components/ui";
import { useT } from "@/i18n/use-t";
import { api, uploadFile } from "@/lib/api";
import { useSave } from "@/lib/use-save";
import { sortCurriculumClasses } from "@/lib/curriculum-sort";
import { useUi } from "@/lib/ui-store";

type ClassRow = { id: number; name: string };
type Lesson = { id: number; name: string; academicYear: string; teacherName: string | null; order: number };
type UnitRow = { id: number; lessonId: number; name: string; order: number; number: number };
type TopicRow = { id: number; lessonId: number; unitId: number | null; name: string; order: number };
type ContentRow = { id: number; name: string; type: string; storageKey: string; topicId: number | null; order: number };
type ExamRow = { id: number; name: string; topicId: number | null };
type NoteRow = { id: number; text: string; topicId: number | null };
type Created = { data: { id: number } };

type Editor =
  | { kind: "class" }
  | { kind: "lesson" }
  | { kind: "content"; topicId: number | null }
  | { kind: "exam"; topicId: number | null }
  | { kind: "note"; topicId: number | null };

type Rename = { kind: "class" | "unit" | "topic"; id: number; name: string };

export function CurriculumView() {
  const t = useT();
  const push = useUi((state) => state.push);
  const client = useQueryClient();
  const [classId, setClassId] = useState<number | null>(null);
  const [lessonId, setLessonId] = useState<number | null>(null);
  const [openUnits, setOpenUnits] = useState<number[]>([]);
  const [openTopics, setOpenTopics] = useState<number[]>([]);
  const [draftUnit, setDraftUnit] = useState("");
  const [draftTopic, setDraftTopic] = useState<{ unitId: number | null; name: string } | null>(null);
  const [rename, setRename] = useState<Rename | null>(null);
  const [editor, setEditor] = useState<Editor | null>(null);
  const [courseDraft, setCourseDraft] = useState({ name: "", year: "", teacher: "" });

  const classes = useQuery({
    queryKey: ["curriculum-classes"],
    queryFn: () => api<{ data: ClassRow[] }>("/api/curriculum-classes"),
  });
  const lessons = useQuery({
    queryKey: ["lessons", classId],
    enabled: classId != null,
    queryFn: () => api<{ data: Lesson[] }>(`/api/lessons?curriculumClassId=${classId}`),
  });
  const units = useQuery({
    queryKey: ["units", lessonId],
    enabled: lessonId != null,
    queryFn: () => api<{ data: UnitRow[] }>(`/api/units?lessonId=${lessonId}`),
  });
  const topics = useQuery({
    queryKey: ["topics", lessonId],
    enabled: lessonId != null,
    queryFn: () => api<{ data: TopicRow[] }>(`/api/topics?lessonId=${lessonId}`),
  });
  const contents = useQuery({
    queryKey: ["contents", lessonId],
    enabled: lessonId != null,
    queryFn: () => api<{ data: ContentRow[] }>(`/api/contents?lessonId=${lessonId}`),
  });
  const exams = useQuery({
    queryKey: ["exams", lessonId],
    enabled: lessonId != null,
    queryFn: () => api<{ data: ExamRow[] }>(`/api/exams?lessonId=${lessonId}`),
  });
  const notes = useQuery({
    queryKey: ["lesson-notes", lessonId],
    enabled: lessonId != null,
    queryFn: () => api<{ data: NoteRow[] }>(`/api/lesson-notes?lessonId=${lessonId}`),
  });
  const academicYears = useQuery({
    queryKey: ["academic-years"],
    queryFn: () => api<{ data: { years: string[] } }>("/api/settings/academic-years"),
  });
  const teachers = useQuery({
    queryKey: ["teacher-pick"],
    queryFn: () => api<{ data: { teachers: string[] } }>("/api/settings/teachers"),
  });

  const saveClass = useSave((name: string) => api("/api/curriculum-classes", { method: "POST", body: JSON.stringify({ name }) }), ["curriculum-classes"]);
  const saveLesson = useSave((body: object) => api("/api/lessons", { method: "POST", body: JSON.stringify(body) }), ["lessons", classId]);
  const saveUnit = useSave((body: object) => api("/api/units", { method: "POST", body: JSON.stringify(body) }), ["units", lessonId]);
  const saveTopic = useSave((body: object) => api("/api/topics", { method: "POST", body: JSON.stringify(body) }), ["topics", lessonId]);
  const saveContent = useSave((body: object) => api("/api/contents", { method: "POST", body: JSON.stringify(body) }), ["contents", lessonId]);
  const saveExam = useSave((body: object) => api("/api/exams", { method: "POST", body: JSON.stringify(body) }), ["exams", lessonId]);
  const saveNote = useSave((body: object) => api("/api/lesson-notes", { method: "POST", body: JSON.stringify(body) }), ["lesson-notes", lessonId]);
  const patchLesson = useSave((body: { id: number; name: string; academicYear: string; teacherName: string | null }) => api(`/api/lessons/${body.id}`, { method: "PATCH", body: JSON.stringify(body) }), ["lessons", classId]);

  const unitRows = units.data?.data ?? [];
  const topicRows = topics.data?.data ?? [];
  const contentRows = contents.data?.data ?? [];
  const examRows = exams.data?.data ?? [];
  const noteRows = notes.data?.data ?? [];
  const lesson = (lessons.data?.data ?? []).find((row) => row.id === lessonId) ?? null;
  const sortedClasses = useMemo(() => sortCurriculumClasses(classes.data?.data ?? []), [classes.data?.data]);
  const yearOptions = academicYears.data?.data.years ?? [];
  const teacherOptions = teachers.data?.data.teachers ?? [];

  useEffect(() => {
    if (!lesson) return;
    setCourseDraft({
      name: lesson.name,
      year: lesson.academicYear || yearOptions[0] || "",
      teacher: lesson.teacherName ?? "",
    });
  }, [lesson, academicYears.data]);
  const looseTopics = topicRows.filter((row) => row.unitId == null);
  const looseContents = contentRows.filter((row) => row.topicId == null);

  function refresh(keys: Array<readonly unknown[]>) {
    return Promise.all(keys.map((queryKey) => client.invalidateQueries({ queryKey })));
  }

  function chooseClass(id: number | null) {
    setClassId(id);
    setLessonId(null);
    setOpenUnits([]);
    setOpenTopics([]);
    setDraftUnit("");
    setDraftTopic(null);
    setRename(null);
  }

  function chooseLesson(id: number) {
    setLessonId(id);
    setOpenUnits([]);
    setOpenTopics([]);
    setDraftUnit("");
    setDraftTopic(null);
    setRename(null);
  }

  function toggle(list: number[], id: number, setList: (next: number[]) => void) {
    setList(list.includes(id) ? list.filter((item) => item !== id) : [...list, id]);
  }

  async function remove(path: string, keys: Array<readonly unknown[]>) {
    if (!window.confirm(t("confirmDelete"))) return;
    await api(path, { method: "DELETE" });
    push("ok", t("deleted"));
    await refresh(keys);
  }

  async function commitRename() {
    if (!rename || !rename.name.trim()) return;
    const name = rename.name.trim();
    if (rename.kind === "class") {
      await api(`/api/curriculum-classes/${rename.id}`, { method: "PATCH", body: JSON.stringify({ name }) });
      await refresh([["curriculum-classes"]]);
    }
    if (rename.kind === "unit") {
      await api(`/api/units/${rename.id}`, { method: "PATCH", body: JSON.stringify({ name }) });
      await refresh([["units", lessonId]]);
    }
    if (rename.kind === "topic") {
      await api(`/api/topics/${rename.id}`, { method: "PATCH", body: JSON.stringify({ name }) });
      await refresh([["topics", lessonId]]);
    }
    push("ok", t("saved"));
    setRename(null);
  }

  async function addUnit() {
    if (!lessonId || !draftUnit.trim()) return;
    const result = (await saveUnit.mutateAsync({
      lessonId,
      name: draftUnit.trim(),
      order: unitRows.length,
      number: unitRows.length + 1,
    })) as Created;
    setOpenUnits((prev) => [...prev, result.data.id]);
    setDraftUnit("");
  }

  async function addTopic(unitId: number | null) {
    if (!lessonId || !draftTopic || draftTopic.unitId !== unitId || !draftTopic.name.trim()) return;
    const siblings = topicRows.filter((row) => row.unitId === unitId);
    const result = (await saveTopic.mutateAsync({
      lessonId,
      unitId,
      name: draftTopic.name.trim(),
      order: siblings.length,
    })) as Created;
    setOpenTopics((prev) => [...prev, result.data.id]);
    setDraftTopic(null);
  }

  async function move(kind: "units" | "topics" | "contents", rows: Array<{ id: number }>, index: number, direction: -1 | 1) {
    const next = index + direction;
    if (next < 0 || next >= rows.length) return;
    const copy = rows.slice();
    const [item] = copy.splice(index, 1);
    copy.splice(next, 0, item);
    await Promise.all(
      copy.map((row, order) => api(`/api/${kind}/${row.id}`, { method: "PATCH", body: JSON.stringify({ order }) })),
    );
    await refresh([[kind, lessonId]]);
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    if (editor?.kind === "class") await saveClass.mutateAsync(String(form.get("name")));
    if (editor?.kind === "lesson" && classId) {
      const result = (await saveLesson.mutateAsync({
        curriculumClassId: classId,
        name: String(form.get("name")),
        academicYear: String(form.get("year") ?? ""),
        teacherName: String(form.get("teacher") ?? "") || null,
        order: lessons.data?.data.length ?? 0,
      })) as Created;
      chooseLesson(result.data.id);
    }
    if (editor?.kind === "content" && lessonId) {
      const kind = String(form.get("kind"));
      let storageKey = String(form.get("link") ?? "");
      const file = form.get("file");
      if (file instanceof File && file.size > 0) storageKey = await uploadFile(file);
      if (kind === "text") {
        storageKey = await uploadFile(new File([String(form.get("text") ?? "")], "note.txt", { type: "text/plain" }));
      }
      const siblings = contentRows.filter((row) => row.topicId === editor.topicId);
      await saveContent.mutateAsync({
        lessonId,
        topicId: editor.topicId,
        name: String(form.get("name")),
        type: kind === "text" ? "text" : kind,
        storageKey,
        order: siblings.length,
      });
    }
    if (editor?.kind === "exam" && lessonId) {
      await saveExam.mutateAsync({
        lessonId,
        topicId: editor.topicId,
        name: String(form.get("name")),
        questions: [{ prompt: String(form.get("prompt")), type: "text", order: 0, options: [] }],
      });
    }
    if (editor?.kind === "note" && lessonId) {
      await saveNote.mutateAsync({ lessonId, topicId: editor.topicId, text: String(form.get("text")) });
    }
    setEditor(null);
  }

  async function saveCourse(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!lesson) return;
    const form = new FormData(event.currentTarget);
    await patchLesson.mutateAsync({
      id: lesson.id,
      name: String(form.get("name")),
      academicYear: String(form.get("year") ?? ""),
      teacherName: String(form.get("teacher") ?? "") || null,
    });
  }

  return (
    <div className="grid gap-4">
      <PageTitle title={t("curriculum")} subtitle={t("stepsHint")} />
      <ol className="flex flex-wrap gap-2 text-xs font-medium">
        <Step active={classId == null} done={classId != null} label={t("classes")} />
        <Step active={classId != null && lessonId == null} done={lessonId != null} label={t("course")} />
        <Step active={lessonId != null && unitRows.length === 0} done={unitRows.length > 0} label={t("units")} />
        <Step active={unitRows.length > 0 && topicRows.length === 0} done={topicRows.length > 0} label={t("topics")} />
        <Step active={topicRows.length > 0 && contentRows.length === 0} done={contentRows.length > 0} label={t("contents")} />
      </ol>
      <div className="grid items-start gap-4 lg:grid-cols-[18rem_1fr]">
        <aside className="grid gap-4">
          <section className="rounded-2xl bg-white p-3 ring-1 ring-slate-200 dark:bg-slate-900 dark:ring-slate-800">
            <div className="mb-2 flex items-center justify-between">
              <h2 className="flex items-center gap-2 text-sm font-semibold">
                <GraduationCap size={16} /> {t("classes")}
              </h2>
              <Button className="px-2" onClick={() => setEditor({ kind: "class" })} aria-label={t("create")}>
                <Plus size={16} />
              </Button>
            </div>
            {classes.isLoading ? <Skeleton className="h-16" /> : null}
            {(sortedClasses.length ?? 0) === 0 && !classes.isLoading ? <Empty text={t("empty")} /> : null}
            <Field label={t("selectClass")}>
              <Select
                value={classId ?? ""}
                onChange={(event) => {
                  const value = event.target.value;
                  if (!value) {
                    chooseClass(null);
                    return;
                  }
                  chooseClass(Number(value));
                }}
              >
                <option value="">{t("classes")}</option>
                {sortedClasses.map((row) => (
                  <option key={row.id} value={row.id}>
                    {row.name}
                  </option>
                ))}
              </Select>
            </Field>
            {classId != null ? (
              <div className="mt-2 flex flex-wrap gap-1">
                <IconButton
                  label={t("edit")}
                  onClick={() => {
                    const row = sortedClasses.find((item) => item.id === classId);
                    if (row) setRename({ kind: "class", id: row.id, name: row.name });
                  }}
                >
                  <Pencil size={14} />
                </IconButton>
                <IconButton
                  label={t("delete")}
                  danger
                  onClick={() => {
                    if (!window.confirm(t("confirmDelete"))) return;
                    void api(`/api/curriculum-classes/${classId}`, { method: "DELETE" }).then(() => {
                      push("ok", t("deleted"));
                      return refresh([["curriculum-classes"]]);
                    });
                    chooseClass(null);
                  }}
                >
                  <Trash2 size={14} />
                </IconButton>
              </div>
            ) : null}
            {rename?.kind === "class" ? (
              <div className="mt-2">
                <RenameField value={rename.name} onChange={(name) => setRename({ ...rename, name })} onSave={() => void commitRename()} onCancel={() => setRename(null)} />
              </div>
            ) : null}
          </section>
          <section className="rounded-2xl bg-white p-3 ring-1 ring-slate-200 dark:bg-slate-900 dark:ring-slate-800">
            <div className="mb-2 flex items-center justify-between">
              <h2 className="flex items-center gap-2 text-sm font-semibold">
                <BookOpen size={16} /> {t("course")}
              </h2>
              <Button className="px-2" disabled={!classId} onClick={() => setEditor({ kind: "lesson" })} aria-label={t("create")}>
                <Plus size={16} />
              </Button>
            </div>
            {!classId ? <Empty text={t("selectClass")} /> : null}
            {classId && lessons.isLoading ? <Skeleton className="h-16" /> : null}
            {classId && !lessons.isLoading && (lessons.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
            <ul className="grid gap-1">
              {(lessons.data?.data ?? []).map((row) => (
                <li key={row.id}>
                  <button
                    type="button"
                    onClick={() => chooseLesson(row.id)}
                    className={`w-full rounded-lg px-2 py-2 text-left text-sm ${lessonId === row.id ? "bg-blue-50 text-brand dark:bg-slate-800" : "hover:bg-slate-50 dark:hover:bg-slate-800"}`}
                  >
                    <span className="block font-medium">{row.name}</span>
                    <span className="block truncate text-xs text-slate-500">
                      {[row.academicYear, row.teacherName].filter(Boolean).join(" · ") || t("outline")}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          </section>
        </aside>

        <section className="min-w-0 rounded-2xl bg-white p-4 ring-1 ring-slate-200 dark:bg-slate-900 dark:ring-slate-800">
          {!lesson ? (
            <Empty text={classId ? t("selectLesson") : t("selectClass")} />
          ) : (
            <div className="grid gap-4">
              <form className="grid gap-3 border-b border-slate-100 pb-4 dark:border-slate-800" onSubmit={saveCourse}>
                <p className="text-xs font-medium uppercase tracking-wide text-brand">{t("course")}</p>
                <div className="grid gap-3 sm:grid-cols-2">
                  <Field label={t("name")}>
                    <Input name="name" required value={courseDraft.name} onChange={(event) => setCourseDraft((draft) => ({ ...draft, name: event.target.value }))} />
                  </Field>
                  <YearTeacherPick yearOptions={yearOptions} teacherOptions={teacherOptions} year={courseDraft.year} teacher={courseDraft.teacher} onYear={(year) => setCourseDraft((draft) => ({ ...draft, year }))} onTeacher={(teacher) => setCourseDraft((draft) => ({ ...draft, teacher }))} />
                </div>
                <div className="flex flex-wrap gap-2">
                  <Button type="submit" disabled={patchLesson.isPending}>
                    {t("saveCourse")}
                  </Button>
                  <Button
                    type="button"
                    variant="danger"
                    onClick={() => {
                      if (!window.confirm(t("confirmDelete"))) return;
                      void api(`/api/lessons/${lesson.id}`, { method: "DELETE" }).then(() => {
                        push("ok", t("deleted"));
                        return refresh([["lessons", classId]]);
                      });
                      setLessonId(null);
                    }}
                  >
                    <Trash2 size={16} /> {t("delete")}
                  </Button>
                </div>
              </form>

              {units.isLoading || topics.isLoading || contents.isLoading ? <Skeleton className="h-40" /> : null}

              {unitRows.length === 0 && looseTopics.length === 0 ? <Empty text={t("outlineEmpty")} /> : null}

              <div className="grid gap-2">
                {unitRows.map((unit, index) => (
                  <UnitBlock
                    key={unit.id}
                    unit={unit}
                    index={index}
                    open={openUnits.includes(unit.id)}
                    onToggle={() => toggle(openUnits, unit.id, setOpenUnits)}
                    topics={topicRows.filter((row) => row.unitId === unit.id)}
                    contents={contentRows}
                    exams={examRows}
                    notes={noteRows}
                    openTopics={openTopics}
                    onToggleTopic={(id) => toggle(openTopics, id, setOpenTopics)}
                    rename={rename}
                    setRename={setRename}
                    commitRename={() => void commitRename()}
                    draftTopic={draftTopic}
                    setDraftTopic={setDraftTopic}
                    onAddTopic={() => void addTopic(unit.id)}
                    onMove={(direction) => void move("units", unitRows, index, direction)}
                    onMoveTopic={(rows, topicIndex, direction) => void move("topics", rows, topicIndex, direction)}
                    onMoveContent={(rows, contentIndex, direction) => void move("contents", rows, contentIndex, direction)}
                    onDeleteUnit={() => void remove(`/api/units/${unit.id}`, [["units", lessonId], ["topics", lessonId]])}
                    onDeleteTopic={(id) => void remove(`/api/topics/${id}`, [["topics", lessonId], ["contents", lessonId]])}
                    onDeleteContent={(id) => void remove(`/api/contents/${id}`, [["contents", lessonId]])}
                    onDeleteExam={(id) => void remove(`/api/exams/${id}`, [["exams", lessonId]])}
                    onDeleteNote={(id) => void remove(`/api/lesson-notes/${id}`, [["lesson-notes", lessonId]])}
                    onAddContent={(topicId) => setEditor({ kind: "content", topicId })}
                    onAddExam={(topicId) => setEditor({ kind: "exam", topicId })}
                    onAddNote={(topicId) => setEditor({ kind: "note", topicId })}
                  />
                ))}
              </div>

              {looseTopics.length > 0 ? (
                <div className="rounded-xl bg-slate-50 p-3 dark:bg-slate-950">
                  <h3 className="mb-2 text-sm font-semibold">{t("unsectioned")}</h3>
                  <TopicList
                    topics={looseTopics}
                    contents={contentRows}
                    exams={examRows}
                    notes={noteRows}
                    openTopics={openTopics}
                    onToggleTopic={(id) => toggle(openTopics, id, setOpenTopics)}
                    rename={rename}
                    setRename={setRename}
                    commitRename={() => void commitRename()}
                    onMoveTopic={(index, direction) => void move("topics", looseTopics, index, direction)}
                    onMoveContent={(rows, contentIndex, direction) => void move("contents", rows, contentIndex, direction)}
                    onDeleteTopic={(id) => void remove(`/api/topics/${id}`, [["topics", lessonId], ["contents", lessonId]])}
                    onDeleteContent={(id) => void remove(`/api/contents/${id}`, [["contents", lessonId]])}
                    onDeleteExam={(id) => void remove(`/api/exams/${id}`, [["exams", lessonId]])}
                    onDeleteNote={(id) => void remove(`/api/lesson-notes/${id}`, [["lesson-notes", lessonId]])}
                    onAddContent={(topicId) => setEditor({ kind: "content", topicId })}
                    onAddExam={(topicId) => setEditor({ kind: "exam", topicId })}
                    onAddNote={(topicId) => setEditor({ kind: "note", topicId })}
                  />
                </div>
              ) : null}

              {looseContents.length > 0 ? (
                <div className="rounded-xl bg-slate-50 p-3 dark:bg-slate-950">
                  <h3 className="mb-2 text-sm font-semibold">{t("looseContent")}</h3>
                  <ContentList
                    rows={looseContents}
                    onMove={(index, direction) => void move("contents", looseContents, index, direction)}
                    onDelete={(id) => void remove(`/api/contents/${id}`, [["contents", lessonId]])}
                  />
                </div>
              ) : null}

              <form
                className="flex flex-col gap-2 rounded-xl border border-dashed border-slate-300 p-3 sm:flex-row dark:border-slate-700"
                onSubmit={(event) => {
                  event.preventDefault();
                  void addUnit();
                }}
              >
                <label className="grid flex-1 gap-1 text-sm">
                  <span className="font-medium">{t("newUnit")}</span>
                  <Input value={draftUnit} onChange={(event) => setDraftUnit(event.target.value)} placeholder={t("addUnit")} />
                </label>
                <Button type="submit" className="sm:self-end" disabled={!draftUnit.trim() || saveUnit.isPending}>
                  <Plus size={16} /> {t("addUnit")}
                </Button>
              </form>
            </div>
          )}
        </section>
      </div>

      <Modal open={editor != null} title={editor ? editorTitle(editor, t) : ""} onClose={() => setEditor(null)}>
        <form className="grid gap-3" onSubmit={submit}>
          {editor && editor.kind !== "note" ? (
            <Field label={t("name")}>
              <Input name="name" required />
            </Field>
          ) : null}
          {editor?.kind === "lesson" ? (
            <YearTeacherPick yearOptions={yearOptions} teacherOptions={teacherOptions} year={yearOptions[0] ?? ""} teacher="" />
          ) : null}
          {editor?.kind === "content" ? <ContentFields /> : null}
          {editor?.kind === "exam" ? (
            <Field label={t("prompt")}>
              <Textarea name="prompt" required />
            </Field>
          ) : null}
          {editor?.kind === "note" ? (
            <Field label={t("notes")}>
              <Textarea name="text" required />
            </Field>
          ) : null}
          <Button type="submit">{t("save")}</Button>
        </form>
      </Modal>
    </div>
  );
}

function editorTitle(editor: Editor, t: (key: "create" | "edit" | "quiz" | "notes" | "contents" | "course") => string) {
  if (editor.kind === "content") return t("contents");
  if (editor.kind === "exam") return t("quiz");
  if (editor.kind === "note") return t("notes");
  if (editor.kind === "lesson") return t("course");
  return t("create");
}

function YearTeacherPick({
  yearOptions,
  teacherOptions,
  year,
  teacher,
  onYear,
  onTeacher,
}: {
  yearOptions: string[];
  teacherOptions: string[];
  year: string;
  teacher: string;
  onYear?: (year: string) => void;
  onTeacher?: (teacher: string) => void;
}) {
  const t = useT();
  return (
    <>
      <Field label={t("academicYear")}>
        {onYear ? (
          <Select name="year" value={year} onChange={(event) => onYear(event.target.value)} required>
            <option value="">{t("pickYear")}</option>
            {yearOptions.map((item) => (
              <option key={item} value={item}>
                {item}
              </option>
            ))}
          </Select>
        ) : (
          <Select name="year" defaultValue={yearOptions[0] ?? ""} required>
            <option value="">{t("pickYear")}</option>
            {yearOptions.map((item) => (
              <option key={item} value={item}>
                {item}
              </option>
            ))}
          </Select>
        )}
      </Field>
      <Field label={t("teacherName")}>
        {onTeacher ? (
          <Select name="teacher" value={teacher} onChange={(event) => onTeacher(event.target.value)}>
            <option value="">{t("pickTeacher")}</option>
            {teacherOptions.map((item) => (
              <option key={item} value={item}>
                {item}
              </option>
            ))}
          </Select>
        ) : (
          <Select name="teacher" defaultValue="">
            <option value="">{t("pickTeacher")}</option>
            {teacherOptions.map((item) => (
              <option key={item} value={item}>
                {item}
              </option>
            ))}
          </Select>
        )}
      </Field>
    </>
  );
}

function Step({ active, done, label }: { active: boolean; done: boolean; label: string }) {
  const tone = active ? "bg-brand text-white" : done ? "bg-blue-50 text-brand dark:bg-slate-800" : "bg-slate-100 text-slate-500 dark:bg-slate-800";
  return <li className={`rounded-full px-3 py-1 ${tone}`}>{label}</li>;
}

function IconButton({ label, onClick, children, danger = false }: { label: string; onClick: () => void; children: React.ReactNode; danger?: boolean }) {
  return (
    <button
      type="button"
      aria-label={label}
      title={label}
      onClick={(event) => {
        event.stopPropagation();
        onClick();
      }}
      className={`rounded-md p-1.5 ${danger ? "text-red-600 hover:bg-red-50 dark:hover:bg-red-950" : "text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"}`}
    >
      {children}
    </button>
  );
}

function RenameField({ value, onChange, onSave, onCancel }: { value: string; onChange: (value: string) => void; onSave: () => void; onCancel: () => void }) {
  const t = useT();
  return (
    <form
      className="flex gap-1"
      onSubmit={(event) => {
        event.preventDefault();
        onSave();
      }}
    >
      <Input value={value} onChange={(event) => onChange(event.target.value)} autoFocus />
      <Button type="submit" className="px-2" aria-label={t("save")}>
        {t("save")}
      </Button>
      <Button type="button" variant="ghost" className="px-2" onClick={onCancel}>
        {t("cancel")}
      </Button>
    </form>
  );
}

function ContentFields() {
  const t = useT();
  return (
    <>
      <Field label={t("type")}>
        <Select name="kind" defaultValue="pdf">
          <option value="pdf">PDF</option>
          <option value="word">Word</option>
          <option value="image">{t("file")}</option>
          <option value="video">Video</option>
          <option value="link">{t("link")}</option>
          <option value="text">{t("text")}</option>
          <option value="homework">{t("homework")}</option>
        </Select>
      </Field>
      <Field label={t("file")}>
        <Input name="file" type="file" />
      </Field>
      <Field label={t("link")}>
        <Input name="link" placeholder="https://" />
      </Field>
      <Field label={t("text")}>
        <Textarea name="text" />
      </Field>
    </>
  );
}

function contentIcon(type: string) {
  if (type === "video") return Video;
  if (type === "image") return ImageIcon;
  if (type === "link") return Link2;
  return FileText;
}

function UnitBlock(props: {
  unit: UnitRow;
  index: number;
  open: boolean;
  onToggle: () => void;
  topics: TopicRow[];
  contents: ContentRow[];
  exams: ExamRow[];
  notes: NoteRow[];
  openTopics: number[];
  onToggleTopic: (id: number) => void;
  rename: Rename | null;
  setRename: (value: Rename | null) => void;
  commitRename: () => void;
  draftTopic: { unitId: number | null; name: string } | null;
  setDraftTopic: (value: { unitId: number | null; name: string } | null) => void;
  onAddTopic: () => void;
  onMove: (direction: -1 | 1) => void;
  onMoveTopic: (rows: TopicRow[], index: number, direction: -1 | 1) => void;
  onMoveContent: (rows: ContentRow[], index: number, direction: -1 | 1) => void;
  onDeleteUnit: () => void;
  onDeleteTopic: (id: number) => void;
  onDeleteContent: (id: number) => void;
  onDeleteExam: (id: number) => void;
  onDeleteNote: (id: number) => void;
  onAddContent: (topicId: number) => void;
  onAddExam: (topicId: number) => void;
  onAddNote: (topicId: number) => void;
}) {
  const t = useT();
  const renaming = props.rename?.kind === "unit" && props.rename.id === props.unit.id;
  return (
    <article className="overflow-hidden rounded-xl ring-1 ring-slate-200 dark:ring-slate-700">
      <div className="flex items-center gap-1 bg-slate-50 px-2 py-1 dark:bg-slate-950">
        <button type="button" onClick={props.onToggle} className="flex min-w-0 flex-1 items-center gap-2 px-1 py-2 text-left" aria-expanded={props.open}>
          <ChevronDown size={16} className={`shrink-0 transition ${props.open ? "rotate-0" : "-rotate-90"}`} />
          <Layers size={16} className="shrink-0 text-brand" />
          <span className="truncate text-sm font-semibold">
            {props.index + 1}. {props.unit.name}
          </span>
          <span className="text-xs text-slate-500">{props.topics.length}</span>
        </button>
        <IconButton label={t("order")} onClick={() => props.onMove(-1)}>
          <ArrowUp size={14} />
        </IconButton>
        <IconButton label={t("order")} onClick={() => props.onMove(1)}>
          <ArrowDown size={14} />
        </IconButton>
        <IconButton label={t("edit")} onClick={() => props.setRename({ kind: "unit", id: props.unit.id, name: props.unit.name })}>
          <Pencil size={14} />
        </IconButton>
        <IconButton label={t("delete")} danger onClick={props.onDeleteUnit}>
          <Trash2 size={14} />
        </IconButton>
      </div>
      {renaming && props.rename ? (
        <div className="px-3 py-2">
          <RenameField value={props.rename.name} onChange={(name) => props.setRename({ kind: "unit", id: props.unit.id, name })} onSave={props.commitRename} onCancel={() => props.setRename(null)} />
        </div>
      ) : null}
      {props.open ? (
        <div className="grid gap-3 p-3">
          {props.topics.length === 0 ? <Empty text={t("topicEmpty")} /> : null}
          <TopicList
            topics={props.topics}
            contents={props.contents}
            exams={props.exams}
            notes={props.notes}
            openTopics={props.openTopics}
            onToggleTopic={props.onToggleTopic}
            rename={props.rename}
            setRename={props.setRename}
            commitRename={props.commitRename}
            onMoveTopic={(index, direction) => props.onMoveTopic(props.topics, index, direction)}
            onMoveContent={props.onMoveContent}
            onDeleteTopic={props.onDeleteTopic}
            onDeleteContent={props.onDeleteContent}
            onDeleteExam={props.onDeleteExam}
            onDeleteNote={props.onDeleteNote}
            onAddContent={props.onAddContent}
            onAddExam={props.onAddExam}
            onAddNote={props.onAddNote}
          />
          <form
            className="flex flex-col gap-2 sm:flex-row"
            onSubmit={(event) => {
              event.preventDefault();
              props.onAddTopic();
            }}
          >
            <Input
              value={props.draftTopic?.unitId === props.unit.id ? props.draftTopic.name : ""}
              onChange={(event) => props.setDraftTopic({ unitId: props.unit.id, name: event.target.value })}
              placeholder={t("newTopic")}
            />
            <Button type="submit" disabled={props.draftTopic?.unitId !== props.unit.id || !props.draftTopic.name.trim()}>
              <Plus size={16} /> {t("addTopic")}
            </Button>
          </form>
        </div>
      ) : null}
    </article>
  );
}

function TopicList(props: {
  topics: TopicRow[];
  contents: ContentRow[];
  exams: ExamRow[];
  notes: NoteRow[];
  openTopics: number[];
  onToggleTopic: (id: number) => void;
  rename: Rename | null;
  setRename: (value: Rename | null) => void;
  commitRename: () => void;
  onMoveTopic: (index: number, direction: -1 | 1) => void;
  onMoveContent: (rows: ContentRow[], index: number, direction: -1 | 1) => void;
  onDeleteTopic: (id: number) => void;
  onDeleteContent: (id: number) => void;
  onDeleteExam: (id: number) => void;
  onDeleteNote: (id: number) => void;
  onAddContent: (topicId: number) => void;
  onAddExam: (topicId: number) => void;
  onAddNote: (topicId: number) => void;
}) {
  const t = useT();
  return (
    <ul className="grid gap-2">
      {props.topics.map((topic, index) => {
        const open = props.openTopics.includes(topic.id);
        const rows = props.contents.filter((row) => row.topicId === topic.id);
        const topicExams = props.exams.filter((row) => row.topicId === topic.id);
        const topicNotes = props.notes.filter((row) => row.topicId === topic.id);
        const renaming = props.rename?.kind === "topic" && props.rename.id === topic.id;
        return (
          <li key={topic.id} className="rounded-lg ring-1 ring-slate-200 dark:ring-slate-700">
            <div className="flex items-center gap-1 px-1">
              <button type="button" onClick={() => props.onToggleTopic(topic.id)} className="flex min-w-0 flex-1 items-center gap-2 px-1 py-2 text-left" aria-expanded={open}>
                <ChevronDown size={14} className={`shrink-0 transition ${open ? "rotate-0" : "-rotate-90"}`} />
                <span className="truncate text-sm">{topic.name}</span>
                <span className="text-xs text-slate-500">{rows.length}</span>
              </button>
              <IconButton label={t("order")} onClick={() => props.onMoveTopic(index, -1)}>
                <ArrowUp size={14} />
              </IconButton>
              <IconButton label={t("order")} onClick={() => props.onMoveTopic(index, 1)}>
                <ArrowDown size={14} />
              </IconButton>
              <IconButton label={t("edit")} onClick={() => props.setRename({ kind: "topic", id: topic.id, name: topic.name })}>
                <Pencil size={14} />
              </IconButton>
              <IconButton label={t("delete")} danger onClick={() => props.onDeleteTopic(topic.id)}>
                <Trash2 size={14} />
              </IconButton>
            </div>
            {renaming && props.rename ? (
              <div className="px-3 pb-2">
                <RenameField value={props.rename.name} onChange={(name) => props.setRename({ kind: "topic", id: topic.id, name })} onSave={props.commitRename} onCancel={() => props.setRename(null)} />
              </div>
            ) : null}
            {open ? (
              <div className="grid gap-2 border-t border-slate-100 px-3 py-3 dark:border-slate-800">
                {rows.length === 0 ? <Empty text={t("contentEmpty")} /> : null}
                <ContentList rows={rows} onMove={(contentIndex, direction) => props.onMoveContent(rows, contentIndex, direction)} onDelete={props.onDeleteContent} />
                {topicExams.map((exam) => (
                  <p key={exam.id} className="flex items-center justify-between gap-2 text-sm">
                    <span className="flex items-center gap-2"><ClipboardList size={14} /> {exam.name}</span>
                    <IconButton label={t("delete")} danger onClick={() => props.onDeleteExam(exam.id)}>
                      <Trash2 size={14} />
                    </IconButton>
                  </p>
                ))}
                {topicNotes.map((note) => (
                  <p key={note.id} className="flex items-start justify-between gap-2 text-sm">
                    <span className="flex gap-2"><StickyNote size={14} className="mt-0.5 shrink-0" /> {note.text}</span>
                    <IconButton label={t("delete")} danger onClick={() => props.onDeleteNote(note.id)}>
                      <Trash2 size={14} />
                    </IconButton>
                  </p>
                ))}
                <div className="flex flex-wrap gap-2">
                  <Button variant="soft" onClick={() => props.onAddContent(topic.id)}>
                    <Plus size={14} /> {t("addContent")}
                  </Button>
                  <Button variant="ghost" onClick={() => props.onAddExam(topic.id)}>
                    <ClipboardList size={14} /> {t("quiz")}
                  </Button>
                  <Button variant="ghost" onClick={() => props.onAddNote(topic.id)}>
                    <StickyNote size={14} /> {t("notes")}
                  </Button>
                </div>
              </div>
            ) : null}
          </li>
        );
      })}
    </ul>
  );
}

function ContentList({ rows, onMove, onDelete }: { rows: ContentRow[]; onMove: (index: number, direction: -1 | 1) => void; onDelete: (id: number) => void }) {
  const t = useT();
  return (
    <ul className="grid gap-1">
      {rows.map((row, index) => {
        const Icon = contentIcon(row.type);
        return (
          <li key={row.id} className="flex items-center gap-1 rounded-lg px-1 hover:bg-slate-50 dark:hover:bg-slate-800">
            <Icon size={14} className="shrink-0 text-slate-500" />
            <a className="min-w-0 flex-1 truncate py-1.5 text-sm text-brand" href={`/api/files?key=${encodeURIComponent(row.storageKey)}`} target="_blank" rel="noreferrer">
              {row.name}
            </a>
            <span className="text-xs uppercase text-slate-400">{row.type}</span>
            <IconButton label={t("order")} onClick={() => onMove(index, -1)}>
              <ArrowUp size={14} />
            </IconButton>
            <IconButton label={t("order")} onClick={() => onMove(index, 1)}>
              <ArrowDown size={14} />
            </IconButton>
            <IconButton label={t("delete")} danger onClick={() => onDelete(row.id)}>
              <Trash2 size={14} />
            </IconButton>
          </li>
        );
      })}
    </ul>
  );
}
