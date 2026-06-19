import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({Key? key}) : super(key: key);

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

  final _tituloCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();

  static const _monthNames = [
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
    'Dezembro'
  ];

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _localCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
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

  Future<void> _selecionarData(DateTime data) async {
    setState(() {
      _selectedDate = data;
      _selectedEvents = _eventosDaData(data);
      _eventsError = null;
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

  List<Widget> _buildDayHeaders() {
    const labels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return labels.map((l) => Center(child: Text(l, style: const TextStyle(fontSize: 12)))).toList();
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
    final accent = const Color(0xFF0F5166);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      monthLabel,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(children: [IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)), IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right))])
                ],
              ),
              const SizedBox(height: 18),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                childAspectRatio: 3,
                children: _buildDayHeaders()
                    .map((w) => Center(child: DefaultTextStyle(style: TextStyle(color: Colors.grey.shade600, fontSize: 12), child: w)))
                    .toList(),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.6),
                itemBuilder: (context, index) {
                  final d = days[index];
                  if (d == null) return const SizedBox.shrink();
                  final isToday = DateTime.now().year == d.year && DateTime.now().month == d.month && DateTime.now().day == d.day;
                  final isSelected = d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;

                  return GestureDetector(
                    onTap: () => _selecionarData(d),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: isSelected ? null : Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            if (isSelected)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
                                  ),
                                ),
                              ),
                            Positioned.fill(
                              child: Center(
                                child: Text(
                                  '${d.day}',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : (isToday ? accent : Colors.black87),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (_temEventoNaData(d))
                              Positioned(
                                top: -10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 2)],
                                    ),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsCard() {
    final formatted = '${_selectedDate.day} de ${_monthNames[_selectedDate.month - 1]} de ${_selectedDate.year}';
    final accent = const Color(0xFF0F5166);

    return Container(
      width: 340,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('AGENDA', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(formatted, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))]),
                const SizedBox.shrink()
              ],
            ),
          ),
          const Divider(height: 1),
          if (_loadingEvents)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36.0, horizontal: 18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_eventsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 18),
              child: Column(
                children: [
                  Icon(Icons.cloud_off_rounded, size: 44, color: Colors.blueGrey.shade200),
                  const SizedBox(height: 12),
                  Text(_eventsError!, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ],
              ),
            )
          else if (_selectedEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 18),
              child: Column(
                children: [
                  Icon(Icons.event_note_outlined, size: 44, color: Colors.blueGrey.shade200),
                  const SizedBox(height: 12),
                  const Text('Nenhum evento nesta data', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Selecione outro dia no calendário', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int index = 0; index < _selectedEvents.length; index++) ...[
                    _CalendarEventCard(event: _selectedEvents[index]),
                    if (index < _selectedEvents.length - 1) const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Column(
        children: [
          MobileHeader(onMenuPressed: _showMenu),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 1000;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildCalendarCard()),
                                const SizedBox(width: 24),
                                _buildEventsCard(),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildCalendarCard(),
                                const SizedBox(height: 12),
                                _buildEventsCard(),
                              ],
                            );
                    },
                  ),
                ),
              ),
            ),
          ),
          const MobileFooter(),
        ],
      ),
    );
  }
}

class _CalendarEvent {
  const _CalendarEvent({
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
      date: parsedDate == null
          ? DateTime.now()
          : DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      title: json['titulo']?.toString() ?? 'Evento',
      genre: descricao.isNotEmpty ? descricao : 'Evento',
      location: json['local_nome']?.toString() ?? 'Local não informado',
      time: timeLabel,
      price: json['valor_ingresso']?.toString() ?? 'Consulte',
      imageUrl: json['foto_capa_url']?.toString().isNotEmpty == true
          ? json['foto_capa_url'].toString()
          : 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=900&q=80',
      organization: communityName,
      dateLabel: dateLabel,
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.event});

  final _CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFF0F5166);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.blueGrey.shade100,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 44,
                    color: accent.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  event.genre,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                _EventInfoRow(icon: Icons.calendar_month_outlined, text: event.dateLabel),
                const SizedBox(height: 8),
                _EventInfoRow(icon: Icons.location_on_rounded, text: event.location),
                const SizedBox(height: 8),
                _EventInfoRow(icon: Icons.apartment_outlined, text: event.organization),
                const SizedBox(height: 8),
                if (event.time.isNotEmpty)
                  _EventInfoRow(icon: Icons.access_time_rounded, text: event.time),
                if (event.time.isNotEmpty) const SizedBox(height: 8),
                _EventInfoRow(icon: Icons.confirmation_number_outlined, text: event.price),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventInfoRow extends StatelessWidget {
  const _EventInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F5166)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
