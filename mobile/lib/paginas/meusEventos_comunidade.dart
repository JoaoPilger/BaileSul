import 'dart:convert';

import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../navigation/app_navigator.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'criar_editar_evento.dart';
import 'home.dart';

class MeusEventosComunidadePage extends StatefulWidget {
  const MeusEventosComunidadePage({super.key, this.comunidadeId});

  final int? comunidadeId;

  @override
  State<MeusEventosComunidadePage> createState() => _MeusEventosComunidadePageState();
}

class _MeusEventosComunidadePageState extends State<MeusEventosComunidadePage> with RouteAware {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _eventos = [];
  String _selectedFiltro = 'Todos';
  String _busca = '';
  // Mesmas 4 abas do site para o papel de comunidade (MeusEventos.jsx,
  // TABS_COMUNIDADE): Todos, Agendados, Realizados, Cancelados.
  static const List<String> _filtros = [
    'Todos',
    'Agendados',
    'Realizados',
    'Cancelados',
  ];
  int _total = 0;
  int _proximos = 0;
  int _realizados = 0;
  int _cancelados = 0;

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Uma rota empilhada por cima (ex.: Criar Evento aberto pelo menu
    // hambúrguer) foi fechada e esta tela ficou visível de novo — recarrega
    // sozinha em vez de depender do usuário reconstruir a tela manualmente.
    _carregarEventos();
  }

