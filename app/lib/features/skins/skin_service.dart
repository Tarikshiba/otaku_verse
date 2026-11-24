import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'skin_model.dart';

/// === SERVICE GOODIES (SKINS) V9.2 — PERSONNAGES ORIGINAUX OTAKU VERSE ===
/// - ZERO achat de skin en XP (regle inviolable §1.2)
/// - 1 seul Goodies gratuit de base (Kio) + 1 seul Goodies de depart Tuto a 300 OC (Mazu)
/// - 100% des autres Goodies (Classiques 350-500 VC, Epiques 700-900 VC,
///   Fondateurs Legendaires Soryn & Nyxara 1200-1500 VC) achetes via `shop-tutorial-engine`
class SkinService {
  final _supabase = Supabase.instance.client;
  String? get _myId => _supabase.auth.currentUser?.id;

  /// Catalogue officiel des personnages originaux (noms & cles 100 % originaux sans copyright)
  static const List<Skin> catalogueOfficiel = [
    Skin(
      id: 'skin_kio',
      name: 'Kio',
      role: 'Le Novice du Verse',
      powerName: 'Mémoire Musculaire',
      description: 'Combattant de départ gratuit. Ses fibres musculaires enregistrent les gestes adverses pour les rejouer en combat.',
      rarity: 'commun',
      currency: 'free',
      price: 0,
      imageKey: 'skin_kio',
      accentColor: Color(0xFF6F8499),
      has3DModel: true,
    ),
    Skin(
      id: 'skin_mazu',
      name: 'Mazú',
      role: 'Coursière des Zones Effacées',
      powerName: 'Courrier Intriqué',
      description: '1er Goodies du Tutoriel (300 OC). Ses enveloppes scellées frappent instantanément par intrication quantique.',
      rarity: 'classique',
      currency: 'oc',
      price: 300,
      imageKey: 'skin_mazu',
      accentColor: Color(0xFFFF7A3D),
      has3DModel: true,
      isTutorialStarter: true,
    ),
    Skin(
      id: 'skin_tavik',
      name: 'Tavik',
      role: 'Mécano-Bidouilleur · Radio Vivante',
      powerName: 'Fréquences Mortes',
      description: 'Capte la fréquence exacte d\'une attaque pour l\'annuler. Armé de son énorme clé à molette.',
      rarity: 'classique',
      currency: 'vc',
      price: 350,
      imageKey: 'skin_tavik',
      accentColor: Color(0xFF9BE564),
      has3DModel: true,
    ),
    Skin(
      id: 'skin_ruve',
      name: 'Ruvé',
      role: 'Doyenne des Rescapés',
      powerName: 'Cuisson Lente',
      description: 'Remue le temps avec sa louche de guerre et ralentit ses adversaires dans la vapeur de sa marmite.',
      rarity: 'classique',
      currency: 'vc',
      price: 400,
      imageKey: 'skin_ruve',
      accentColor: Color(0xFFC94A38),
      has3DModel: true,
    ),
    Skin(
      id: 'skin_hesk',
      name: 'Hesk',
      role: 'Tatoueur-Cartographe',
      powerName: 'Cartographie Pliée',
      description: 'Ses tatouages cartographient les mondes effacés : il plie l\'espace en traçant un trait lumineux.',
      rarity: 'classique',
      currency: 'vc',
      price: 450,
      imageKey: 'skin_hesk',
      accentColor: Color(0xFF8B5CF6),
      has3DModel: true,
    ),
    Skin(
      id: 'skin_ilka',
      name: 'Ilka',
      role: 'Héritière des Cinq Ancêtres',
      powerName: 'Lignée Invoquée',
      description: 'Porte cinq guerrières ancêtres en superposition à travers ses reliques dorées.',
      rarity: 'classique',
      currency: 'vc',
      price: 500,
      imageKey: 'skin_ilka',
      accentColor: Color(0xFFE8C97A),
      has3DModel: true,
    ),
    Skin(
      id: 'skin_vael',
      name: 'Vael',
      role: 'Combattant MMA à Moitié Oublié',
      powerName: 'Présence Incertaine',
      description: 'Retenu dans la mémoire des vivants par son ancre, il s\'efface quand on le fixe.',
      rarity: 'epique',
      currency: 'vc',
      price: 700,
      imageKey: 'skin_vael',
      accentColor: Color(0xFF2E8B57),
      has3DModel: true,
    ),
    Skin(
      id: 'skin_dakore',
      name: 'Dakoré',
      role: 'Ancien Champion d\'Arène',
      powerName: 'Partout à la Fois',
      description: 'Présent à plusieurs endroits en même temps, redoutable au corps à corps en costume bordeaux.',
      rarity: 'epique',
      currency: 'vc',
      price: 800,
      imageKey: 'skin_dakore',
      accentColor: Color(0xFFB02E46),
      has3DModel: true,
    ),
    Skin(
      id: 'skin_ysae',
      name: 'Ysaé',
      role: 'Prodige des Arts Martiaux',
      powerName: 'Hostilité Renvoyée',
      description: 'Petit frère d\'Ilka et fils de Cassio Vey. Ses bras-serpents cyan retournent toute hostilité.',
      rarity: 'epique',
      currency: 'vc',
      price: 850,
      imageKey: 'skin_ysae',
      accentColor: Color(0xFF00E5FF),
      has3DModel: true,
    ),
    Skin(
      id: 'skin_cassio_vey',
      name: 'Cassio Vey',
      role: 'Le Dernier Écouteur',
      powerName: 'Somme des Futurs',
      description: 'Père d\'Ilka et d\'Ysaé. Il entend toutes les issues du duel et choisit la voix de la victoire.',
      rarity: 'epique',
      currency: 'vc',
      price: 900,
      imageKey: 'skin_cassio_vey',
      accentColor: Color(0xFFDCE6F2),
      has3DModel: true,
    ),
    Skin(
      id: 'avatar_soryn_ether_watcher',
      name: 'Soryn',
      role: 'Le Veilleur des Âmes Perdues',
      powerName: 'Veille de l\'Éther',
      description: 'Personnage Fondateur Légendaire d\'Otaku Verse (édition signature).',
      rarity: 'legendaire',
      currency: 'vc',
      price: 1200,
      imageKey: 'bot_akina',
      accentColor: Color(0xFF7C4DFF),
      has3DModel: false,
      isFounderLegendary: true,
    ),
    Skin(
      id: 'avatar_nyxara_twin_fangs',
      name: 'Nyxara',
      role: 'La Souveraine des Deux Crocs',
      powerName: 'Crocs Jumeaux',
      description: 'Personnage Fondateur Légendaire aux lames jumelles du Verse.',
      rarity: 'legendaire',
      currency: 'vc',
      price: 1500,
      imageKey: 'avatar_nyxara_twin_fangs',
      accentColor: Color(0xFFFFD700),
      has3DModel: false,
      isFounderLegendary: true,
    ),
  ];

