import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import '../widgets/mobile_footer.dart';
import 'criar_editar_evento.dart';
import 'home.dart';

class MeusEventosComunidadePage extends StatefulWidget {
  const MeusEventosComunidadePage({super.key, this.comunidadeId});

  final int? comunidadeId;

  @override
  State<MeusEventosComunidadePage> createState() => _MeusEventosComunidadePageState();
}

class _MeusEventosComunidadePageState extends State<MeusEventosComunidadePage> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _eventos = [];
  String _search = '';
  String _selectedFiltro = 'Todos';
  static const List<String> _filtros = [
    'Todos',
    'Rascunhos',
    'Agendados',
    'Em andamento',
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

  Future<void> _carregarEventos() async {
    setState(() {
      _loading = true;
      _error = null;
      _eventos = [];
    });

    final int? id = widget.comunidadeId ?? SessaoUsuario.instance.usuarioId;
    if (id == null) {
      setState(() {
        _error = 'Comunidade não informada.';
        _loading = false;
      });
      return;
    }

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/comunidades/$id');
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final String? token = SessaoUsuario.instance.token;
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

      final http.Response resp = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('Falha ao carregar comunidade (${resp.statusCode})');
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
    final List<Map<String, dynamic>> listaFiltrada = _eventos.where((e) {
      if (_search.isNotEmpty) {
        final titulo = (e['titulo'] ?? '').toString().toLowerCase();
        if (!titulo.contains(_search.toLowerCase())) {
          return false;
        }
      }
      return _filtrarPorStatus(e);
    }).toList();

    return Scaffold(
      backgroundColor: BaileSulColors.dark,
      body: Column(
        children: [
          MobileHeader(onMenuPressed: _abrirMenu, logoHeight: 58, horizontalPadding: 16),
          Expanded(
            child: Container(
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
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CriarEditarEventoPage()),
                                  ),
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
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const CriarEditarEventoPage()),
                                      ),
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
                              ],
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 120),
                          child: Column(
                            children: [
                              _buildStatsGrid(),
                              const SizedBox(height: 16),
                              _buildSearchBar(),
                              const SizedBox(height: 12),
                              _buildFilterTabs(),
                              const SizedBox(height: 12),
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
                                      _EventoListCard(event: event),
                                      const SizedBox(height: 12),
                                    ],
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MobileFooter(),
    );
  }

  Widget _buildSearchBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 540;

        return isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Buscar eventos',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: BaileSulColors.headerText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Buscar eventos',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: BaileSulColors.headerText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ],
              );
      },
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
    final String dataInicio = evento['data_inicio']?.toString() ?? '';
    final String dataFim = evento['data_fim']?.toString() ?? '';
    final DateTime? inicio = DateTime.tryParse(dataInicio);
    final DateTime? fim = DateTime.tryParse(dataFim);
    final DateTime agora = DateTime.now();

    switch (_selectedFiltro) {
      case 'Todos':
        return true;
      case 'Rascunhos':
        return status == 'rascunho';
      case 'Agendados':
        return status == 'agendado';
      case 'Cancelados':
        return status == 'cancelado';
      case 'Realizados':
        return status == 'finalizado';
      case 'Em andamento':
        if (status == 'andamento') return true;
        if (status == 'agendado' && inicio != null && fim != null) {
          return agora.isAfter(inicio) && agora.isBefore(fim);
        }
        return false;
      default:
        return true;
    }
  }

  Widget _buildStatTile(String title, String value, {IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: BaileSulColors.headerText),
            const SizedBox(height: 8),
          ],
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: BaileSulColors.mutedText)),
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
            SizedBox(width: itemWidth, child: _buildStatTile('Total de Eventos', '$_total')),
            SizedBox(width: itemWidth, child: _buildStatTile('Próximos', '$_proximos')),
            SizedBox(width: itemWidth, child: _buildStatTile('Realizados', '$_realizados')),
            SizedBox(width: itemWidth, child: _buildStatTile('Cancelados', '$_cancelados')),
          ],
        );
      },
    );
  }
}

class _EventoListCard extends StatelessWidget {
  const _EventoListCard({required this.event});

  final Map<String, dynamic> event;

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = (event['foto_capa_url']?.toString().isNotEmpty == true) ? event['foto_capa_url'].toString() : 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=900&q=80';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 500;

        return DecoratedBox(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: BaileSulColors.cardBorder)),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: SizedBox(
                        height: 180,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(color: Colors.grey.shade200, child: const Icon(Icons.event, size: 36)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event['titulo']?.toString() ?? 'Título', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(event['descricao']?.toString() ?? '', style: const TextStyle(color: BaileSulColors.mutedText)),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.black54),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_formatDate(event['data_inicio']?.toString()), style: const TextStyle(fontWeight: FontWeight.w600))),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                            const SizedBox(width: 8),
                            Expanded(child: Text(event['local_nome']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                          ]),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(color: Colors.grey.shade200, child: const Icon(Icons.event, size: 36)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event['titulo']?.toString() ?? 'Título', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(event['descricao']?.toString() ?? '', style: const TextStyle(color: BaileSulColors.mutedText)),
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.black54),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_formatDate(event['data_inicio']?.toString()), style: const TextStyle(fontWeight: FontWeight.w600))),
                            ]),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                              const SizedBox(width: 8),
                              Expanded(child: Text(event['local_nome']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
