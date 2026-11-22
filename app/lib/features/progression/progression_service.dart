import 'package:supabase_flutter/supabase_flutter.dart';
import '../economy/economy_v92_service.dart';

/// === SERVICE DE PROGRESSION (ALIGNE V9.2) ===
/// Gere l'XP, les niveaux et les rangs du joueur.
/// Les donnees sont stockees dans la table `profiles` de Supabase.

class ProgressionService {
  final _supabase = Supabase.instance.client;

  // --- BAREME XP V9.2 (§1.2) ---
  static const int xpCombatTermine = 15;
  static const int xpBonneReponse = 3;
  static const int xpBonusKO = 15;
  static const int xpBonusSansDegat = 50;

  /// Cout en XP pour passer au niveau suivant (courbe V9.2 §1.3)
  static int xpRequise(int niveau) => EconomyV92Service.xpPourNiveauSuivant(niveau);

  /// Niveau exact calcule depuis l'XP totale (courbe V9.2 §1.3)
  static int calculerNiveau(int xpTotale) => EconomyV92Service.calculerNiveau(xpTotale);

  /// XP accumulee dans le niveau actuel (pour la barre de progression)
  static int xpDansNiveauActuel(int xpTotale) => EconomyV92Service.xpDansNiveauActuel(xpTotale);

  /// Badge de Rang officiel permanent (Novice du Verse -> Legende Eternelle ★)
  static String rang(int niveau) => EconomyV92Service.titreRangOfficiel(niveau);

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

  /// Cree le profil si il n'existe pas encore (premier lancement apres inscription).
  /// [pseudo] est optionnel : fourni a l'inscription, pas aux lancements suivants.
  Future<void> creerProfilSiAbsent({String? pseudo}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final existe = await recupererProfil();
    if (existe != null) return;

    await _supabase.from('profiles').insert({
      'id': userId,
      'pseudo': pseudo,
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
