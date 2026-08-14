import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'pesquisa_padrao_eventos.dart' show EventoApi;

/// Cores compartilhadas do app BaileSul.
class BaileSulColors {
  static const Color dark = Color(0xFF0D0F16);
  static const Color accent = Color(0xFF0D496B);
  static const Color accentHover = Color(0xFF0F5A84);
  static const Color accentLight = Color(0xFF60B8E0);
  static const Color accentSoft = Color(0xFFF0E5FF);
  static const Color pageBackground = Color(0xFFE8ECF0);
  static const Color cardBackground = Color(0xFFF8F8F8);
  static const Color cardBorder = Color(0xFFE2E6EA);
  static const Color headerText = Color(0xFF111111);
  static const Color mutedText = Color(0xFF546173);
  static const Color inputFill = Color(0xFF7C9AB1);
  static const Color styleSurfaceA = Color(0xFFD4E0EB);
  static const Color styleSurfaceB = Color(0xFFB8CAD8);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentLight, Color(0xFF6A4CFF)],
  );

  static const LinearGradient heroOverlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xF00D0F16),
      Color(0x990D496B),
      Color(0xE60D0F16),
    ],
  );

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: accent.withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    const BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
}

class _HomeTypography {
  static const TextStyle heroTitle = TextStyle(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.8,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: BaileSulColors.headerText,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.15,
  );

  static TextStyle sectionSubtitle = TextStyle(
    color: BaileSulColors.headerText.withValues(alpha: 0.52),
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle statValue = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1,
  );

  static TextStyle statLabel = TextStyle(
    color: Colors.white.withValues(alpha: 0.58),
    fontSize: 10,
    letterSpacing: 1.1,
    fontWeight: FontWeight.w600,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Mesmos tipos de evento exibidos na home do site (TIPOS_EVENTO em
  // frontend/src/paginas/home/home.jsx), com rótulos de
  // frontend/src/utils/events.js (TIPO_EVENTO_LABELS).
  static const List<_StyleItem> _styles = [
    _StyleItem('musical', 'Musical', 'Bailes e música ao vivo', '🪗'),
    _StyleItem('almoco', 'Almoço', 'Almoços comunitários', '🍽️'),
    _StyleItem('bingo', 'Bingo', 'Bingos e sorteios', '🎱'),
    _StyleItem('expos', 'Expos', 'Exposições e feiras', '🎪'),
    _StyleItem('futebol', 'Futebol', 'Jogos e torneios', '⚽'),
  ];

  List<EventoApi> _eventosApi = <EventoApi>[];
  bool _carregandoEventos = true;

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  Future<void> _carregarEventos() async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/eventos?limite=6');
      final http.Response response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> dados = _extrairListaEventos(decoded);
        final List<EventoApi> eventos = dados
            .whereType<Map>()
            .map((Map<dynamic, dynamic> item) =>
                EventoApi.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (!mounted) return;
        setState(() {
          _eventosApi = eventos.take(6).toList();
          _carregandoEventos = false;
        });
        return;
      }
    } catch (_) {
      // segue para o estado vazio, igual ao comportamento do site
    }

    if (!mounted) return;
    setState(() {
      _eventosApi = <EventoApi>[];
      _carregandoEventos = false;
    });
  }

