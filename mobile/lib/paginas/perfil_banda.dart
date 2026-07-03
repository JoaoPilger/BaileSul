import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/tipo_conta.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

/// Perfil (vitrine) de uma banda.
///
/// Se [bandaId] não for informado, a página assume que o usuário logado é
/// uma conta de banda e carrega o perfil dela mesma (usuario_id da sessão
/// == id da banda no backend).
class PerfilBandaPage extends StatefulWidget {
  const PerfilBandaPage({super.key, this.bandaId});

  final int? bandaId;

  @override
  State<PerfilBandaPage> createState() => _PerfilBandaPageState();
}

class _PerfilBandaPageState extends State<PerfilBandaPage> {
  final ScrollController _scrollController = ScrollController();
  bool _expandedBio = false;
  bool _seguindo = false;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _banda;
  List<Map<String, dynamic>> _eventos = [];
  List<Map<String, dynamic>> _midias = [];

  // GlobalKeys to enable scrolling to sections
  final GlobalKey _keySobre = GlobalKey();
  final GlobalKey _keyEventos = GlobalKey();
  final GlobalKey _keyGaleria = GlobalKey();
  final GlobalKey _keyAvaliacoes = GlobalKey();

  int? get _perfilId {
    if (widget.bandaId != null) return widget.bandaId;
    final SessaoUsuario sessao = SessaoUsuario.instance;
    if (sessao.autenticado && sessao.tipoConta == TipoConta.banda) {
      return sessao.usuarioId;
    }
    return null;
  }

  bool get _isMinhaConta {
    final SessaoUsuario sessao = SessaoUsuario.instance;
    return sessao.autenticado &&
        sessao.tipoConta == TipoConta.banda &&
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
        _error = 'Faça login em uma conta de banda para ver este perfil.';
      });
      return;
    }

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/bandas/$id');
      final http.Response resp =
          await http.get(url).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 404) {
        throw Exception('Banda não encontrada.');
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
        _banda = decoded;
        _eventos = eventosRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _midias = midiasRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar o perfil da banda.';
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

    if (_error != null || _banda == null) {
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

            // Band Title and Action buttons
            _buildHeaderInfo(),

            // Tab Bar navigation
            _buildTabBarNav(),

            // "Sobre a Banda" section
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

            // Avaliações da Banda Section
            Container(
              key: _keyAvaliacoes,
              color: BaileSulColors.pageBackground.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: _buildAvaliacoesSection(),
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
            const Icon(Icons.music_note_outlined, size: 56, color: Colors.black26),
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
    final dynamic valor = _banda?[chave];
    if (valor == null) return fallback;
    final String texto = valor.toString().trim();
    return texto.isEmpty ? fallback : texto;
  }

  String get _nome => _campo('nome_artistico', 'Banda');
  bool get _verificado => _banda?['cnpj_validado'] == true;

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
        // Overlay for dark visual touch at the bottom
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
                  child: Text(
                    'Banda',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (_isMinhaConta)
                // Camera edit icon at bottom right of avatar
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Editar foto de perfil.')),
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
      child: const Icon(Icons.music_note, color: Colors.white24, size: 64),
    );
  }

  Widget _buildHeaderInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Band Name
          Text(
            _nome,
            style: const TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),

          // Estilo musical (usado como subtítulo, já que a banda não tem cidade fixa)
          if (_campo('estilo_musical').isNotEmpty)
            Row(
              children: [
                Icon(Icons.music_note_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _campo('estilo_musical'),
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
              _buildTagChip('Banda'),
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
                                  ? 'Você começou a seguir a banda.'
                                  : 'Você deixou de seguir a banda.',
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
              : 'Esta banda não informou um contato.',
        ),
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
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
          _buildTabButton('Avaliações', () => _scrollToSection(_keyAvaliacoes)),
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
        _campo('descricao', 'Esta banda ainda não adicionou uma descrição.');
    final bool descricaoLonga = descricaoCompleta.length > 180;
    final String descricaoExibida = !descricaoLonga || _expandedBio
        ? descricaoCompleta
        : '${descricaoCompleta.substring(0, 180)}...';
    final String videoUrl = _campo('video_url');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sobre a banda',
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
          Icons.music_note_outlined,
          'Estilo musical',
          _campo('estilo_musical', 'Não informado'),
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
          _verificado ? 'Banda verificada' : 'Ainda não verificada',
        ),

        if (videoUrl.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_circle_outline, size: 20, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vídeo de apresentação',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Abrindo: $videoUrl')),
                        );
                      },
                      child: Text(
                        videoUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0D496B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          _buildStatCol(Icons.event_available_outlined, '${_eventos.length}', 'Próximos\neventos'),
          _buildVerticalDivider(),
          _buildStatCol(Icons.photo_library_outlined, '${_midias.length}', 'Fotos na\ngaleria'),
          _buildVerticalDivider(),
          _buildStatCol(
            _verificado ? Icons.verified_outlined : Icons.hourglass_empty,
            _verificado ? 'Sim' : 'Não',
            'Verificado',
          ),
          _buildVerticalDivider(),
          _buildStatCol(Icons.music_note_outlined, _campo('estilo_musical', '-'), 'Estilo'),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
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
          'Galeria',
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
              'Próximos eventos confirmados',
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
              'Nenhum evento confirmado no momento.',
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
    final String cidade = ev['cidade']?.toString() ?? '';
    final String estado = ev['estado']?.toString() ?? '';
    final String local = [
      if ((ev['local_nome']?.toString() ?? '').isNotEmpty) ev['local_nome'].toString(),
      if (cidade.isNotEmpty || estado.isNotEmpty) [cidade, estado].where((s) => s.isNotEmpty).join(', '),
    ].join(' • ');

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
            // Left Image (a banda não recebe capa de evento na API, usamos ícone)
            Container(
              width: 100,
              height: 100,
              color: Colors.grey.shade200,
              child: const Icon(Icons.music_video, color: Colors.black26),
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

                    // Location / community
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            local.isNotEmpty ? local : 'Local a confirmar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Comunidade contratante
                    if ((ev['comunidade']?.toString() ?? '').isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.apartment_outlined, size: 13, color: Colors.black54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ev['comunidade'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
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

  Widget _buildAvaliacoesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avaliações da banda',
          style: TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          alignment: Alignment.center,
          child: const Text(
            'As avaliações de bandas ainda não estão disponíveis nesta versão do app.',
            textAlign: TextAlign.center,
            style: TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
