"use client";

export default function AppError({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <main className="grid min-h-screen place-items-center p-6">
      <section className="max-w-md rounded-2xl bg-white p-6 ring-1 ring-slate-200" role="alert">
        <h1 className="text-xl font-semibold">Bir sorun oluştu</h1>
        <p className="mt-2 text-sm text-slate-600">{error.message}</p>
        <button type="button" className="mt-4 rounded-lg bg-brand px-3 py-2 text-sm text-white" onClick={reset}>
          Yeniden dene
        </button>
      </section>
    </main>
  );
}
