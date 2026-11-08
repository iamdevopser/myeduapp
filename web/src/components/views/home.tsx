"use client";

import { useQuery } from "@tanstack/react-query";
import { Empty, PageTitle, Panel, Skeleton } from "@/components/ui";
import { useT } from "@/i18n/use-t";
import { api } from "@/lib/api";
import { useSession } from "@/lib/session-store";

export function HomeView() {
  const t = useT();
  const user = useSession((state) => state.user);
  const role = user?.role;
  const activities = useQuery({
    queryKey: ["activities"],
    enabled: role === "teacher",
    queryFn: () => api<{ data: { id: number; title: string; type: string; createdAt: string }[] }>("/api/activities"),
  });
  const students = useQuery({
    queryKey: ["students"],
    enabled: role === "secretary" || role === "parent" || role === "teacher",
    queryFn: () => api<{ data: { id: number; fullName: string; number: number }[] }>("/api/students"),
  });
  const parents = useQuery({
    queryKey: ["parents"],
    enabled: role === "secretary",
    queryFn: () => api<{ data: { id: number }[] }>("/api/parents"),
  });
  const accounts = useQuery({
    queryKey: ["accounts"],
    enabled: role === "admin",
    queryFn: () => api<{ total: number; data: { role: string; active: boolean }[] }>("/api/accounts?take=200"),
  });
  const notes = useQuery({
    queryKey: ["notifications", "home"],
    enabled: Boolean(role),
    queryFn: () => api<{ unread: number }>("/api/notifications?take=1"),
  });

  if (!user) return <Skeleton />;
  return (
    <div className="grid gap-4">
      <PageTitle title={`${t("welcome")}, ${user.fullName || user.username}`} subtitle={t(user.role)} />
      <div className="grid gap-4 sm:grid-cols-3">
        <Panel title={t("notifications")}>
          <p className="text-3xl font-semibold">{notes.data?.unread ?? 0}</p>
          <p className="text-sm text-slate-500">{t("unread")}</p>
        </Panel>
        {role === "secretary" || role === "teacher" || role === "parent" ? (
          <Panel title={t("students")}>
            <p className="text-3xl font-semibold">{students.data?.data.length ?? "–"}</p>
          </Panel>
        ) : null}
        {role === "secretary" ? (
          <Panel title={t("parents")}>
            <p className="text-3xl font-semibold">{parents.data?.data.length ?? "–"}</p>
          </Panel>
        ) : null}
        {role === "admin" ? (
          <Panel title={t("users")}>
            <p className="text-3xl font-semibold">{accounts.data?.total ?? "–"}</p>
          </Panel>
        ) : null}
      </div>
      {role === "teacher" ? (
        <Panel title={t("activities")}>
          {activities.isLoading ? <Skeleton className="h-16" /> : null}
          {(activities.data?.data.length ?? 0) === 0 && !activities.isLoading ? <Empty text={t("empty")} /> : null}
          <ul className="grid gap-2">
            {activities.data?.data.map((item) => (
              <li key={item.id} className="flex items-center justify-between gap-3 text-sm">
                <span>{item.title}</span>
                <time className="text-slate-500">{new Date(item.createdAt).toLocaleString()}</time>
              </li>
            ))}
          </ul>
        </Panel>
      ) : null}
      {role === "parent" ? (
        <Panel title={t("child")}>
          {(students.data?.data.length ?? 0) === 0 ? <Empty text={t("noChildren")} /> : null}
          <ul className="grid gap-2">
            {students.data?.data.map((student) => (
              <li key={student.id} className="rounded-lg bg-slate-50 px-3 py-2 text-sm dark:bg-slate-800">
                {student.number} · {student.fullName}
              </li>
            ))}
          </ul>
        </Panel>
      ) : null}
    </div>
  );
}
