import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart' show BaileSulColors;

/// Painel inicial exibido para contas do tipo "comunidade" — espelha o painel
/// web (frontend/src/paginas/painel/painel_comunidade.jsx), reaproveitando os
/// componentes e a linguagem visual já existentes no app mobile.
///
/// Estrutura (igual à versão desktop):
///   • Saudação "Bem-vindo, {email}. Aqui está um resumo do que está rolando."
///   • 4 cards de estatísticas: Total de Eventos, Agendados, Realizados,
///     Vendedores Ativos.
///   • Atalhos: Criar Evento, Meus Eventos, Vendedores, Configurações.
///   • Card de Calendário com mini-calendário navegável + agenda do dia
///     selecionado.
///   • Próximos eventos.
class PainelComunidadePage extends StatefulWidget {
  const PainelComunidadePage({super.key});

  @override
  State<PainelComunidadePage> createState() => _PainelComunidadePageState();
}

class _PainelComunidadePageState extends State<PainelComunidadePage> {
  static const List<String> _weekdays = <String>['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
  static const List<String> _months = <String>[
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  final ScrollController _scrollController = ScrollController();

  bool _carregando = true;
  List<Map<String, dynamic>> _eventos = <Map<String, dynamic>>[];
  int _vendedoresAtivos = 0;

  // ── calendário ──────────────────────────────────────────────
  late DateTime _hoje;
  late int _viewYear;
  late int _viewMonth; // 0-based
  late int _selDay;
  late int _selMonth;
  late int _selYear;

  @override
  void initState() {
    super.initState();
    final DateTime agora = DateTime.now();
    _hoje = DateTime(agora.year, agora.month, agora.day);
    _viewYear = _hoje.year;
    _viewMonth = _hoje.month - 1;
    _selDay = _hoje.day;
    _selMonth = _hoje.month - 1;
    _selYear = _hoje.year;
    _carregarDados();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── data helpers ────────────────────────────────────────────

  /// Extrai YYYY-MM-DD de uma string de data (ISO timestamp ou só data).
  String? _extrairData(dynamic raw) {
    if (raw == null) return null;
    final String s = raw.toString();
    if (s.length < 10) return null;
    return s.substring(0, 10);
  }

  DateTime? _dataLocal(dynamic raw) {
    final String? s = _extrairData(raw);
    if (s == null) return null;
    final List<String> partes = s.split('-');
    if (partes.length != 3) return null;
    final int? y = int.tryParse(partes[0]);
    final int? m = int.tryParse(partes[1]);
    final int? d = int.tryParse(partes[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  Map<String, String> _headers() {
    final Map<String, String> headers = <String, String>{'Content-Type': 'application/json'};
    final String? token = SessaoUsuario.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final List<Map<String, dynamic>> eventos = await _buscarEventos();
    final int vendedores = await _buscarVendedoresAtivos();

    if (!mounted) return;
    setState(() {
      _eventos = eventos;
      _vendedoresAtivos = vendedores;
      _carregando = false;
    });
  }

  Future<List<Map<String, dynamic>>> _buscarEventos() async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/comunidades/me/eventos');
      final http.Response resp =
          await http.get(url, headers: _headers()).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final dynamic decoded = jsonDecode(resp.body);
        final dynamic lista = decoded is Map ? decoded['eventos'] : decoded;
        if (lista is List) {
          return lista.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {
      // silencioso — retorna lista vazia
    }
    return <Map<String, dynamic>>[];
  }

  Future<int> _buscarVendedoresAtivos() async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/vendedores');
      final http.Response resp =
          await http.get(url, headers: _headers()).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final dynamic decoded = jsonDecode(resp.body);
        if (decoded is List) {
          // O backend já devolve apenas vendedores ativos; ainda assim
          // filtramos por segurança (espelha o comportamento da web).
          return decoded.where((v) {
            if (v is Map && v.containsKey('ativo')) return v['ativo'] == true;
            return true;
          }).length;
        }
      }
    } catch (_) {
      // silencioso
    }
    return 0;
  }

  void _abrirMenu() {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  // ── derivados ───────────────────────────────────────────────

  int get _totalEventos => _eventos.length;
  int get _agendados => _eventos.where((e) => e['status'] == 'agendado').length;
  int get _realizados => _eventos.where((e) => e['status'] == 'finalizado').length;

  List<Map<String, dynamic>> get _proximos {
    final List<Map<String, dynamic>> comDias = _eventos
        .where((e) => e['status'] == 'agendado')
        .map((e) {
          final DateTime? data = _dataLocal(e['data_inicio']);
          int? dias;
          if (data != null) {
            dias = data.difference(_hoje).inDays;
          }
          return <String, dynamic>{...e, '_dias': dias};
        })
        .where((e) {
          final int? dias = e['_dias'] as int?;
          return dias == null || dias >= 0;
        })
        .toList();

    comDias.sort((a, b) => ((a['_dias'] as int?) ?? 0).compareTo((b['_dias'] as int?) ?? 0));
    return comDias.take(5).toList();
  }

  /// Dias (número) com evento no mês visualizado.
  Set<int> get _diasComEvento {
    final Set<int> dias = <int>{};
    for (final Map<String, dynamic> e in _eventos) {
      final String? s = _extrairData(e['data_inicio']);
      if (s == null) continue;
      final List<String> p = s.split('-');
      if (p.length != 3) continue;
      final int? y = int.tryParse(p[0]);
      final int? m = int.tryParse(p[1]);
      final int? d = int.tryParse(p[2]);
      if (y == _viewYear && m != null && m - 1 == _viewMonth && d != null) {
        dias.add(d);
      }
    }
    return dias;
  }

  List<Map<String, dynamic>> get _eventosDoDia {
    return _eventos.where((e) {
      final String? s = _extrairData(e['data_inicio']);
      if (s == null) return false;
      final List<String> p = s.split('-');
      if (p.length != 3) return false;
      final int? y = int.tryParse(p[0]);
      final int? m = int.tryParse(p[1]);
      final int? d = int.tryParse(p[2]);
      return y == _selYear && m != null && m - 1 == _selMonth && d == _selDay;
    }).toList();
  }

  void _irParaMes(int delta) {
    setState(() {
      int m = _viewMonth + delta;
      int y = _viewYear;
      if (m < 0) {
        m = 11;
        y -= 1;
      } else if (m > 11) {
        m = 0;
        y += 1;
      }
      _viewMonth = m;
      _viewYear = y;
    });
  }

  String get _dataSelecionadaLabel {
    final DateTime data = DateTime(_selYear, _selMonth + 1, _selDay);
    const List<String> semana = <String>[
      'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira',
      'Sexta-feira', 'Sábado', 'Domingo',
    ];
    // DateTime.weekday: 1 = segunda ... 7 = domingo
    final String diaSemana = semana[data.weekday - 1];
    return '$diaSemana, ${_selDay.toString().padLeft(2, '0')} de ${_months[_selMonth]} de $_selYear';
  }

  void _criarEventoNaData() {
    Navigator.pushNamed(context, '/criar-evento');
  }

  @override
  Widget build(BuildContext context) {
    final String? email = SessaoUsuario.instance.email;

    return Scaffold(
      backgroundColor: BaileSulColors.pageBackground,
      body: Column(
        children: [
          MobileHeader(onMenuPressed: _abrirMenu, logoHeight: 58, horizontalPadding: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Painel da Comunidade',
                                style: TextStyle(
                                  color: BaileSulColors.headerText,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Bem-vindo${email != null && email.isNotEmpty ? ', $email' : ''}. '
                                'Aqui está um resumo do que está rolando.',
                                style: TextStyle(
                                  color: BaileSulColors.headerText.withValues(alpha: 0.6),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_carregando)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else ...[
                                if (_vendedoresAtivos < 2) ...[
                                  _VendorAlert(vendedoresAtivos: _vendedoresAtivos),
                                  const SizedBox(height: 20),
                                ],
                                _StatsGrid(
                                  total: _totalEventos,
                                  agendados: _agendados,
                                  realizados: _realizados,
                                  vendedores: _vendedoresAtivos,
                                ),
                                const SizedBox(height: 28),
                                const _SectionTitle('Atalhos'),
                                const SizedBox(height: 12),
                                _AtalhosGrid(
                                  onCriarEvento: () => Navigator.pushNamed(context, '/criar-evento'),
                                  onMeusEventos: () =>
                                      Navigator.pushNamed(context, '/meus-eventos-comunidade'),
                                  onVendedores: () => Navigator.pushNamed(context, '/vendedores'),
                                  onConfiguracoes: () =>
                                      Navigator.pushNamed(context, '/editar-perfil-comunidade'),
                                ),
                                const SizedBox(height: 28),
                                const _SectionTitle('Calendário'),
                                const SizedBox(height: 12),
                                _CalendarioCard(
                                  viewYear: _viewYear,
                                  viewMonth: _viewMonth,
                                  monthLabel: '${_months[_viewMonth]} $_viewYear',
                                  weekdays: _weekdays,
                                  selDay: _selDay,
                                  selMonth: _selMonth,
                                  selYear: _selYear,
                                  hoje: _hoje,
                                  diasComEvento: _diasComEvento,
                                  eventosDoDia: _eventosDoDia,
                                  dataLabel: _dataSelecionadaLabel,
                                  onPrevMonth: () => _irParaMes(-1),
                                  onNextMonth: () => _irParaMes(1),
                                  onSelecionarDia: (int dia) {
                                    setState(() {
                                      _selDay = dia;
                                      _selMonth = _viewMonth;
                                      _selYear = _viewYear;
                                    });
                                  },
                                  onCriarEvento: _criarEventoNaData,
                                  onVerEvento: (dynamic id) =>
                                      Navigator.pushNamed(context, '/meus-eventos-comunidade'),
                                ),
                                const SizedBox(height: 28),
                                const _SectionTitle('Próximos eventos'),
                                const SizedBox(height: 12),
                                _proximos.isNotEmpty
                                    ? _ProximosList(itens: _proximos)
                                    : const _EmptyCard('Nenhum evento agendado no momento.'),
                                const SizedBox(height: 24),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Seções e componentes
// ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: BaileSulColors.headerText,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

/// Aviso exibido quando há menos de 2 vendedores ativos, espelhando o
/// `.pn-vendor-alert` do painel web.
class _VendorAlert extends StatelessWidget {
  const _VendorAlert({required this.vendedoresAtivos});

  final int vendedoresAtivos;

  static const Color _warning = Color(0xFFB8862B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _warning.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 22, color: _warning),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendedoresAtivos == 0
                          ? 'Nenhum vendedor cadastrado'
                          : 'Só 1 vendedor cadastrado',
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'O ideal são pelo menos 2 vendedores ativos — sem isso, se o único '
                      'vendedor ficar indisponível, ninguém consegue confirmar pagamento '
                      'dos compradores.',
                      style: TextStyle(
                        color: BaileSulColors.headerText.withValues(alpha: 0.55),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/vendedores'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BaileSulColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cadastrar vendedores'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.total,
    required this.agendados,
    required this.realizados,
    required this.vendedores,
  });

  final int total;
  final int agendados;
  final int realizados;
  final int vendedores;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool duasColunas = constraints.maxWidth >= 420;
        final double largura =
            duasColunas ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

        final List<Widget> cards = <Widget>[
          _StatCard(
            label: 'Total de Eventos',
            value: total,
            icon: Icons.calendar_today_rounded,
            iconBg: const Color(0x1F185FA5),
            iconColor: const Color(0xFF185FA5),
          ),
          _StatCard(
            label: 'Agendados',
            value: agendados,
            icon: Icons.schedule_rounded,
            iconBg: const Color(0x1F0F6E56),
            iconColor: const Color(0xFF0F6E56),
          ),
          _StatCard(
            label: 'Realizados',
            value: realizados,
            icon: Icons.check_circle_outline_rounded,
            iconBg: const Color(0x1F0D496B),
            iconColor: BaileSulColors.accent,
          ),
          _StatCard(
            label: 'Vendedores Ativos',
            value: vendedores,
            icon: Icons.groups_rounded,
            iconBg: const Color(0x1FB8862B),
            iconColor: const Color(0xFFB8862B),
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: largura, child: card))
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
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
                  label,
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _AtalhosGrid extends StatelessWidget {
  const _AtalhosGrid({
    required this.onCriarEvento,
    required this.onMeusEventos,
    required this.onVendedores,
    required this.onConfiguracoes,
  });

  final VoidCallback onCriarEvento;
  final VoidCallback onMeusEventos;
  final VoidCallback onVendedores;
  final VoidCallback onConfiguracoes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool duasColunas = constraints.maxWidth >= 420;
        final double largura =
            duasColunas ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

        final List<Widget> cards = <Widget>[
          _AtalhoCard(
            icon: Icons.add_rounded,
            titulo: 'Criar Evento',
            subtitulo: 'Novo evento pra sua comunidade',
            onTap: onCriarEvento,
          ),
          _AtalhoCard(
            icon: Icons.list_alt_rounded,
            titulo: 'Meus Eventos',
            subtitulo: 'Ver e gerenciar todos',
            onTap: onMeusEventos,
          ),
          _AtalhoCard(
            icon: Icons.people_alt_rounded,
            titulo: 'Vendedores',
            subtitulo: 'Gerenciar equipe de venda',
            onTap: onVendedores,
          ),
          _AtalhoCard(
            icon: Icons.settings_outlined,
            titulo: 'Editar Vitrine',
            subtitulo: 'Dados e perfil da comunidade',
            onTap: onConfiguracoes,
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: largura, child: card))
              .toList(),
        );
      },
    );
  }
}

class _AtalhoCard extends StatelessWidget {
  const _AtalhoCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BaileSulColors.cardBorder),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x1A0D496B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: BaileSulColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: BaileSulColors.headerText.withValues(alpha: 0.55),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card Calendário ─────────────────────────────────────────

class _CalendarioCard extends StatelessWidget {
  const _CalendarioCard({
    required this.viewYear,
    required this.viewMonth,
    required this.monthLabel,
    required this.weekdays,
    required this.selDay,
    required this.selMonth,
    required this.selYear,
    required this.hoje,
    required this.diasComEvento,
    required this.eventosDoDia,
    required this.dataLabel,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelecionarDia,
    required this.onCriarEvento,
    required this.onVerEvento,
  });

  final int viewYear;
  final int viewMonth;
  final String monthLabel;
  final List<String> weekdays;
  final int selDay;
  final int selMonth;
  final int selYear;
  final DateTime hoje;
  final Set<int> diasComEvento;
  final List<Map<String, dynamic>> eventosDoDia;
  final String dataLabel;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<int> onSelecionarDia;
  final VoidCallback onCriarEvento;
  final ValueChanged<dynamic> onVerEvento;

  bool _isHoje(int dia) =>
      dia == hoje.day && viewMonth == hoje.month - 1 && viewYear == hoje.year;

  bool _isSelecionado(int dia) =>
      dia == selDay && viewMonth == selMonth && viewYear == selYear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grade do calendário
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrevMonth),
                        const SizedBox(width: 6),
                        _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNextMonth),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CalendarGrid(
                  viewYear: viewYear,
                  viewMonth: viewMonth,
                  weekdays: weekdays,
                  diasComEvento: diasComEvento,
                  isHoje: _isHoje,
                  isSelecionado: _isSelecionado,
                  onSelecionarDia: onSelecionarDia,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: BaileSulColors.cardBorder),
          // Agenda do dia selecionado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AGENDA',
                            style: TextStyle(
                              color: BaileSulColors.accentLight,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dataLabel,
                            style: const TextStyle(
                              color: BaileSulColors.headerText,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: onCriarEvento,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Criar evento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BaileSulColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (eventosDoDia.isEmpty)
                  const _AgendaVazia()
                else
                  Column(
                    children: eventosDoDia
                        .map((e) => _AgendaItem(evento: e, onVer: () => onVerEvento(e['id'])))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: BaileSulColors.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 20, color: BaileSulColors.mutedText),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.viewYear,
    required this.viewMonth,
    required this.weekdays,
    required this.diasComEvento,
    required this.isHoje,
    required this.isSelecionado,
    required this.onSelecionarDia,
  });

  final int viewYear;
  final int viewMonth;
  final List<String> weekdays;
  final Set<int> diasComEvento;
  final bool Function(int) isHoje;
  final bool Function(int) isSelecionado;
  final ValueChanged<int> onSelecionarDia;

  @override
  Widget build(BuildContext context) {
    final int diasNoMes = DateTime(viewYear, viewMonth + 2, 0).day;
    // DateTime.weekday: 1=segunda..7=domingo. A grade começa no domingo (D),
    // então convertemos: domingo => 0, segunda => 1, ...
    final int primeiroDiaSemana = DateTime(viewYear, viewMonth + 1, 1).weekday % 7;

    final List<int?> celulas = <int?>[];
    for (int i = 0; i < primeiroDiaSemana; i++) {
      celulas.add(null);
    }
    for (int d = 1; d <= diasNoMes; d++) {
      celulas.add(d);
    }

    return Column(
      children: [
        Row(
          children: weekdays
              .map((w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: const TextStyle(
                          color: BaileSulColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: celulas.length,
          itemBuilder: (context, index) {
            final int? dia = celulas[index];
            if (dia == null) return const SizedBox.shrink();
            return _CalendarCell(
              dia: dia,
              selecionado: isSelecionado(dia),
              hoje: isHoje(dia) && !isSelecionado(dia),
              temEvento: diasComEvento.contains(dia),
              onTap: () => onSelecionarDia(dia),
            );
          },
        ),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.dia,
    required this.selecionado,
    required this.hoje,
    required this.temEvento,
    required this.onTap,
  });

  final int dia;
  final bool selecionado;
  final bool hoje;
  final bool temEvento;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    Color texto = BaileSulColors.headerText;
    Border? borda;

    if (selecionado) {
      bg = BaileSulColors.accent;
      texto = Colors.white;
    } else if (hoje) {
      bg = const Color(0x0F0D496B);
      texto = BaileSulColors.accent;
      borda = Border.all(color: const Color(0x590D496B));
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: borda,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dia',
                style: TextStyle(
                  color: texto,
                  fontSize: 13,
                  fontWeight: selecionado || hoje ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (temEvento) ...[
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selecionado ? Colors.white70 : BaileSulColors.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaVazia extends StatelessWidget {
  const _AgendaVazia();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 36,
            color: BaileSulColors.accentLight.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nenhum evento nesta data',
            style: TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Clique em "Criar evento" para adicionar',
            style: TextStyle(
              color: BaileSulColors.headerText.withValues(alpha: 0.5),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaItem extends StatelessWidget {
  const _AgendaItem({required this.evento, required this.onVer});

  final Map<String, dynamic> evento;
  final VoidCallback onVer;

  String _statusLabel(String? status) {
    switch (status) {
      case 'agendado':
        return 'Agendado';
      case 'finalizado':
        return 'Realizado';
      default:
        return status ?? '';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'agendado':
        return const Color(0xFF0F6E56);
      case 'finalizado':
        return BaileSulColors.mutedText;
      case 'cancelado':
        return const Color(0xFFC24545);
      default:
        return BaileSulColors.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? status = evento['status']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: BaileSulColors.pageBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: BaileSulColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento['titulo']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onVer,
            style: ElevatedButton.styleFrom(
              backgroundColor: BaileSulColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 32),
              textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}

class _ProximosList extends StatelessWidget {
  const _ProximosList({required this.itens});

  final List<Map<String, dynamic>> itens;

  String _sufixo(int? dias) {
    if (dias == 0) return 'Hoje';
    if (dias == 1) return 'Amanhã';
    if (dias != null) return 'Em $dias dias';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: itens.map((e) {
        final int? dias = e['_dias'] as int?;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BaileSulColors.cardBorder),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['titulo']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _sufixo(dias),
                      style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/meus-eventos-comunidade'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BaileSulColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Ver'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Text(
        texto,
        style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 13.5),
      ),
    );
  }
}
