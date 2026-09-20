import 'package:flutter/material.dart';
import '../../core/theme.dart';

const Map<String, Map<String, List<String>>> _countryData = {
  'Afrique': {
    "Afrique de l'Ouest": ['Sénégal', "Côte d'Ivoire", 'Mali', 'Guinée', 'Burkina Faso', 'Togo', 'Bénin', 'Niger'],
    'Afrique Centrale': ['Cameroun', 'Congo', 'RDC', 'Gabon', 'Tchad', 'Centrafrique'],
    'Afrique du Nord': ['Maroc', 'Algérie', 'Tunisie', 'Égypte', 'Mauritanie'],
    'Est & Sud': ['Madagascar', 'Comores', 'Djibouti', 'Afrique du Sud']
  },
  'Europe': {
    "Europe de l'Ouest": ['France', 'Belgique', 'Suisse', 'Luxembourg', 'Allemagne'],
    'Europe du Sud': ['Espagne', 'Italie', 'Portugal'],
    'Autres': ['Royaume-Uni', 'Russie', 'Pologne']
  },
  'Amériques': {
    'Amérique du Nord': ['Canada', 'États-Unis'],
    'Caraïbes & Sud': ['Haïti', 'Brésil', 'Argentine', 'Mexique', 'Colombie']
  },
  'Asie & Océanie': {
    'Asie': ['Japon', 'Chine', 'Corée du Sud', 'Inde', 'Vietnam'],
    'Océanie': ['Australie', 'Nouvelle-Zélande']
  }
};

Future<String?> showCountrySelector(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _CountrySelectorSheet(),
  );
}

class _CountrySelectorSheet extends StatefulWidget {
  const _CountrySelectorSheet();

  @override
  State<_CountrySelectorSheet> createState() => _CountrySelectorSheetState();
}

class _CountrySelectorSheetState extends State<_CountrySelectorSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<String> get _searchResults {
    final results = <String>[];
    final query = _searchQuery.toLowerCase().trim();
    if (query.isEmpty) return results;

    _countryData.values.forEach((regions) {
      regions.values.forEach((countries) {
        for (var c in countries) {
          if (c.toLowerCase().contains(query)) {
            results.add(c);
          }
        }
      });
    });
    return results..sort();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: OtakuColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: OtakuColors.glassBorder),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: OtakuColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('CHOISIS TON PAYS', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
              const SizedBox(height: 16),
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: OtakuColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un pays...',
                    hintStyle: const TextStyle(color: OtakuColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: OtakuColors.textMuted),
                    filled: true,
                    fillColor: OtakuColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: OtakuColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: OtakuColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: OtakuColors.accent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _searchQuery.isNotEmpty
                    ? _buildSearchResults()
                    : _buildHierarchicalList(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    final results = _searchResults;
    if (results.isEmpty) {
      return Center(child: Text('Aucun pays trouvé', style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final pays = results[index];
        return ListTile(
          title: Text(pays, style: const TextStyle(color: OtakuColors.textPrimary)),
          onTap: () => Navigator.pop(context, pays),
        );
      },
    );
  }

  Widget _buildHierarchicalList(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: _countryData.entries.map((continentEntry) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(continentEntry.key, style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.accent, fontSize: 16)),
            iconColor: OtakuColors.accent,
            collapsedIconColor: OtakuColors.textMuted,
            children: continentEntry.value.entries.map((regionEntry) {
              return ExpansionTile(
                title: Text(regionEntry.key, style: const TextStyle(color: OtakuColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14)),
                children: regionEntry.value.map((pays) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 40),
                    title: Text(pays, style: const TextStyle(color: OtakuColors.textPrimary, fontSize: 14)),
                    onTap: () => Navigator.pop(context, pays),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
