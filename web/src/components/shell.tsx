"use client";

import {
  Bell,
  BookOpen,
  CalendarDays,
  ClipboardCheck,
  FileText,
  GraduationCap,
  HeartHandshake,
  HelpCircle,
  Home,
  LogOut,
  Megaphone,
  Menu,
  Settings,
  Users,
  X,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { useEffect } from "react";
import { ErrorBoundary } from "@/components/error-boundary";
import { Skeleton } from "@/components/ui";
import { useT } from "@/i18n/use-t";
import type { MessageKey } from "@/i18n/messages";
import { api, roleHome, type SessionUser } from "@/lib/api";
import { useSession } from "@/lib/session-store";
import { useUi } from "@/lib/ui-store";

const icons = {
  home: Home,
  curriculum: BookOpen,
  students: Users,
  grades: GraduationCap,
  plans: CalendarDays,
  mentorship: HeartHandshake,
  questions: HelpCircle,
  settings: Settings,
  announcements: Megaphone,
  documents: FileText,
  attendance: ClipboardCheck,
  schedule: CalendarDays,
  notifications: Bell,
  parents: Users,
  users: Users,
} as const;

const links: Record<SessionUser["role"], MessageKey[]> = {
  teacher: ["home", "curriculum", "students", "grades", "plans", "mentorship", "questions", "documents", "notifications", "settings"],
  student: ["home", "announcements", "documents", "attendance", "grades", "schedule", "notifications", "settings"],
  secretary: ["home", "students", "parents", "attendance", "announcements", "documents", "notifications", "settings"],
  parent: ["home", "announcements", "documents", "attendance", "schedule", "notifications", "settings"],
  admin: ["home", "notifications", "settings"],
};

function hrefFor(role: SessionUser["role"], key: MessageKey) {
  if (key === "home") return roleHome(role);
  if (key === "users") return "/admin";
  return `/${role}/${key}`;
}

export function Shell({ children }: { children: React.ReactNode }) {
  const t = useT();
  const pathname = usePathname();
  const router = useRouter();
  const user = useSession((state) => state.user);
  const ready = useSession((state) => state.ready);
  const refresh = useSession((state) => state.refresh);
  const logout = useSession((state) => state.logout);
  const navOpen = useUi((state) => state.navOpen);
  const setNavOpen = useUi((state) => state.setNavOpen);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  useEffect(() => {
    if (!ready || !user) {
      if (ready) router.replace("/");
      return;
    }
    if (user.mustChangePassword) {
      router.replace("/change-password");
      return;
    }
    const home = roleHome(user.role);
    if (!pathname.startsWith(home) && pathname !== "/notifications") {
      router.replace(home);
    }
  }, [ready, user, pathname, router]);

  const notes = useQuery({
    queryKey: ["notifications", "badge"],
    enabled: Boolean(user) && !user?.mustChangePassword,
    queryFn: () => api<{ unread: number }>("/api/notifications?take=1"),
  });

  if (!ready || !user || user.mustChangePassword) {
    return (
      <div className="grid min-h-screen place-items-center p-6">
        <Skeleton className="h-40 w-full max-w-3xl" />
      </div>
    );
  }

  const items = links[user.role];
  return (
    <div className="min-h-screen md:grid md:grid-cols-[16rem_1fr]">
      <aside className={`${navOpen ? "fixed inset-0 z-30" : "hidden"} bg-navy text-white md:sticky md:top-0 md:block md:h-screen`}>
        <div className="flex h-full flex-col p-4">
          <div className="mb-6 flex items-center justify-between">
            <Link href={roleHome(user.role)} className="text-lg font-semibold">
              {t("appName")}
            </Link>
            <button type="button" className="md:hidden" aria-label={t("close")} onClick={() => setNavOpen(false)}>
              <X />
            </button>
          </div>
          <nav className="grid gap-1" aria-label={t("menu")}>
            {items.map((key) => {
              const Icon = icons[key as keyof typeof icons] ?? Home;
              const href = key === "notifications" ? "/notifications" : hrefFor(user.role, key);
              const active = pathname === href;
              return (
                <Link
                  key={key}
                  href={href}
                  onClick={() => setNavOpen(false)}
                  className={`flex items-center gap-2 rounded-lg px-3 py-2 text-sm ${active ? "bg-brand" : "hover:bg-navy-2"}`}
                  aria-current={active ? "page" : undefined}
                >
                  <Icon size={18} />
                  <span>{t(key)}</span>
                </Link>
              );
            })}
          </nav>
          <div className="mt-auto grid gap-2 pt-6 text-sm">
            <p className="truncate text-slate-300">{user.fullName || user.username}</p>
            <p className="text-slate-400">{t(user.role)}</p>
            <button type="button" onClick={() => void logout()} className="flex items-center gap-2 rounded-lg px-3 py-2 hover:bg-navy-2">
              <LogOut size={18} />
              {t("logout")}
            </button>
          </div>
        </div>
      </aside>
      <div className="min-w-0">
        <header className="sticky top-0 z-20 flex items-center gap-3 border-b border-slate-200 bg-white/90 px-4 py-3 backdrop-blur dark:border-slate-800 dark:bg-slate-950/90">
          <button type="button" className="md:hidden" aria-label={t("openMenu")} onClick={() => setNavOpen(true)}>
            <Menu />
          </button>
          <p className="truncate text-sm text-slate-500">{t(user.role)}</p>
          <Link href="/notifications" className="ml-auto inline-flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1 text-sm dark:bg-slate-800">
            <Bell size={16} />
            <span>{notes.data?.unread ?? 0}</span>
            <span className="sr-only">{t("unread")}</span>
          </Link>
        </header>
        <main className="mx-auto w-full max-w-6xl p-4 pb-16">
          <ErrorBoundary>{children}</ErrorBoundary>
        </main>
        <footer className="px-4 pb-6 text-center text-xs text-slate-400">{t("appName")}</footer>
      </div>
    </div>
  );
}
