import Link from "next/link";

export default function NotFound() {
  return (
    <main className="grid min-h-screen place-items-center p-6">
      <section className="text-center">
        <h1 className="text-2xl font-semibold">Sayfa bulunamadı</h1>
        <Link href="/" className="mt-4 inline-block text-brand">
          Girişe dön
        </Link>
      </section>
    </main>
  );
}
