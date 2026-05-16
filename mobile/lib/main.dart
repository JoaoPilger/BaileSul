import 'package:flutter/material.dart';

import 'widgets/mobile_header.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BaileSul',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A4CFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color pageBackground = Color(0xFFD7D7D7);
  static const Color cardBackground = Color(0xFFF8F8F8);
  static const Color cardBorder = Color(0xFFCDCDCD);
  static const Color headerText = Color(0xFF1C2330);
  static const Color mutedText = Color(0xFF546173);
  static const Color accent = Color(0xFF8B3DFF);
  static const Color accentSoft = Color(0xFFF0E5FF);
  static const Color eventColor = Color(0xFF2E5F83);
  static const Color inputFill = Color(0xFF7C9AB1);
  static const Color footerBg = Color(0xFF0A0C12);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final DateTime _month = DateTime(2026, 5, 1);
  static final DateTime _today = DateTime(2026, 5, 15);

  DateTime _selectedDate = DateTime(2026, 5, 31);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileHeader(
            logoHeight: 60,
            horizontalPadding: 14,
            onMenuPressed: () => _showMenu(context),
          ),
          Expanded(
            child: Container(
              color: HomeScreen.pageBackground,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(6, 12, 6, 14),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CalendarCard(
                            month: _month,
                            selectedDate: _selectedDate,
                            today: _today,
                            onPreviousMonth: () {},
                            onNextMonth: () {},
                            onDateSelected: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          _EventsCard(selectedDate: _selectedDate),
                          const SizedBox(height: 14),
                          const _CreateEventCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _BrandFooter(backgroundColor: HomeScreen.footerBg),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: HomeScreen.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Calendário'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.month,
    required this.selectedDate,
    required this.today,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime selectedDate;
  final DateTime today;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cells = <Widget>[];
    final int leadingBlankCells = month.weekday % 7;
    for (var index = 0; index < leadingBlankCells; index += 1) {
      cells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= 31; day += 1) {
      final DateTime date = DateTime(month.year, month.month, day);
      cells.add(_CalendarDayCell(
        date: date,
        label: '$day',
        isSelected: _isSameDay(date, selectedDate),
        isToday: _isSameDay(date, today),
        onTap: () => onDateSelected(date),
      ));
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeScreen.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: HomeScreen.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _monthLabel(month),
                    style: const TextStyle(
                      color: HomeScreen.headerText,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _MonthArrowButton(icon: Icons.chevron_left, onPressed: onPreviousMonth),
                const SizedBox(width: 6),
                _MonthArrowButton(icon: Icons.chevron_right, onPressed: onNextMonth),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(child: Center(child: _WeekdayLabel('Dom'))),
                Expanded(child: Center(child: _WeekdayLabel('Seg'))),
                Expanded(child: Center(child: _WeekdayLabel('Ter'))),
                Expanded(child: Center(child: _WeekdayLabel('Qua'))),
                Expanded(child: Center(child: _WeekdayLabel('Qui'))),
                Expanded(child: Center(child: _WeekdayLabel('Sex'))),
                Expanded(child: Center(child: _WeekdayLabel('Sáb'))),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
              children: cells,
            ),
          ],
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _monthLabel(DateTime date) {
    const List<String> months = [
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

    return '${months[date.month - 1]} ${date.year}';
  }
}

class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: HomeScreen.accentSoft,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFE0CBFF)),
        ),
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          color: HomeScreen.accent,
          icon: Icon(icon),
          tooltip: 'Navegar mês',
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: HomeScreen.mutedText,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.label,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final String label;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected
        ? HomeScreen.accent
        : isToday
            ? const Color(0xFFFF6AAE)
            : const Color(0xFFD8D8D8);
    final Color backgroundColor = isSelected
        ? HomeScreen.accentSoft
        : isToday
            ? const Color(0xFFFFEEF6)
            : Colors.white;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: borderColor, width: isSelected || isToday ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? HomeScreen.accent : HomeScreen.headerText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsCard extends StatelessWidget {
  const _EventsCard({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeScreen.cardBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: HomeScreen.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        height: 178,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 22, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Eventos - ${_formatDate(selectedDate)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: HomeScreen.headerText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 44,
                      color: HomeScreen.eventColor,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Nenhum evento nesta data',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HomeScreen.eventColor,
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 14,
              bottom: 14,
              child: Container(
                width: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF7EABC6),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateEventCard extends StatelessWidget {
  const _CreateEventCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeScreen.cardBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: HomeScreen.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Criar Evento',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HomeScreen.headerText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            const _StaticInputField(),
            const SizedBox(height: 10),
            const _StaticInputField(),
            const SizedBox(height: 10),
            const _StaticInputField(),
            const SizedBox(height: 10),
            const _StaticInputField(),
            const SizedBox(height: 10),
            const _StaticInputField(),
            const SizedBox(height: 10),
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: HomeScreen.inputFill,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
              child: const Text(
                'imagem do evento',
                style: TextStyle(
                  color: Color(0xFF15202A),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 72,
                height: 22,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D4668),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  child: const Text(
                    'Finalizar',
                    style: TextStyle(fontSize: 9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticInputField extends StatelessWidget {
  const _StaticInputField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: HomeScreen.inputFill,
        borderRadius: BorderRadius.circular(1),
      ),
      alignment: Alignment.centerLeft,
      child: const Text(
        'campus de input',
        style: TextStyle(
          color: Color(0xFF15202A),
          fontSize: 8,
        ),
      ),
    );
  }
}

class _BrandFooter extends StatelessWidget {
  const _BrandFooter({required this.backgroundColor});

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'images/logo.png',
            height: 50,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          const Text(
            '© BaileSul - Todos os direitos reservados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB8C0CC),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileHeader(
            logoHeight: 18,
            horizontalPadding: 14,
            onMenuPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Container(
              color: HomeScreen.pageBackground,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: HomeScreen.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Login',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: HomeScreen.headerText,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 42),
                              _LoginLabel('Email', context),
                              const SizedBox(height: 6),
                              const _LoginField(),
                              const SizedBox(height: 24),
                              _LoginLabel('Senha', context),
                              const SizedBox(height: 6),
                              const _LoginField(obscureText: true),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 44,
                                child: FilledButton(
                                  onPressed: () {},
                                  style: FilledButton.styleFrom(
                                    backgroundColor: HomeScreen.headerText,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Text('Entrar'),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'ou',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: HomeScreen.headerText,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              const _SocialLoginButton(label: 'Google'),
                              const SizedBox(height: 10),
                              const _SocialLoginButton(label: 'Facebook'),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Não possui uma conta? ',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: HomeScreen.headerText,
                                        ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const CadastroScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: HomeScreen.accent,
                                    ),
                                    child: Text(
                                      'Cadastro',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: HomeScreen.accent,
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
}

class CadastroScreen extends StatelessWidget {
  const CadastroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileHeader(
            logoHeight: 18,
            horizontalPadding: 14,
            onMenuPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Container(
              color: HomeScreen.pageBackground,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: HomeScreen.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Cadastro',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: HomeScreen.headerText,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 26),
                              Text(
                                'Tipo de conta:',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: HomeScreen.headerText,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              _AccountTypeButton(
                                label: 'Pessoal',
                                selected: true,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const PersonalRegistrationScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _AccountTypeButton(
                                label: 'Comunidade',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const CommunityRegistrationScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _AccountTypeButton(
                                label: 'Banda',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const BandRegistrationScreen(),
                                    ),
                                  );
                                },
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
          ),
        ],
      ),
    );
  }
}

class PersonalRegistrationScreen extends StatelessWidget {
  const PersonalRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _RegistrationScreenShell(
        title: 'Cadastro',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Informações Básicas'),
            const SizedBox(height: 18),
            const _RegistrationField(label: 'Nome Completo'),
            const SizedBox(height: 12),
            const _RegistrationField(label: 'Email*'),
            const SizedBox(height: 12),
            const _RegistrationField(label: 'Telefone*'),
            const SizedBox(height: 12),
            const _RegistrationField(label: 'CPF*'),
            const SizedBox(height: 20),
            const _SectionTitle('Imagem de Perfil'),
            const SizedBox(height: 12),
            const _UploadBox(label: 'Clique para fazer upload de imagens', height: 160),
            const SizedBox(height: 8),
            const _TermsRow(),
            const SizedBox(height: 6),
            const _ActionRow(
              primaryLabel: 'Cadastrar-se',
              secondaryLabel: 'Cancelar',
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityRegistrationScreen extends StatelessWidget {
  const CommunityRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _RegistrationScreenShell(
        title: 'Cadastro',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Informações Básicas'),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(child: _RegistrationField(label: 'Nome da Comunidade*')),
                SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'Telefone*')),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: _RegistrationField(label: 'Email*')),
                SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'CNPJ*')),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Imagem de Capa'),
            const SizedBox(height: 12),
            const _UploadBox(
              label: 'Clique para fazer upload de imagens',
              height: 84,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Localização'),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(child: _RegistrationField(label: 'CEP *')),
                SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'Cidade *')),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: _RegistrationField(label: 'Bairro *')),
                SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'Rua *')),
              ],
            ),
            const SizedBox(height: 12),
            const _RegistrationField(label: 'Referência'),
            const SizedBox(height: 12),
            const _MapPreviewBox(height: 160),
            const SizedBox(height: 8),
            const _TermsRow(),
            const SizedBox(height: 6),
            const _ActionRow(
              primaryLabel: 'Salvar',
              secondaryLabel: 'Cancelar',
            ),
          ],
        ),
      ),
    );
  }
}

