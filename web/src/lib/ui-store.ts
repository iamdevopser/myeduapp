"use client";

import { create } from "zustand";

export type Locale = "tr" | "en" | "ro" | "ru";
export type ThemeMode = "system" | "light" | "dark";

type Toast = { id: number; tone: "ok" | "err"; text: string };

type UiState = {
  locale: Locale;
  themeMode: ThemeMode;
  navOpen: boolean;
  selectedStudentId: number | null;
  toasts: Toast[];
  setLocale: (locale: Locale) => void;
  setThemeMode: (themeMode: ThemeMode) => void;
  setNavOpen: (open: boolean) => void;
  setSelectedStudentId: (id: number | null) => void;
  push: (tone: Toast["tone"], text: string) => void;
  dismiss: (id: number) => void;
};

let toastId = 1;

export const useUi = create<UiState>((set) => ({
  locale: "tr",
  themeMode: "system",
  navOpen: false,
  selectedStudentId: null,
  toasts: [],
  setLocale: (locale) => set({ locale }),
  setThemeMode: (themeMode) => set({ themeMode }),
  setNavOpen: (navOpen) => set({ navOpen }),
  setSelectedStudentId: (selectedStudentId) => set({ selectedStudentId }),
  push: (tone, text) => {
    const id = toastId++;
    set((state) => ({ toasts: [...state.toasts, { id, tone, text }] }));
    window.setTimeout(() => {
      set((state) => ({ toasts: state.toasts.filter((item) => item.id !== id) }));
    }, 4200);
  },
  dismiss: (id) => set((state) => ({ toasts: state.toasts.filter((item) => item.id !== id) })),
}));
