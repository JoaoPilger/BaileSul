import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import '../services/sessao_usuario.dart';

/// Rodapé mobile padrão: logo, copyright e acesso de sessão.
class MobileFooter extends StatefulWidget {
  const MobileFooter({
    super.key,
    this.logoHeight = 40,
    this.horizontalPadding = 16,
  });

  static const Color backgroundColor = Color(0xFF0A0C12);
  static const Color copyrightColor = Color(0xFFB8C0CC);

  final double logoHeight;
  final double horizontalPadding;

  @override
  State<MobileFooter> createState() => _MobileFooterState();
}

class _MobileFooterState extends State<MobileFooter> {
  Future<void> _onSessionTap() async {
    if (!SessaoUsuario.instance.autenticado) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    await SessaoUsuario.instance.encerrarSessao();

    final NavigatorState? navigator = appNavigatorKey.currentState;
    if (navigator != null) {
      navigator.popUntil((Route<dynamic> route) => route.isFirst);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SessaoUsuario.instance,
      builder: (BuildContext context, _) {
        final bool autenticado = SessaoUsuario.instance.autenticado;
        final TextStyle? linkStyle =
            Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                );

        return Material(
          color: MobileFooter.backgroundColor,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                widget.horizontalPadding,
                14,
                widget.horizontalPadding,
                12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'images/logo.png',
                    height: widget.logoHeight,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '© BaileSul – Todos os direitos reservados.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MobileFooter.copyrightColor,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _onSessionTap,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child:
                        Text(autenticado ? 'Sair' : 'Login', style: linkStyle),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
