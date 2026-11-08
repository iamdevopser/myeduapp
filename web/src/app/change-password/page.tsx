"use client";

import { FormEvent, useEffect, useState } from "react";
import { Button, Field, Input, PageTitle } from "@/components/ui";
import { useT } from "@/i18n/use-t";
import { api } from "@/lib/api";
import { goHome, useSession } from "@/lib/session-store";
import { useUi } from "@/lib/ui-store";

export default function ChangePasswordPage() {
  const t = useT();
  const refresh = useSession((state) => state.refresh);
  const user = useSession((state) => state.user);
  const ready = useSession((state) => state.ready);
  const push = useUi((state) => state.push);
  const [pending, setPending] = useState(false);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  useEffect(() => {
    if (!ready) return;
    if (!user) window.location.assign("/");
    else if (!user.mustChangePassword) goHome(user);
  }, [ready, user]);

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    setPending(true);
    try {
      await api("/api/auth/change-password", {
        method: "POST",
        body: JSON.stringify({
          currentPassword: String(form.get("current") ?? ""),
          newPassword: String(form.get("next") ?? ""),
        }),
      });
      const next = await refresh();
      if (next) goHome({ ...next, mustChangePassword: false });
    } catch (error) {
      push("err", error instanceof Error ? error.message : t("errorTitle"));
    } finally {
      setPending(false);
    }
  }

  return (
    <main className="grid min-h-screen place-items-center p-4">
      <form className="grid w-full max-w-md gap-4 rounded-2xl bg-white p-6 ring-1 ring-slate-200 dark:bg-slate-900" onSubmit={onSubmit}>
        <PageTitle title={t("changePassword")} subtitle={t("passwordHint")} />
        <Field label={t("currentPassword")}>
          <Input name="current" type="password" required autoComplete="current-password" />
        </Field>
        <Field label={t("newPassword")}>
          <Input name="next" type="password" required minLength={8} autoComplete="new-password" />
        </Field>
        <Button type="submit" disabled={pending}>
          {t("save")}
        </Button>
      </form>
    </main>
  );
}
