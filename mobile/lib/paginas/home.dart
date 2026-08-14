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
  // Mesmos estilos exibidos na home do site (frontend/src/paginas/home/home.jsx).
  static const List<_StyleItem> _styles = [
    _StyleItem('Gaúcha', 'Chamamé e ginga', Icons.nightlife_rounded, 1),
    _StyleItem('Vanera', 'Ritmo do sul', Icons.graphic_eq_rounded, 0),
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
                        'melhores bailes',
                        style: _HomeTypography.heroTitle,
                      ),
                    ),
                    const Text('da região', style: _HomeTypography.heroTitle),
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
    this.eyebrow,
  });

  final String? eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: TextStyle(
              color: BaileSulColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
        ],
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
    return EventItem(
      id: evento.id,
      title: evento.titulo,
      genre: evento.comunidadeNome,
      location: evento.localComCidadeEstado,
      dateTime: evento.dataFormatada,
      price: evento.valorFormatado,
      imageUrl: evento.fotoCapaUrl ?? _imagemPadrao,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BaileSulColors.pageBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _Badge(label: event.genre, filled: true),
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
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MetaRow(icon: Icons.location_on_rounded, text: event.location),
                    const SizedBox(height: 6),
                    _MetaRow(icon: Icons.calendar_month_rounded, text: event.dateTime),
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

class _StylesSection extends StatelessWidget {
  const _StylesSection({required this.styles});

  final List<_StyleItem> styles;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BaileSulColors.pageBackground,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  BaileSulColors.accent.withValues(alpha: 0.35),
                  BaileSulColors.accentLight.withValues(alpha: 0.6),
                  BaileSulColors.accent.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const _SectionHeader(
            eyebrow: 'Filtre pelo seu ritmo',
            title: 'Busque por Estilo',
            subtitle: 'Cada ritmo tem sua alma. Encontre o evento que faz seu corpo mexer.',
          ),
          const SizedBox(height: 22),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: styles.length,
            itemBuilder: (context, index) => _StyleTile(style: styles[index]),
          ),
        ],
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({required this.style});

  final _StyleItem style;

  @override
  Widget build(BuildContext context) {
    final Color surface = style.variant == 0
        ? BaileSulColors.styleSurfaceA
        : BaileSulColors.styleSurfaceB;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: BaileSulColors.accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pushNamed(context, '/pesquisa-eventos'),
          splashColor: BaileSulColors.accent.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Icon(
                    style.icon,
                    size: 26,
                    color: BaileSulColors.headerText.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  style.label,
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  style.desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: BaileSulColors.mutedText.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
}

class _StyleItem {
  const _StyleItem(this.label, this.desc, this.icon, this.variant);

  final String label;
  final String desc;
  final IconData icon;
  final int variant;
}
