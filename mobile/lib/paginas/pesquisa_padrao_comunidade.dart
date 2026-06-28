import 'package:flutter/material.dart';

import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class PesquisaPadraoComunidade extends StatefulWidget {
  const PesquisaPadraoComunidade({super.key});

  @override
  State<PesquisaPadraoComunidade> createState() => _PesquisaPadraoComunidadeState();
}

class _PesquisaPadraoComunidadeState extends State<PesquisaPadraoComunidade> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allCommunities = [
    {
      'nome': 'CTG Porteira Aberta',
      'cidade': 'Concórdia, SC',
      'descricao': 'Tradicionalismo, dança gaúcha e culinária típica.',
      'foto': 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?auto=format&fit=crop&w=200&q=80',
      'membros': '1500',
    },
    {
      'nome': 'Clube 25 de Julho',
      'cidade': 'Porto Alegre, RS',
      'descricao': 'Associação cultural com foco em bailes e festas de casais.',
      'foto': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=200&q=80',
      'membros': '2300',
    },
    {
      'nome': 'Associação Recreativa Concórdia',
      'cidade': 'Concórdia, SC',
      'descricao': 'Clube recreativo, esporte, bailes regionais e jantares.',
      'foto': 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=200&q=80',
      'membros': '920',
    },
  ];

  List<Map<String, dynamic>> _filteredCommunities = [];

  @override
  void initState() {
    super.initState();
    _filteredCommunities = List.from(_allCommunities);
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
        _filteredCommunities = List.from(_allCommunities);
      } else {
        _filteredCommunities = _allCommunities.where((community) {
          final String nome = community['nome']!.toLowerCase();
          final String cidade = community['cidade']!.toLowerCase();
          final String descricao = community['descricao']!.toLowerCase();
          return nome.contains(query) || cidade.contains(query) || descricao.contains(query);
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
                              'Comunidades',
                              style: TextStyle(
                                color: BaileSulColors.headerText,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pesquise comunidades cadastradas na plataforma.',
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
                                  hintText: 'Buscar por nome, cidade ou descrição...',
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
                    if (_filteredCommunities.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhuma comunidade encontrada.',
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
                              final community = _filteredCommunities[index];
                              return _buildCommunityCard(community);
                            },
                            childCount: _filteredCommunities.length,
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

  Widget _buildCommunityCard(Map<String, dynamic> community) {
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
            Navigator.pushNamed(context, '/perfil-comunidade');
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Community Image Avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    community['foto']!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.apartment, color: Colors.black26),
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
                        community['nome']!,
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
                            community['cidade']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        community['descricao']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: BaileSulColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Members & Action icon
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      community['membros']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BaileSulColors.headerText,
                      ),
                    ),
                    const Text(
                      'membros',
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
