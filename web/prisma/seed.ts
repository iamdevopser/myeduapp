import { readFileSync } from "fs";
import path from "path";
import { BehaviorKind, PrismaClient } from "@prisma/client";
import { hashPassword } from "../src/lib/password";

function loadDotEnv() {
  try {
    const text = readFileSync(path.join(process.cwd(), ".env"), "utf8");
    for (const line of text.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) continue;
      const eq = trimmed.indexOf("=");
      if (eq <= 0) continue;
      const key = trimmed.slice(0, eq).trim();
      let value = trimmed.slice(eq + 1).trim();
      if ((value.startsWith("\"") && value.endsWith("\"")) || (value.startsWith("'") && value.endsWith("'"))) {
        value = value.slice(1, -1);
      }
      if (process.env[key] == null) process.env[key] = value;
    }
  } catch {
    // Prisma CLI also injects variables from .env when seeding through it.
  }
}

loadDotEnv();

const prisma = new PrismaClient();

const behaviors: { code: string; name: string; kind: BehaviorKind; order: number }[] = [
  { code: "active_participation", name: "Aktif katılım", kind: "positive", order: 1 },
  { code: "taking_responsibility", name: "Sorumluluk alma", kind: "positive", order: 2 },
  { code: "cooperation", name: "İş birliği", kind: "positive", order: 3 },
  { code: "helping_peer", name: "Arkadaşına yardımcı olma", kind: "positive", order: 4 },
  { code: "respectful_communication", name: "Saygılı iletişim", kind: "positive", order: 5 },
  { code: "following_rules", name: "Kurallara uyma", kind: "positive", order: 6 },
  { code: "talking_in_class", name: "Derste konuşma", kind: "needs_improvement", order: 7 },
  { code: "disrupting_lesson", name: "Dersi bölme", kind: "needs_improvement", order: 8 },
  { code: "being_late", name: "Geç kalma", kind: "needs_improvement", order: 9 },
  { code: "distracting", name: "Dikkat dağıtma", kind: "needs_improvement", order: 10 },
  { code: "not_doing_homework", name: "Ödevini yapmama", kind: "needs_improvement", order: 11 },
  { code: "breaking_rules", name: "Kurallara uymama", kind: "needs_improvement", order: 12 },
];

const periods: { period: number; start: string; end: string }[] = [
  { period: 1, start: "08:00", end: "08:45" },
  { period: 2, start: "08:50", end: "09:35" },
  { period: 3, start: "09:40", end: "10:25" },
  { period: 4, start: "10:30", end: "11:15" },
  { period: 5, start: "11:20", end: "12:05" },
  { period: 6, start: "13:00", end: "13:45" },
  { period: 7, start: "13:50", end: "14:35" },
  { period: 8, start: "14:40", end: "15:25" },
];

async function main() {
  for (const behavior of behaviors) {
    await prisma.behaviorDefinition.upsert({
      where: { code: behavior.code },
      create: behavior,
      update: { name: behavior.name, kind: behavior.kind, order: behavior.order },
    });
  }
  for (const slot of periods) {
    await prisma.periodSlot.upsert({
      where: { period: slot.period },
      create: slot,
      update: { start: slot.start, end: slot.end },
    });
  }

  const username = process.env.BOOTSTRAP_ADMIN_USERNAME?.trim() ?? "";
  const password = process.env.BOOTSTRAP_ADMIN_PASSWORD ?? "";
  if (username && password.length >= 8) {
    const existing = await prisma.account.count({ where: { role: "admin", active: true } });
    if (existing === 0) {
      await prisma.account.create({
        data: {
          username,
          email: process.env.BOOTSTRAP_ADMIN_EMAIL?.trim() || null,
          fullName: process.env.BOOTSTRAP_ADMIN_NAME?.trim() || "Yönetici",
          role: "admin",
          passwordHash: await hashPassword(password),
          mustChangePassword: false,
          preference: { create: {} },
        },
      });
    }
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
