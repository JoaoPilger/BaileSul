import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/tipo_conta.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

/// Perfil (vitrine) de uma comunidade — espelha a estrutura em "cards"
/// empilhados do site (frontend/src/paginas/vitrine/VitrinePerfil.jsx,
/// ramo `tipo === 'comunidade'`): card de perfil (capa + ações), card
/// "Sobre", card de avaliações, card de estatísticas, card de galeria e
/// card de próximos eventos.
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
  int _seguidoresCount = 0;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _comunidade;
  List<Map<String, dynamic>> _eventos = [];
  List<Map<String, dynamic>> _midias = [];

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
        _seguindo = decoded['seguindo'] == true;
        _seguidoresCount = int.tryParse('${decoded['seguidores'] ?? 0}') ?? 0;
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
      backgroundColor: BaileSulColors.pageBackground,
      body: Column(
        children: [
          MobileHeader(
            logoHeight: 58,
            horizontalPadding: 16,
            onMenuPressed: _abrirMenu,
          ),
          Expanded(
            child: Container(
              color: BaileSulColors.pageBackground,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: BaileSulColors.accent));
    }

    if (_error != null || _comunidade == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _carregarPerfil,
      color: BaileSulColors.accent,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 14),
                  _buildAboutCard(),
                  const SizedBox(height: 14),
                  _buildRatingsCard(),
                  const SizedBox(height: 14),
                  _buildStatsCard(),
                  const SizedBox(height: 14),
                  _buildGalleryCard(),
                  const SizedBox(height: 14),
                  _buildEventsCard(),
                ],
              ),
            ),
          ),
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
            Icon(Icons.apartment_outlined, size: 56, color: BaileSulColors.mutedText.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Não foi possível carregar este perfil.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _carregarPerfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: BaileSulColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    if (cidade.isEmpty && estado.isEmpty) return '';
    if (estado.isEmpty) return cidade;
    if (cidade.isEmpty) return estado;
    return '$cidade, $estado';
  }

  double get _mediaAvaliacao =>
      double.tryParse('${_comunidade?['media_avaliacao'] ?? 0}') ?? 0;
  int get _totalAvaliacoes =>
      int.tryParse('${_comunidade?['total_avaliacoes'] ?? 0}') ?? 0;
  double get _minhaAvaliacao =>
      double.tryParse('${_comunidade?['minha_avaliacao'] ?? 0}') ?? 0;

  // ── card: perfil ────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BaileSulColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: padding,
      child: child,
    );
  }

  Widget _buildProfileCard() {
    final String fotoPerfilUrl =
        ApiConfig.resolveMediaUrl(_comunidade?['foto_perfil_url']?.toString());
    final String local = _cidadeEstado;
    final String whatsapp = _campo('whatsapp');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Capa (mesma imagem usada como foto de perfil no site).
          SizedBox(
            height: 180,
            width: double.infinity,
            child: fotoPerfilUrl.isNotEmpty
                ? Image.network(
                    fotoPerfilUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _coverFallback(),
                  )
                : _coverFallback(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_seguidoresCount Seguidores',
                style: TextStyle(
                  color: BaileSulColors.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nome,
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (local.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 13, color: BaileSulColors.mutedText),
                      const SizedBox(width: 5),
                      Text(
                        local,
                        style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 12.5),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagChip(label: 'Comunidade'),
                    if (_isMinhaConta)
                      _FilledPillButton(
                        label: 'Editar Perfil',
                        onPressed: () async {
                          final bool? atualizado = await Navigator.pushNamed(
                            context,
                            '/editar-perfil-comunidade',
                          ) as bool?;
                          if (atualizado == true) {
                            _carregarPerfil();
                          }
                        },
                      )
                    else
                      _FilledPillButton(
                        label: _seguindo ? '✓ Seguindo' : 'Seguir',
                        tonal: _seguindo,
                        onPressed: () {
                          setState(() {
                            _seguindo = !_seguindo;
                            _seguidoresCount += _seguindo ? 1 : -1;
                            if (_seguidoresCount < 0) _seguidoresCount = 0;
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
                      ),
                    _OutlinePillButton(
                      label: 'Contato',
                      enabled: whatsapp.isNotEmpty,
                      onPressed: () => _abrirContato(whatsapp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [BaileSulColors.accent, BaileSulColors.dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.apartment, color: Colors.white24, size: 56),
    );
  }

  void _abrirContato(String whatsapp) {
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

  // ── card: sobre ─────────────────────────────────────────────

  Widget _buildAboutCard() {
    final String descricaoCompleta = _campo('descricao');
    final bool temDescricao = descricaoCompleta.isNotEmpty;
    final bool descricaoLonga = descricaoCompleta.length > 160;
    final String descricaoExibida = !descricaoLonga || _expandedBio
        ? descricaoCompleta
        : '${descricaoCompleta.substring(0, 160)}...';

    final String endereco = _campo('endereco');
    final String localizacao = endereco.isNotEmpty
        ? (_cidadeEstado.isNotEmpty ? '$endereco, $_cidadeEstado' : endereco)
        : _cidadeEstado;
    final String whatsapp = _campo('whatsapp');

    return _card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre a comunidade',
            style: TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            temDescricao ? descricaoExibida : 'Nenhuma descrição cadastrada.',
            style: TextStyle(
              color: BaileSulColors.mutedText,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
          if (descricaoLonga) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _expandedBio = !_expandedBio),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: BaileSulColors.cardBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _expandedBio ? 'Ver menos ▲' : 'Ver mais ▼',
                  style: TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: BaileSulColors.cardBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (localizacao.isNotEmpty) ...[
                  _MetaItem(icon: Icons.place_outlined, text: 'Localização'),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2, bottom: 10),
                    child: Text(
                      localizacao,
                      style: TextStyle(color: BaileSulColors.mutedText, fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
                if (whatsapp.isNotEmpty)
                  _MetaItem(icon: Icons.chat_bubble_outline, text: 'Contato: $whatsapp'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── card: avaliações ────────────────────────────────────────

  Widget _buildRatingsCard() {
    final bool logado = SessaoUsuario.instance.autenticado;

    String promptLabel;
    if (_isMinhaConta) {
      promptLabel = 'Você não pode avaliar seu próprio perfil';
    } else if (logado) {
      promptLabel = _minhaAvaliacao > 0
          ? 'Sua avaliação enviada:'
          : 'Avalie esta comunidade:';
    } else {
      promptLabel = 'Faça login para avaliar esta comunidade';
    }

    return _card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avaliações da comunidade',
            style: TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _mediaAvaliacao.toStringAsFixed(_mediaAvaliacao % 1 == 0 ? 0 : 1),
                style: const TextStyle(
                  color: BaileSulColors.headerText,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StarsDisplay(value: _mediaAvaliacao),
                  const SizedBox(height: 4),
                  Text(
                    _totalAvaliacoes == 0
                        ? 'Nenhuma avaliação ainda'
                        : 'Baseado em $_totalAvaliacoes avaliações',
                    style: TextStyle(color: BaileSulColors.mutedText, fontSize: 11.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: BaileSulColors.cardBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    promptLabel,
                    style: const TextStyle(
                      color: BaileSulColors.headerText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!logado && !_isMinhaConta)
                  _OutlinePillButton(
                    label: 'Entrar',
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── card: estatísticas ──────────────────────────────────────

  Widget _buildStatsCard() {
    final List<_StatData> stats = [
      _StatData(icon: Icons.calendar_month_outlined, value: '${_eventos.length}', label: 'Eventos'),
      _StatData(icon: Icons.groups_outlined, value: '$_seguidoresCount', label: 'Seguidores'),
      _StatData(
        icon: Icons.star_border_rounded,
        value: _mediaAvaliacao.toStringAsFixed(_mediaAvaliacao % 1 == 0 ? 0 : 1),
        label: _totalAvaliacoes == 0 ? 'Sem avaliações' : '$_totalAvaliacoes avaliações',
      ),
      _StatData(icon: Icons.event_available_outlined, value: '${_eventos.length}', label: 'Próximos eventos'),
    ];

    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.1,
        children: stats.map((s) => _StatItem(data: s)).toList(),
      ),
    );
  }

  // ── card: galeria ───────────────────────────────────────────

  Widget _buildGalleryCard() {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: BaileSulColors.accent.withValues(alpha: 0.12))),
            ),
            child: Text(
              'GALERIA',
              style: TextStyle(
                color: BaileSulColors.accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_midias.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nenhuma imagem ou vídeo na galeria',
                  style: TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemCount: _midias.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> m = _midias[index];
                final bool isVideo = (m['tipo']?.toString() ?? 'imagem') == 'video';
                final String url = ApiConfig.resolveMediaUrl(m['url']?.toString());
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isVideo
                      ? Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 30),
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: BaileSulColors.pageBackground,
                            child: const Icon(Icons.image_outlined, color: BaileSulColors.mutedText),
                          ),
                        ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── card: próximos eventos ──────────────────────────────────

  String _formatarData(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final String s = raw.length >= 10 ? raw.substring(0, 10) : raw;
    final List<String> p = s.split('-');
    if (p.length != 3) return raw;
    final int? y = int.tryParse(p[0]);
    final int? m = int.tryParse(p[1]);
    final int? d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return raw;
    return '${d.toString().padLeft(2, '0')}/${m.toString().padLeft(2, '0')}/$y';
  }

  String _formatarPreco(dynamic valor) {
    if (valor == null) return '';
    final double? v = double.tryParse('$valor');
    if (v == null || v <= 0) return 'Grátis';
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _buildEventsCard() {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRÓXIMOS EVENTOS',
                style: TextStyle(
                  color: BaileSulColors.accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/pesquisa-eventos'),
                child: Text(
                  'Ver todos os eventos',
                  style: TextStyle(
                    color: BaileSulColors.accentLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_eventos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nenhum evento agendado',
                  style: TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
                ),
              ),
            )
          else
            Column(
              children: _eventos.map((ev) => _buildEventItem(ev)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> ev) {
    final String capa = ApiConfig.resolveMediaUrl(ev['foto_capa_url']?.toString());
    final String local = ev['local_nome']?.toString() ?? '';
    final String preco = _formatarPreco(ev['valor_ingresso']);
    final String status = (ev['status']?.toString() ?? 'agendado');

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/evento', arguments: ev['id']),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: BaileSulColors.cardBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: capa.isNotEmpty
                  ? Image.network(
                      capa,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _eventThumbFallback(),
                    )
                  : _eventThumbFallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ev['titulo']?.toString() ?? 'Evento',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BaileSulColors.headerText,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _EventMetaRow(icon: Icons.calendar_month_outlined, text: _formatarData(ev['data_inicio']?.toString())),
                  if (local.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _EventMetaRow(icon: Icons.place_outlined, text: local),
                  ],
                  if (preco.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _EventMetaRow(icon: Icons.sell_outlined, text: preco),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.chevron_right, size: 18, color: BaileSulColors.mutedText),
                const SizedBox(height: 6),
                _EventStatusBadge(status: status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventThumbFallback() {
    return Container(
      width: 62,
      height: 62,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [BaileSulColors.accent, BaileSulColors.dark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.white24, size: 22),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Componentes auxiliares
// ─────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: BaileSulColors.cardBorder, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: BaileSulColors.mutedText,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilledPillButton extends StatelessWidget {
  const _FilledPillButton({required this.label, required this.onPressed, this.tonal = false});

  final String label;
  final VoidCallback onPressed;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              tonal ? BaileSulColors.accent.withValues(alpha: 0.1) : BaileSulColors.accent,
          foregroundColor: tonal ? BaileSulColors.accent : Colors.white,
          elevation: 0,
          side: tonal ? BorderSide(color: BaileSulColors.accent.withValues(alpha: 0.3)) : null,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _OutlinePillButton extends StatelessWidget {
  const _OutlinePillButton({required this.label, required this.onPressed, this.enabled = true});

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: BaileSulColors.mutedText,
          side: BorderSide(color: BaileSulColors.cardBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: BaileSulColors.accent),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: BaileSulColors.mutedText, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarsDisplay extends StatelessWidget {
  const _StarsDisplay({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final int cheias = value.round();
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < cheias ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: const Color(0xFFF5A623),
        );
      }),
    );
  }
}

class _StatData {
  const _StatData({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: BaileSulColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(data.icon, size: 17, color: BaileSulColors.accent),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  color: BaileSulColors.headerText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: BaileSulColors.mutedText, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventMetaRow extends StatelessWidget {
  const _EventMetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 12, color: BaileSulColors.mutedText),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: BaileSulColors.mutedText, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _EventStatusBadge extends StatelessWidget {
  const _EventStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;
    switch (status) {
      case 'andamento':
        bg = const Color(0x1A0F6E56);
        fg = const Color(0xFF0F6E56);
        label = 'Em andamento';
        break;
      case 'realizado':
      case 'finalizado':
        bg = BaileSulColors.mutedText.withValues(alpha: 0.1);
        fg = BaileSulColors.mutedText;
        label = 'Realizado';
        break;
      default:
        bg = BaileSulColors.accent.withValues(alpha: 0.1);
        fg = BaileSulColors.accent;
        label = 'Agendado';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
