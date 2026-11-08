import { createHash, randomBytes, timingSafeEqual } from "crypto";
import { argon2id } from "hash-wasm";

const MEMORY = 19456;
const ITERATIONS = 2;
const PARALLELISM = 1;
const HASH_LENGTH = 32;

export async function hashPassword(plain: string): Promise<string> {
  const salt = randomBytes(16);
  const hash = await argon2id({
    password: plain,
    salt,
    parallelism: PARALLELISM,
    iterations: ITERATIONS,
    memorySize: MEMORY,
    hashLength: HASH_LENGTH,
    outputType: "hex",
  });
  return `argon2id$${salt.toString("hex")}$${hash}`;
}

/** Desktop app stored unsalted SHA-256 of each code point masked to one byte. */
export function legacySha256(plain: string): string {
  const bytes: number[] = [];
  for (const ch of plain) {
    bytes.push((ch.codePointAt(0) ?? 0) & 0xff);
  }
  return createHash("sha256").update(Buffer.from(bytes)).digest("hex");
}

export async function verifyPassword(
  plain: string,
  stored: string,
): Promise<{ ok: boolean; rehash: boolean }> {
  if (stored.startsWith("argon2id$")) {
    const parts = stored.split("$");
    const saltHex = parts[1];
    const hashHex = parts[2];
    if (!saltHex || !hashHex) return { ok: false, rehash: false };
    const hash = await argon2id({
      password: plain,
      salt: Buffer.from(saltHex, "hex"),
      parallelism: PARALLELISM,
      iterations: ITERATIONS,
      memorySize: MEMORY,
      hashLength: HASH_LENGTH,
      outputType: "hex",
    });
    const actual = Buffer.from(hash, "hex");
    const expected = Buffer.from(hashHex, "hex");
    if (actual.length !== expected.length) return { ok: false, rehash: false };
    return { ok: timingSafeEqual(actual, expected), rehash: false };
  }
  const legacy = legacySha256(plain);
  const actual = Buffer.from(legacy);
  const expected = Buffer.from(stored);
  if (actual.length !== expected.length) return { ok: false, rehash: false };
  const ok = timingSafeEqual(actual, expected);
  return { ok, rehash: ok };
}
