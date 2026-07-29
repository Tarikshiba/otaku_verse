import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Otaku Verse — Admin",
  description: "Dashboard d'administration Otaku Verse",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="fr" className="h-full antialiased">
      <body className="min-h-full flex flex-col bg-gray-950 text-white">
        {children}
      </body>
    </html>
  );
}
