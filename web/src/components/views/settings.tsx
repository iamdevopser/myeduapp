"use client";

import { useQuery } from "@tanstack/react-query";
import { FormEvent } from "react";
import { Button, Empty, Field, Input, PageTitle, Panel, Select } from "@/components/ui";
import { useT } from "@/i18n/use-t";
import { api } from "@/lib/api";
import { useSession } from "@/lib/session-store";
import { useUi, type Locale, type ThemeMode } from "@/lib/ui-store";
import { useSave } from "@/lib/use-save";

export function SettingsView() {
  const t = useT();
  const role = useSession((state) => state.user?.role);
  const locale = useUi((state) => state.locale);
  const themeMode = useUi((state) => state.themeMode);
  const setLocale = useUi((state) => state.setLocale);
  const setThemeMode = useUi((state) => state.setThemeMode);
  const smtp = useQuery({
    queryKey: ["smtp"],
    enabled: role === "teacher",
    queryFn: () =>
      api<{ data: { host: string; port: number; username: string; fromEmail: string; useSsl: boolean; passwordSet: boolean } }>(
        "/api/settings/smtp",
      ),
  });
  const savePrefs = useSave(
    (body: object) => api("/api/settings/preferences", { method: "PATCH", body: JSON.stringify(body) }),
    ["preferences"],
  );
  const saveSmtp = useSave((body: object) => api("/api/settings/smtp", { method: "PATCH", body: JSON.stringify(body) }), ["smtp"]);
  const academicYears = useQuery({
    queryKey: ["academic-years"],
    enabled: role === "teacher",
    queryFn: () => api<{ data: { years: string[] } }>("/api/settings/academic-years"),
  });
  const saveYears = useSave(
    (body: object) => api("/api/settings/academic-years", { method: "PATCH", body: JSON.stringify(body) }),
    ["academic-years"],
  );

  function onPrefs(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const nextLocale = String(form.get("locale")) as Locale;
    const nextTheme = String(form.get("theme")) as ThemeMode;
    setLocale(nextLocale);
    setThemeMode(nextTheme);
    savePrefs.mutate({ locale: nextLocale, themeMode: nextTheme });
  }
  function onSmtp(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const password = String(form.get("password") ?? "");
    saveSmtp.mutate({
      host: String(form.get("host") ?? ""),
      port: Number(form.get("port") ?? 587),
      username: String(form.get("username") ?? ""),
      fromEmail: String(form.get("fromEmail") ?? ""),
      useSsl: form.get("useSsl") === "on",
      password: password || undefined,
    });
  }

  return (
    <div className="grid gap-4">
      <PageTitle title={t("settings")} />
      <Panel title={t("preferences")}>
        <form className="grid gap-3 sm:grid-cols-2" onSubmit={onPrefs}>
          <Field label={t("locale")}>
            <Select name="locale" defaultValue={locale}>
              <option value="tr">Türkçe</option>
              <option value="en">English</option>
              <option value="ro">Română</option>
              <option value="ru">Русский</option>
            </Select>
          </Field>
          <Field label={t("theme")}>
            <Select name="theme" defaultValue={themeMode}>
              <option value="system">{t("system")}</option>
              <option value="light">{t("light")}</option>
              <option value="dark">{t("dark")}</option>
            </Select>
          </Field>
          <Button type="submit">{t("save")}</Button>
        </form>
      </Panel>
      {role === "teacher" && academicYears.data ? (
        <Panel title={t("academicYears")}>
          <p className="mb-3 text-sm text-slate-500">{t("academicYearsHint")}</p>
          <form
            className="grid gap-3"
            onSubmit={(event) => {
              event.preventDefault();
              const form = new FormData(event.currentTarget);
              const years = String(form.get("years") ?? "")
                .split(/\r?\n/)
                .map((line) => line.trim())
                .filter(Boolean);
              saveYears.mutate({ years });
            }}
          >
            <Field label={t("academicYear")}>
              <textarea
                name="years"
                className="min-h-28 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950"
                defaultValue={academicYears.data.data.years.join("\n")}
              />
            </Field>
            <Button type="submit">{t("save")}</Button>
          </form>
        </Panel>
      ) : null}
      {role === "teacher" && smtp.data ? (
        <Panel title={t("smtp")}>
          <form className="grid gap-3 sm:grid-cols-2" onSubmit={onSmtp}>
            <Field label={t("host")}><Input name="host" defaultValue={smtp.data.data.host} required /></Field>
            <Field label={t("port")}><Input name="port" type="number" defaultValue={smtp.data.data.port} required /></Field>
            <Field label={t("username")}><Input name="username" defaultValue={smtp.data.data.username} required /></Field>
            <Field label={t("fromEmail")}><Input name="fromEmail" type="email" defaultValue={smtp.data.data.fromEmail} required /></Field>
            <Field label={t("password")}>
              <Input name="password" type="password" autoComplete="new-password" placeholder={smtp.data.data.passwordSet ? t("passwordSet") : ""} />
            </Field>
            <label className="flex items-center gap-2 text-sm">
              <input name="useSsl" type="checkbox" defaultChecked={smtp.data.data.useSsl} /> {t("useSsl")}
            </label>
            <Button type="submit">{t("save")}</Button>
          </form>
        </Panel>
      ) : null}
    </div>
  );
}

