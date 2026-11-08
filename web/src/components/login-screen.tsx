"use client";

import { useQuery } from "@tanstack/react-query";
import { FormEvent, useEffect, useState } from "react";
import { useT } from "@/i18n/use-t";
import { api } from "@/lib/api";
import { goHome, useSession } from "@/lib/session-store";
import { useUi, type Locale } from "@/lib/ui-store";
import { Button, Field, Input } from "@/components/ui";

export function LoginScreen() {
  const t = useT();
  const refresh = useSession((state) => state.refresh);
  const ready = useSession((state) => state.ready);
  const user = useSession((state) => state.user);
  const setUser = useSession((state) => state.setUser);
  const push = useUi((state) => state.push);
  const locale = useUi((state) => state.locale);
  const setLocale = useUi((state) => state.setLocale);
  const [pending, setPending] = useState(false);
  const status = useQuery({
    queryKey: ["auth-status"],
    queryFn: () => api<{ data: { hasAdmin: boolean } }>("/api/auth/status"),
  });

  useEffect(() => {
    void refresh();
  }, [refresh]);

  useEffect(() => {
    if (ready && user) goHome(user);
  }, [ready, user]);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const hasAdmin = status.data?.data.hasAdmin !== false;
    setPending(true);
    try {
      const path = hasAdmin ? "/api/auth/login" : "/api/auth/bootstrap";
      const body = hasAdmin
        ? { login: String(form.get("login") ?? ""), password: String(form.get("password") ?? "") }
        : {
            username: String(form.get("login") ?? ""),
            password: String(form.get("password") ?? ""),
            fullName: String(form.get("fullName") ?? ""),
            email: String(form.get("email") ?? "") || null,
          };
      const result = await api<{ data: NonNullable<typeof user> }>(path, {
        method: "POST",
        body: JSON.stringify(body),
      });
      setUser(result.data);
      goHome(result.data);
    } catch (error) {
      push("err", error instanceof Error ? error.message : t("errorTitle"));
    } finally {
      setPending(false);
    }
  }

  const first = status.data?.data.hasAdmin === false;
  return (
    <main className="grid min-h-screen lg:grid-cols-2">
      <section className="hidden bg-navy p-12 text-white lg:flex lg:flex-col lg:justify-between">
        <p className="text-lg font-semibold">{t("appName")}</p>
        <div>
          <h1 className="max-w-md text-4xl font-semibold leading-tight">{t("heroTitle")}</h1>
          <p className="mt-4 max-w-md text-slate-300">{t("heroBody")}</p>
        </div>
        <p className="text-sm text-slate-400">MyEduApp</p>
      </section>
      <section className="grid place-items-center p-4">
        <div className="w-full max-w-md">
          <div className="mb-6 flex items-center justify-between">
            <p className="text-lg font-semibold lg:hidden">{t("appName")}</p>
            <label className="ml-auto text-sm">
              <span className="sr-only">{t("locale")}</span>
              <select
                className="rounded-lg border border-slate-300 bg-white px-2 py-1 dark:border-slate-700 dark:bg-slate-950"
                value={locale}
                onChange={(event) => setLocale(event.target.value as Locale)}
              >
                <option value="tr">Türkçe</option>
                <option value="en">English</option>
                <option value="ro">Română</option>
                <option value="ru">Русский</option>
              </select>
            </label>
          </div>
          <h2 className="text-2xl font-semibold">{first ? t("firstAdmin") : t("loginTitle")}</h2>
          <p className="mt-2 text-sm text-slate-500">{t("loginLead")}</p>
          <form className="mt-6 grid gap-4" onSubmit={onSubmit}>
            {first ? (
              <>
                <Field label={t("fullName")}>
                  <Input name="fullName" required autoComplete="name" />
                </Field>
                <Field label={t("email")}>
                  <Input name="email" type="email" autoComplete="email" />
                </Field>
              </>
            ) : null}
            <Field label={t("username")}>
              <Input name="login" required autoComplete="username" />
            </Field>
            <Field label={t("password")}>
              <Input name="password" type="password" required minLength={first ? 8 : 1} autoComplete={first ? "new-password" : "current-password"} />
            </Field>
            {first ? <p className="text-xs text-slate-500">{t("passwordHint")}</p> : null}
            <Button type="submit" disabled={pending || status.isLoading}>
              {first ? t("createAdmin") : t("signIn")}
            </Button>
          </form>
        </div>
      </section>
    </main>
  );
}
