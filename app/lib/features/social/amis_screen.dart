import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/textures.dart';
import 'friend_model.dart';
import 'friends_service.dart';
import 'profil_public_page.dart';
import 'recherche_joueur_dialog.dart';

/// Ecran Amis — version connectee a Supabase.
/// Affiche 4 onglets : Tous, En ligne, En combat, Demandes.
class AmisScreen extends StatefulWidget {
  const AmisScreen({super.key});

  @override
  State<AmisScreen> createState() => _AmisScreenState();
}

class _AmisScreenState extends State<AmisScreen> {
  final _friendsService = FriendsService();

  // Donnees chargees depuis Supabase
  List<Friend> _amis = [];
  List<FriendRequest> _demandes = [];
  bool _chargement = true;

  // Onglet actif : 0 = Tous, 1 = En ligne, 2 = En combat, 3 = Demandes
  int _tabActive = 0;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  /// Charge la liste d'amis + les demandes en attente
  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    try {
      final amis = await _friendsService.mesAmis();
      final demandes = await _friendsService.demandesRecues();
      if (mounted) {
        setState(() {
          _amis = amis;
          _demandes = demandes;
          _chargement = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  /// Amis filtres selon l'onglet actif
  List<Friend> get _amisFiltres {
    switch (_tabActive) {
      case 0: // Tous les amis
        return _amis;
      case 1: // En ligne (pas en combat)
        return _amis.where((a) => a.estEnLigne && !a.isInCombat).toList();
      case 2: // En combat
        return _amis.where((a) => a.isInCombat).toList();
      default:
        return [];
    }
  }

  /// Compteurs pour chaque onglet
  int get _countTous => _amis.length;
  int get _countEnLigne => _amis.where((a) => a.estEnLigne && !a.isInCombat).length;
  int get _countEnCombat => _amis.where((a) => a.isInCombat).length;
  int get _countDemandes => _demandes.length;

  /// Ouvre la recherche de joueurs
  void _ouvrirRecherche() {
    showDialog(
      context: context,
      builder: (_) => RechercheJoueurDialog(
        onDemandeEnvoyee: _chargerDonnees,
      ),
    );
  }

  /// Accepter une demande
  Future<void> _accepter(FriendRequest demande) async {
    await _friendsService.accepterDemande(demande.id);
    _chargerDonnees();
  }

  /// Refuser une demande
  Future<void> _refuser(FriendRequest demande) async {
    await _friendsService.refuserDemande(demande.id);
    _chargerDonnees();
  }

  @override
  Widget build(BuildContext context) {
    return SectionTexture(
      type: TextureType.bulles,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 12),

              // Tabs de filtrage
              _buildTabs(),
              const SizedBox(height: 12),

              // Contenu
              Expanded(child: _buildContenu()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('AMIS', style: OtakuTypo.headlineLarge.copyWith(fontSize: 22)),
        const SizedBox(width: 12),
        // Compteur total d'amis
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: OtakuColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${_amis.length}',
            style: OtakuTypo.hud.copyWith(fontSize: 12, color: OtakuColors.accent),
          ),
        ),
        const Spacer(),
        // Bouton ajouter
        GestureDetector(
          onTap: _ouvrirRecherche,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: OtakuColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add_rounded, size: 16, color: OtakuColors.accent),
                const SizedBox(width: 6),
                Text('AJOUTER', style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.accent)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabChip('Tous', _countTous, OtakuColors.textPrimary, _tabActive == 0, () => setState(() => _tabActive = 0)),
          const SizedBox(width: 8),
          _buildTabChip('En ligne', _countEnLigne, OtakuColors.pvHaut, _tabActive == 1, () => setState(() => _tabActive = 1)),
          const SizedBox(width: 8),
          _buildTabChip('En combat', _countEnCombat, OtakuColors.modeDuel, _tabActive == 2, () => setState(() => _tabActive = 2)),
          const SizedBox(width: 8),
          _buildTabChip('Demandes', _countDemandes, OtakuColors.accent, _tabActive == 3, () => setState(() => _tabActive = 3)),
        ],
      ),
    );
  }

  Widget _buildContenu() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: OtakuColors.accent));
    }

    // Onglet Demandes
    if (_tabActive == 3) {
      if (_demandes.isEmpty) {
        return Center(
          child: Text('Aucune demande en attente', style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)),
        );
      }
      return ListView.separated(
        itemCount: _demandes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildDemandeCard(_demandes[i]),
      );
    }

    // Onglets amis (tous / en ligne / en combat)
    final liste = _amisFiltres;
    if (liste.isEmpty) {
      final messages = {
        0: 'Aucun ami pour le moment',
        1: 'Aucun ami en ligne',
        2: 'Aucun ami en combat',
      };
      return Center(
        child: Text(messages[_tabActive] ?? '', style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)),
      );
    }

    return ListView.separated(
      itemCount: liste.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildAmiCard(liste[i]),
    );
  }

  Widget _buildTabChip(String label, int count, Color couleur, bool actif, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: actif ? couleur.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: actif ? couleur.withValues(alpha: 0.5) : OtakuColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: OtakuTypo.label.copyWith(fontSize: 10, color: actif ? couleur : OtakuColors.textMuted)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('$count', style: OtakuTypo.hud.copyWith(fontSize: 10, color: couleur)),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre le profil public d'un joueur
  void _ouvrirProfil(String userId, String pseudo, int niveau, String rang) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilPublicPage(
          userId: userId,
          pseudo: pseudo,
          niveau: niveau,
          rang: rang,
        ),
      ),
    );
  }

  Widget _buildAmiCard(Friend ami) {
    final couleur = ami.isInCombat
        ? OtakuColors.modeDuel
        : ami.estEnLigne
            ? OtakuColors.pvHaut
            : OtakuColors.textMuted;

    return GestureDetector(
      onTap: () => _ouvrirProfil(ami.userId, ami.pseudo, ami.niveau, ami.rang),
      child: LiquidGlass(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Indicateur statut
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: couleur,
              boxShadow: [BoxShadow(color: couleur.withValues(alpha: 0.5), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: couleur.withValues(alpha: 0.5), width: 1.5),
              color: OtakuColors.surface,
            ),
            child: Icon(Icons.person, size: 18, color: couleur.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ami.pseudo, style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
                Text('Nv.${ami.niveau} · ${ami.rang}', style: OtakuTypo.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
          // Badge statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ami.statut,
              style: OtakuTypo.label.copyWith(fontSize: 9, color: couleur),
            ),
          ),
          // Icone defier (seulement si pas en combat)
          if (!ami.isInCombat) ...[
            const SizedBox(width: 10),
            Icon(Icons.sports_mma_rounded, size: 18, color: OtakuColors.modeDuel.withValues(alpha: 0.6)),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildDemandeCard(FriendRequest demande) {
    return GestureDetector(
      onTap: () => _ouvrirProfil(demande.senderId, demande.pseudo, demande.niveau, demande.rang),
      child: LiquidGlass(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.5), width: 1.5),
              color: OtakuColors.surface,
            ),
            child: Icon(Icons.person, size: 18, color: OtakuColors.accent.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(demande.pseudo, style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
                Text('Nv.${demande.niveau} · ${demande.rang}', style: OtakuTypo.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
          // Bouton accepter
          GestureDetector(
            onTap: () => _accepter(demande),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: OtakuColors.pvHaut.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: OtakuColors.pvHaut.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.check_rounded, size: 16, color: OtakuColors.pvHaut),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton refuser
          GestureDetector(
            onTap: () => _refuser(demande),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: OtakuColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: OtakuColors.error.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: OtakuColors.error),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