class BandRegistrationScreen extends StatelessWidget {
  const BandRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _RegistrationScreenShell(
        title: 'Cadastro',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Informações da Banda'),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(child: _RegistrationField(label: 'Nome da Banda*')),
                SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'Telefone*')),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: _RegistrationField(label: 'Email*')),
                SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'CNPJ*')),
              ],
            ),
            const SizedBox(height: 20),
            const _UploadBox(label: 'Imagem da Banda', height: 100),
            const SizedBox(height: 20),
            const _SectionTitle('Localização'),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(child: _RegistrationField(label: 'CEP *')),
                SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'Cidade *')),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: _RegistrationField(label: 'Bairro *')),
                SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'Rua *')),
              ],
            ),
            const SizedBox(height: 12),
            const _RegistrationField(label: 'Referência'),
            const SizedBox(height: 8),
            const _TermsRow(),
            const SizedBox(height: 6),
            const _ActionRow(
              primaryLabel: 'Salvar',
              secondaryLabel: 'Cancelar',
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationScreenShell extends StatelessWidget {
  const _RegistrationScreenShell({
    required this.title,
    required this.content,
  });

  final String title;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MobileHeader(
          logoHeight: 18,
          horizontalPadding: 14,
          onMenuPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Container(
            color: HomeScreen.pageBackground,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: HomeScreen.cardBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(40, 30, 40, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: HomeScreen.headerText,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            const Divider(height: 1, thickness: 1, color: Color(0xFFE9E9E9)),
                            const SizedBox(height: 20),
                            content,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: HomeScreen.headerText,
            fontWeight: FontWeight.w400,
          ),
    );
  }
}

class _RegistrationField extends StatelessWidget {
  const _RegistrationField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: HomeScreen.inputFill,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HomeScreen.headerText,
            ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({required this.label, required this.height});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFCFD8DF),
        border: Border.all(
          color: const Color(0xFF9DB8C8),
          width: 1,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF295F83),
            ),
      ),
    );
  }
}

