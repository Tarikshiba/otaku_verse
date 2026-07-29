"use client";

import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import Link from "next/link";

interface Profil {
  id: string;
  xp_totale: number;
  niveau: number;
  rang: string;
  combats_joues: number;
  combats_gagnes: number;
  created_at: string;
}

export default function UsersPage() {
  const [profils, setProfils] = useState<Profil[]>([]);
  const [chargement, setChargement] = useState(true);

  useEffect(() => {
    chargerProfils();
  }, []);

  const chargerProfils = async () => {
    const { data } = await supabase
      .from("profiles")
      .select("*")
      .order("xp_totale", { ascending: false });
    setProfils(data || []);
    setChargement(false);
  };

  if (chargement) {
    return <div className="flex items-center justify-center min-h-screen"><p className="text-gray-400">Chargement...</p></div>;
  }

  return (
    <div className="min-h-screen">
      <header className="bg-gray-900 border-b border-gray-800 px-6 py-4 flex items-center gap-4">
        <Link href="/" className="text-gray-400 hover:text-white text-sm">← Retour</Link>
        <h1 className="text-lg font-bold text-purple-400">UTILISATEURS ({profils.length})</h1>
      </header>

      <div className="p-6">
        <table className="w-full max-w-4xl">
          <thead>
            <tr className="text-left text-xs text-gray-400 border-b border-gray-800">
              <th className="pb-2 pr-4">ID</th>
              <th className="pb-2 pr-4">NIVEAU</th>
              <th className="pb-2 pr-4">RANG</th>
              <th className="pb-2 pr-4">XP</th>
              <th className="pb-2 pr-4">COMBATS</th>
              <th className="pb-2 pr-4">VICTOIRES</th>
              <th className="pb-2">TAUX</th>
            </tr>
          </thead>
          <tbody>
            {profils.map((p) => {
              const taux = p.combats_joues > 0 ? Math.round((p.combats_gagnes / p.combats_joues) * 100) : 0;
              return (
                <tr key={p.id} className="border-b border-gray-800/50 text-sm">
                  <td className="py-2 pr-4 text-xs text-gray-500 font-mono">{p.id.substring(0, 8)}...</td>
                  <td className="py-2 pr-4 font-bold text-purple-400">{p.niveau}</td>
                  <td className="py-2 pr-4">{p.rang}</td>
                  <td className="py-2 pr-4">{p.xp_totale}</td>
                  <td className="py-2 pr-4">{p.combats_joues}</td>
                  <td className="py-2 pr-4">{p.combats_gagnes}</td>
                  <td className="py-2">{taux}%</td>
                </tr>
              );
            })}
          </tbody>
        </table>

        {profils.length === 0 && (
          <p className="text-gray-400 text-sm mt-4">Aucun utilisateur inscrit.</p>
        )}
      </div>
    </div>
  );
}
