"use client";

import { useMutation, useQueryClient, type QueryKey } from "@tanstack/react-query";
import { ApiClientError } from "@/lib/api";
import { useUi } from "@/lib/ui-store";
import { useT } from "@/i18n/use-t";

export function useSave<TVars>(
  fn: (vars: TVars) => Promise<unknown>,
  invalidate: QueryKey,
  success: "saved" | "deleted" = "saved",
  also: QueryKey[] = [],
) {
  const push = useUi((state) => state.push);
  const client = useQueryClient();
  const t = useT();
  return useMutation({
    mutationFn: fn,
    onSuccess: async () => {
      push("ok", t(success));
      await Promise.all([invalidate, ...also].map((queryKey) => client.invalidateQueries({ queryKey })));
    },
    onError: (error) => {
      push("err", error instanceof ApiClientError ? error.message : t("errorTitle"));
    },
  });
}