  /// Convertit toute ancienne cle historique Supabase vers les nouvelles cles propres
  static String normaliserCle(String? rawKey) {
    final k = rawKey?.trim() ?? '';
    if (k.isEmpty) return 'skin_kio';
    if (catalogueOfficiel.any((s) => s.imageKey == k || s.id == k)) {
      return catalogueOfficiel.firstWhere((s) => s.imageKey == k || s.id == k).imageKey;
    }
    return 'skin_kio';
  }

  /// Retourne le Skin correspondant a une imageKey (ou Kio par defaut)
  static Skin parImageKey(String imageKey) {
    final clean = normaliserCle(imageKey);
    return catalogueOfficiel.where((s) => s.imageKey == clean).firstOrNull ??
        catalogueOfficiel.first;
  }

  /// Recupere tous les Goodies V9.2 avec leur etat possede / equipe depuis Supabase.
  Future<List<Skin>> tousLesSkins() async {
    final uid = _myId;
    if (uid == null) {
      return catalogueOfficiel
          .map((s) => s.copyWith(owned: s.currency == 'free', equipped: s.currency == 'free'))
          .toList();
    }

    final ownedMap = <String, bool>{};
    try {
      final rows = await _supabase
          .from('player_cosmetics')
          .select('item_id, equipped')
          .eq('user_id', uid)
          .eq('category', 'skin');

      for (final row in List<Map<String, dynamic>>.from(rows)) {
        final itemId = row['item_id']?.toString() ?? '';
        if (itemId.isNotEmpty) {
          ownedMap[itemId] = row['equipped'] == true;
        }
      }
    } catch (_) {}

    // Retrocompatibilite avec d'eventuels skins deja debloques en V1 (player_skins)
    try {
      final legacyRows = await _supabase
          .from('player_skins')
          .select('equipped, skins(image_key)')
          .eq('player_id', uid);

      for (final row in List<Map<String, dynamic>>.from(legacyRows)) {
        final imageKey = (row['skins'] as Map?)?['image_key']?.toString();
        if (imageKey == null) continue;
        final match = catalogueOfficiel.where((s) => s.imageKey == imageKey).firstOrNull;
        if (match != null && !ownedMap.containsKey(match.id)) {
          ownedMap[match.id] = row['equipped'] == true;
        }
      }
    } catch (_) {}

    // Le skin de base gratuit (Kio) est toujours possede
    ownedMap.putIfAbsent('skin_kio', () => false);
    final hasAnyEquipped = ownedMap.values.any((e) => e);
    if (!hasAnyEquipped) {
      ownedMap['skin_kio'] = true;
    }

    return catalogueOfficiel.map((s) {
      final owned = ownedMap.containsKey(s.id);
      final equipped = ownedMap[s.id] == true;
      return s.copyWith(owned: owned, equipped: equipped);
    }).toList();
  }

