import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

/// Rota: `/calendario` — espelha frontend/src/paginas/calendario/calendario.jsx.
class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime _visibleMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  List<_CalendarEvent> _allEvents = <_CalendarEvent>[];
  List<_CalendarEvent> _selectedEvents = <_CalendarEvent>[];
  bool _loadingEvents = false;
  String? _eventsError;

  static const List<String> _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static const List<String> _weekdayLabels = [
    'DOM',
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SÁB',
  ];

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  void _selecionarData(DateTime data) {
    setState(() {
      _selectedDate = data;
      _selectedEvents = _eventosDaData(data);
    });
  }

  List<_CalendarEvent> _eventosDaData(DateTime data) {
    return _allEvents.where((event) => _mesmaData(event.date, data)).toList();
  }

  bool _temEventoNaData(DateTime data) {
    return _allEvents.any((event) => _mesmaData(event.date, data));
  }

  bool _mesmaData(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _carregarEventos() async {
    setState(() {
      _loadingEvents = true;
      _eventsError = null;
      _allEvents = <_CalendarEvent>[];
      _selectedEvents = <_CalendarEvent>[];
    });

    try {
      final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/eventos${SessaoUsuario.instance.autenticado ? '/calendario' : ''}',
      );

      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json',
      };
      final String? token = SessaoUsuario.instance.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final http.Response response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Falha ao carregar eventos (${response.statusCode}).');
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> rows = decoded is List ? decoded : <dynamic>[];

      final List<_CalendarEvent> eventos = rows
          .map((dynamic item) => _CalendarEvent.fromApi(item as Map<String, dynamic>))
          .whereType<_CalendarEvent>()
          .toList();

      if (!mounted) return;
      setState(() {
        _allEvents = eventos;
        _selectedEvents = _eventosDaData(_selectedDate);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _eventsError = 'Não foi possível carregar os eventos do dia.';
      });
    }

    if (!mounted) return;
    setState(() {
      _loadingEvents = false;
    });
  }

  void _showMenu() {
    MobileAppMenu.show(
      context,
      entries: MobileAppMenu.entries(context),
    );
  }

  void _abrirEvento(_CalendarEvent event) {
    Navigator.pushNamed(
      context,
      '/evento',
      arguments: EventItem(
        id: event.id,
        title: event.title,
        genre: event.genre,
        location: event.location,
        dateTime: event.dateLabel,
        price: event.price,
        imageUrl: event.imageUrl,
        organizer: event.organization,
      ),
    );
  }

  List<DateTime?> _computeCalendarDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // Sunday=0

    final totalSlots = ((startWeekday + daysInMonth) / 7).ceil() * 7;
    final days = <DateTime?>[];
    for (var i = 0; i < totalSlots; i++) {
      final dayIndex = i - startWeekday + 1;
      if (dayIndex < 1 || dayIndex > daysInMonth) {
        days.add(null);
      } else {
        days.add(DateTime(month.year, month.month, dayIndex));
      }
    }
    return days;
  }

  Widget _buildCalendarCard() {
    final days = _computeCalendarDays(_visibleMonth);
    final monthLabel = '${_monthNames[_visibleMonth.month - 1]} de ${_visibleMonth.year}';

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    monthLabel,
                    style: const TextStyle(
                      color: BaileSulColors.headerText,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _NavButton(icon: Icons.chevron_left_rounded, onPressed: _prevMonth),
                const SizedBox(width: 8),
                _NavButton(icon: Icons.chevron_right_rounded, onPressed: _nextMonth),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: _weekdayLabels
                  .map(
                    (w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: TextStyle(
                            color: BaileSulColors.mutedText.withValues(alpha: 0.75),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final d = days[index];
                if (d == null) return const SizedBox.shrink();
                final now = DateTime.now();
                final isToday = now.year == d.year && now.month == d.month && now.day == d.day;
                final isSelected = _mesmaData(d, _selectedDate);
                final hasEvent = _temEventoNaData(d);

                return _CalendarCell(
                  day: d.day,
                  isToday: isToday,
                  isSelected: isSelected,
                  hasEvent: hasEvent,
                  onTap: () => _selecionarData(d),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaCard() {
    final selectedDate = _selectedDate;
    final weekday = _weekdayFullName(selectedDate.weekday);
    final dateLabel =
        '$weekday, ${selectedDate.day} de ${_monthNames[selectedDate.month - 1]} de ${selectedDate.year}';
    final bool podeCriarEvento = SessaoUsuario.instance.podeCriarEvento || !SessaoUsuario.instance.autenticado;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AGENDA',
                        style: TextStyle(
                          color: BaileSulColors.accentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: BaileSulColors.headerText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (podeCriarEvento) ...[
                  const SizedBox(width: 10),
                  _CriarEventoButton(
                    onPressed: () => Navigator.pushNamed(context, '/criar-evento'),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: BaileSulColors.cardBorder),
          if (_loadingEvents)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: BaileSulColors.accent)),
            )
          else if (_eventsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  Icon(Icons.cloud_off_rounded, size: 40, color: BaileSulColors.mutedText.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    _eventsError!,
                    style: const TextStyle(color: BaileSulColors.mutedText, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (_selectedEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
              child: Column(
                children: [
                  Icon(Icons.event_note_outlined, size: 38, color: BaileSulColors.accentLight.withValues(alpha: 0.45)),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhum evento nesta data',
                    style: TextStyle(color: BaileSulColors.headerText, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecione outro dia no calendário',
                    style: TextStyle(color: BaileSulColors.mutedText.withValues(alpha: 0.8), fontSize: 12.5),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  for (int i = 0; i < _selectedEvents.length; i++) ...[
                    _CalendarEventCard(
                      event: _selectedEvents[i],
                      onTap: () => _abrirEvento(_selectedEvents[i]),
                    ),
                    if (i < _selectedEvents.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _weekdayFullName(int weekday) {
    const names = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];
    return names[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessaoUsuario.instance,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          backgroundColor: BaileSulColors.pageBackground,
          body: Column(
            children: [
              MobileHeader(onMenuPressed: _showMenu),
              Expanded(
                child: Container(
                  color: BaileSulColors.pageBackground,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 32,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: LayoutBuilder(
                                builder: (context, innerConstraints) {
                                  final isWide = innerConstraints.maxWidth > 900;
                                  return isWide
                                      ? Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(flex: 6, child: _buildCalendarCard()),
                                            const SizedBox(width: 20),
                                            Expanded(flex: 4, child: _buildAgendaCard()),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            _buildCalendarCard(),
                                            const SizedBox(height: 16),
                                            _buildAgendaCard(),
                                          ],
                                        );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

/// Cartão branco padrão, espelhando `.cal-card` / `.cal-aside`.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BaileSulColors.cardBorder),
        boxShadow: BaileSulColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Botão de navegação de mês, espelhando `.cal-nav-btn`.
class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onPressed,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: BaileSulColors.cardBorder),
          ),
          child: Icon(icon, size: 19, color: BaileSulColors.mutedText),
        ),
      ),
    );
  }
}

/// Botão "Criar evento", espelhando `.cal-btn-add`.
class _CriarEventoButton extends StatelessWidget {
  const _CriarEventoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BaileSulColors.accent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'Criar evento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Célula de dia do calendário, espelhando `.cal-cell`.
class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEvent,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isSelected
        ? Colors.white
        : (isToday ? BaileSulColors.accent : BaileSulColors.headerText);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? BaileSulColors.accent
                  : (isToday ? BaileSulColors.accent.withValues(alpha: 0.1) : Colors.transparent),
              border: isToday && !isSelected
                  ? Border.all(color: BaileSulColors.accent.withValues(alpha: 0.35))
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: BaileSulColors.accent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (hasEvent) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white.withValues(alpha: 0.7) : BaileSulColors.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card de evento na agenda do dia, espelhando `.cal-event-card`.
class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.event, required this.onTap});

  final _CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BaileSulColors.pageBackground,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: BaileSulColors.cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 88,
                  child: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7C9AB1), Color(0xFF0D496B)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 26,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (event.genre.isNotEmpty)
                          Text(
                            event.genre.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: BaileSulColors.accentLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BaileSulColors.headerText,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 12, color: BaileSulColors.mutedText),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: BaileSulColors.mutedText,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              event.price,
                              style: const TextStyle(
                                color: BaileSulColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
    );
  }
}

class _CalendarEvent {
  const _CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    required this.genre,
    required this.location,
    required this.time,
    required this.price,
    required this.imageUrl,
    required this.organization,
    required this.dateLabel,
  });

  final int id;
  final DateTime date;
  final String title;
  final String genre;
  final String location;
  final String time;
  final String price;
  final String imageUrl;
  final String organization;
  final String dateLabel;

  factory _CalendarEvent.fromApi(Map<String, dynamic> json) {
    final String? dataInicio = (json['data_evento'] ?? json['data_inicio'])?.toString();
    final DateTime? parsedDate = dataInicio == null || dataInicio.length < 10
        ? null
        : DateTime.tryParse(dataInicio.substring(0, 10));
    final String dateLabel = parsedDate == null
        ? ''
        : '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';

    final String descricao = json['descricao']?.toString() ?? '';
    final String communityName = (json['comunidade'] ?? json['comunidade_nome'])?.toString() ?? 'Organização não informada';
    final String horaInicio = json['hora_inicio']?.toString() ?? '';
    final String horaFim = json['hora_fim']?.toString() ?? '';
    final String timeLabel = horaInicio.isNotEmpty
        ? (horaFim.isNotEmpty ? '$horaInicio - $horaFim' : horaInicio)
        : (parsedDate == null ? '' : '${parsedDate.hour.toString().padLeft(2, '0')}h');

    return _CalendarEvent(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      date: parsedDate == null
          ? DateTime.now()
          : DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      title: json['titulo']?.toString() ?? 'Evento',
      genre: descricao.isNotEmpty ? descricao : 'Evento',
      location: json['local_nome']?.toString() ?? 'Local não informado',
      time: timeLabel,
      price: _formatarPreco(json['valor_ingresso']),
      imageUrl: json['foto_capa_url']?.toString().isNotEmpty == true
          ? json['foto_capa_url'].toString()
          : 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=900&q=80',
      organization: communityName,
      dateLabel: dateLabel,
    );
  }

  /// Formata o valor do ingresso (ex: "R$ 50,00" ou "Grátis"), espelhando o
  /// mesmo padrão usado em EventoApi.valorFormatado (pesquisa_padrao_eventos.dart).
  static String _formatarPreco(dynamic valorIngresso) {
    if (valorIngresso == null) return 'Grátis';
    final double? valor = double.tryParse(valorIngresso.toString());
    if (valor == null || valor <= 0) return 'Grátis';
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
