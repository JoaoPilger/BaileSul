import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/api_config.dart';
import '../models/tipo_conta.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

/// Perfil (vitrine) de uma comunidade.
///
/// Se [comunidadeId] não for informado, a página assume que o usuário logado
/// é uma conta de comunidade e carrega o perfil dela mesma (usuario_id da
/// sessão == id da comunidade no backend).
class PerfilComunidadePage extends StatefulWidget {
  const PerfilComunidadePage({super.key, this.comunidadeId});

  final int? comunidadeId;

  @override
  State<PerfilComunidadePage> createState() => _PerfilComunidadePageState();
}

class _PerfilComunidadePageState extends State<PerfilComunidadePage> {
  final ScrollController _scrollController = ScrollController();
  bool _expandedBio = false;
  bool _seguindo = false;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _comunidade;
  List<Map<String, dynamic>> _eventos = [];
  List<Map<String, dynamic>> _midias = [];

  // GlobalKeys to enable scrolling to sections
  final GlobalKey _keySobre = GlobalKey();
  final GlobalKey _keyEventos = GlobalKey();
  final GlobalKey _keyGaleria = GlobalKey();
  final GlobalKey _keyLocalizacao = GlobalKey();

  int? get _perfilId {
    if (widget.comunidadeId != null) return widget.comunidadeId;
    final SessaoUsuario sessao = SessaoUsuario.instance;
    if (sessao.autenticado && sessao.tipoConta == TipoConta.comunidade) {
      return sessao.usuarioId;
    }
    return null;
  }

  bool get _isMinhaConta {
    final SessaoUsuario sessao = SessaoUsuario.instance;
    return sessao.autenticado &&
        sessao.tipoConta == TipoConta.comunidade &&
        sessao.usuarioId == _perfilId;
  }

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final int? id = _perfilId;

