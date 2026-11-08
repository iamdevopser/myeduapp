import { json } from "@/lib/http";

export function GET() {
  return json({ data: { ok: true, service: "myeduapp-web" } });
}