  List<dynamic> _extrairListaEventos(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final dynamic eventos =
          decoded['dados'] ?? decoded['eventos'] ?? decoded['data'] ?? decoded['rows'];
      if (eventos is List) return eventos;
    }
    return <dynamic>[];
  }

  void _showMenu() {
    MobileAppMenu.show(
      context,
      entries: MobileAppMenu.entries(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessaoUsuario.instance,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          backgroundColor: BaileSulColors.dark,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MobileHeader(
                logoHeight: 58,
                horizontalPadding: 16,
                onMenuPressed: _showMenu,
              ),
              Expanded(
                child: CustomScrollView(
                  key: const Key('home_scroll'),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    const SliverToBoxAdapter(child: _HeroBlock()),
                    SliverToBoxAdapter(
                      child: _UpcomingEventsSection(
                        eventos: _eventosApi,
                        carregando: _carregandoEventos,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _StylesSection(styles: _styles),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock();

  static const String _heroImage =
      'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=1400&q=80';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _heroImage,
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.22),
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: BaileSulColors.dark),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: BaileSulColors.heroOverlay)),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _GlowOrb(
              size: 260,
              color: BaileSulColors.accent.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -50,
            child: _GlowOrb(
              size: 220,
              color: const Color(0xFF6A4CFF).withValues(alpha: 0.22),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    const Text('Descubra os', style: _HomeTypography.heroTitle),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (Rect bounds) =>
                          BaileSulColors.accentGradient.createShader(bounds),
                      child: const Text(
                        'Melhores Bailes',
                        style: _HomeTypography.heroTitle,
                      ),
                    ),
                    const Text('da Região', style: _HomeTypography.heroTitle),
                    const SizedBox(height: 16),
                    Text(
                      'Encontre eventos, bandas e comunidades. Seu hub completo para a vida noturna da AMAUC.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _HeroButton(
                      label: 'Explorar Eventos',
                      icon: Icons.search_rounded,
                      filled: true,
                      onPressed: () =>
                          Navigator.pushNamed(context, '/pesquisa-eventos'),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(child: _HeroStat(value: '50+', label: 'EVENTOS')),
                        Expanded(child: _HeroStat(value: '30+', label: 'BANDAS')),
                        Expanded(child: _HeroStat(value: '13', label: 'CIDADES')),
                      ],
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: BaileSulColors.accent.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: BaileSulColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: _HomeTypography.statValue),
        const SizedBox(height: 4),
        Text(label, style: _HomeTypography.statLabel),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _HomeTypography.sectionTitle),
        const SizedBox(height: 6),
        Text(subtitle, style: _HomeTypography.sectionSubtitle),
      ],
    );
  }
}

class _UpcomingEventsSection extends StatelessWidget {
  const _UpcomingEventsSection({required this.eventos, required this.carregando});

  final List<EventoApi> eventos;
  final bool carregando;

  static const String _imagemPadrao =
      'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80';

  EventItem _paraEventItem(EventoApi evento) {
    String dia = '';
    String mes = '';
    final DateTime? inicio = DateTime.tryParse(evento.dataInicio);
    if (inicio != null) {
      dia = inicio.day.toString().padLeft(2, '0');
      mes = _mesesAbreviados[inicio.month - 1];
    }

    return EventItem(
      id: evento.id,
      title: evento.titulo,
      genre: evento.comunidadeNome,
      location: evento.localComCidadeEstado,
      dateTime: evento.dataFormatada,
      price: evento.valorFormatado,
      imageUrl: evento.fotoCapaUrl ?? _imagemPadrao,
      day: dia,
      month: mes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BaileSulColors.pageBackground,
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Próximos Eventos',
            subtitle: 'Os melhores bailes chegando na região',
          ),
          const SizedBox(height: 24),
          if (carregando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: BaileSulColors.accent),
              ),
            )
          else if (eventos.isEmpty)
            const _EventosVazio()
          else
            ...eventos.map(
              (evento) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _EventCard(event: _paraEventItem(evento)),
              ),
            ),
          const SizedBox(height: 4),
          _PrimaryOutlineButton(
            label: 'Ver todos os eventos',
            icon: Icons.keyboard_arrow_down_rounded,
            onPressed: () => Navigator.pushNamed(context, '/pesquisa-eventos'),
          ),
        ],
      ),
    );
  }
}