    setState(() {
      _loading = true;
      _error = null;
    });

    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Faça login em uma conta de comunidade para ver este perfil.';
      });
      return;
    }

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/comunidades/$id');
      final http.Response resp =
          await http.get(url).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 404) {
        throw Exception('Comunidade não encontrada.');
      }
      if (resp.statusCode != 200) {
        throw Exception('Falha ao carregar perfil (${resp.statusCode})');
      }

      final Map<String, dynamic> decoded =
          jsonDecode(resp.body) as Map<String, dynamic>;

      final List<dynamic> eventosRaw =
          decoded['eventos'] is List ? decoded['eventos'] as List<dynamic> : <dynamic>[];
      final List<dynamic> midiasRaw =
          decoded['midias'] is List ? decoded['midias'] as List<dynamic> : <dynamic>[];

      if (!mounted) return;
      setState(() {
        _comunidade = decoded;
        _eventos = eventosRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _midias = midiasRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar o perfil da comunidade.';
        _loading = false;
      });
    }
  }

  void _scrollToSection(GlobalKey key) {
    final BuildContext? context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _abrirMenu() {
    MobileAppMenu.show(
      context,
      entries: MobileAppMenu.entries(context),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaileSulColors.dark,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MobileHeader(
              logoHeight: 58,
              horizontalPadding: 16,
              onMenuPressed: _abrirMenu,
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _comunidade == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _carregarPerfil,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner and Profile image section
            _buildHeaderBanner(),

            // Community Title and Action buttons
            _buildHeaderInfo(),

            // Tab Bar navigation
            _buildTabBarNav(),

            // "Sobre a Comunidade" section
            Container(
              key: _keySobre,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: _buildSobreSection(),
            ),

            const Divider(height: 1, color: BaileSulColors.cardBorder),

            // Stats Row
            _buildStatsRow(),

            const Divider(height: 1, color: BaileSulColors.cardBorder),

            // Galeria Section
            Container(
              key: _keyGaleria,
              color: BaileSulColors.pageBackground.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: _buildGaleriaSection(),
            ),

            const Divider(height: 1, color: BaileSulColors.cardBorder),

            // Próximos Eventos Section
            Container(
              key: _keyEventos,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: _buildEventosSection(),
            ),

            const Divider(height: 1, color: BaileSulColors.cardBorder),

            // Localização Section (with OpenStreetMap)
            Container(
              key: _keyLocalizacao,
              color: BaileSulColors.pageBackground.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: _buildLocalizacaoSection(),
            ),

            // Footer
            const MobileFooter(
              logoHeight: 52,
              horizontalPadding: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.apartment_outlined, size: 56, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Não foi possível carregar este perfil.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _carregarPerfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D496B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  String _campo(String chave, [String fallback = '']) {
    final dynamic valor = _comunidade?[chave];
    if (valor == null) return fallback;
    final String texto = valor.toString().trim();
    return texto.isEmpty ? fallback : texto;
  }

  String get _nome => _campo('nome_entidade', 'Comunidade');
  String get _cidadeEstado {
    final String cidade = _campo('cidade');
    final String estado = _campo('estado');
    if (cidade.isEmpty && estado.isEmpty) return 'Localização não informada';
    if (estado.isEmpty) return cidade;
    if (cidade.isEmpty) return estado;
    return '$cidade, $estado';
  }

  bool get _verificado => _comunidade?['cnpj_validado'] == true;

  Widget _buildHeaderBanner() {
    final String? bannerUrl = _midias.isNotEmpty
        ? ApiConfig.resolveMediaUrl(_midias.first['url']?.toString())
        : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background banner image
        (bannerUrl != null && bannerUrl.isNotEmpty)
            ? Image.network(
                bannerUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _bannerFallback(),
              )
            : _bannerFallback(),
        // Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Profile picture overlapping
        Positioned(
          bottom: -45,
          left: 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Comunidade',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
              if (_isMinhaConta)
                // Camera edit icon at bottom right
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Editar foto da comunidade.')),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bannerFallback() {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [BaileSulColors.accent, BaileSulColors.dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.apartment, color: Colors.white24, size: 64),
    );
  }

  Widget _buildHeaderInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Community Name
          Text(
            _nome,
            style: const TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _cidadeEstado,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chips
          Row(
            children: [
              _buildTagChip('Comunidade'),
              if (_verificado) ...[
                const SizedBox(width: 8),
                _buildTagChip('Verificado'),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              if (!_isMinhaConta) ...[
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _seguindo = !_seguindo;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _seguindo
                                  ? 'Você começou a seguir esta comunidade.'
                                  : 'Você deixou de seguir esta comunidade.',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D496B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        _seguindo ? 'Seguindo' : 'Seguir',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: _isMinhaConta
                      ? OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/configuracoes');
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.black38, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          label: const Text(
                            'Editar perfil',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () => _abrirContato(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.black38, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Contato',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirContato() {
    final String whatsapp = _campo('whatsapp');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          whatsapp.isNotEmpty
              ? 'WhatsApp: $whatsapp'
              : 'Esta comunidade não informou um contato.',
        ),
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTabBarNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton('Sobre', () => _scrollToSection(_keySobre)),
          _buildTabButton('Eventos', () => _scrollToSection(_keyEventos)),
          _buildTabButton('Galeria', () => _scrollToSection(_keyGaleria)),
          _buildTabButton('Localização', () => _scrollToSection(_keyLocalizacao)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSobreSection() {
    final String descricaoCompleta =
        _campo('descricao', 'Esta comunidade ainda não adicionou uma descrição.');
    final bool descricaoLonga = descricaoCompleta.length > 180;
    final String descricaoExibida = !descricaoLonga || _expandedBio
        ? descricaoCompleta
        : '${descricaoCompleta.substring(0, 180)}...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sobre a comunidade',
          style: TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),

        // Collapsible Text description
        Text(
          descricaoExibida,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 4),

        // Toggle button
        if (descricaoLonga)
          InkWell(
            onTap: () {
              setState(() {
                _expandedBio = !_expandedBio;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expandedBio ? 'Ver menos' : 'Ver mais',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  _expandedBio ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.black87,
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Info List Row Items
        _buildSobreInfoRow(
          Icons.location_on_outlined,
          'Endereço',
          _campo('endereco', 'Endereço não informado'),
        ),
        const SizedBox(height: 12),
        _buildSobreInfoRow(
          Icons.phone_outlined,
          'WhatsApp',
          _campo('whatsapp', 'Não informado'),
        ),
        const SizedBox(height: 12),
        _buildSobreInfoRow(
          Icons.verified_outlined,
          'Verificação de CNPJ',
          _verificado ? 'Comunidade verificada' : 'Ainda não verificada',
        ),
      ],
    );
  }

  Widget _buildSobreInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          _buildStatCol(Icons.event_outlined, '${_eventos.length}', 'Eventos\nagendados'),
          _buildVerticalDivider(),
          _buildStatCol(Icons.photo_library_outlined, '${_midias.length}', 'Fotos na\ngaleria'),
          _buildVerticalDivider(),
          _buildStatCol(
            _verificado ? Icons.verified_outlined : Icons.hourglass_empty,
            _verificado ? 'Sim' : 'Não',
            'Verificado',
          ),
          _buildVerticalDivider(),
          _buildStatCol(Icons.location_on_outlined, _campo('estado', '-'), 'Estado'),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStatCol(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: Colors.black54),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaleriaSection() {
    final List<String> imageUrls = _midias
        .where((m) => (m['tipo']?.toString() ?? 'imagem') == 'imagem')
        .map((m) => ApiConfig.resolveMediaUrl(m['url']?.toString()))
        .where((u) => u.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Galeria do Espaço',
          style: TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),

        if (imageUrls.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: const Text(
              'Nenhuma foto adicionada ainda.',
              style: TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      imageUrls[index],
                      width: 170,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 170,
                          height: 110,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, color: Colors.white),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatarData(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final DateTime? d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatarHora(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final DateTime? d = DateTime.tryParse(raw);
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEventosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Próximos eventos no espaço',
              style: TextStyle(
                color: BaileSulColors.headerText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/pesquisa-eventos');
              },
              child: const Text(
                'Ver todos',
                style: TextStyle(
                  color: Color(0xFF0D496B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_eventos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: const Text(
              'Nenhum evento agendado no momento.',
              style: TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
            ),
          )
        else ...[
          ..._eventos.map((ev) => _buildEventCard(ev)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/pesquisa-eventos');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black38, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Ver todos os eventos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> ev) {
    final String capa = ApiConfig.resolveMediaUrl(ev['foto_capa_url']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: BaileSulColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
              child: capa.isNotEmpty
                  ? Image.network(
                      capa,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _eventImageFallback(),
                    )
                  : _eventImageFallback(),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ev['titulo']?.toString() ?? 'Evento',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: BaileSulColors.headerText,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Date & Time
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 13, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          _formatarData(ev['data_inicio']?.toString()),
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time, size: 13, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          _formatarHora(ev['data_inicio']?.toString()),
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ev['local_nome']?.toString() ?? _cidadeEstado,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Status
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 13, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          (ev['status']?.toString() ?? '').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Right Chevron
            const Icon(Icons.chevron_right, color: Colors.black45),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _eventImageFallback() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey.shade200,
      child: const Icon(Icons.music_video, color: Colors.black26),
    );
  }

  Widget _buildLocalizacaoSection() {
    final double? lat = double.tryParse('${_comunidade?['latitude'] ?? ''}');
    final double? lng = double.tryParse('${_comunidade?['longitude'] ?? ''}');
    final String endereco = _campo('endereco');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localização no Mapa',
          style: TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          endereco.isNotEmpty ? '$endereco, $_cidadeEstado' : _cidadeEstado,
          style: const TextStyle(
            color: BaileSulColors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),

        if (lat == null || lng == null)
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BaileSulColors.cardBorder, width: 1.5),
            ),
            child: const Text(
              'Localização não informada.',
              style: TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BaileSulColors.cardBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 15.5,
                  minZoom: 10,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.mobile',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFFFF6A00),
                          size: 44,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
