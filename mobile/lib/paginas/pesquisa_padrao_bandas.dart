import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';
import 'perfil_banda.dart';

/// Rota: `/pesquisa-bandas`
class PesquisaPadraoBandas extends StatefulWidget {
  const PesquisaPadraoBandas({super.key});

  @override
  State<PesquisaPadraoBandas> createState() => _PesquisaPadraoBandasState();
}

class _PesquisaPadraoBandasState extends State<PesquisaPadraoBandas> {
  final TextEditingController _searchController = TextEditingController();

  List<BandaApi> _todasBandas = <BandaApi>[];
  List<BandaApi> _bandasFiltradas = <BandaApi>[];
  List<String> _sugestoes = <String>[];
  List<String> _estilosMusicais = <String>[];
  String _estiloSelecionado = '';
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarBandas();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarBandas() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/bandas');
      final http.Response response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> dados = _extrairLista(decoded);
        final List<BandaApi> bandas = dados
            .whereType<Map>()
            .map((Map<dynamic, dynamic> item) =>
                BandaApi.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (!mounted) return;
        setState(() {
          _todasBandas = bandas;
          _bandasFiltradas = List<BandaApi>.from(bandas);
          _estilosMusicais = bandas
              .map((BandaApi b) => b.estiloMusical)
              .where((String s) => s.isNotEmpty)
              .toSet()
              .toList();
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = 'Erro ao buscar bandas (${response.statusCode}).';
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
          decoded['dados'] ?? decoded['bandas'] ?? decoded['data'] ?? decoded['rows'];
      if (dados is List) return dados;
    }
    return <dynamic>[];
  }

  void _onSearchChanged() {
    final String textoOriginal = _searchController.text;
    final String query = textoOriginal.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _sugestoes = <String>[];
      } else {
        _sugestoes = _todasBandas
            .where((BandaApi b) => b.nomeArtistico.toLowerCase().contains(query))
            .take(8)
            .map((BandaApi b) => b.nomeArtistico)
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

  void _onEstiloChanged(String? estilo) {
    setState(() {
      _estiloSelecionado = estilo ?? '';
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    final String query = _searchController.text.toLowerCase().trim();
    Iterable<BandaApi> out = _todasBandas;
    if (query.isNotEmpty) {
      out = out.where((BandaApi b) => b.nomeArtistico.toLowerCase().contains(query));
    }
    if (_estiloSelecionado.isNotEmpty) {
      out = out.where((BandaApi b) => b.estiloMusical == _estiloSelecionado);
    }
    _bandasFiltradas = out.toList();
  }

  void _showMenu() {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  void _abrirPerfil(BandaApi banda) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PerfilBandaPage(bandaId: banda.usuarioId),
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
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                color: BaileSulColors.pageBackground,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Hero escuro — espelha .listing-hero de listings.module.css
                                    // (bandas.jsx): título + subtítulo sobre fundo em gradiente.
                                    Container(
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
                                            'Descubra grandes artistas',
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
                                            'Encontre as melhores bandas e artistas para sua próxima festa.',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.75),
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Cabeçalho da seção + filtros
                                    Padding(
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
                                                      'Bandas Disponíveis',
                                                      style: TextStyle(
                                                        color: BaileSulColors.headerText,
                                                        fontSize: 19,
                                                        fontWeight: FontWeight.w800,
                                                        letterSpacing: -0.3,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    const Text(
                                                      'Descubra os melhores artistas e bandas.',
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
                                                  '${_bandasFiltradas.length} banda${_bandasFiltradas.length == 1 ? '' : 's'}',
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
                                                    hintText: 'Buscar banda...',
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
                                          const SizedBox(height: 10),

                                          // Filtro por estilo musical
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
                                                value: _estiloSelecionado.isEmpty ? '' : _estiloSelecionado,
                                                icon: const Icon(Icons.expand_more_rounded, color: BaileSulColors.mutedText),
                                                style: const TextStyle(color: BaileSulColors.headerText, fontSize: 14),
                                                items: [
                                                  const DropdownMenuItem(value: '', child: Text('Todos os estilos')),
                                                  ..._estilosMusicais.map(
                                                    (e) => DropdownMenuItem(value: e, child: Text(e)),
                                                  ),
                                                ],
                                                onChanged: _onEstiloChanged,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Results
                                    if (_carregando)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 60),
                                        child: Center(
                                          child: CircularProgressIndicator(color: BaileSulColors.accent),
                                        ),
                                      )
                                    else if (_erro != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                                        child: _EstadoVazio(
                                          icone: Icons.error_outline_rounded,
                                          titulo: 'Ops!',
                                          subtitulo: _erro!,
                                          labelBotao: 'Tentar novamente',
                                          onBotao: _carregarBandas,
                                        ),
                                      )
                                    else if (_bandasFiltradas.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                                        child: _EstadoVazio(
                                          icone: Icons.groups_outlined,
                                          titulo: 'Nenhuma banda encontrada',
                                          subtitulo: (_searchController.text.trim().isNotEmpty || _estiloSelecionado.isNotEmpty)
                                              ? 'Tente ajustar seus filtros ou busque por outro termo.'
                                              : 'Ainda não há bandas cadastradas na plataforma.',
                                          labelBotao: (_searchController.text.trim().isNotEmpty || _estiloSelecionado.isNotEmpty)
                                              ? 'Limpar filtros'
                                              : 'Atualizar',
                                          onBotao: () {
                                            if (_searchController.text.trim().isNotEmpty || _estiloSelecionado.isNotEmpty) {
                                              _searchController.clear();
                                              setState(() {
                                                _estiloSelecionado = '';
                                                _aplicarFiltros();
                                              });
                                            } else {
                                              _carregarBandas();
                                            }
                                          },
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        child: Column(
                                          children: _bandasFiltradas
                                              .map((BandaApi banda) => _buildBandCard(banda))
                                              .toList(),
                                        ),
                                      ),

                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBandCard(BandaApi banda) {
    final String fotoUrl = ApiConfig.resolveMediaUrl(banda.fotoPerfilUrl);
    final String descricaoResumida =
        banda.descricao.length > 80 ? '${banda.descricao.substring(0, 80)}…' : banda.descricao;

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
          onTap: () => _abrirPerfil(banda),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem (foto de perfil da banda) com selo do estilo musical,
                // espelhando .listing-card-img-wrap/.listing-card-price do
                // site — placeholder com o mesmo gradiente roxo de
                // .listing-card-placeholder-band quando não há foto.
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: fotoUrl.isNotEmpty
                          ? Image.network(
                              fotoUrl,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _bandPlaceholder(),
                            )
                          : _bandPlaceholder(),
                    ),
                    if (banda.estiloMusical.isNotEmpty)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            banda.estiloMusical,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Info Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BANDA',
                        style: TextStyle(
                          color: BaileSulColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              banda.nomeArtistico,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: BaileSulColors.headerText,
                              ),
                            ),
                          ),
                          if (banda.cnpjValidado)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.verified_rounded, size: 16, color: BaileSulColors.accent),
                            ),
                        ],
                      ),
                      if (descricaoResumida.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          descricaoResumida,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: BaileSulColors.mutedText,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
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

  Widget _bandPlaceholder() {
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C45FD), Color(0xFF9E47F5)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.music_note_rounded, color: Colors.white70, size: 30),
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

/// Representa uma banda retornada pela API (`GET /api/bandas`).
class BandaApi {
  const BandaApi({
    required this.usuarioId,
    required this.nomeArtistico,
    required this.estiloMusical,
    required this.descricao,
    required this.whatsapp,
    required this.cnpjValidado,
    required this.fotoPerfilUrl,
  });

  factory BandaApi.fromJson(Map<String, dynamic> json) {
    return BandaApi(
      usuarioId: int.tryParse(json['usuario_id']?.toString() ?? '') ?? 0,
      nomeArtistico: json['nome_artistico']?.toString() ?? 'Banda',
      estiloMusical: json['estilo_musical']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      cnpjValidado: json['cnpj_validado'] == true,
      fotoPerfilUrl: json['foto_perfil_url']?.toString() ?? '',
    );
  }

  final int usuarioId;
  final String nomeArtistico;
  final String estiloMusical;
  final String descricao;
  final String whatsapp;
  final bool cnpjValidado;
  final String fotoPerfilUrl;
}
