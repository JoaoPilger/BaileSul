import 'package:flutter/material.dart';

/// Item de navegação exibido na linha inferior do rodapé.
class FooterNavLink {
  const FooterNavLink({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// Rodapé mobile: logo centralizada, copyright e três links distribuídos.
class MobileFooter extends StatelessWidget {
  const MobileFooter({
    super.key,
    this.logoHeight = 88,
    this.horizontalPadding = 20,
    this.navLinks = const [
      FooterNavLink(label: 'Log in'),
      FooterNavLink(label: 'Log in'),
      FooterNavLink(label: 'Log in'),
    ],
  });

  static const Color backgroundColor = Color(0xFF0A0C12);
  static const Color copyrightColor = Color(0xFFB8C0CC);

  final double logoHeight;
  final double horizontalPadding;
  final List<FooterNavLink> navLinks;

  @override
  Widget build(BuildContext context) {
    assert(
      navLinks.length == 3,
      'MobileFooter espera exatamente 3 links (esquerda, centro, direita).',
    );

    final TextStyle? linkStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        );

    return Material(
      color: backgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            28,
            horizontalPadding,
            20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'images/logo.png',
                height: logoHeight,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text(
                '© BaileSul – Todos os direitos reservados.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: copyrightColor,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _FooterLinkButton(
                        link: navLinks[0],
                        style: linkStyle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _FooterLinkButton(
                        link: navLinks[1],
                        style: linkStyle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _FooterLinkButton(
                        link: navLinks[2],
                        style: linkStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLinkButton extends StatelessWidget {
  const _FooterLinkButton({
    required this.link,
    required this.style,
  });

  final FooterNavLink link;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onTap = link.onTap;
    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(link.label, style: style),
      );
    }

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(link.label, style: style),
    );
  }
}
