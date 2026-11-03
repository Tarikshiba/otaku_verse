"use client";

import { useState, useRef, useEffect } from "react";
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
  image_url?: string | null;
  statut: string;
}

export default function QuestionsPage() {
  const [user, setUser] = useState<any>(null);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [chargement, setChargement] = useState(true);
  const [filtre, setFiltre] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [editQuestion, setEditQuestion] = useState<Question | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isUploadingImage, setIsUploadingImage] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const imageInputRef = useRef<HTMLInputElement>(null);

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
    image_url: "",
  });

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (!data.user) {
        window.location.href = "/";
      } else {
        setUser(data.user);
        chargerQuestions();
      }
    });
  }, []);


  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsUploading(true);
    const formData = new FormData();
    formData.append("file", file);

    try {
      const res = await fetch("/api/questions/import", {
        method: "POST",
        body: formData,
      });
      const data = await res.json();
      if (res.ok) {
        alert(`${data.count} questions importees avec succes !`);
        chargerQuestions();
      } else {
        alert(`Erreur: ${data.error}`);
      }
    } catch (err) {
      alert("Erreur reseau lors de l'import.");
    } finally {
      setIsUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  const chargerQuestions = async () => {
    const { data } = await supabase
      .from("questions")
      .select("*")
      .order("created_at", { ascending: false });
    setQuestions(data || []);
    setChargement(false);
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsUploadingImage(true);
    setFormError(null);
    const formData = new FormData();
    formData.append("file", file);

    try {
      const res = await fetch("/api/questions/upload-image", {
        method: "POST",
        body: formData,
      });
      const data = await res.json();
      if (res.ok && data.url) {
        setForm((prev) => ({ ...prev, image_url: data.url }));
      } else {
        setFormError(data.error || "Erreur lors de l'envoi de l'image.");
      }
    } catch (_) {
      setFormError("Erreur reseau lors de l'envoi de l'image.");
    } finally {
      setIsUploadingImage(false);
      if (imageInputRef.current) imageInputRef.current.value = "";
    }
  };

  const sauvegarder = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    const payload: Record<string, any> = {
      ...form,
      id: editQuestion?.id || `Q_${Date.now()}`,
      statut: "actif",
      arc: form.arc || null,
      explication: form.explication || null,
      type: "general",
      isEdit: !!editQuestion,
    };

    if (form.image_url) {
      payload.image_url = form.image_url;
    } else {
      delete payload.image_url;
    }

    const res = await fetch("/api/questions", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const errData = await res.json();
      setFormError(errData.error || "Impossible d'enregistrer la question.");
      return;
    }

    setShowForm(false);
    setEditQuestion(null);
    setForm({
      anime: "", arc: "", difficulte: "moyen", question: "",
      choix_a: "", choix_b: "", choix_c: "", choix_d: "",
      bonne_reponse: "A", explication: "", image_url: "",
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
    setFormError(null);
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
      image_url: q.image_url || "",
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
        <div className="flex gap-2">
          <input 
            type="file" 
            accept=".md" 
            className="hidden" 
            ref={fileInputRef} 
            onChange={handleFileUpload} 
          />
          <button 
            onClick={() => fileInputRef.current?.click()} 
            disabled={isUploading}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded text-sm font-bold flex items-center gap-2"
          >
            {isUploading ? "IMPORTATION..." : "IMPORTER MD"}
          </button>
          <button
            onClick={() => { setShowForm(true); setEditQuestion(null); }}
            className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded text-sm font-bold"
          >
            + AJOUTER
          </button>
        </div>
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
            {/* Champ Image optionnel */}
            <div className="mb-3 p-3 bg-gray-800/60 border border-gray-700 rounded">
              <div className="flex items-center gap-3">
                <input
                  placeholder="URL de l'image (optionnel)"
                  value={form.image_url}
                  onChange={(e) => setForm({ ...form, image_url: e.target.value })}
                  className="flex-1 px-2 py-1 bg-gray-900 border border-gray-700 rounded text-sm"
                />
                <input
                  type="file"
                  accept="image/png,image/jpeg,image/webp,image/gif"
                  className="hidden"
                  ref={imageInputRef}
                  onChange={handleImageUpload}
                />
                <button
                  type="button"
                  onClick={() => imageInputRef.current?.click()}
                  disabled={isUploadingImage}
                  className="px-3 py-1 bg-blue-600 hover:bg-blue-700 rounded text-xs font-bold"
                >
                  {isUploadingImage ? "ENVOI..." : "CHOISIR IMAGE"}
                </button>
                {form.image_url && (
                  <button
                    type="button"
                    onClick={() => setForm({ ...form, image_url: "" })}
                    className="px-2 py-1 bg-red-900/60 hover:bg-red-800 text-red-200 rounded text-xs"
                  >
                    Retirer
                  </button>
                )}
              </div>
              {form.image_url && (
                <div className="mt-2">
                  <img
                    src={form.image_url}
                    alt={`Illustration pour la question : ${form.question || "aperçu"}`}
                    className="max-h-32 rounded border border-gray-700 object-contain"
                  />
                </div>
              )}
            </div>
            {formError && (
              <p className="text-red-400 text-xs mb-3">{formError}</p>
            )}
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
              {q.image_url && (
                <img
                  src={q.image_url}
                  alt={`Illustration de la question ${q.id}`}
                  className="w-12 h-12 rounded object-cover border border-gray-700"
                />
              )}
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
