"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

interface QuestionReport {
  id: string;
  question_id: string;
  work_slug: string;
  question_text: string;
  reason: string;
  comment: string | null;
  status: string;
  created_at: string;
}

export default function ReportsPage() {
  const [reports, setReports] = useState<QuestionReport[]>([]);
  const [filter, setFilter] = useState<string>("open");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const loadReports = async (status: string) => {
    setLoading(true);
    setError("");
    const { data: sessionData } = await supabase.auth.getSession();
    const token = sessionData.session?.access_token;
    if (!token) {
      setError("Connecte-toi d'abord sur la page d'accueil Admin.");
      setLoading(false);
      return;
    }

    const res = await fetch(`/api/reports?status=${encodeURIComponent(status)}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const json = await res.json();
    if (!res.ok) {
      setError(json.error || "Impossible de charger les signalements.");
    } else {
      setReports(json.reports || []);
    }
    setLoading(false);
  };

  const updateStatus = async (id: string, newStatus: string) => {
    const { data: sessionData } = await supabase.auth.getSession();
    const token = sessionData.session?.access_token;
    if (!token) return;
    await fetch("/api/reports", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ id, status: newStatus }),
    });
    loadReports(filter);
  };

  useEffect(() => {
    loadReports(filter);
  }, [filter]);

  return (
    <div className="min-h-screen p-6 max-w-5xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <Link href="/" className="text-xs text-purple-400 hover:underline">
            &larr; Retour Admin
          </Link>
          <h1 className="text-2xl font-bold text-white mt-1">
            SIGNALEMENTS DE QUESTIONS (PHASE B4)
          </h1>
        </div>
        <div className="flex gap-2">
          {["open", "resolved", "dismissed"].map((st) => (
            <button
              key={st}
              onClick={() => setFilter(st)}
              className={`px-3 py-1.5 rounded text-xs font-semibold border ${
                filter === st
                  ? "bg-purple-600 border-purple-400 text-white"
                  : "bg-gray-900 border-gray-700 text-gray-400"
              }`}
            >
              {st.toUpperCase()}
            </button>
          ))}
        </div>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-950 border border-red-700 rounded text-red-300 text-sm">
          {error}
        </div>
      )}

      {loading ? (
        <p className="text-gray-400 text-sm">Chargement des signalements...</p>
      ) : reports.length === 0 ? (
        <p className="text-gray-400 text-sm">Aucun signalement dans cet etat.</p>
      ) : (
        <div className="space-y-3">
          {reports.map((r) => (
            <div
              key={r.id}
              className="bg-gray-900 border border-gray-800 rounded p-4 flex flex-col gap-2"
            >
              <div className="flex items-center justify-between gap-2">
                <span className="text-xs px-2 py-0.5 rounded bg-purple-900/50 text-purple-300 border border-purple-700">
                  {r.work_slug} · {r.question_id}
                </span>
                <span className="text-xs text-amber-400 font-semibold">
                  {r.reason}
                </span>
              </div>
              <p className="text-sm text-white">{r.question_text}</p>
              {r.comment && (
                <p className="text-xs text-gray-300 italic">
                  Commentaire joueur : {r.comment}
                </p>
              )}
              <div className="flex items-center justify-between pt-2 border-t border-gray-800">
                <span className="text-xs text-gray-500">
                  {new Date(r.created_at).toLocaleString("fr-FR")}
                </span>
                <div className="flex gap-2">
                  {r.status !== "resolved" && (
                    <button
                      onClick={() => updateStatus(r.id, "resolved")}
                      className="px-3 py-1 bg-emerald-600 hover:bg-emerald-700 rounded text-xs font-bold"
                    >
                      Marquer resolu
                    </button>
                  )}
                  {r.status !== "dismissed" && (
                    <button
                      onClick={() => updateStatus(r.id, "dismissed")}
                      className="px-3 py-1 bg-gray-700 hover:bg-gray-600 rounded text-xs"
                    >
                      Ignorer
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
