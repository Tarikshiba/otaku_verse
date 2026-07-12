import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'combat_models.dart';
import 'combat_service.dart';
import 'combat_page.dart';

/// === ECRAN DE PARAMETRAGE DU COMBAT ===
/// Le joueur choisit l'anime et la difficulte avant de lancer un combat.
/// C'est le "lobby" d'avant-match.

class CombatSetupPage extends StatefulWidget {
  const CombatSetupPage({super.key});

  @override
  State<CombatSetupPage> createState() => _CombatSetupPageState();
}

class _CombatSetupPageState extends State<CombatSetupPage> {
  final CombatService _combatService = CombatService();

  // Anime selectionne (null = toutes categories)
  String? _animeChoisi;

  // Difficulte selectionnee
  String _difficulteChoisie = 'moyen';

  // Liste des animes disponibles (chargee depuis Supabase)
  List<String> _animesDisponibles = [];

  // Etats de chargement
  bool _chargementAnimes = true;
  bool _lancementCombat = false;

  // Les niveaux de difficulte disponibles
  static const List<Map<String, String>> _difficultes = [
    {'id': 'facile', 'label': 'FACILE', 'desc': 'Bot faible — pour s\'echauffer'},
    {'id': 'moyen', 'label': 'MOYEN', 'desc': 'Bot equilibre — 50/50'},
    {'id': 'difficile', 'label': 'DIFFICILE', 'desc': 'Bot redoutable'},
    {'id': 'expert', 'label': 'EXPERT', 'desc': 'Bot quasi-imbattable'},
    {'id': 'adaptatif', 'label': 'ADAPTATIF', 'desc': 'S\'ajuste a ton niveau'},
  ];

  @override
  void initState() {
    super.initState();
    _chargerAnimes();
  }

  /// Charge la liste des animes depuis la base de questions
  Future<void> _chargerAnimes() async {
    try {
      final animes = await _combatService.recupererAnimesDisponibles();
      if (!mounted) return;
      setState(() {
        _animesDisponibles = animes;
        _chargementAnimes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargementAnimes = false);
    }
  }

  /// Lance le combat avec les parametres choisis
  Future<void> _lancerCombat() async {
    setState(() => _lancementCombat = true);

    try {
      final params = CombatParams(
        anime: _animeChoisi,
        difficulte: _difficulteChoisie,
      );

      // Recuperer les questions pour ce combat
      final questions = await _combatService.preparerCombat(params);

      if (!mounted) return;

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune question disponible pour ces parametres')),
        );
        setState(() => _lancementCombat = false);
        return;
      }

      // Naviguer vers l'ecran de combat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CombatPage(
            questions: questions,
            params: params,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }

    if (mounted) setState(() => _lancementCombat = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bouton retour
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: OtakuColors.textSecondary, size: 20),
                    SizedBox(width: 8),
                    Text('RETOUR', style: OtakuTypo.label),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Titre
              const Text('PREPARER LE COMBAT', style: OtakuTypo.headlineLarge),
              const SizedBox(height: 8),
              const Text(
                'Choisis ton terrain et la force de ton adversaire.',
                style: OtakuTypo.bodySmall,
              ),
              const SizedBox(height: 32),

              // --- SECTION ANIME ---
              const Text('ANIME', style: OtakuTypo.label),
              const SizedBox(height: 12),

              if (_chargementAnimes)
                const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                _buildSelectionAnime(),

              const SizedBox(height: 28),

              // --- SECTION DIFFICULTE ---
              const Text('DIFFICULTE', style: OtakuTypo.label),
              const SizedBox(height: 12),
              _buildSelectionDifficulte(),

              const SizedBox(height: 32),

              // --- BOUTON LANCER ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _lancementCombat ? null : _lancerCombat,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: _lancementCombat
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('LANCER LE COMBAT', style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Grille de selection de l'anime
  Widget _buildSelectionAnime() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Option "Toutes categories"
        _buildChipAnime(null, 'TOUS'),
        // Un chip par anime dispo
        ..._animesDisponibles.map(
          (anime) => _buildChipAnime(anime, anime.toUpperCase()),
        ),
      ],
    );
  }

  /// Un chip cliquable pour un anime
  Widget _buildChipAnime(String? anime, String label) {
    final estSelectionne = _animeChoisi == anime;

    return GestureDetector(
      onTap: () => setState(() => _animeChoisi = anime),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: estSelectionne ? OtakuColors.accent : Colors.transparent,
          border: Border.all(
            color: estSelectionne ? OtakuColors.accent : OtakuColors.border,
            width: estSelectionne ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: estSelectionne ? Colors.black : OtakuColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Liste de selection de la difficulte
  Widget _buildSelectionDifficulte() {
    return Column(
      children: _difficultes.map((diff) {
        final estSelectionne = _difficulteChoisie == diff['id'];

        return GestureDetector(
          onTap: () => setState(() => _difficulteChoisie = diff['id']!),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: estSelectionne
                  ? OtakuColors.accent.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border.all(
                color: estSelectionne ? OtakuColors.accent : OtakuColors.border,
                width: estSelectionne ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                // Indicateur de selection (point)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: estSelectionne ? OtakuColors.accent : OtakuColors.textMuted,
                      width: 2,
                    ),
                    color: estSelectionne ? OtakuColors.accent : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 12),
                // Label + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diff['label']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: estSelectionne
                              ? OtakuColors.accent
                              : OtakuColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        diff['desc']!,
                        style: OtakuTypo.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
