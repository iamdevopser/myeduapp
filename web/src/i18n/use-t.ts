"use client";

import { messages, type MessageKey } from "@/i18n/messages";
import { useUi } from "@/lib/ui-store";

export function useT() {
  const locale = useUi((state) => state.locale);
  return (key: MessageKey) => messages[locale][key] ?? messages.tr[key];
}
