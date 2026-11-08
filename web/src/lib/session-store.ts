"use client";

import { create } from "zustand";
import { api, roleHome, type SessionUser } from "@/lib/api";

type SessionState = {
  user: SessionUser | null;
  ready: boolean;
  refresh: () => Promise<SessionUser | null>;
  setUser: (user: SessionUser | null) => void;
  logout: () => Promise<void>;
};

export const useSession = create<SessionState>((set) => ({
  user: null,
  ready: false,
  setUser: (user) => set({ user, ready: true }),
  refresh: async () => {
    try {
      const result = await api<{ data: SessionUser }>("/api/auth/session");
      set({ user: result.data, ready: true });
      return result.data;
    } catch {
      set({ user: null, ready: true });
      return null;
    }
  },
  logout: async () => {
    await api("/api/auth/logout", { method: "POST" }).catch(() => undefined);
    set({ user: null, ready: true });
    window.location.assign("/");
  },
}));

export function goHome(user: SessionUser) {
  window.location.assign(user.mustChangePassword ? "/change-password" : roleHome(user.role));
}
