"use client";

import { useQuery } from "@tanstack/react-query";
import { FormEvent } from "react";
import { Button, Empty, Field, Input, PageTitle, Panel, Select, Textarea } from "@/components/ui";
import { useT } from "@/i18n/use-t";
import { api } from "@/lib/api";
import { useSave } from "@/lib/use-save";

const dayOptions = [
  { value: 1, key: "monday" },
  { value: 2, key: "tuesday" },
  { value: 3, key: "wednesday" },
  { value: 4, key: "thursday" },
  { value: 5, key: "friday" },
] as const;

export function PlansView() {
  const t = useT();
  const periods = useQuery({
    queryKey: ["periods"],
    queryFn: () => api<{ data: { period: number; start: string; end: string }[] }>("/api/academic-plans/periods"),
  });
  const weekly = useQuery({
    queryKey: ["weekly", "edit"],
    queryFn: () => api<{ data: { id: number; day: number; period: number; start: string; end: string; topicText: string }[] }>("/api/academic-plans/weekly"),
  });
  const daily = useQuery({
    queryKey: ["daily"],
    queryFn: () => api<{ data: { id: number; date: string; topic: string | null; homework: string | null }[] }>("/api/academic-plans/daily"),
  });
  const annual = useQuery({
    queryKey: ["annual"],
    queryFn: () => api<{ data: { id: number; academicYear: string; unitTopic: string; hours: number | null }[] }>("/api/academic-plans/annual"),
  });
  const classes = useQuery({
    queryKey: ["roster-classes"],
    queryFn: () => api<{ data: { id: number; name: string }[] }>("/api/roster-classes"),
  });
  const lessons = useQuery({
    queryKey: ["lessons", "all"],
    queryFn: () => api<{ data: { id: number; name: string }[] }>("/api/lessons"),
  });
  const saveWeekly = useSave((body: object) => api("/api/academic-plans/weekly", { method: "POST", body: JSON.stringify(body) }), ["weekly"]);
  const saveDaily = useSave((body: object) => api("/api/academic-plans/daily", { method: "POST", body: JSON.stringify(body) }), ["daily"]);
  const saveAnnual = useSave((body: object) => api("/api/academic-plans/annual", { method: "POST", body: JSON.stringify(body) }), ["annual"]);
  const removeWeekly = useSave((id: number) => api(`/api/academic-plans/weekly/${id}`, { method: "DELETE" }), ["weekly"], "deleted");

  function submit(kind: "weekly" | "daily" | "annual") {
    return (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      const form = new FormData(event.currentTarget);
      const rosterClassId = form.get("rosterClassId") ? Number(form.get("rosterClassId")) : null;
      const lessonId = form.get("lessonId") ? Number(form.get("lessonId")) : null;
      if (kind === "weekly") {
        saveWeekly.mutate({
          day: Number(form.get("day")),
          period: Number(form.get("period")),
          start: String(form.get("start")),
          end: String(form.get("end")),
          topicText: String(form.get("topic") ?? ""),
          rosterClassId,
          lessonId,
        });
      }
      if (kind === "daily") {
        saveDaily.mutate({
          date: String(form.get("date")),
          topic: String(form.get("topic") ?? "") || null,
          goals: String(form.get("goals") ?? "") || null,
          homework: String(form.get("homework") ?? "") || null,
          rosterClassId,
          lessonId,
        });
      }
      if (kind === "annual") {
        saveAnnual.mutate({
          academicYear: String(form.get("year")),
          unitTopic: String(form.get("unitTopic")),
          hours: form.get("hours") ? Number(form.get("hours")) : null,
          goals: String(form.get("goals") ?? "") || null,
          rosterClassId,
          lessonId,
        });
      }
      event.currentTarget.reset();
    };
  }

  return (
    <div className="grid gap-4">
      <PageTitle title={t("plans")} />
      <Panel title={t("period")}>
        <ul className="grid gap-1 text-sm sm:grid-cols-2">
          {(periods.data?.data ?? []).map((slot) => (
            <li key={slot.period}>{slot.period}. {slot.start}–{slot.end}</li>
          ))}
        </ul>
      </Panel>
      <Panel title={t("schedule")}>
        <form className="grid gap-3 sm:grid-cols-3" onSubmit={submit("weekly")}>
          <Field label={t("day")}>
            <Select name="day" defaultValue="1">
              {dayOptions.map((day) => (
                <option key={day.value} value={day.value}>{t(day.key)}</option>
              ))}
            </Select>
          </Field>
          <Field label={t("period")}><Input name="period" type="number" min={1} max={12} required defaultValue={1} /></Field>
          <Field label={t("start")}><Input name="start" type="time" required defaultValue="08:00" /></Field>
          <Field label={t("end")}><Input name="end" type="time" required defaultValue="08:45" /></Field>
          <Field label={t("topic")}><Input name="topic" /></Field>
          <SharedSelects classes={classes.data?.data ?? []} lessons={lessons.data?.data ?? []} />
          <Button type="submit">{t("save")}</Button>
        </form>
        <ul className="mt-3 grid gap-1 text-sm">
          {(weekly.data?.data ?? []).map((row) => (
            <li key={row.id} className="flex items-center justify-between gap-2">
              <span>{row.day}/{row.period} {row.start}–{row.end} {row.topicText}</span>
              <Button variant="ghost" onClick={() => removeWeekly.mutate(row.id)}>{t("delete")}</Button>
            </li>
          ))}
        </ul>
        {(weekly.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
      </Panel>
      <Panel title={t("date")}>
        <form className="grid gap-3 sm:grid-cols-2" onSubmit={submit("daily")}>
          <Field label={t("date")}><Input name="date" type="date" required /></Field>
          <Field label={t("topic")}><Input name="topic" /></Field>
          <Field label={t("goals")}><Textarea name="goals" /></Field>
          <Field label={t("homework")}><Textarea name="homework" /></Field>
          <SharedSelects classes={classes.data?.data ?? []} lessons={lessons.data?.data ?? []} />
          <Button type="submit">{t("save")}</Button>
        </form>
        <ul className="mt-3 text-sm">
          {(daily.data?.data ?? []).map((row) => (
            <li key={row.id}>{row.date} · {row.topic || row.homework}</li>
          ))}
        </ul>
      </Panel>
      <Panel title={t("academicYear")}>
        <form className="grid gap-3 sm:grid-cols-2" onSubmit={submit("annual")}>
          <Field label={t("academicYear")}><Input name="year" required placeholder="2026–27" /></Field>
          <Field label={t("unitTopic")}><Input name="unitTopic" required /></Field>
          <Field label={t("hours")}><Input name="hours" type="number" min={0} /></Field>
          <Field label={t("goals")}><Textarea name="goals" /></Field>
          <SharedSelects classes={classes.data?.data ?? []} lessons={lessons.data?.data ?? []} />
          <Button type="submit">{t("save")}</Button>
        </form>
        <ul className="mt-3 text-sm">
          {(annual.data?.data ?? []).map((row) => (
            <li key={row.id}>{row.academicYear} · {row.unitTopic}</li>
          ))}
        </ul>
      </Panel>
    </div>
  );
}

function SharedSelects({ classes, lessons }: { classes: { id: number; name: string }[]; lessons: { id: number; name: string }[] }) {
  const t = useT();
  return (
    <>
      <Field label={t("classes")}>
        <Select name="rosterClassId">
          <option value="" />
          {classes.map((row) => (
            <option key={row.id} value={row.id}>{row.name}</option>
          ))}
        </Select>
      </Field>
      <Field label={t("lessons")}>
        <Select name="lessonId">
          <option value="" />
          {lessons.map((row) => (
            <option key={row.id} value={row.id}>{row.name}</option>
          ))}
        </Select>
      </Field>
    </>
  );
}

export function MentorshipView() {
  const t = useT();
  const classes = useQuery({
    queryKey: ["roster-classes"],
    queryFn: () => api<{ data: { id: number; name: string }[] }>("/api/roster-classes"),
  });
  const linked = useQuery({
    queryKey: ["mentorship-classes"],
    queryFn: () => api<{ data: { id: number; rosterClass: { name: string } }[] }>("/api/mentorship/classes"),
  });
  const events = useQuery({
    queryKey: ["events"],
    queryFn: () => api<{ data: { id: number; title: string; date: string; time: string; status: string }[] }>("/api/mentorship/events"),
  });
  const link = useSave((rosterClassId: number) => api("/api/mentorship/classes", { method: "POST", body: JSON.stringify({ rosterClassId }) }), ["mentorship-classes"]);
  const saveEvent = useSave((body: object) => api("/api/mentorship/events", { method: "POST", body: JSON.stringify(body) }), ["events"]);
  const saveNote = useSave((body: object) => api("/api/mentorship/notes", { method: "POST", body: JSON.stringify(body) }), ["events"]);
  const students = useQuery({
    queryKey: ["students", "mentor"],
    queryFn: () => api<{ data: { id: number; fullName: string }[] }>("/api/students"),
  });

  function onEvent(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    saveEvent.mutate({
      rosterClassId: Number(form.get("rosterClassId")),
      type: String(form.get("type") || "meeting"),
      title: String(form.get("title")),
      date: String(form.get("date")),
      time: String(form.get("time")),
      status: String(form.get("status") || "planned"),
      wholeClass: form.get("wholeClass") === "on",
      description: String(form.get("description") ?? "") || null,
    });
    event.currentTarget.reset();
  }
  function onNote(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    saveNote.mutate({ studentId: Number(form.get("studentId")), text: String(form.get("text")) });
    event.currentTarget.reset();
  }

  return (
    <div className="grid gap-4">
      <PageTitle title={t("mentorship")} />
      <Panel title={t("classes")}>
        <form
          className="flex flex-wrap gap-2"
          onSubmit={(event) => {
            event.preventDefault();
            const form = new FormData(event.currentTarget);
            link.mutate(Number(form.get("rosterClassId")));
          }}
        >
          <Select name="rosterClassId" required>
            {(classes.data?.data ?? []).map((row) => (
              <option key={row.id} value={row.id}>{row.name}</option>
            ))}
          </Select>
          <Button type="submit">{t("create")}</Button>
        </form>
        <ul className="mt-3 text-sm">
          {(linked.data?.data ?? []).map((row) => (
            <li key={row.id}>{row.rosterClass.name}</li>
          ))}
        </ul>
      </Panel>
      <Panel title={t("event")}>
        <form className="grid gap-3 sm:grid-cols-2" onSubmit={onEvent}>
          <Field label={t("classes")}>
            <Select name="rosterClassId" required>
              {(classes.data?.data ?? []).map((row) => (
                <option key={row.id} value={row.id}>{row.name}</option>
              ))}
            </Select>
          </Field>
          <Field label={t("title")}><Input name="title" required /></Field>
          <Field label={t("date")}><Input name="date" type="date" required /></Field>
          <Field label={t("time")}><Input name="time" type="time" required /></Field>
          <Field label={t("type")}><Input name="type" defaultValue="meeting" /></Field>
          <Field label={t("status")}><Input name="status" defaultValue="planned" /></Field>
          <Field label={t("description")}><Textarea name="description" /></Field>
          <label className="flex items-center gap-2 text-sm"><input name="wholeClass" type="checkbox" /> {t("wholeClass")}</label>
          <Button type="submit">{t("save")}</Button>
        </form>
        <ul className="mt-3 text-sm">
          {(events.data?.data ?? []).map((row) => (
            <li key={row.id}>{row.date} {row.time} · {row.title} · {row.status}</li>
          ))}
        </ul>
        {(events.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
      </Panel>
      <Panel title={t("notes")}>
        <form className="grid gap-3" onSubmit={onNote}>
          <Field label={t("students")}>
            <Select name="studentId" required>
              {(students.data?.data ?? []).map((student) => (
                <option key={student.id} value={student.id}>{student.fullName}</option>
              ))}
            </Select>
          </Field>
          <Field label={t("notes")}><Textarea name="text" required /></Field>
          <Button type="submit">{t("save")}</Button>
        </form>
      </Panel>
    </div>
  );
}

export function QuestionsView() {
  const t = useT();
  const list = useQuery({
    queryKey: ["question-bank"],
    queryFn: () => api<{ data: { id: number; prompt: string; type: string }[] }>("/api/question-bank"),
  });
  const save = useSave((body: object) => api("/api/question-bank", { method: "POST", body: JSON.stringify(body) }), ["question-bank"]);
  const remove = useSave((id: number) => api(`/api/question-bank/${id}`, { method: "DELETE" }), ["question-bank"], "deleted");

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const options = String(form.get("options") ?? "")
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean);
    save.mutate({
      prompt: String(form.get("prompt")),
      type: options.length > 0 ? "mcq" : "text",
      options,
      correctOptionIndex: options.length > 0 ? Number(form.get("correct") ?? 0) : null,
    });
    event.currentTarget.reset();
  }

  return (
    <div className="grid gap-4">
      <PageTitle title={t("questions")} />
      <Panel title={t("create")}>
        <form className="grid gap-3" onSubmit={onSubmit}>
          <Field label={t("prompt")}><Textarea name="prompt" required /></Field>
          <Field label={t("options")}><Textarea name="options" placeholder={"A\nB\nC"} /></Field>
          <Field label={t("score")}><Input name="correct" type="number" min={0} defaultValue={0} /></Field>
          <Button type="submit">{t("save")}</Button>
        </form>
      </Panel>
      <ul className="grid gap-2">
        {(list.data?.data ?? []).map((item) => (
          <li key={item.id} className="flex items-start justify-between gap-3 rounded-xl bg-white p-3 text-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:ring-slate-800">
            <span>{item.prompt}</span>
            <Button variant="ghost" onClick={() => remove.mutate(item.id)}>{t("delete")}</Button>
          </li>
        ))}
      </ul>
      {(list.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
    </div>
  );
}
