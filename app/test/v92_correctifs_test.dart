import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_verse/features/core/feature_flags_service.dart';
import 'package:otaku_verse/features/economy/economy_v92_service.dart';
import 'package:otaku_verse/features/quiz/quiz_service.dart';
import 'package:otaku_verse/features/skins/skin_3d_cache_service.dart';
import 'package:otaku_verse/features/skins/skin_service.dart';
import 'package:otaku_verse/shared/rank_badge.dart';

void main() {
  group('Correctifs Terrain V9.2 (Economie, Rangs, 21 Oeuvres & Brassage V4.0)', () {
    test('Titres de rangs officiels avec accents francais exacts', () {
      expect(EconomyV92Service.titreRangOfficiel(1), 'Novice du Verse');
      expect(EconomyV92Service.titreRangOfficiel(5), 'Novice du Verse');
      expect(EconomyV92Service.titreRangOfficiel(6), 'Apprenti Otaku');
      expect(EconomyV92Service.titreRangOfficiel(16), 'Érudit des Arcs');
      expect(EconomyV92Service.titreRangOfficiel(31), "Maître de l'Encre");
      expect(EconomyV92Service.titreRangOfficiel(51), 'Seigneur du Verse');
      expect(EconomyV92Service.titreRangOfficiel(76), 'Légende Éternelle ★1');
      expect(EconomyV92Service.titreRangOfficiel(78), 'Légende Éternelle ★3');
    });

    test('Courbe XP officielle et plancher Niveau 15 exact a 12 300 XP', () {
      expect(EconomyV92Service.calculerNiveau(0), 1);
      expect(EconomyV92Service.calculerNiveau(1499), 5);
      expect(EconomyV92Service.calculerNiveau(1500), 6);
      expect(EconomyV92Service.calculerNiveau(12300), 15);
      expect(EconomyV92Service.calculerNiveau(14100), 16);
    });

    test('Arbitrage frais d arene OC : 0 OC Niv 1-5, Division vs Niveau des Niv 6', () {
      expect(EconomyV92Service.fraisAreneOc(niveau: 3, divisionId: 1, mode: 'division'), 0);
      expect(EconomyV92Service.fraisAreneOc(niveau: 5, divisionId: 10, mode: 'solo'), 0);
      expect(EconomyV92Service.fraisAreneOc(niveau: 6, divisionId: 10, mode: 'division'), 10);
      expect(EconomyV92Service.fraisAreneOc(niveau: 20, divisionId: 7, mode: 'division'), 15);
      expect(EconomyV92Service.fraisAreneOc(niveau: 6, divisionId: 3, mode: 'division'), 30);
      expect(EconomyV92Service.fraisAreneOc(niveau: 6, divisionId: 1, mode: 'division'), 50);
      expect(EconomyV92Service.fraisAreneOc(niveau: 6, divisionId: 1, mode: 'solo'), 15);
      expect(EconomyV92Service.fraisAreneOc(niveau: 16, divisionId: 10, mode: 'solo'), 30);
      expect(EconomyV92Service.fraisAreneOc(niveau: 31, divisionId: 10, mode: 'solo'), 50);
    });

    test('Seuils des 10 Divisions officiels', () {
      expect(EconomyV92Service.divisionsOfficielles.length, 10);
      expect(EconomyV92Service.calculerDivision(0), 10);
      expect(EconomyV92Service.calculerDivision(100), 9);
      expect(EconomyV92Service.calculerDivision(220), 8);
      expect(EconomyV92Service.calculerDivision(370), 7);
      expect(EconomyV92Service.calculerDivision(550), 6);
      expect(EconomyV92Service.calculerDivision(760), 5);
      expect(EconomyV92Service.calculerDivision(1000), 4);
      expect(EconomyV92Service.calculerDivision(1270), 3);
      expect(EconomyV92Service.calculerDivision(1570), 2);
      expect(EconomyV92Service.calculerDivision(1900), 1);
    });

    test('Mapping nom propre des 21 oeuvres (jamais de slug technique)', () {
      expect(EconomyV92Service.catalogueTitresOeuvres.length, 21);
      expect(EconomyV92Service.nomPropreOeuvre('demon_slayer'), 'Demon Slayer');
      expect(EconomyV92Service.nomPropreOeuvre('naruto_shippuden'), 'Naruto Shippuden');
      expect(EconomyV92Service.nomPropreOeuvre('re_zero'), 'Re:Zero');
      expect(EconomyV92Service.nomPropreOeuvre('one_piece'), 'One Piece');
      expect(EconomyV92Service.nomPropreOeuvre('fullmetal_alchemist_brotherhood'), 'Fullmetal Alchemist: Brotherhood');
    });

    test('Double securite melange A/B/C/D conserve les cles d origine serveur', () {
      final q = Question(
        id: 'Q-TEST-1',
        anime: 'One Piece',
        type: '1.1',
        difficulte: 'moyen',
        variantCode: '1.1',
        question: 'Question test ?',
        choixA: 'Rep A',
        choixB: 'Rep B',
        choixC: 'Rep C',
        choixD: 'Rep D',
      );
      final shuffled = q.choixMelanges(Random(42));
      expect(shuffled.length, 4);
      expect(shuffled.map((e) => e.displayLetter).toList(), ['A', 'B', 'C', 'D']);
      expect(shuffled.map((e) => e.originalKey).toSet(), {'A', 'B', 'C', 'D'});
      for (final c in shuffled) {
        if (c.originalKey == 'A') expect(c.text, 'Rep A');
        if (c.originalKey == 'B') expect(c.text, 'Rep B');
        if (c.originalKey == 'C') expect(c.text, 'Rep C');
        if (c.originalKey == 'D') expect(c.text, 'Rep D');
      }
    });

    test('Catalogue 10 personnages originaux et cles propres sans noms copyrightes', () {
      final byKey = {for (final s in SkinService.catalogueOfficiel) s.imageKey: s.name};
      expect(byKey['skin_kio'], 'Kio');
      expect(byKey['skin_mazu'], 'Mazú');
      expect(byKey['skin_tavik'], 'Tavik');
      expect(byKey['skin_ruve'], 'Ruvé');
      expect(byKey['skin_hesk'], 'Hesk');
      expect(byKey['skin_ilka'], 'Ilka');
      expect(byKey['skin_vael'], 'Vael');
      expect(byKey['skin_dakore'], 'Dakoré');
      expect(byKey['skin_ysae'], 'Ysaé');
      expect(byKey['skin_cassio_vey'], 'Cassio Vey');

      final allText = SkinService.catalogueOfficiel.map((s) => '${s.id} ${s.imageKey} ${s.name}').join(' ').toLowerCase();
      expect(allText.contains('ninja'), false);
      expect(allText.contains('pirate'), false);
      expect(allText.contains('samourai'), false);
      expect(allText.contains('hokage'), false);
      expect(allText.contains('titan'), false);
      expect(allText.contains('konoha'), false);
      expect(allText.contains('wano'), false);
    });

    test('Medailles de rang PNG, cadres valides et streaming 3D R2', () {
      expect(OfficialRankBadge.assetPourNiveau(1), 'assets/images/ranks/rank_1_bronze.png');
      expect(OfficialRankBadge.assetPourNiveau(10), 'assets/images/ranks/rank_2_acier.png');
      expect(OfficialRankBadge.assetPourNiveau(25), 'assets/images/ranks/rank_3_argent.png');
      expect(OfficialRankBadge.assetPourNiveau(40), 'assets/images/ranks/rank_4_or.png');
      expect(OfficialRankBadge.assetPourNiveau(60), 'assets/images/ranks/rank_5_platine.png');
      expect(OfficialRankBadge.assetPourNiveau(80), 'assets/images/ranks/rank_6_legende.png');

      expect(SafeAvatarBox.validFrames.length, 4);
      expect(Skin3DCacheService.embeddedAssetSkins, {'skin_kio'});
      expect(Skin3DCacheService.available3DSkins.length, 10);
    });

    test('Controle semver min_app_version (Phase B3) et normalisation cles skins', () {
      expect(FeatureFlagsService.estVersionInferieure('1.0.0', '1.0.0'), false);
      expect(FeatureFlagsService.estVersionInferieure('1.0.0', '1.0.1'), true);
      expect(FeatureFlagsService.estVersionInferieure('1.0.9', '1.1.0'), true);
      expect(FeatureFlagsService.estVersionInferieure('1.2.0', '1.1.5'), false);
      expect(FeatureFlagsService.estVersionInferieure('2.0.0', '1.9.9'), false);

      expect(SkinService.normaliserCle('skin_kio'), 'skin_kio');
      expect(SkinService.normaliserCle('skin_cassio_vey'), 'skin_cassio_vey');
      expect(SkinService.normaliserCle('inconnu'), 'skin_kio');
      expect(SkinService.normaliserCle(null), 'skin_kio');
    });
  });
}
