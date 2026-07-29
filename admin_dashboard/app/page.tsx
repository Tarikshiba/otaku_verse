"use client";

import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase";
import Link from "next/link";

// Seuls ces emails peuvent acceder au dashboard
const ADMINS = ["drx@otaku.admin", "heat@otaku.admin"];

export default function AdminHome() {
  const [user, setUser] = useState<any>(null);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [erreur, setErreur] = useState("");
  const [chargement, setChargement] = useState(true);

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      setUser(data.user);
      setChargement(false);
    });
  }, []);

  const login = async (e: React.FormEvent) => {
    e.preventDefault();
    setErreur("");

    // Verifier que l'email est dans la liste des admins
    if (!ADMINS.includes(email.toLowerCase())) {
      setErreur("Acces refuse. Ce compte n'est pas administrateur.");
      return;
    }

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) {
      setErreur(error.message);
    } else {
      setUser(data.user);
    }
  };

  const logout = async () => {
    await supabase.auth.signOut();
    setUser(null);
  };

  if (chargement) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <p className="text-gray-400">Chargement...</p>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <form
          onSubmit={login}
          className="bg-gray-900 border border-gray-800 p-8 rounded w-96"
        >
          <h1 className="text-xl font-bold mb-2 text-purple-400">
            OTAKU VERSE — ADMIN
          </h1>
          <p className="text-sm text-gray-400 mb-6">
            Acces reserve a Tariq et Heat.
          </p>

          {erreur && (
            <p className="text-red-400 text-sm mb-4">{erreur}</p>
          )}

          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full mb-3 px-3 py-2 bg-gray-800 border border-gray-700 rounded text-sm focus:border-purple-500 focus:outline-none"
          />
          <input
            type="password"
            placeholder="Mot de passe"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full mb-4 px-3 py-2 bg-gray-800 border border-gray-700 rounded text-sm focus:border-purple-500 focus:outline-none"
          />
          <button
            type="submit"
            className="w-full py-2 bg-purple-600 hover:bg-purple-700 text-white font-bold rounded text-sm"
          >
            CONNEXION
          </button>
        </form>
      </div>
    );
  }

  return (
    <div className="min-h-screen">
      <header className="bg-gray-900 border-b border-gray-800 px-6 py-4 flex items-center justify-between">
        <h1 className="text-lg font-bold text-purple-400">
          OTAKU VERSE — ADMIN
        </h1>
        <div className="flex items-center gap-4">
          <span className="text-sm text-gray-400">{user.email}</span>
          <button
            onClick={logout}
            className="text-sm text-red-400 hover:text-red-300"
          >
            Deconnexion
          </button>
        </div>
      </header>

      <div className="p-6">
        <div className="grid grid-cols-2 gap-4 max-w-2xl mx-auto">
          <Link
            href="/questions"
            className="bg-gray-900 border border-gray-800 hover:border-purple-500 rounded p-6 transition"
          >
            <h2 className="text-lg font-bold text-purple-400 mb-2">
              QUESTIONS
            </h2>
            <p className="text-sm text-gray-400">
              Ajouter, modifier, desactiver des questions de quiz.
            </p>
          </Link>

          <Link
            href="/users"
            className="bg-gray-900 border border-gray-800 hover:border-purple-500 rounded p-6 transition"
          >
            <h2 className="text-lg font-bold text-purple-400 mb-2">
              UTILISATEURS
            </h2>
            <p className="text-sm text-gray-400">
              Voir les joueurs, niveaux, stats de combat.
            </p>
          </Link>
        </div>
      </div>
    </div>
  );
}
