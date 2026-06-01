import 'package:flutter/material.dart';

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

  void _showMenu() {
    MobileAppMenu.show(
      context,
      entries: MobileAppMenu.entries(
        context,
        incluirInicio: true,
      ),
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
                    onTap: () => setState(() => _selectedDate = d),
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
                            if ((d.day % 7 == 0 || d.day % 14 == 0))
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
                Container(
                  height: 40,
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
                  child: TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add, color: Colors.white, size: 16), label: const Text('Criar evento', style: TextStyle(color: Colors.white))),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 18),
            child: Column(children: [Icon(Icons.event_note_outlined, size: 44, color: Colors.blueGrey.shade200), const SizedBox(height: 12), const Text('Nenhum evento nesta data', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8), Text('Selecione outro dia no calendário', style: TextStyle(color: Colors.grey.shade500))]),
          )
        ],
      ),
    );
  }

  Widget _buildCreateEventCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Criar Evento', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInputField(_tituloCtrl, 'Campo de input'),
            _buildInputField(_localCtrl, 'Campo de input'),
            _buildInputField(_descricaoCtrl, 'Campo de input'),
            _buildInputField(TextEditingController(), 'Campo de input'),
            _buildInputField(TextEditingController(), 'Campo de input'),
            const SizedBox(height: 12),
            Container(
              height: 160,
              decoration: BoxDecoration(color: Colors.blueGrey.shade200, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('imagem do evento')),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento criado (simulado)')));
              },
              child: const Text('Finalizar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: Colors.blueGrey.shade100, borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Center(child: TextField(controller: controller, decoration: InputDecoration(border: InputBorder.none, hintText: hint))),
        ),
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
                                const SizedBox(height: 12),
                                _buildCreateEventCard(),
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
