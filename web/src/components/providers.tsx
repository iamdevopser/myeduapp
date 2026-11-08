"use client";

import { QueryClient, QueryClientProvider, useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { ToastRegion } from "@/components/ui";
import { api } from "@/lib/api";
import { useSession } from "@/lib/session-store";
import { useUi, type Locale, type ThemeMode } from "@/lib/ui-store";

function Appearance() {
  const user = useSession((state) => state.user);
  const setLocale = useUi((state) => state.setLocale);
  const setThemeMode = useUi((state) => state.setThemeMode);
  const themeMode = useUi((state) => state.themeMode);
  const locale = useUi((state) => state.locale);

  useQuery({
    queryKey: ["preferences", user?.id],
    enabled: Boolean(user && !user.mustChangePassword),
    queryFn: async () => {
      const result = await api<{ data: { locale: Locale; themeMode: ThemeMode } }>("/api/settings/preferences");
      setLocale(result.data.locale);
      setThemeMode(result.data.themeMode);
      return result.data;
    },
  });

  useEffect(() => {
    document.documentElement.lang = locale;
    const dark =
      themeMode === "dark" ||
      (themeMode === "system" && window.matchMedia("(prefers-color-scheme: dark)").matches);
    document.documentElement.classList.toggle("dark", dark);
  }, [locale, themeMode]);

  return null;
}

export function Providers({ children }: { children: React.ReactNode }) {
  const [client] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: { retry: 1, staleTime: 10_000, refetchOnWindowFocus: false },
        },
      }),
  );
  return (
    <QueryClientProvider client={client}>
      <Appearance />
      {children}
      <ToastRegion />
    </QueryClientProvider>
  );
}
