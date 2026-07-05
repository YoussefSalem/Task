import type { Metadata } from "next";
import "./globals.css";
import { AdminDataProvider } from "@/components/admin-data-provider";
import { AppPreferencesProvider } from "@/components/app-preferences-provider";
import { AuthProvider } from "@/components/auth-provider";
import { SettingsProvider } from "@/components/settings-provider";

export const metadata: Metadata = {
  title: "Task — Operations Console",
  description: "Command center for Task home services marketplace",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className="dark" suppressHydrationWarning>
      <body>
        <AuthProvider>
          <AppPreferencesProvider>
            <SettingsProvider>
              <AdminDataProvider>{children}</AdminDataProvider>
            </SettingsProvider>
          </AppPreferencesProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
