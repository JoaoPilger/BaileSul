import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';
import 'perfil_comunidade.dart';

/// Rota: `/pesquisa-comunidades`
class PesquisaPadraoComunidade extends StatefulWidget {
  const PesquisaPadraoComunidade({super.key});

  @override
  State<PesquisaPadraoComunidade> createState() => _PesquisaPadraoComunidadeState();
}

class _PesquisaPadraoComunidadeState extends State<PesquisaPadraoComunidade> {
  final TextEditingController _searchController = TextEditingController();

  List<ComunidadeApi> _todasComunidades = <ComunidadeApi>[];
  List<ComunidadeApi> _comunidadesFiltradas = <ComunidadeApi>[];
  List<String> _sugestoes = <String>[];
  bool _carregando = true;
  String? _erro;
  String _cidadeSelecionada = '';

  List<String> get _cidadesDisponiveis {
    final Set<String> cidades = _todasComunidades
        .map((c) => c.cidade)
        .where((c) => c.isNotEmpty)
        .toSet();
    final List<String> lista = cidades.toList()..sort();
    return lista;
  }

  @override
  void initState() {
    super.initState();
    _carregarComunidades();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarComunidades() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/comunidades');
      final http.Response response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> dados = _extrairLista(decoded);
        final List<ComunidadeApi> comunidades = dados
            .whereType<Map>()
            .map((Map<dynamic, dynamic> item) =>
                ComunidadeApi.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (!mounted) return;
        setState(() {
          _todasComunidades = comunidades;
          _aplicarFiltros();
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = 'Erro ao buscar comunidades (${response.statusCode}).';
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Não foi possível conectar ao servidor.';
        _carregando = false;
      });
    }
  }

