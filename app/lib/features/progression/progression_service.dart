import 'package:supabase_flutter/supabase_flutter.dart';

/// === SERVICE DE PROGRESSION ===
/// Gere l'XP, les niveaux et les rangs du joueur.
/// Les donnees sont stockees dans la table `profiles` de Supabase.

class ProgressionService {
  final _supabase = Supabase.instance.client;

  // --- BAREME XP (voir ROADMAP section 9.2) ---
  static const int xpCombatTermine = 20;
  static const int xpBonneReponse = 10;
  static const int xpBonusKO = 30;
  static const int xpBonusSansDegat = 50;

  /// Calcule l'XP requise pour atteindre le niveau N.
  /// Formule : 100 * N * 1.2
  static int xpRequise(int niveau) {
    return (100 * niveau * 1.2).round();
  }

  /// Calcule le niveau a partir de l'XP totale accumulee.
  /// On monte de niveau quand l'XP totale depasse la somme des paliers.
  static int calculerNiveau(int xpTotale) {
    int niveau = 1;
    int xpAccumulee = 0;
    while (true) {
      final palier = xpRequise(niveau);
      if (xpAccumulee + palier > xpTotale) break;
      xpAccumulee += palier;
      niveau++;
    }
    return niveau;
  }

  /// XP restante dans le niveau actuel (pour la barre de progression)
  static int xpDansNiveauActuel(int xpTotale) {
    int niveau = 1;
    int xpAccumulee = 0;
    while (true) {
      final palier = xpRequise(niveau);
      if (xpAccumulee + palier > xpTotale) break;
      xpAccumulee += palier;
      niveau++;
    }
    return xpTotale - xpAccumulee;
  }

  /// Retourne le rang correspondant au niveau
  static String rang(int niveau) {
    if (niveau <= 5) return 'Debutant';
    if (niveau <= 15) return 'Apprenti Otaku';
    if (niveau <= 30) return 'Passionne';
    if (niveau <= 50) return 'Expert';
    if (niveau <= 75) return 'Maitre du Verse';
    return 'Legende';
  }

  /// Calcule l'XP gagnee a la fin d'un combat.
  /// [bonnesReponses] : nombre de bonnes reponses du joueur
  /// [victoire] : le joueur a-t-il gagne ?
  /// [ko] : victoire par K.O. ?
  /// [sansDegat] : le joueur n'a pris aucun degat ?
  static int calculerXpCombat({
    required int bonnesReponses,
    required bool victoire,
    required bool ko,
    required bool sansDegat,
  }) {
    int xp = xpCombatTermine; // +20 pour avoir termine
    xp += bonnesReponses * xpBonneReponse; // +10 par bonne reponse

    if (victoire && ko) {
      xp += xpBonusKO; // +30 bonus K.O.
    }
    if (victoire && sansDegat) {
      xp += xpBonusSansDegat; // +50 bonus sans degat
    }

    return xp;
  }

  /// Recupere le profil du joueur connecte depuis Supabase.
  /// Retourne null si le profil n'existe pas encore.
  Future<Map<String, dynamic>?> recupererProfil() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final reponse = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return reponse;
  }

  /// Cree le profil si il n'existe pas encore (premier lancement apres inscription)
  Future<void> creerProfilSiAbsent() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final existe = await recupererProfil();
    if (existe != null) return;

    await _supabase.from('profiles').insert({
      'id': userId,
      'xp_totale': 0,
      'niveau': 1,
      'rang': 'Debutant',
      'combats_joues': 0,
      'combats_gagnes': 0,
    });
  }

  /// Met a jour le profil apres un combat (ajoute l'XP, recalcule le niveau/rang)
  Future<Map<String, dynamic>> mettreAJourApresComabat({
    required int xpGagne,
    required bool victoire,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non connecte');

    // Recuperer le profil actuel
    final profil = await recupererProfil();
    if (profil == null) {
      await creerProfilSiAbsent();
      return await mettreAJourApresComabat(xpGagne: xpGagne, victoire: victoire);
    }

    // Calculer les nouvelles valeurs
    final nouvelleXp = (profil['xp_totale'] as int) + xpGagne;
    final nouveauNiveau = calculerNiveau(nouvelleXp);
    final nouveauRang = rang(nouveauNiveau);
    final combatsJoues = (profil['combats_joues'] as int) + 1;
    final combatsGagnes = (profil['combats_gagnes'] as int) + (victoire ? 1 : 0);

    // Mettre a jour dans Supabase
    await _supabase.from('profiles').update({
      'xp_totale': nouvelleXp,
      'niveau': nouveauNiveau,
      'rang': nouveauRang,
      'combats_joues': combatsJoues,
      'combats_gagnes': combatsGagnes,
    }).eq('id', userId);

    return {
      'xp_totale': nouvelleXp,
      'niveau': nouveauNiveau,
      'rang': nouveauRang,
      'combats_joues': combatsJoues,
      'combats_gagnes': combatsGagnes,
      'ancien_niveau': profil['niveau'],
    };
  }
}