class _EventosVazio extends StatelessWidget {
  const _EventosVazio();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_month_rounded, size: 36, color: BaileSulColors.mutedText),
          const SizedBox(height: 12),
          const Text(
            'Nenhum evento encontrado',
            style: TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Seja o primeiro a criar um evento!',
            style: TextStyle(
              color: BaileSulColors.mutedText.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryOutlineButton extends StatelessWidget {
  const _PrimaryOutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: BaileSulColors.cardShadow,
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 22),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: BaileSulColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final EventItem event;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: BaileSulColors.cardShadow,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
                context,
                '/evento',
                arguments: event,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 172,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
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
                          size: 52,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    if (event.day.isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _DateBadge(day: event.day, month: event.month),
                      ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _Badge(label: event.price, filled: false),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.genre.isNotEmpty)
                      Text(
                        event.genre.toUpperCase(),
                        style: const TextStyle(
                          color: BaileSulColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MetaRow(icon: Icons.location_on_rounded, text: event.location),
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

/// Selo com dia/mês sobre a imagem do card, espelhando `.eventCardDateBadge`
/// (frontend/src/styles/shared.module.css).
class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.day, required this.month});

  final String day;
  final String month;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BaileSulColors.accent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: BaileSulColors.accent.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            Text(
              month.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: BaileSulColors.accent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: BaileSulColors.accent.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: BaileSulColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: BaileSulColors.accent),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: BaileSulColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Seção "Busque por Tipo de Evento" — espelha `.stylesSection` do site
/// (frontend/src/paginas/home/home.module.css), que usa fundo escuro
/// (`--dark`), diferente da seção de eventos acima que é clara.
class _StylesSection extends StatelessWidget {
  const _StylesSection({required this.styles});

  final List<_StyleItem> styles;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BaileSulColors.dark,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DecoLine(),
          const SizedBox(height: 32),
          Text(
            'FILTRE PELO QUE VOCÊ PROCURA',
            style: TextStyle(
              color: BaileSulColors.accentLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Busque por Tipo de Evento',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'De bailes a bingos. Encontre o evento certo pra sua próxima saída.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          for (int i = 0; i < styles.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _StylePill(style: styles[i]),
          ],
          const SizedBox(height: 32),
          _DecoLine(),
        ],
      ),
    );
  }
}

/// Linha decorativa em gradiente, espelhando `.stylesDecoLine`.
class _DecoLine extends StatelessWidget {
  const _DecoLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            BaileSulColors.accent.withValues(alpha: 0.7),
            BaileSulColors.accentLight,
            BaileSulColors.accent.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Item de tipo de evento em formato de "pill", espelhando `.stylePill`.
class _StylePill extends StatelessWidget {
  const _StylePill({required this.style});

  final _StyleItem style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushNamed(context, '/pesquisa-eventos'),
          splashColor: BaileSulColors.accent.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(style.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        style.desc,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.52),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.genre,
    required this.location,
    required this.dateTime,
    required this.price,
    required this.imageUrl,
    this.description = '',
    this.status = '',
    this.address = '',
    this.organizer = '',
    this.startDateTime = '',
    this.endDateTime = '',
    this.day = '',
    this.month = '',
  });

  final int id;
  final String title;
  final String genre;
  final String location;
  final String dateTime;
  final String price;
  final String imageUrl;
  final String description;
  final String status;
  final String address;
  final String organizer;
  final String startDateTime;
  final String endDateTime;

  /// Dia (2 dígitos) e mês abreviado (3 letras minúsculas) usados no selo de
  /// data sobre a imagem do card, espelhando o `eventCardDateBadge` do site
  /// (frontend/src/styles/shared.module.css).
  final String day;
  final String month;
}

/// Meses abreviados em pt-BR (minúsculos, sem ponto) — mesmo formato que
/// `toLocaleDateString('pt-BR', { month: 'short' })` produz no site.
const List<String> _mesesAbreviados = <String>[
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

class _StyleItem {
  const _StyleItem(this.value, this.label, this.desc, this.emoji);

  final String value;
  final String label;
  final String desc;
  final String emoji;
}
