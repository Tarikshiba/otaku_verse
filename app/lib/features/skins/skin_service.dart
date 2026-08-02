import 'package:supabase_flutter/supabase_flutter.dart';
import 'skin_model.dart';

/// Service pour la collection de skins :
/// lister, debloquer, equiper.
class SkinService {
  final _supabase = Supabase.instance.client;
  String? get _myId => _supabase.auth.currentUser?.id;

  /// Recupere tous les skins + indique lesquels le joueur possede/equipe.
  Future<List<Skin>> tousLesSkins() async {
    // Tous les skins du jeu
    final allSkins = await _supabase
        .from('skins')
        .select()
        .order('unlock_value', ascending: true);

    // Mes skins debloques
    final mesSkins = await _supabase
        .from('player_skins')
        .select('skin_id, equipped')
        .eq('player_id', _myId!);

    // Creer un map rapide de mes skins
    final mesSkinsMap = <String, bool>{};
    for (final ps in List<Map<String, dynamic>>.from(mesSkins)) {
      mesSkinsMap[ps['skin_id']] = ps['equipped'] ?? false;
    }

    return List<Map<String, dynamic>>.from(allSkins).map((json) {
      final skinId = json['id'];
      final owned = mesSkinsMap.containsKey(skinId);
      final equipped = mesSkinsMap[skinId] ?? false;
      return Skin.fromJson(json, owned: owned, equipped: equipped);
    }).toList();
  }

  /// Debloquer un skin (par niveau ou en depensant de l'XP).
  /// Retourne null si OK, ou un message d'erreur.
  Future<String?> debloquer(Skin skin) async {
    if (skin.owned) return 'Tu possedes deja ce skin';

    // Verifier les conditions
    final profil = await _supabase
        .from('profiles')
        .select('niveau, xp_totale')
        .eq('id', _myId!)
        .single();

    final niveau = profil['niveau'] as int;
    final xp = profil['xp_totale'] as int;

    if (skin.unlockType == 'level') {
      if (niveau < skin.unlockValue) {
        return 'Niveau ${skin.unlockValue} requis (tu es Nv.$niveau)';
      }
    } else if (skin.unlockType == 'xp') {
      if (xp < skin.unlockValue) {
        return 'Il te faut ${skin.unlockValue} XP (tu as $xp)';
      }
      // Depenser l'XP
      await _supabase.from('profiles').update({
        'xp_totale': xp - skin.unlockValue,
      }).eq('id', _myId!);
    }

    // Ajouter le skin au joueur
    await _supabase.from('player_skins').insert({
      'player_id': _myId,
      'skin_id': skin.id,
      'equipped': false,
    });

    return null;
  }

  /// Equiper un skin (desequipe l'ancien automatiquement)
  Future<void> equiper(String skinId) async {
    // Desequiper tous mes skins
    await _supabase
        .from('player_skins')
        .update({'equipped': false})
        .eq('player_id', _myId!);

    // Equiper celui-ci
    await _supabase
        .from('player_skins')
        .update({'equipped': true})
        .eq('player_id', _myId!)
        .eq('skin_id', skinId);
  }

  /// Donne le skin gratuit au joueur s'il ne l'a pas encore
  Future<void> donnerSkinGratuit() async {
    final skinGratuit = await _supabase
        .from('skins')
        .select('id')
        .eq('unlock_type', 'free')
        .maybeSingle();

    if (skinGratuit == null) return;

    final dejaObtenu = await _supabase
        .from('player_skins')
        .select('id')
        .eq('player_id', _myId!)
        .eq('skin_id', skinGratuit['id'])
        .maybeSingle();

    if (dejaObtenu != null) return;

    await _supabase.from('player_skins').insert({
      'player_id': _myId,
      'skin_id': skinGratuit['id'],
      'equipped': true,
    });
  }
}
