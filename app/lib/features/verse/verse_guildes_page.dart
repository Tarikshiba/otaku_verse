import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'verse_v5_service.dart';

/// Écran V5 des Guildes / Clans & Classement Mondial des Clans
class VerseGuildesPage extends StatefulWidget {
  const VerseGuildesPage({super.key});

  @override
  State<VerseGuildesPage> createState() => _VerseGuildesPageState();
}

class _VerseGuildesPageState extends State<VerseGuildesPage> with SingleTickerProviderStateMixin {
  final VerseV5Service _service = VerseV5Service();
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _tagCtrl = TextEditingController();
  final TextEditingController _deviseCtrl = TextEditingController();
  final TextEditingController _chatCtrl = TextEditingController();

  late TabController _tabController;
  bool _loading = true;
  Map<String, dynamic>? _maGuilde;
  List<Map<String, dynamic>> _classementMondial = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final res = await _service.recupererDonneesGuildes();
    if (!mounted) return;
    setState(() {
      _maGuilde = res['maGuilde'] as Map<String, dynamic>?;
      _classementMondial = res['classementMondial'] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomCtrl.dispose();
    _tagCtrl.dispose();
    _deviseCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      appBar: AppBar(
        backgroundColor: OtakuColors.surface,
        elevation: 0,
        title: Text("GUILDES & CLASSEMENT MONDIAL", style: OtakuTypo.headlineSmall.copyWith(fontSize: 15)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: OtakuColors.accent,
          labelColor: OtakuColors.accent,
          unselectedLabelColor: OtakuColors.textMuted,
          tabs: const [
            Tab(text: "MA GUILDE / CRÉER"),
            Tab(text: "CLASSEMENT MONDIAL"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OtakuColors.accent))
          : TabBarView(
              controller: _tabController,
              children: [
                _maGuilde != null ? _buildMaGuildeView() : _buildCreerGuildeView(),
                _buildClassementMondialView(),
              ],
            ),
    );
  }

  Widget _buildMaGuildeView() {
    final g = _maGuilde!;
    final String guildeId = g['id'] as String;
    final Map membresMap = (g['membres'] is Map) ? Map.from(g['membres'] as Map) : {};
    final List<dynamic> messages = (g['messages'] is List) ? g['messages'] as List : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OtakuColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "[${g['tag']}] ${g['nom']}",
                        style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.accent),
                      ),
                      const SizedBox(height: 4),
                      Text(g['devise'] ?? '', style: OtakuTypo.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        "Membres : ${membresMap.length}  |  Score Mondial : ${g['pointsTotaux'] ?? 0} PTS",
                        style: OtakuTypo.bodySmall.copyWith(color: Colors.amber),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await _service.quitterGuilde(guildeId);
                    await _charger();
                  },
                  child: const Text("QUITTER", style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text("SALON DE DISCUSSION DU CLAN", style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            height: 120,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: OtakuColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OtakuColors.glassBorder),
            ),
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i] as Map;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "${m['auteur']} : ${m['texte']}",
                    style: OtakuTypo.bodySmall.copyWith(fontSize: 11),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  style: OtakuTypo.bodySmall,
                  decoration: InputDecoration(
                    hintText: "Envoyer un message à ton clan...",
                    isDense: true,
                    filled: true,
                    fillColor: OtakuColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.accent),
                onPressed: () async {
                  await _service.envoyerMessageGuilde(guildeId, _chatCtrl.text);
                  _chatCtrl.clear();
                  await _charger();
                },
                child: const Text("ENVOYER"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreerGuildeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("FONDER UNE NOUVELLE GUILDE", style: OtakuTypo.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _nomCtrl,
                  style: OtakuTypo.bodySmall,
                  decoration: InputDecoration(
                    hintText: "Nom du Clan (ex: Akatsuki SN)",
                    filled: true,
                    fillColor: OtakuColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _tagCtrl,
                  maxLength: 4,
                  style: OtakuTypo.bodySmall,
                  decoration: InputDecoration(
                    hintText: "TAG (4 max)",
                    counterText: "",
                    filled: true,
                    fillColor: OtakuColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _deviseCtrl,
            style: OtakuTypo.bodySmall,
            decoration: InputDecoration(
              hintText: "Devise de la guilde (optionnel)",
              filled: true,
              fillColor: OtakuColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.accent),
            onPressed: () async {
              try {
                await _service.creerGuilde(
                  nom: _nomCtrl.text,
                  tag: _tagCtrl.text,
                  devise: _deviseCtrl.text,
                );
                await _charger();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                );
              }
            },
            icon: const Icon(Icons.shield_rounded),
            label: const Text("CRÉER LA GUILDE"),
          ),
        ],
      ),
    );
  }

  Widget _buildClassementMondialView() {
    if (_classementMondial.isEmpty) {
      return Center(
        child: Text(
          "Aucune guilde fondée pour l'instant. Sois le premier à créer ton clan !",
          style: OtakuTypo.bodySmall,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _classementMondial.length,
      itemBuilder: (context, index) {
        final g = _classementMondial[index];
        final bool dejaMembre = _maGuilde != null && _maGuilde!['id'] == g['id'];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: OtakuColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: index == 0 ? Colors.amber : OtakuColors.glassBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "#${index + 1}  [${g['tag']}] ${g['nom']}",
                      style: OtakuTypo.headlineSmall.copyWith(fontSize: 14, color: index == 0 ? Colors.amber : Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Chef : ${g['chefPseudo']}  |  ${g['nbMembres']} membres  |  ${g['pointsTotaux']} PTS",
                      style: OtakuTypo.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (!dejaMembre && _maGuilde == null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.accent),
                  onPressed: () async {
                    await _service.rejoindreGuilde(g['id'] as String);
                    await _charger();
                    _tabController.animateTo(0);
                  },
                  child: const Text("REJOINDRE", style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
        );
      },
    );
  }
}
