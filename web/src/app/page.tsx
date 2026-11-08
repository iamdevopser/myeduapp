import type { Metadata } from "next";
import { LoginScreen } from "@/components/login-screen";

export const metadata: Metadata = {
  title: "Giriş",
  description: "MyEduApp giriş ekranı. Öğretmen, öğrenci, sekreter, veli ve yönetici aynı formdan giriş yapar.",
};

export default function LoginPage() {
  return <LoginScreen />;
}