  List<dynamic> _extrairLista(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final dynamic dados =
          decoded['dados'] ?? decoded['comunidades'] ?? decoded['data'] ?? decoded['rows'];
      if (dados is List) return dados;
    }
    return <dynamic>[];
  }

  void _onSearchChanged() {
    final String query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _sugestoes = <String>[];
      } else {
        _sugestoes = _todasComunidades
            .where((ComunidadeApi c) => c.nomeEntidade.toLowerCase().contains(query))
            .take(8)
            .map((ComunidadeApi c) => c.nomeEntidade)
            .toList();
      }
      _aplicarFiltros();
    });
  }

  void _selecionarSugestao(String texto) {
    _searchController.removeListener(_onSearchChanged);
    _searchController.text = texto;
    _searchController.selection = TextSelection.collapsed(offset: texto.length);
    _searchController.addListener(_onSearchChanged);
    setState(() {
      _sugestoes = <String>[];
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    final String query = _searchController.text.toLowerCase().trim();
    _comunidadesFiltradas = _todasComunidades.where((ComunidadeApi comunidade) {
      final bool matchBusca = query.isEmpty ||
          comunidade.nomeEntidade.toLowerCase().contains(query) ||
          comunidade.cidade.toLowerCase().contains(query) ||
          comunidade.estado.toLowerCase().contains(query) ||
          comunidade.descricao.toLowerCase().contains(query);
      final bool matchCidade =
          _cidadeSelecionada.isEmpty || comunidade.cidade == _cidadeSelecionada;
      return matchBusca && matchCidade;
    }).toList();
  }

  void _onCidadeChanged(String? cidade) {
    setState(() {
      _cidadeSelecionada = cidade ?? '';
      _aplicarFiltros();
    });
  }

  void _showMenu() {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  void _abrirPerfil(ComunidadeApi comunidade) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PerfilComunidadePage(comunidadeId: comunidade.usuarioId),
      ),
    );
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
                    // Hero escuro — espelha .listing-hero de listings.module.css
                    // (comunidades.jsx): título + subtítulo sobre fundo em gradiente.
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Color(0xFF0D2535), BaileSulColors.dark],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Explore comunidades locais',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Descubra as melhores comunidades de dança da sua região.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Cabeçalho da seção + busca + filtros
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Comunidades Disponíveis',
                                        style: TextStyle(
                                          color: BaileSulColors.headerText,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'Encontre a comunidade perfeita para você.',
                                        style: TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: BaileSulColors.accent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_comunidadesFiltradas.length} comunidade${_comunidadesFiltradas.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      color: BaileSulColors.accent,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Search bar input + sugestões
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                      hintText: 'Buscar por nome, cidade ou estado...',
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
                                if (_sugestoes.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: BaileSulColors.cardBorder),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _sugestoes.map((s) {
                                        return InkWell(
                                          onTap: () => _selecionarSugestao(s),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                            child: Text(
                                              s,
                                              style: const TextStyle(color: BaileSulColors.headerText, fontSize: 14),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            if (_cidadesDisponiveis.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: BaileSulColors.cardBorder),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _cidadeSelecionada.isEmpty ? null : _cidadeSelecionada,
                                    hint: Text(
                                      'Todas as cidades',
                                      style: TextStyle(color: BaileSulColors.mutedText, fontSize: 14),
                                    ),
                                    icon: const Icon(Icons.expand_more_rounded, color: BaileSulColors.mutedText),
                                    style: const TextStyle(color: BaileSulColors.headerText, fontSize: 14),
                                    items: <DropdownMenuItem<String>>[
                                      const DropdownMenuItem<String>(
                                        value: '',
                                        child: Text('Todas as cidades'),
                                      ),
                                      ..._cidadesDisponiveis.map(
                                        (c) => DropdownMenuItem<String>(value: c, child: Text(c)),
                                      ),
                                    ],
                                    onChanged: (value) => _onCidadeChanged(value == '' ? null : value),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Results
                    if (_carregando)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(color: BaileSulColors.accent),
                        ),
                      )
                    else if (_erro != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                          child: _EstadoVazio(
                            icone: Icons.error_outline_rounded,
                            titulo: 'Ops!',
                            subtitulo: _erro!,
                            labelBotao: 'Tentar novamente',
                            onBotao: _carregarComunidades,
                          ),
                        ),
                      )
                    else if (_comunidadesFiltradas.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                          child: _EstadoVazio(
                            icone: Icons.location_off_outlined,
                            titulo: 'Nenhuma comunidade encontrada',
                            subtitulo: _searchController.text.trim().isNotEmpty
                                ? 'Tente outro termo de busca.'
                                : 'Ainda não há comunidades cadastradas na plataforma.',
                            labelBotao: _searchController.text.trim().isNotEmpty
                                ? 'Limpar busca'
                                : 'Atualizar',
                            onBotao: () {
                              if (_searchController.text.trim().isNotEmpty) {
                                _searchController.clear();
                              } else {
                                _carregarComunidades();
                              }
                            },
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final ComunidadeApi comunidade = _comunidadesFiltradas[index];
                              return _buildCommunityCard(comunidade);
                            },
                            childCount: _comunidadesFiltradas.length,
                          ),
                        ),
                      ),

                    // Bottom spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
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

  Widget _buildCommunityCard(ComunidadeApi comunidade) {
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
          onTap: () => _abrirPerfil(comunidade),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Community Avatar (placeholder, comunidade não possui foto de perfil própria)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7C9AB1), Color(0xFF0D496B)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.apartment_rounded, color: Colors.white70, size: 30),
                ),
                const SizedBox(width: 14),

                // Info Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COMUNIDADE',
                        style: TextStyle(
                          color: BaileSulColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comunidade.nomeEntidade,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: BaileSulColors.headerText,
                              ),
                            ),
                          ),
                          if (comunidade.cnpjValidado)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.verified_rounded, size: 16, color: BaileSulColors.accent),
                            ),
                        ],
                      ),
                      if (comunidade.cidadeEstado.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                comunidade.cidadeEstado,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (comunidade.descricao.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          comunidade.descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: BaileSulColors.mutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.labelBotao,
    required this.onBotao,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;
  final String labelBotao;
  final VoidCallback onBotao;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 52, color: BaileSulColors.mutedText),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BaileSulColors.mutedText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: onBotao,
              style: FilledButton.styleFrom(
                backgroundColor: BaileSulColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                labelBotao,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Representa uma comunidade retornada pela API (`GET /api/comunidades`).
class ComunidadeApi {
  const ComunidadeApi({
    required this.usuarioId,
    required this.nomeEntidade,
    required this.descricao,
    required this.whatsapp,
    required this.cidade,
    required this.estado,
    required this.cnpjValidado,
  });

  factory ComunidadeApi.fromJson(Map<String, dynamic> json) {
    return ComunidadeApi(
      usuarioId: int.tryParse(json['usuario_id']?.toString() ?? '') ?? 0,
      nomeEntidade: json['nome_entidade']?.toString() ?? 'Comunidade',
      descricao: json['descricao']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      cidade: json['cidade']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      cnpjValidado: json['cnpj_validado'] == true,
    );
  }

  final int usuarioId;
  final String nomeEntidade;
  final String descricao;
  final String whatsapp;
  final String cidade;
  final String estado;
  final bool cnpjValidado;

  String get cidadeEstado {
    if (cidade.isEmpty && estado.isEmpty) return '';
    if (estado.isEmpty) return cidade;
    if (cidade.isEmpty) return estado;
    return '$cidade/$estado';
  }
}
