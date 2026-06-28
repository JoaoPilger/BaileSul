import 'package:flutter/material.dart';

import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class PerfilBandaPage extends StatefulWidget {
  const PerfilBandaPage({super.key});

  @override
  State<PerfilBandaPage> createState() => _PerfilBandaPageState();
}

class _PerfilBandaPageState extends State<PerfilBandaPage> {
  final ScrollController _scrollController = ScrollController();
  bool _expandedBio = false;
  bool _seguindo = false;

  // GlobalKeys to enable scrolling to sections
  final GlobalKey _keySobre = GlobalKey();
  final GlobalKey _keyEventos = GlobalKey();
  final GlobalKey _keyGaleria = GlobalKey();
  final GlobalKey _keyAvaliacoes = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final BuildContext? context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _abrirMenu() {
    MobileAppMenu.show(
      context,
      entries: MobileAppMenu.entries(context),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaileSulColors.dark,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MobileHeader(
              logoHeight: 58,
              horizontalPadding: 16,
              onMenuPressed: _abrirMenu,
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner and Profile image section
                      _buildHeaderBanner(),

                      // Band Title and Action buttons
                      _buildHeaderInfo(),

                      // Tab Bar navigation
                      _buildTabBarNav(),

                      // "Sobre a Banda" section
                      Container(
                        key: _keySobre,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: _buildSobreSection(),
                      ),

                      const Divider(height: 1, color: BaileSulColors.cardBorder),

                      // Stats Row
                      _buildStatsRow(),

                      const Divider(height: 1, color: BaileSulColors.cardBorder),

                      // Galeria Section
                      Container(
                        key: _keyGaleria,
                        color: BaileSulColors.pageBackground.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: _buildGaleriaSection(),
                      ),

                      const Divider(height: 1, color: BaileSulColors.cardBorder),

                      // Próximos Eventos Section
                      Container(
                        key: _keyEventos,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: _buildEventosSection(),
                      ),

                      const Divider(height: 1, color: BaileSulColors.cardBorder),

                      // Avaliações da Banda Section
                      Container(
                        key: _keyAvaliacoes,
                        color: BaileSulColors.pageBackground.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: _buildAvaliacoesSection(),
                      ),

                      // Footer
                      const MobileFooter(
                        logoHeight: 52,
                        horizontalPadding: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background banner image
        Image.network(
          'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?auto=format&fit=crop&w=800&q=80',
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [BaileSulColors.accent, BaileSulColors.dark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.music_note, color: Colors.white24, size: 64),
            );
          },
        ),
        // Overlay for dark visual touch at the bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Profile picture overlapping
        Positioned(
          bottom: -45,
          left: 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Banda',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              // Camera edit icon at bottom right of avatar
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Editar foto de perfil.')),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Band Name
          const Text(
            'Banda exemplo',
            style: TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Florianópolis, SC',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chips
          Row(
            children: [
              _buildTagChip('Banda'),
              const SizedBox(width: 8),
              _buildTagChip('Ao vivo'),
            ],
          ),
          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _seguindo = !_seguindo;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _seguindo
                                ? 'Você começou a seguir a banda.'
                                : 'Você deixou de seguir a banda.',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D496B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      _seguindo ? 'Seguindo' : 'Seguir',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Informações de contato em breve.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black38, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Contato',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTabBarNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton('Sobre', () => _scrollToSection(_keySobre)),
          _buildTabButton('Eventos', () => _scrollToSection(_keyEventos)),
          _buildTabButton('Galeria', () => _scrollToSection(_keyGaleria)),
          _buildTabButton('Avaliações', () => _scrollToSection(_keyAvaliacoes)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSobreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sobre a banda',
          style: TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),

        // Collapsible Text description
        Text(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer in diam purus. '
          'Nullam blandit, lectus pretium pellentesque dapibus, augue tellus finibus nibh, '
          'a imperdiet eros urna in mi. Sed metus ipsum, ornare a sapien vel, congue tempus nibh.'
          '${_expandedBio ? ' Com repertório dinâmico e animado, a banda se destaca na animação de grandes públicos.' : ''}',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 4),

        // Toggle button
        InkWell(
          onTap: () {
            setState(() {
              _expandedBio = !_expandedBio;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expandedBio ? 'Ver menos' : 'Ver mais',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Icon(
                _expandedBio ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.black87,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Info List Row Items
        _buildSobreInfoRow(Icons.location_on_outlined, 'Localização', 'Florianópolis, SC'),
        const SizedBox(height: 12),
        _buildSobreInfoRow(Icons.album_outlined, 'Formação', 'Desde 2018'),
        const SizedBox(height: 12),
        _buildSobreInfoRow(Icons.music_note_outlined, 'Estilo musical', 'Sertanejo, pop'),
        const SizedBox(height: 12),
        _buildSobreInfoRow(Icons.groups_outlined, 'Integrantes', '6 membros'),
        const SizedBox(height: 12),

        // Social networks item
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.link_outlined, size: 20, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Site/redes sociais',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildSocialIconButton(Icons.facebook, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Acessando Facebook...')),
                        );
                      }),
                      const SizedBox(width: 8),
                      _buildSocialIconButton(Icons.camera_alt, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Acessando Instagram...')),
                        );
                      }),
                      const SizedBox(width: 8),
                      _buildSocialIconButton(Icons.music_note, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Acessando TikTok...')),
                        );
                      }),
                      const SizedBox(width: 8),
                      _buildSocialIconButton(Icons.phone, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Acessando WhatsApp...')),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSobreInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          _buildStatCol(Icons.music_note_outlined, '10', 'Eventos\nrealizados'),
          _buildVerticalDivider(),
          _buildStatCol(Icons.groups_outlined, '1250', 'Seguidores'),
          _buildVerticalDivider(),
          _buildStatCol(Icons.star_outline, '4.8', '150 avaliações'),
          _buildVerticalDivider(),
          _buildStatCol(Icons.calendar_month_outlined, '6', 'Próximos\neventos'),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStatCol(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: Colors.black54),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaleriaSection() {
    final List<String> imageUrls = [
      'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&w=400&q=80',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Galeria',
              style: TextStyle(
                color: BaileSulColors.headerText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Acessando galeria completa...')),
                );
              },
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  color: Color(0xFF0D496B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Scrollable row
        Stack(
          alignment: Alignment.centerRight,
          children: [
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        imageUrls[index],
                        width: 170,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 170,
                            height: 110,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            // Right scroll chevron arrow
            GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  _scrollController.offset + 100,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.chevron_right, color: Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventosSection() {
    final List<Map<String, String>> eventosMock = [
      {
        'titulo': 'FESTA TERCEIRÃO IFC',
        'data': '01/01/2000',
        'hora': '00:00',
        'cidade': 'Concórdia, SC',
        'confirmados': '850/1000 confirmados',
        'imagem': 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=300&q=80',
      },
      {
        'titulo': 'SHOW REGIONAL BAILESUL',
        'data': '15/07/2026',
        'hora': '22:00',
        'cidade': 'Florianópolis, SC',
        'confirmados': '450/600 confirmados',
        'imagem': 'https://images.unsplash.com/photo-1506157786151-b8491531f063?auto=format&fit=crop&w=300&q=80',
      },
      {
        'titulo': 'BAILE DA CERVEJA CTG',
        'data': '05/09/2026',
        'hora': '23:30',
        'cidade': 'Lages, SC',
        'confirmados': '950/1200 confirmados',
        'imagem': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=300&q=80',
      },
      {
        'titulo': 'FESTIVAL DE PRIMAVERA',
        'data': '10/10/2026',
        'hora': '18:00',
        'cidade': 'Chapecó, SC',
        'confirmados': '310/500 confirmados',
        'imagem': 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?auto=format&fit=crop&w=300&q=80',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Próximos eventos',
              style: TextStyle(
                color: BaileSulColors.headerText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/pesquisa-eventos');
              },
              child: const Text(
                'Ver todos',
                style: TextStyle(
                  color: Color(0xFF0D496B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Event list
        ...eventosMock.map((ev) => _buildEventCard(ev)),
        const SizedBox(height: 12),

        // "Ver todos os eventos" button
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/pesquisa-eventos');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Colors.black38, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Ver todos os eventos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, String> ev) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: BaileSulColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
              child: Image.network(
                ev['imagem']!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.music_video, color: Colors.black26),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ev['titulo']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: BaileSulColors.headerText,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Date & Time
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 13, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          ev['data']!,
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time, size: 13, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          ev['hora']!,
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ev['cidade']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Confirmados
                    Row(
                      children: [
                        const Icon(Icons.groups_outlined, size: 13, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          ev['confirmados']!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Right Chevron
            const Icon(Icons.chevron_right, color: Colors.black45),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAvaliacoesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avaliações da banda',
          style: TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left block
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '4,8',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star_half, color: Colors.amber, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Baseado em 156 avaliações',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right block: rating distribution bars
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  _buildDistributionRow(5, 0.77, '120'),
                  const SizedBox(height: 4),
                  _buildDistributionRow(4, 0.16, '25'),
                  const SizedBox(height: 4),
                  _buildDistributionRow(3, 0.05, '7'),
                  const SizedBox(height: 4),
                  _buildDistributionRow(2, 0.02, '3'),
                  const SizedBox(height: 4),
                  _buildDistributionRow(1, 0.01, '1'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistributionRow(int stars, double ratio, String count) {
    return Row(
      children: [
        Text(
          '$stars',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, color: Colors.grey, size: 12),
        const SizedBox(width: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: constraints.maxWidth * ratio,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 24,
          child: Text(
            '($count)',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 10, color: Colors.black45),
          ),
        ),
      ],
    );
  }
}
