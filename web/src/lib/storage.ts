import { mkdir, readFile, unlink, writeFile } from "fs/promises";
import path from "path";
import { env } from "@/lib/env";
import { ApiError } from "@/lib/http";

const MAX_BYTES = 25 * 1024 * 1024;

export type StoredObject = {
  key: string;
  contentType: string;
  originalName: string;
};

function rootDir(): string {
  return path.resolve(process.cwd(), env().STORAGE_DIR);
}

export function assertStorageKey(key: string): string {
  if (!key || key.includes("..") || key.startsWith("/") || key.startsWith("\\") || path.isAbsolute(key)) {
    throw new ApiError(400, "invalid_key", "Invalid storage key");
  }
  const normalized = key.replaceAll("\\", "/");
  if (!normalized.startsWith("uploads/")) {
    throw new ApiError(400, "invalid_key", "Invalid storage key");
  }
  return normalized;
}

function absolutePath(key: string): string {
  const safe = assertStorageKey(key);
  const full = path.resolve(rootDir(), safe);
  const root = rootDir();
  if (!full.startsWith(root + path.sep) && full !== root) {
    throw new ApiError(400, "invalid_key", "Invalid storage key");
  }
  return full;
}

export async function putObject(input: {
  bytes: Buffer;
  contentType: string;
  originalName: string;
}): Promise<StoredObject> {
  if (input.bytes.byteLength === 0) {
    throw new ApiError(400, "empty_file", "File is empty");
  }
  if (input.bytes.byteLength > MAX_BYTES) {
    throw new ApiError(413, "file_too_large", "File exceeds 25 MB");
  }
  const now = new Date();
  const id = crypto.randomUUID();
  const cleaned = input.originalName.replace(/[^a-zA-Z0-9._-]+/g, "_").slice(0, 80) || "file";
  const key = `uploads/${now.getUTCFullYear()}/${String(now.getUTCMonth() + 1).padStart(2, "0")}/${id}-${cleaned}`;
  const full = absolutePath(key);
  await mkdir(path.dirname(full), { recursive: true });
  await writeFile(full, input.bytes);
  await writeFile(
    `${full}.meta.json`,
    JSON.stringify({ contentType: input.contentType || "application/octet-stream", originalName: cleaned }),
  );
  return { key, contentType: input.contentType || "application/octet-stream", originalName: cleaned };
}

export async function readObject(key: string): Promise<{ bytes: Buffer; contentType: string; originalName: string }> {
  const full = absolutePath(key);
  const bytes = await readFile(full);
  let contentType = "application/octet-stream";
  let originalName = path.basename(key);
  try {
    const meta = JSON.parse(await readFile(`${full}.meta.json`, "utf8")) as {
      contentType?: string;
      originalName?: string;
    };
    if (meta.contentType) contentType = meta.contentType;
    if (meta.originalName) originalName = meta.originalName;
  } catch {
    // The object can still be served without sidecar metadata.
  }
  return { bytes, contentType, originalName };
}

export async function deleteObject(key: string): Promise<void> {
  const full = absolutePath(key);
  await unlink(full).catch(() => undefined);
  await unlink(`${full}.meta.json`).catch(() => undefined);
}
