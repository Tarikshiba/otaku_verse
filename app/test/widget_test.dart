import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_verse/features/economy/economy_v92_service.dart';

void main() {
  test('Courbe XP et rangs officiels V9.2', () {
    expect(EconomyV92Service.calculerNiveau(0), 1);
    expect(EconomyV92Service.calculerNiveau(100), 2);
    expect(EconomyV92Service.titreRangOfficiel(1), 'Novice du Verse');
    expect(EconomyV92Service.titreRangOfficiel(10), 'Apprenti Otaku');
    expect(EconomyV92Service.titreRangOfficiel(76), 'Legende Eternelle ★1');
  });

  test('Frais entree OC et divisions V9.2', () {
    expect(EconomyV92Service.fraisAreneOc(niveau: 5, divisionId: 10, mode: 'division'), 0);
    expect(EconomyV92Service.fraisAreneOc(niveau: 10, divisionId: 10, mode: 'division'), 10);
    expect(EconomyV92Service.fraisAreneOc(niveau: 10, divisionId: 2, mode: 'division'), 50);
    expect(EconomyV92Service.calculerDivision(0), 10);
    expect(EconomyV92Service.calculerDivision(1900), 1);
  });
}
