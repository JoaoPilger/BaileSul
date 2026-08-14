import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

/// "Meus eventos" para contas de banda — ramo `tipo === 'banda'` de
/// frontend/src/paginas/meus_eventos/MeusEventos.jsx: lista os eventos
/// CONTRATADOS pela banda (via GET /bandas/me/agenda), não eventos criados
/// por ela. Mostra convites pendentes, agendados, realizados e
/// cancelados/recusados, com aceitar/recusar convite inline (mesmo endpoint
/// usado em contratos.dart e painel_banda.dart).
class MeusEventosBandasPage extends StatefulWidget {
  const MeusEventosBandasPage({super.key, this.bandaId});

  final int? bandaId;

  @override
  State<MeusEventosBandasPage> createState() => _MeusEventosBandasPageState();
}

class _MeusEventosBandasPageState extends State<MeusEventosBandasPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _eventos = [];
  int? _processandoId;

  String _selectedFiltro = 'Todos';
  // Mesmas 5 abas do site pro papel de banda (MeusEventos.jsx, TABS_BANDA).
  static const List<String> _filtros = [
    'Todos',
    'Convites (Pendentes)',
    'Agendados',
    'Realizados',
    'Cancelados/Recusados',
  ];
  String _busca = '';

  int _total = 0;
  int _proximos = 0;
  int _realizados = 0;
  int _canceladosRecusados = 0;

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  Future<void> _carregarEventos() async {
    setState(() {
      _loading = true;
      _error = null;
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
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/bandas/me/agenda');
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final http.Response resp = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('Falha ao carregar eventos (${resp.statusCode})');
      }

      final dynamic decoded = jsonDecode(resp.body);
      final List<Map<String, dynamic>> eventos = decoded is List
          ? decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _eventos = eventos;
        _recalcularEstatisticas();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os eventos da banda.';
      });
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  /// dias faltando (>= 0) até `data_inicio`, mesmo critério de
  /// MeusEventos.jsx (mapDataLocal): diferença de dias em relação a hoje,
  /// zerada se já passou.
  int? _diasFaltando(Map<String, dynamic> ev) {
    final String raw = ev['data_inicio']?.toString() ?? '';
    if (raw.isEmpty) return null;
    final DateTime? data = DateTime.tryParse(raw);
    if (data == null) return null;
    final DateTime hoje = DateTime.now();
    final DateTime hojeBase = DateTime(hoje.year, hoje.month, hoje.day);
    final DateTime dataBase = DateTime(data.year, data.month, data.day);
    final int dias = dataBase.difference(hojeBase).inDays;
    return dias > 0 ? dias : 0;
  }

  void _recalcularEstatisticas() {
    _total = _eventos.length;
    _proximos = _eventos.where((e) {
      final String status = e['status_evento']?.toString() ?? '';
      final String aceite = e['status_aceite']?.toString() ?? '';
      final int? dias = _diasFaltando(e);
      return status == 'agendado' && aceite == 'aceito' && dias != null && dias <= 30 && dias >= 0;
    }).length;
    _realizados = _eventos.where((e) => (e['status_evento']?.toString() ?? '') == 'finalizado').length;
    _canceladosRecusados = _eventos.where((e) {
      final String status = e['status_evento']?.toString() ?? '';
      final String aceite = e['status_aceite']?.toString() ?? '';
      return status == 'cancelado' || aceite == 'recusado';
    }).length;
  }

  Future<void> _responderContrato(int contratoId, dynamic eventoId, bool aceitar) async {
    setState(() => _processandoId = contratoId);

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/eventos/$eventoId/contratos/$contratoId');
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final String? token = SessaoUsuario.instance.token;
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

      final http.Response resp = await http
          .patch(url, headers: headers, body: jsonEncode({'status_aceite': aceitar ? 'aceito' : 'recusado'}))
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await _carregarEventos();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível processar essa resposta.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível conectar ao servidor.')),
        );
      }
    } finally {
      if (mounted) setState(() => _processandoId = null);
    }
  }

  void _abrirDetalhesEvento(Map<String, dynamic> evento) {
    Navigator.pushNamed(
      context,
      '/evento',
      arguments: EventItem(
        id: int.tryParse('${evento['id'] ?? 0}') ?? 0,
        title: evento['titulo']?.toString() ?? 'Evento',
        genre: 'Evento',
        location: _localDoEvento(evento),
        dateTime: evento['data_inicio']?.toString() ?? '',
        price: 'Grátis',
        imageUrl: '',
        organizer: evento['comunidade']?.toString() ?? '',
        status: evento['status_evento']?.toString() ?? '',
        startDateTime: evento['data_inicio']?.toString() ?? '',
        endDateTime: evento['data_fim']?.toString() ?? '',
      ),
    );
  }

  String _localDoEvento(Map<String, dynamic> ev) {
    final String localNome = ev['local_nome']?.toString() ?? '';
    if (localNome.isNotEmpty) return localNome;
    final String cidade = ev['cidade']?.toString() ?? 'Concórdia';
    final String estado = ev['estado']?.toString() ?? 'SC';
    return '$cidade, $estado';
  }

  void _abrirMenu() {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  bool _filtrarPorStatus(Map<String, dynamic> evento) {
    final String status = (evento['status_evento'] ?? '').toString();
    final String aceite = (evento['status_aceite'] ?? '').toString();

    bool matchAba;
    switch (_selectedFiltro) {
      case 'Todos':
        matchAba = true;
        break;
      case 'Convites (Pendentes)':
        matchAba = aceite == 'pendente';
        break;
      case 'Agendados':
        matchAba = aceite == 'aceito' && status == 'agendado';
        break;
      case 'Realizados':
        matchAba = status == 'finalizado';
        break;
      case 'Cancelados/Recusados':
        matchAba = status == 'cancelado' || aceite == 'recusado';
        break;
      default:
        matchAba = true;
    }
    if (!matchAba) return false;

    if (_busca.trim().isEmpty) return true;
    final String q = _busca.trim().toLowerCase();
    final String titulo = (evento['titulo']?.toString() ?? '').toLowerCase();
    final String comunidade = (evento['comunidade']?.toString() ?? '').toLowerCase();
    final String cidade = (evento['cidade']?.toString() ?? '').toLowerCase();
    return titulo.contains(q) || comunidade.contains(q) || cidade.contains(q);
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
            child: Container(
              color: BaileSulColors.pageBackground,
              child: RefreshIndicator(
                onRefresh: _carregarEventos,
                color: BaileSulColors.accent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meus eventos',
                              style: TextStyle(color: BaileSulColors.headerText, fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gerencie e acompanhe os eventos da sua banda',
                              style: TextStyle(color: BaileSulColors.headerText.withValues(alpha: 0.6), fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            _buildFilterTabs(),
                            const SizedBox(height: 16),
                            _buildStatsGrid(),
                            const SizedBox(height: 16),
                            _buildSearchBox(),
                            const SizedBox(height: 16),
                            if (_loading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(child: CircularProgressIndicator(color: BaileSulColors.accent)),
                              )
                            else if (_error != null)
                              _EmptyCard(_error!, danger: true)
                            else if (listaFiltrada.isEmpty)
                              const _EmptyCard('Nenhum evento encontrado para os filtros selecionados.')
                            else
                              Column(
                                children: [
                                  for (final evento in listaFiltrada) ...[
                                    _EventoCard(
                                      evento: evento,
                                      diasFaltando: _diasFaltando(evento),
                                      local: _localDoEvento(evento),
                                      processando: _processandoId == (int.tryParse('${evento['contrato_id'] ?? -1}') ?? -1),
                                      onDetalhes: () => _abrirDetalhesEvento(evento),
                                      onResponder: _responderContrato,
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
                ),
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
        final bool wrap = constraints.maxWidth < 560;
        final chips = _filtros.map((filtro) {
          final bool selected = filtro == _selectedFiltro;
          return ChoiceChip(
            label: Text(filtro),
            selected: selected,
            selectedColor: BaileSulColors.accent,
            labelStyle: TextStyle(
              color: selected ? Colors.white : BaileSulColors.headerText,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            side: BorderSide(color: selected ? Colors.transparent : BaileSulColors.cardBorder),
            onSelected: (_) => setState(() => _selectedFiltro = filtro),
          );
        }).toList();

        if (wrap) {
          return Wrap(spacing: 8, runSpacing: 8, children: chips);
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final chip in chips) Padding(padding: const EdgeInsets.only(right: 8), child: chip),
            ],
          ),
        );
      },
    );
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
                Text(title, style: const TextStyle(color: BaileSulColors.headerText, fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(color: BaileSulColors.headerText, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sublabel, style: TextStyle(color: BaileSulColors.mutedText, fontSize: 10.5)),
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
                'Eventos contratados',
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
                'Confirmados (30 dias)',
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
                'Cancelados/Recusados',
                'Eventos cancelados/recusados',
                '$_canceladosRecusados',
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
                hintText: 'Buscar eventos da banda',
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.texto, {this.danger = false});

  final String texto;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: danger ? const Color(0xFFFCA5A5) : BaileSulColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      alignment: Alignment.center,
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(color: danger ? const Color(0xFFC24545) : BaileSulColors.mutedText, fontSize: 13.5),
      ),
    );
  }
}

/// Badge de status do evento visto pela banda — espelha `StatusBadgeBanda`
/// de MeusEventos.jsx: prioriza o status do convite (pendente/recusado)
/// antes do status do evento em si.
class _StatusBadgeBanda extends StatelessWidget {
  const _StatusBadgeBanda({required this.status, required this.statusAceite});

  final String status;
  final String statusAceite;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;

    if (statusAceite == 'pendente') {
      bg = const Color(0x1FB8862B);
      fg = const Color(0xFFB8862B);
      label = 'Pendente (Convite)';
    } else if (statusAceite == 'recusado') {
      bg = const Color(0x1AC24545);
      fg = const Color(0xFFC24545);
      label = 'Recusado';
    } else if (status == 'cancelado') {
      bg = const Color(0x1AC24545);
      fg = const Color(0xFFC24545);
      label = 'Cancelado';
    } else if (status == 'finalizado') {
      bg = BaileSulColors.mutedText.withValues(alpha: 0.1);
      fg = BaileSulColors.mutedText;
      label = 'Realizado';
    } else {
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
}

class _EventoCard extends StatelessWidget {
  const _EventoCard({
    required this.evento,
    required this.diasFaltando,
    required this.local,
    required this.processando,
    required this.onDetalhes,
    required this.onResponder,
  });

  final Map<String, dynamic> evento;
  final int? diasFaltando;
  final String local;
  final bool processando;
  final VoidCallback onDetalhes;
  final Future<void> Function(int contratoId, dynamic eventoId, bool aceitar) onResponder;

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final DateTime d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  /// Nota de status abaixo do badge — espelha a composição de spans
  /// condicionais de MeusEventos.jsx.
  String _statusNote(String status, String aceite) {
    if (aceite == 'pendente') return 'Convite recebido';
    if (aceite == 'recusado') return 'Convite recusado';
    if (aceite == 'aceito' && status == 'agendado') {
      if (diasFaltando == null) return '';
      return diasFaltando! > 0 ? 'Faltam $diasFaltando dias' : 'Evento hoje';
    }
    if (status == 'finalizado') return 'Realizado em ${_formatDate(evento['data_inicio']?.toString())}';
    if (status == 'cancelado') return 'Cancelado em ${_formatDate(evento['data_inicio']?.toString())}';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final int contratoId = int.tryParse('${evento['contrato_id'] ?? -1}') ?? -1;
    final dynamic eventoId = evento['id'];
    final String status = evento['status_evento']?.toString() ?? 'agendado';
    final String aceite = evento['status_aceite']?.toString() ?? '';
    final int confirmados = int.tryParse('${evento['confirmados'] ?? 0}') ?? 0;

    return Container(
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
              Container(
                width: 64,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [BaileSulColors.accent, BaileSulColors.dark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.image_outlined, color: Colors.white24, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento['titulo']?.toString() ?? 'Evento',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: BaileSulColors.headerText, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Contratado por: ${evento['comunidade']?.toString().isNotEmpty == true ? evento['comunidade'] : 'Organização'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: BaileSulColors.mutedText, fontSize: 11.5),
                    ),
                    const SizedBox(height: 6),
                    _metaRow(Icons.calendar_month_outlined, _formatDate(evento['data_inicio']?.toString())),
                    _metaRow(Icons.place_outlined, local),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadgeBanda(status: status, statusAceite: aceite),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      _statusNote(status, aceite),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: BaileSulColors.mutedText, fontSize: 10.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.groups_outlined, size: 14, color: BaileSulColors.mutedText),
              const SizedBox(width: 5),
              Text('$confirmados confirmados', style: TextStyle(color: BaileSulColors.mutedText, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onDetalhes,
                style: OutlinedButton.styleFrom(
                  foregroundColor: BaileSulColors.mutedText,
                  side: const BorderSide(color: BaileSulColors.cardBorder, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Ver detalhes', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              if (aceite == 'pendente') ...[
                FilledButton.icon(
                  onPressed: (processando || contratoId < 0) ? null : () => onResponder(contratoId, eventoId, true),
                  icon: const Icon(Icons.check_circle, size: 15),
                  label: const Text('Aceitar Convite', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F6E56),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                FilledButton.icon(
                  onPressed: (processando || contratoId < 0) ? null : () => onResponder(contratoId, eventoId, false),
                  icon: const Icon(Icons.cancel_outlined, size: 15),
                  label: const Text('Recusar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC24545),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: BaileSulColors.mutedText),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: BaileSulColors.mutedText, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