  Future<void> _carregarEventos() async {
    setState(() {
      _loading = true;
      _error = null;
      _eventos = [];
    });

    final String? token = SessaoUsuario.instance.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Faça login para ver seus eventos.';
        _loading = false;
      });
      return;
    }

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/comunidades/me/eventos');
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final http.Response resp = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('Falha ao carregar eventos (${resp.statusCode})');
      }

      final dynamic decoded = jsonDecode(resp.body);
      final List<dynamic> eventosRaw = decoded is Map && decoded['eventos'] is List ? decoded['eventos'] as List<dynamic> : <dynamic>[];

      final List<Map<String, dynamic>> eventos = eventosRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (!mounted) return;
      setState(() {
        _eventos = eventos;
        _recalcularEstatisticas();
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os eventos.';
      });
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _abrirCriarEvento() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CriarEditarEventoPage(isComunidade: true)),
    );
    if (!mounted) return;
    _carregarEventos();
  }

  Future<void> _abrirEditarEvento(Map<String, dynamic> evento) async {
    final bool? salvou = await showDialog<bool>(
      context: context,
      builder: (context) => _EditarEventoDialog(evento: evento),
    );
    if (salvou == true && mounted) {
      _carregarEventos();
    }
  }

  EventItem _paraEventItem(Map<String, dynamic> evento) {
    final String inicioRaw = evento['data_inicio']?.toString() ?? '';
    final String fimRaw = evento['data_fim']?.toString() ?? '';
    final String dateTime = _formatDateTime(inicioRaw, fimRaw);
    final String location = [
      evento['local_nome']?.toString(),
      evento['cidade']?.toString(),
      evento['estado']?.toString(),
    ]
        .where((value) => value != null && value.trim().isNotEmpty)
        .join(' • ');
    final String address = evento['local_endereco']?.toString() ?? '';
    final String organizer = evento['comunidade_nome']?.toString() ?? evento['comunidade']?.toString() ?? '';
    final String description = evento['descricao']?.toString() ?? '';
    final String status = evento['status']?.toString() ?? '';
    final String imageUrl = ApiConfig.resolveMediaUrl(evento['foto_capa_url']?.toString());

    return EventItem(
      id: int.tryParse('${evento['id'] ?? 0}') ?? 0,
      title: evento['titulo']?.toString() ?? 'Evento',
      genre: evento['tipo_evento']?.toString() ?? 'Evento',
      location: location.isNotEmpty ? location : 'Local não informado',
      dateTime: dateTime,
      price: evento['valor_ingresso'] != null && evento['valor_ingresso'].toString().isNotEmpty
          ? 'R\$ ${double.tryParse(evento['valor_ingresso'].toString())?.toStringAsFixed(2).replaceAll('.', ',') ?? evento['valor_ingresso'].toString()}'
          : 'Grátis',
      imageUrl: imageUrl.isNotEmpty
          ? imageUrl
          : 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=900&q=80',
      description: description,
      organizer: organizer,
      address: address,
      status: status,
      startDateTime: inicioRaw,
      endDateTime: fimRaw,
    );
  }

  Future<void> _abrirDetalhesEvento(Map<String, dynamic> evento) async {
    final int eventId = int.tryParse('${evento['id'] ?? 0}') ?? 0;
    Navigator.pushNamed(context, '/evento-dashboard', arguments: eventId);
  }

  String _formatDateTime(String inicioRaw, String fimRaw) {
    if (inicioRaw.isEmpty) return 'Data não informada';
    try {
      final DateTime inicio = DateTime.parse(inicioRaw);
      final DateTime fim = fimRaw.isNotEmpty ? DateTime.parse(fimRaw) : inicio;
      final String data = '${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')}/${inicio.year}';
      final String horaInicio = '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
      final String horaFim = fimRaw.isNotEmpty ? '${fim.hour.toString().padLeft(2, '0')}:${fim.minute.toString().padLeft(2, '0')}' : '';
      if (horaFim.isNotEmpty && inicio.day == fim.day && inicio.month == fim.month && inicio.year == fim.year) {
        return '$data • $horaInicio - $horaFim';
      }
      return fimRaw.isNotEmpty ? '$data • $horaInicio até ${fim.day.toString().padLeft(2, '0')}/${fim.month.toString().padLeft(2, '0')}/${fim.year} ${horaFim}' : '$data • $horaInicio';
    } catch (_) {
      return inicioRaw;
    }
  }

  Future<void> _confirmarCancelarEvento(Map<String, dynamic> evento) async {
    final bool? confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar evento'),
        content: Text(
          'Tem certeza que deseja cancelar o evento "${evento['titulo'] ?? ''}"? Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar evento'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    final String? token = SessaoUsuario.instance.token;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login novamente para cancelar o evento.')),
      );
      return;
    }

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/eventos/${evento['id']}');
      final http.Response resp = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        final Map<String, dynamic> body = resp.body.isNotEmpty ? jsonDecode(resp.body) as Map<String, dynamic> : {};
        throw Exception(body['error']?.toString() ?? 'Erro ao cancelar evento.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento cancelado com sucesso.')),
      );
      _carregarEventos();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _recalcularEstatisticas() {
    final now = DateTime.now();
    final in30 = now.add(const Duration(days: 30));

    _total = _eventos.length;
    _proximos = _eventos.where((e) {
      final raw = e['data_inicio']?.toString() ?? '';
      try {
        final d = DateTime.parse(raw);
        return (d.isAtSameMomentAs(now) || d.isAfter(now)) && d.isBefore(in30);
      } catch (_) {
        return false;
      }
    }).length;

    _cancelados = _eventos.where((e) => (e['status']?.toString() ?? '') == 'cancelado').length;
    _realizados = _eventos.where((e) => (e['status']?.toString() ?? '') == 'finalizado').length;
  }

  void _abrirMenu() {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> listaFiltrada = _eventos.where(_filtrarPorStatus).toList();

    return Scaffold(
      backgroundColor: BaileSulColors.pageBackground,
      body: Column(
        children: [
          MobileHeader(onMenuPressed: _abrirMenu, logoHeight: 58, horizontalPadding: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    color: BaileSulColors.pageBackground,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final bool isNarrow = constraints.maxWidth < 700;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (isNarrow) ...[
                                      Text('Meus eventos', style: const TextStyle(color: BaileSulColors.headerText, fontSize: 22, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 12),
                                      _buildFilterTabs(),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: _abrirCriarEvento,
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Criar Evento'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0D496B),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        ),
                                      ),
                                    ] else ...[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text('Meus eventos', style: const TextStyle(color: BaileSulColors.headerText, fontSize: 22, fontWeight: FontWeight.w800)),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton.icon(
                                            onPressed: _abrirCriarEvento,
                                            icon: const Icon(Icons.add, size: 18),
                                            label: const Text('Criar Evento'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0D496B),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildFilterTabs(),
                                    ],
                                    const SizedBox(height: 16),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildStatsGrid(),
                            const SizedBox(height: 16),
                            _buildSearchBox(),
                            const SizedBox(height: 16),
                            if (_loading)
                              const Center(child: CircularProgressIndicator())
                            else if (_error != null)
                              Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                            else if (listaFiltrada.isEmpty)
                              const Center(child: Text('Nenhum evento encontrado'))
                            else
                              Column(
                                children: [
                                  for (final event in listaFiltrada) ...[
                                    _EventoListCard(
                                      event: event,
                                      onTap: () => _abrirDetalhesEvento(event),
                                      onEditar: () => _abrirEditarEvento(event),
                                      onCancelar: () => _confirmarCancelarEvento(event),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wrap = constraints.maxWidth < 500;
        final chips = _filtros.map((filtro) {
          final bool selected = filtro == _selectedFiltro;
          return ChoiceChip(
            label: Text(filtro),
            selected: selected,
            selectedColor: const Color(0xFF0D496B),
            labelStyle: TextStyle(
              color: selected ? Colors.white : BaileSulColors.headerText,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            side: BorderSide(color: selected ? Colors.transparent : Colors.grey.shade300),
            onSelected: (_) => setState(() => _selectedFiltro = filtro),
          );
        }).toList();

        if (wrap) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final chip in chips) ...[
                Padding(padding: const EdgeInsets.only(right: 8), child: chip),
              ],
            ],
          ),
        );
      },
    );
  }

  bool _filtrarPorStatus(Map<String, dynamic> evento) {
    final String status = (evento['status'] ?? '').toString().toLowerCase();

    bool matchAba;
    switch (_selectedFiltro) {
      case 'Todos':
        matchAba = true;
        break;
      case 'Agendados':
        matchAba = status == 'agendado';
        break;
      case 'Cancelados':
        matchAba = status == 'cancelado';
        break;
      case 'Realizados':
        matchAba = status == 'finalizado';
        break;
      default:
        matchAba = true;
    }
    if (!matchAba) return false;

    if (_busca.trim().isEmpty) return true;
    final String titulo = (evento['titulo']?.toString() ?? '').toLowerCase();
    return titulo.contains(_busca.trim().toLowerCase());
  }

  Widget _buildStatTile(
    String title,
    String sublabel,
    String value, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: TextStyle(color: BaileSulColors.mutedText, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double itemWidth = maxWidth >= 700 ? (maxWidth - 12) / 2 : maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildStatTile(
                'Total de Eventos',
                'Todos os eventos criados',
                '$_total',
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF185FA5),
                iconBg: const Color(0x1F185FA5),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatTile(
                'Próximos Eventos',
                'Nos próximos 30 dias',
                '$_proximos',
                icon: Icons.schedule_rounded,
                iconColor: const Color(0xFF0F6E56),
                iconBg: const Color(0x1F0F6E56),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatTile(
                'Eventos Realizados',
                'Eventos concluídos',
                '$_realizados',
                icon: Icons.check_circle_outline_rounded,
                iconColor: BaileSulColors.accent,
                iconBg: const Color(0x1F0D496B),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatTile(
                'Cancelados',
                'Eventos cancelados',
                '$_cancelados',
                icon: Icons.cancel_outlined,
                iconColor: const Color(0xFFC24545),
                iconBg: const Color(0x1FC24545),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: BaileSulColors.mutedText),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _busca = value),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Buscar meus eventos',
                hintStyle: TextStyle(color: BaileSulColors.mutedText, fontSize: 13.5),
              ),
              style: const TextStyle(color: BaileSulColors.headerText, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventoListCard extends StatelessWidget {
  const _EventoListCard({
    required this.event,
    this.onTap,
    this.onEditar,
    this.onCancelar,
  });

  final Map<String, dynamic> event;
  final VoidCallback? onTap;
  final VoidCallback? onEditar;
  final VoidCallback? onCancelar;

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  /// Extrai "Banda/Artista: X" da descrição, igual ao regex usado no site
  /// (MeusEventos.jsx) pra mostrar quem foi contratado pra tocar no evento.
  String _subtitulo() {
    final String descricao = event['descricao']?.toString() ?? '';
    final RegExpMatch? match =
        RegExp(r'Banda/Artista:\s*(.*)', caseSensitive: false).firstMatch(descricao);
    if (match != null) {
      final String nome = match.group(1)?.trim() ?? '';
      if (nome.isNotEmpty) return nome;
    }
    return 'Organização';
  }

  String _valorFormatado() {
    final dynamic valor = event['valor_ingresso'];
    final double? v = valor == null ? null : double.tryParse('$valor');
    if (v == null || v <= 0) return 'Grátis';
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _statusBadge() {
    final String status = (event['status']?.toString() ?? 'agendado');
    late final Color bg;
    late final Color fg;
    late final String label;
    switch (status) {
      case 'finalizado':
        bg = BaileSulColors.mutedText.withValues(alpha: 0.1);
        fg = BaileSulColors.mutedText;
        label = 'Realizado';
        break;
      case 'cancelado':
        bg = const Color(0x1AC24545);
        fg = const Color(0xFFC24545);
        label = 'Cancelado';
        break;
      default:
        bg = BaileSulColors.accent.withValues(alpha: 0.1);
        fg = BaileSulColors.accent;
        label = 'Agendado';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: BaileSulColors.mutedText),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: BaileSulColors.mutedText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final bool podeEditar = (event['status']?.toString() ?? '') == 'agendado';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: BaileSulColors.mutedText,
            side: const BorderSide(color: BaileSulColors.cardBorder, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Ver detalhes', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        if (podeEditar) ...[
          FilledButton(
            onPressed: onEditar,
            style: FilledButton.styleFrom(
              backgroundColor: BaileSulColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Editar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: onCancelar,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC24545),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancelar Evento', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String capaResolvida = ApiConfig.resolveMediaUrl(event['foto_capa_url']?.toString());
    final String imageUrl = capaResolvida.isNotEmpty
        ? capaResolvida
        : 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=900&q=80';
    final int confirmados = int.tryParse('${event['confirmados'] ?? 0}') ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BaileSulColors.cardBorder),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 88,
                      height: 66,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            Container(color: Colors.grey.shade200, child: const Icon(Icons.event, size: 26)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['titulo']?.toString() ?? 'Título',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BaileSulColors.headerText,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Contratado por: ${_subtitulo()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: BaileSulColors.mutedText, fontSize: 11.5),
                        ),
                        _metaRow(Icons.calendar_month_outlined, _formatDate(event['data_inicio']?.toString())),
                        _metaRow(Icons.place_outlined, event['local_nome']?.toString() ?? ''),
                        _metaRow(Icons.sell_outlined, _valorFormatado()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.groups_outlined, size: 14, color: BaileSulColors.mutedText),
                  const SizedBox(width: 5),
                  Text(
                    '$confirmados confirmados',
                    style: TextStyle(color: BaileSulColors.mutedText, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditarEventoDialog extends StatefulWidget {
  const _EditarEventoDialog({required this.evento});

  final Map<String, dynamic> evento;

  @override
  State<_EditarEventoDialog> createState() => _EditarEventoDialogState();
}

class _EditarEventoDialogState extends State<_EditarEventoDialog> {
  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _dataInicioController;
  late final TextEditingController _dataFimController;
  late final TextEditingController _localNomeController;
  late final TextEditingController _localEnderecoController;
  late final TextEditingController _valorIngressoController;

  Uint8List? _novaCapaBytes;
  String _novaCapaFilename = 'capa.jpg';
  bool _salvando = false;
  String? _erro;

  static String _isoParaExibicao(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final DateTime? d = DateTime.tryParse(raw);
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String? _exibicaoParaIso(String value) {
    final List<String> partes = value.trim().split('/');
    if (partes.length != 3) return null;

    final int? dia = int.tryParse(partes[0]);
    final int? mes = int.tryParse(partes[1]);
    final int? ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return null;

    final DateTime data = DateTime(ano, mes, dia);
    if (data.day != dia || data.month != mes || data.year != ano) return null;

    return '$ano-${mes.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    final e = widget.evento;
    _tituloController = TextEditingController(text: e['titulo']?.toString() ?? '');
    _descricaoController = TextEditingController(text: e['descricao']?.toString() ?? '');
    _dataInicioController = TextEditingController(text: _isoParaExibicao(e['data_inicio']?.toString()));
    _dataFimController = TextEditingController(text: _isoParaExibicao(e['data_fim']?.toString()));
    _localNomeController = TextEditingController(text: e['local_nome']?.toString() ?? '');
    _localEnderecoController = TextEditingController(text: e['local_endereco']?.toString() ?? '');
    final valor = e['valor_ingresso'];
    _valorIngressoController = TextEditingController(text: valor == null ? '' : valor.toString());
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _dataInicioController.dispose();
    _dataFimController.dispose();
    _localNomeController.dispose();
    _localEnderecoController.dispose();
    _valorIngressoController.dispose();
    super.dispose();
  }

  MediaType _mediaTypeFromFilename(String filename) {
    final String lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }

  Future<void> _escolherCapa(ImageSource source) async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _novaCapaBytes = bytes;
        _novaCapaFilename = picked.name.isNotEmpty ? picked.name : _novaCapaFilename;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível selecionar a imagem.')),
      );
    }
  }

  void _abrirSeletorCapa() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _escolherCapa(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Câmera'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _escolherCapa(ImageSource.camera);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _salvar() async {
    final String titulo = _tituloController.text.trim();
    final String? dataInicio = _exibicaoParaIso(_dataInicioController.text);
    final String? dataFim = _exibicaoParaIso(_dataFimController.text);

    if (titulo.isEmpty || dataInicio == null || dataFim == null) {
      setState(() => _erro = 'Preencha titulo, data de inicio e data de termino validos.');
      return;
    }

    final String? token = SessaoUsuario.instance.token;
    if (token == null || token.isEmpty) {
      setState(() => _erro = 'Faca login novamente para salvar o evento.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/eventos/${widget.evento['id']}');
      final http.MultipartRequest request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['titulo'] = titulo;
      request.fields['descricao'] = _descricaoController.text.trim();
      request.fields['data_inicio'] = dataInicio;
      request.fields['data_fim'] = dataFim;
      request.fields['local_nome'] = _localNomeController.text.trim();
      request.fields['local_endereco'] = _localEnderecoController.text.trim();
      if (_valorIngressoController.text.trim().isNotEmpty) {
        final double? valor = double.tryParse(_valorIngressoController.text.trim().replaceAll(',', '.'));
        if (valor != null) request.fields['valor_ingresso'] = valor.toString();
      }
      if (_novaCapaBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_capa',
            _novaCapaBytes!,
            filename: _novaCapaFilename,
            contentType: _mediaTypeFromFilename(_novaCapaFilename),
          ),
        );
      }

      final http.StreamedResponse streamed = await request.send().timeout(const Duration(seconds: 30));
      final http.Response resp = await http.Response.fromStream(streamed);

      Map<String, dynamic> respBody = <String, dynamic>{};
      if (resp.body.isNotEmpty) {
        respBody = jsonDecode(resp.body) as Map<String, dynamic>;
      }

      if (resp.statusCode != 200) {
        throw Exception(respBody['error']?.toString() ?? 'Erro ao salvar evento.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento atualizado com sucesso.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Widget _buildCapaPicker() {
    final String capaAtualUrl = ApiConfig.resolveMediaUrl(widget.evento['foto_capa_url']?.toString());

    Widget imagem;
    if (_novaCapaBytes != null) {
      imagem = Image.memory(_novaCapaBytes!, fit: BoxFit.cover);
    } else if (capaAtualUrl.isNotEmpty) {
      imagem = Image.network(
        capaAtualUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.event, size: 36),
        ),
      );
    } else {
      imagem = Container(
        color: const Color(0xFFD9E5EE),
        child: const Center(
          child: Icon(Icons.upload_file_rounded, color: Color(0xFF0D496B), size: 28),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _abrirSeletorCapa,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFB9CBD9)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              imagem,
              Positioned(
                right: 8,
                top: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Evento'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCapaPicker(),
              const SizedBox(height: 12),
              _campo('Titulo do Evento *', _tituloController),
              _campo('Descricao', _descricaoController, maxLines: 3),
              Row(
                children: [
                  Expanded(
                    child: _campo(
                      'Data de Inicio *',
                      _dataInicioController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_DataInputFormatter()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _campo(
                      'Data de Termino *',
                      _dataFimController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_DataInputFormatter()],
                    ),
                  ),
                ],
              ),
              _campo('Local / Cidade', _localNomeController),
              _campo('Endereco', _localEnderecoController, maxLines: 2),
              _campo(
                'Valor do ingresso',
                _valorIngressoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              ),
              if (_erro != null) ...[
                Text(
                  _erro!,
                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D496B)),
          child: _salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

class _DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String trimmed = digits.length > 8 ? digits.substring(0, 8) : digits;

    final StringBuffer result = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      if (i == 2 || i == 4) {
        result.write('/');
      }
      result.write(trimmed[i]);
    }

    final String text = result.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
