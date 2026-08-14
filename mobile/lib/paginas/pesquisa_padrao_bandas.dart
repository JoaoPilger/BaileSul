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
    final String query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _bandasFiltradas = List<BandaApi>.from(_todasBandas);
      } else {
        _bandasFiltradas = _todasBandas.where((BandaApi banda) {
          return banda.nomeArtistico.toLowerCase().contains(query) ||
              banda.estiloMusical.toLowerCase().contains(query) ||
              banda.descricao.toLowerCase().contains(query);
        }).toList();
      }
    });
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
                                    // Search Header Section
                                    Padding(
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
                                                hintText: 'Buscar por nome ou estilo musical...',
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
                                          icone: Icons.music_off_outlined,
                                          titulo: 'Nenhuma banda encontrada',
                                          subtitulo: _searchController.text.trim().isNotEmpty
                                              ? 'Tente outro termo de busca.'
                                              : 'Ainda não há bandas cadastradas na plataforma.',
                                          labelBotao: _searchController.text.trim().isNotEmpty
                                              ? 'Limpar busca'
                                              : 'Atualizar',
                                          onBotao: () {
                                            if (_searchController.text.trim().isNotEmpty) {
                                              _searchController.clear();
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
              children: [
                // Band Avatar (placeholder, banda não possui foto de perfil própria)
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
                  child: const Icon(Icons.music_note_rounded, color: Colors.white70, size: 30),
                ),
                const SizedBox(width: 14),

                // Info Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              banda.nomeArtistico,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
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
                      if (banda.descricao.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          banda.descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (banda.estiloMusical.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: BaileSulColors.pageBackground.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            banda.estiloMusical,
                            style: const TextStyle(
                              fontSize: 11,
                              color: BaileSulColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
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

/// Representa uma banda retornada pela API (`GET /api/bandas`).
class BandaApi {
  const BandaApi({
    required this.usuarioId,
    required this.nomeArtistico,
    required this.estiloMusical,
    required this.descricao,
    required this.whatsapp,
    required this.cnpjValidado,
  });

  factory BandaApi.fromJson(Map<String, dynamic> json) {
    return BandaApi(
      usuarioId: int.tryParse(json['usuario_id']?.toString() ?? '') ?? 0,
      nomeArtistico: json['nome_artistico']?.toString() ?? 'Banda',
      estiloMusical: json['estilo_musical']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      cnpjValidado: json['cnpj_validado'] == true,
    );
  }

  final int usuarioId;
  final String nomeArtistico;
  final String estiloMusical;
  final String descricao;
  final String whatsapp;
  final bool cnpjValidado;
}
