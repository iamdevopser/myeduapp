export class ApiClientError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
  ) {
    super(message);
  }
}

export type SessionUser = {
  id: number;
  username: string;
  email: string | null;
  fullName: string;
  role: "teacher" | "student" | "secretary" | "parent" | "admin";
  active: boolean;
  domainType: string | null;
  domainId: number | null;
  mustChangePassword: boolean;
};

export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers);
  if (init.body && !(init.body instanceof FormData) && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  const response = await fetch(path, { ...init, headers, credentials: "same-origin" });
  if (response.status === 204) return undefined as T;
  const payload = (await response.json().catch(() => null)) as {
    error?: { code?: string; message?: string };
  } | null;
  if (!response.ok) {
    const code = payload?.error?.code ?? "error";
    const message = payload?.error?.message ?? "Request failed";
    if (
      typeof window !== "undefined" &&
      code === "password_change_required" &&
      window.location.pathname !== "/change-password"
    ) {
      window.location.assign("/change-password");
    }
    throw new ApiClientError(response.status, code, message);
  }
  return payload as T;
}

export function roleHome(role: SessionUser["role"]): string {
  return `/${role}`;
}

export async function uploadFile(file: File): Promise<string> {
  const form = new FormData();
  form.set("file", file);
  const result = await api<{ data: { key: string } }>("/api/files", { method: "POST", body: form });
  return result.data.key;
}