class _MapPreviewBox extends StatelessWidget {
  const _MapPreviewBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD8D8D8)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.map_outlined,
        size: 72,
        color: Color(0xFFFF6A00),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: false, onChanged: (_) {}),
        Expanded(
          child: Text(
            'termos de compartilhamento de informações',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HomeScreen.headerText,
                ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  final String primaryLabel;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 34,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD7D7D7),
                foregroundColor: HomeScreen.headerText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: Text(secondaryLabel),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: SizedBox(
            height: 34,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0E5880),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: Text(primaryLabel),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginLabel extends StatelessWidget {
  const _LoginLabel(this.label, this.contextRef);

  final String label;
  final BuildContext contextRef;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(contextRef).textTheme.titleMedium?.copyWith(
            color: HomeScreen.headerText,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({this.obscureText = false});

  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HomeScreen.inputFill,
        borderRadius: BorderRadius.circular(2),
      ),
      child: TextField(
        obscureText: obscureText,
        style: const TextStyle(color: HomeScreen.headerText),
        cursorColor: HomeScreen.headerText,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: HomeScreen.cardBorder,
          foregroundColor: HomeScreen.headerText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AccountTypeButton extends StatelessWidget {
  const _AccountTypeButton({
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: HomeScreen.inputFill,
          foregroundColor: HomeScreen.headerText,
          side: BorderSide(
            color: selected ? const Color(0xFF1180E8) : HomeScreen.inputFill,
            width: selected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
