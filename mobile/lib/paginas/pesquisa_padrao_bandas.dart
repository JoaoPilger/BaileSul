import 'package:flutter/material.dart';

import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class PesquisaPadraoBandas extends StatefulWidget {
  const PesquisaPadraoBandas({super.key});

  @override
  State<PesquisaPadraoBandas> createState() => _PesquisaPadraoBandasState();
}

class _PesquisaPadraoBandasState extends State<PesquisaPadraoBandas> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allBands = [
    {
      'nome': 'Banda exemplo',
      'cidade': 'Florianópolis, SC',
      'generos': 'Sertanejo, pop',
      'foto': 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?auto=format&fit=crop&w=200&q=80',
      'seguidores': '1250',
    },
    {
      'nome': 'Gaudérios do Sul',
      'cidade': 'Porto Alegre, RS',
      'generos': 'Tradicionalista, Gaúcha',
      'foto': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=200&q=80',
      'seguidores': '3400',
    },
    {
      'nome': 'Vanera Nova',
      'cidade': 'Caxias do Sul, RS',
      'generos': 'Vanera, Sertanejo',
      'foto': 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=200&q=80',
      'seguidores': '870',
    },
    {
      'nome': 'Rock da Fronteira',
      'cidade': 'Uruguaiana, RS',
      'generos': 'Rock, Pop Rock',
      'foto': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=200&q=80',
      'seguidores': '2100',
    },
  ];

  List<Map<String, dynamic>> _filteredBands = [];

  @override
  void initState() {
    super.initState();
    _filteredBands = List.from(_allBands);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final String query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredBands = List.from(_allBands);
      } else {
        _filteredBands = _allBands.where((band) {
          final String nome = band['nome']!.toLowerCase();
          final String cidade = band['cidade']!.toLowerCase();
          final String generos = band['generos']!.toLowerCase();
          return nome.contains(query) || cidade.contains(query) || generos.contains(query);
        }).toList();
      }
    });
  }

  void _showMenu() {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaileSulColors.dark,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MobileHeader(onMenuPressed: _showMenu),
            Expanded(
              child: Container(
                color: BaileSulColors.pageBackground,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Search Header Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Banda',
                              style: TextStyle(
                                color: BaileSulColors.headerText,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pesquise bandas cadastradas na plataforma.',
                              style: TextStyle(
                                color: BaileSulColors.mutedText,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Search bar input
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: BaileSulColors.cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por nome, cidade ou estilo...',
                                  hintStyle: TextStyle(
                                    color: BaileSulColors.mutedText.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: BaileSulColors.accent,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 20),
                                          onPressed: () => _searchController.clear(),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Results List
                    if (_filteredBands.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.music_off_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhuma banda encontrada.',
                                  style: TextStyle(
                                    color: BaileSulColors.mutedText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final band = _filteredBands[index];
                              return _buildBandCard(band);
                            },
                            childCount: _filteredBands.length,
                          ),
                        ),
                      ),

                    // Space before footer
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),

                    // Footer
                    const SliverToBoxAdapter(
                      child: MobileFooter(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBandCard(Map<String, dynamic> band) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BaileSulColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // For now, all bands navigate to the mock high-fidelity profile page
            Navigator.pushNamed(context, '/perfil-banda');
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Band Image Avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    band['foto']!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.music_note, color: Colors.black26),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),

                // Info Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        band['nome']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: BaileSulColors.headerText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            band['cidade']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: BaileSulColors.pageBackground.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          band['generos']!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: BaileSulColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Followers & Action icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      band['seguidores']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BaileSulColors.headerText,
                      ),
                    ),
                    const Text(
                      'seguidores',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