  /// Acheter / debloquer un Goodies via le serveur (`shop-tutorial-engine`).
  /// Retourne null si OK, sinon un message d'erreur clair.
  Future<String?> debloquer(Skin skin, {bool autoEquip = true}) async {
    if (skin.owned) return 'Tu possedes deja ce Goodies';
    if (skin.currency == 'free') return null;

    try {
      final res = await _supabase.functions.invoke(
        'shop-tutorial-engine',
        body: {
          'action': 'purchase_goodie',
          'item_id': skin.id,
          'auto_equip': autoEquip,
        },
      );
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      if (res.status >= 400 || data['error'] != null) {
        return data['error']?.toString() ?? 'Achat impossible';
      }
      return null;
    } on FunctionException catch (e) {
      final details = e.details is Map ? Map<String, dynamic>.from(e.details as Map) : <String, dynamic>{};
      return details['error']?.toString() ?? 'Achat impossible (${e.status}).';
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Equiper un Goodies possede (met a jour player_cosmetics + profiles.equipped_skin_key)
  Future<void> equiper(String skinId) async {
    final uid = _myId;
    if (uid == null) return;

    try {
      await _supabase
          .from('player_cosmetics')
          .update({'equipped': false})
          .eq('user_id', uid)
          .eq('category', 'skin');

      if (skinId != 'skin_kio') {
        await _supabase
            .from('player_cosmetics')
            .update({'equipped': true})
            .eq('user_id', uid)
            .eq('item_id', skinId);
      }

      final match = catalogueOfficiel.where((s) => s.id == skinId).firstOrNull;
      final imageKey = match?.imageKey ?? 'skin_kio';
      await _supabase
          .from('profiles')
          .update({'equipped_skin_key': imageKey})
          .eq('id', uid);
    } catch (_) {}
  }

  /// Compatibilite ascendante (le skin gratuit de base est garanti dans tousLesSkins)
  Future<void> donnerSkinGratuit() async {}

  /// Retourne le cadre d'avatar equipe (ou cadre VIP si abonne VIP sans autre cadre equipe)
  Future<String?> recupererCadreEquipe({bool isVip = false}) async {
    final uid = _myId;
    if (uid == null) return isVip ? 'cadre_vip_or_violet' : null;
    try {
      final rows = await _supabase
          .from('player_cosmetics')
          .select('item_id, equipped')
          .eq('user_id', uid)
          .eq('category', 'frame');
      final list = List<Map<String, dynamic>>.from(rows);
      final eq = list.where((r) => r['equipped'] == true).firstOrNull;
      if (eq != null && (eq['item_id']?.toString().isNotEmpty ?? false)) {
        return eq['item_id'].toString();
      }
      if (isVip) return 'cadre_vip_or_violet';
      if (list.isNotEmpty) return list.first['item_id']?.toString();
    } catch (_) {}
    return isVip ? 'cadre_vip_or_violet' : null;
  }

  /// Liste les cadres cosmetiques possedes par le joueur
  Future<List<String>> cadresPossedes({bool isVip = false}) async {
    final uid = _myId;
    final res = <String>[];
    if (isVip) res.add('cadre_vip_or_violet');
    if (uid == null) return res;
    try {
      final rows = await _supabase
          .from('player_cosmetics')
          .select('item_id')
          .eq('user_id', uid)
          .eq('category', 'frame');
      for (final r in List<Map<String, dynamic>>.from(rows)) {
        final id = r['item_id']?.toString() ?? '';
        if (id.isNotEmpty && !res.contains(id)) res.add(id);
      }
    } catch (_) {}
    return res;
  }

  /// Equipe un cadre cosmétique possede
  Future<void> equiperCadre(String? frameId) async {
    final uid = _myId;
    if (uid == null) return;
    try {
      await _supabase
          .from('player_cosmetics')
          .update({'equipped': false})
          .eq('user_id', uid)
          .eq('category', 'frame');
      if (frameId != null && frameId != 'cadre_vip_or_violet') {
        await _supabase
            .from('player_cosmetics')
            .update({'equipped': true})
            .eq('user_id', uid)
            .eq('item_id', frameId);
      }
    } catch (_) {}
  }
}
