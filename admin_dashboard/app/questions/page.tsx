"use client";

import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import Link from "next/link";

interface Question {
  id: string;
  anime: string;
  arc: string | null;
  difficulte: string;
  question: string;
  choix_a: string;
  choix_b: string;
  choix_c: string;
  choix_d: string;
  bonne_reponse: string;
  explication: string | null;
  statut: string;
}

export default function QuestionsPage() {
  const [questions, setQuestions] = useState<Question[]>([]);
  const [chargement, setChargement] = useState(true);
  const [filtre, setFiltre] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [editQuestion, setEditQuestion] = useState<Question | null>(null);

  // Formulaire
  const [form, setForm] = useState({
    anime: "",
    arc: "",
    difficulte: "moyen",
    question: "",
    choix_a: "",
    choix_b: "",
    choix_c: "",
    choix_d: "",
    bonne_reponse: "A",
    explication: "",
  });

  useEffect(() => {
    chargerQuestions();
  }, []);

  const chargerQuestions = async () => {
    const { data } = await supabase
      .from("questions")
      .select("*")
      .order("created_at", { ascending: false });
    setQuestions(data || []);
    setChargement(false);
  };

  const sauvegarder = async (e: React.FormEvent) => {
    e.preventDefault();
    const payload = {
      ...form,
      id: editQuestion?.id || `Q_${Date.now()}`,
      statut: "actif",
      arc: form.arc || null,
      explication: form.explication || null,
      type: "general",
      isEdit: !!editQuestion,
    };

    await fetch("/api/questions", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    setShowForm(false);
    setEditQuestion(null);
    setForm({
      anime: "", arc: "", difficulte: "moyen", question: "",
      choix_a: "", choix_b: "", choix_c: "", choix_d: "",
      bonne_reponse: "A", explication: "",
    });
    chargerQuestions();
  };

  const toggleStatut = async (q: Question) => {
    const nouveauStatut = q.statut === "actif" ? "inactif" : "actif";
    await fetch("/api/questions", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: q.id, statut: nouveauStatut }),
    });
    chargerQuestions();
  };

  const editer = (q: Question) => {
    setEditQuestion(q);
    setForm({
      anime: q.anime,
      arc: q.arc || "",
      difficulte: q.difficulte,
      question: q.question,
      choix_a: q.choix_a,
      choix_b: q.choix_b,
      choix_c: q.choix_c,
      choix_d: q.choix_d,
      bonne_reponse: q.bonne_reponse,
      explication: q.explication || "",
    });
    setShowForm(true);
  };

  const questionsFiltrees = questions.filter(
    (q) =>
      q.question.toLowerCase().includes(filtre.toLowerCase()) ||
      q.anime.toLowerCase().includes(filtre.toLowerCase())
  );

  if (chargement) {
    return <div className="flex items-center justify-center min-h-screen"><p className="text-gray-400">Chargement...</p></div>;
  }

  return (
    <div className="min-h-screen">
      <header className="bg-gray-900 border-b border-gray-800 px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Link href="/" className="text-gray-400 hover:text-white text-sm">← Retour</Link>
          <h1 className="text-lg font-bold text-purple-400">QUESTIONS ({questions.length})</h1>
        </div>
        <button
          onClick={() => { setShowForm(true); setEditQuestion(null); }}
          className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded text-sm font-bold"
        >
          + AJOUTER
        </button>
      </header>

      <div className="p-6">
        {/* Barre de recherche */}
        <input
          type="text"
          placeholder="Rechercher (question ou anime)..."
          value={filtre}
          onChange={(e) => setFiltre(e.target.value)}
          className="w-full max-w-md mb-4 px-3 py-2 bg-gray-900 border border-gray-700 rounded text-sm focus:border-purple-500 focus:outline-none"
        />

        {/* Formulaire ajout/modif */}
        {showForm && (
          <form onSubmit={sauvegarder} className="bg-gray-900 border border-gray-800 rounded p-4 mb-6 max-w-3xl">
            <h3 className="font-bold text-purple-400 mb-3">
              {editQuestion ? "MODIFIER" : "NOUVELLE QUESTION"}
            </h3>
            <div className="grid grid-cols-3 gap-3 mb-3">
              <input placeholder="Anime" value={form.anime} onChange={(e) => setForm({ ...form, anime: e.target.value })} className="px-2 py-1 bg-gray-800 border border-gray-700 rounded text-sm" required />
              <input placeholder="Arc (optionnel)" value={form.arc} onChange={(e) => setForm({ ...form, arc: e.target.value })} className="px-2 py-1 bg-gray-800 border border-gray-700 rounded text-sm" />
              <select value={form.difficulte} onChange={(e) => setForm({ ...form, difficulte: e.target.value })} className="px-2 py-1 bg-gray-800 border border-gray-700 rounded text-sm">
                <option value="facile">Facile</option>
                <option value="moyen">Moyen</option>
                <option value="difficile">Difficile</option>
                <option value="expert">Expert</option>
              </select>
            </div>
            <input placeholder="Question" value={form.question} onChange={(e) => setForm({ ...form, question: e.target.value })} className="w-full mb-3 px-2 py-1 bg-gray-800 border border-gray-700 rounded text-sm" required />
            <div className="grid grid-cols-2 gap-3 mb-3">
              <input placeholder="Choix A" value={form.choix_a} onChange={(e) => setForm({ ...form, choix_a: e.target.value })} className="px-2 py-1 bg-gray-800 border border-gray-700 rounded text-sm" required />
              <input placeholder="Choix B" value={form.choix_b} onChange={(e) => setForm({ ...form, choix_b: e.target.value })} className="px-2 py-1 bg-gray-800 border border-gray-700 rounded text-sm" required />
              <input placeholder="Choix C" value={form.choix_c} onChange={(e) => setForm({ ...form, choix_c: e.target.value })} className="px-2 py-1 bg-gray-800 border border-gray-700 rounded text-sm" required />
              <input placeholder="Choix D" value={form.choix_d} onChange={(e) => setForm({ ...form, choix_d: e.target.value })} className="px-2 py-1 bg-gray-800 border border-gray-700 rounded text-sm" required />
            </div>
            <div className="flex gap-3 mb-3">
              <select value={form.bonne_reponse} onChange={(e) => setForm({ ...form, bonne_reponse: e.target.value })} className="px-2 py-1 bg-gray-800 border border-gray-700 rounded text-sm">
                <option value="A">Bonne reponse : A</option>
                <option value="B">Bonne reponse : B</option>
                <option value="C">Bonne reponse : C</option>
                <option value="D">Bonne reponse : D</option>
              </select>
              <input placeholder="Explication (optionnel)" value={form.explication} onChange={(e) => setForm({ ...form, explication: e.target.value })} className="flex-1 px-2 py-1 bg-gray-800 border border-gray-700 rounded text-sm" />
            </div>
            <div className="flex gap-2">
              <button type="submit" className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded text-sm font-bold">SAUVEGARDER</button>
              <button type="button" onClick={() => { setShowForm(false); setEditQuestion(null); }} className="px-4 py-2 bg-gray-700 rounded text-sm">ANNULER</button>
            </div>
          </form>
        )}

        {/* Liste des questions */}
        <div className="space-y-2">
          {questionsFiltrees.map((q) => (
            <div key={q.id} className={`bg-gray-900 border rounded p-3 flex items-center gap-3 ${q.statut === "inactif" ? "border-red-900 opacity-60" : "border-gray-800"}`}>
              <div className="flex-1">
                <p className="text-sm font-medium">{q.question}</p>
                <p className="text-xs text-gray-400 mt-1">
                  {q.anime} · {q.difficulte} · Reponse: {q.bonne_reponse}
                  {q.statut === "inactif" && <span className="text-red-400 ml-2">INACTIF</span>}
                </p>
              </div>
              <button onClick={() => editer(q)} className="text-xs text-purple-400 hover:text-purple-300">Editer</button>
              <button onClick={() => toggleStatut(q)} className={`text-xs ${q.statut === "actif" ? "text-red-400" : "text-green-400"}`}>
                {q.statut === "actif" ? "Desactiver" : "Activer"}
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