export function AdminView() {
  const t = useT();
  const list = useQuery({
    queryKey: ["accounts"],
    queryFn: () =>
      api<{ data: { id: number; username: string; fullName: string; role: "teacher" | "secretary" | "admin" | "student" | "parent"; active: boolean; email: string | null }[] }>(
        "/api/accounts?take=200",
      ),
  });
  const save = useSave((body: object) => api("/api/accounts", { method: "POST", body: JSON.stringify(body) }), ["accounts"]);
  const update = useSave(
    (input: { id: number; active: boolean }) =>
      api(`/api/accounts/${input.id}`, { method: "PATCH", body: JSON.stringify({ active: input.active }) }),
    ["accounts"],
  );

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    save.mutate({
      username: String(form.get("username")),
      password: String(form.get("password")),
      fullName: String(form.get("fullName")),
      email: String(form.get("email") ?? "") || null,
      role: String(form.get("role")),
      mustChangePassword: true,
    });
    event.currentTarget.reset();
  }

  return (
    <div className="grid gap-4">
      <PageTitle title={t("users")} />
      <Panel title={t("staffCreate")}>
        <form className="grid gap-3 sm:grid-cols-2" onSubmit={onSubmit}>
          <Field label={t("fullName")}><Input name="fullName" required /></Field>
          <Field label={t("username")}><Input name="username" required minLength={3} /></Field>
          <Field label={t("email")}><Input name="email" type="email" /></Field>
          <Field label={t("password")}><Input name="password" type="password" required minLength={8} /></Field>
          <Field label={t("role")}>
            <Select name="role" defaultValue="teacher">
              <option value="teacher">{t("teacher")}</option>
              <option value="secretary">{t("secretary")}</option>
            </Select>
          </Field>
          <div className="self-end"><Button type="submit">{t("create")}</Button></div>
        </form>
        <p className="mt-2 text-xs text-slate-500">{t("mustChange")}</p>
      </Panel>
      <Panel title={t("users")}>
        <ul className="grid gap-2">
          {(list.data?.data ?? []).map((account) => (
            <li key={account.id} className="flex flex-wrap items-center justify-between gap-2 rounded-lg bg-slate-50 px-3 py-2 text-sm dark:bg-slate-800">
              <span>
                {account.fullName || account.username} · {t(account.role)} · {account.active ? t("active") : "—"}
              </span>
              <Button variant="soft" onClick={() => update.mutate({ id: account.id, active: !account.active })}>
                {account.active ? t("close") : t("active")}
              </Button>
            </li>
          ))}
        </ul>
      </Panel>
    </div>
  );
}

export function NotificationsView() {
  const t = useT();
  const list = useQuery({
    queryKey: ["notifications"],
    queryFn: () =>
      api<{ data: { id: number; title: string; body: string; status: string; createdAt: string }[] }>("/api/notifications?take=50"),
  });
  const read = useSave((id: number) => api(`/api/notifications/${id}/read`, { method: "POST" }), ["notifications"]);
  return (
    <div className="grid gap-4">
      <PageTitle title={t("notifications")} />
      {(list.data?.data ?? []).map((item) => (
        <article key={item.id} className="rounded-2xl bg-white p-4 ring-1 ring-slate-200 dark:bg-slate-900 dark:ring-slate-800">
          <div className="flex items-start justify-between gap-3">
            <h2 className="font-semibold">{item.title}</h2>
            <time className="text-xs text-slate-500">{new Date(item.createdAt).toLocaleString()}</time>
          </div>
          {item.body ? <p className="mt-2 text-sm text-slate-600">{item.body}</p> : null}
          {item.status === "unread" ? (
            <Button className="mt-3" variant="soft" onClick={() => read.mutate(item.id)}>
              {t("markRead")}
            </Button>
          ) : null}
        </article>
      ))}
      {(list.data?.data.length ?? 0) === 0 ? <Empty text={t("empty")} /> : null}
    </div>
  );
}
