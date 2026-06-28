import 'package:flutter/material.dart';

import '../models/tipo_conta.dart';
import '../navigation/app_navigator.dart';
import '../paginas/home.dart';
import '../services/sessao_usuario.dart';

class MobileMenuEntry {
  const MobileMenuEntry({
    required this.icon,
    required this.label,
    this.onTap,
    this.children = const <MobileMenuEntry>[],
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final List<MobileMenuEntry> children;
}

abstract final class MobileAppMenu {
  static const bool _devForceShowComunidade = false;
  static const bool _devForceShowBanda = false;

  static List<MobileMenuEntry> entries(
    BuildContext context, {
    VoidCallback? onEventos,
  }) {
    final List<MobileMenuEntry> itens = <MobileMenuEntry>[];

    itens.add(
      MobileMenuEntry(
        icon: Icons.home_rounded,
        label: 'Início',
        onTap: () =>
            Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst),
      ),
    );

    itens.add(
      MobileMenuEntry(
        icon: Icons.search_rounded,
        label: 'Pesquisa',
        children: <MobileMenuEntry>[
          MobileMenuEntry(
            icon: Icons.event_rounded,
            label: 'Eventos',
            onTap:
                onEventos ?? () => Navigator.pushNamed(context, '/pesquisa-eventos'),
          ),
          MobileMenuEntry(
            icon: Icons.groups_rounded,
            label: 'Comunidades',
            onTap: () => Navigator.pushNamed(context, '/pesquisa-comunidades'),
          ),
          MobileMenuEntry(
            icon: Icons.music_note_rounded,
            label: 'Banda',
            onTap: () => Navigator.pushNamed(context, '/pesquisa-bandas'),
          ),
        ],
      ),
    );

    itens.add(
      MobileMenuEntry(
        icon: Icons.notifications_none_rounded,
        label: 'Notificações',
        onTap: () => Navigator.pushNamed(context, '/notificacoes'),
      ),
    );

    final SessaoUsuario sessao = SessaoUsuario.instance;

    if (sessao.autenticado) {
      final TipoConta? tipo = sessao.tipoConta;

      if (tipo == TipoConta.pessoal) {
        itens.add(
          MobileMenuEntry(
            icon: Icons.confirmation_number_outlined,
            label: 'Meus Ingressos',
            onTap: () => Navigator.pushNamed(context, '/meus-ingressos'),
          ),
        );
      } else if (tipo == TipoConta.banda || _devForceShowBanda) {
        itens.add(
          MobileMenuEntry(
            icon: Icons.list_alt_rounded,
            label: 'Meus Eventos',
            onTap: () => Navigator.pushNamed(context, '/meus-eventos-bandas'),
          ),
        );
      } else if (tipo == TipoConta.comunidade || _devForceShowComunidade) {
        itens.add(
          MobileMenuEntry(
            icon: Icons.list_alt_rounded,
            label: 'Meus Eventos',
            onTap: () => Navigator.pushNamed(context, '/meus-eventos-comunidade'),
          ),
        );
        itens.add(
          MobileMenuEntry(
            icon: Icons.add_box_rounded,
            label: 'Criar Eventos',
            onTap: () => Navigator.pushNamed(context, '/criar-evento'),
          ),
        );
      }

      itens.add(
        MobileMenuEntry(
          icon: Icons.settings_outlined,
          label: 'Configurações',
          onTap: () => Navigator.pushNamed(context, '/configuracoes'),
        ),
      );

      itens.add(
        MobileMenuEntry(
          icon: Icons.logout_rounded,
          label: 'Sair',
          onTap: () => _sairDaConta(context),
        ),
      );
    } else {
      // Quando não autenticado, exibimos Login normalmente.
      itens.add(
        MobileMenuEntry(
          icon: Icons.login_rounded,
          label: 'Login',
          onTap: () => Navigator.pushNamed(context, '/login'),
        ),
      );

      // Modo dev: forçar exibição dos itens de eventos mesmo sem sessão.
      if (_devForceShowBanda) {
        itens.add(
          MobileMenuEntry(
            icon: Icons.list_alt_rounded,
            label: 'Meus Eventos - Banda (Teste)',
            onTap: () => Navigator.pushNamed(context, '/meus-eventos-bandas'),
          ),
        );
      }

      if (_devForceShowComunidade) {
        itens.add(
          MobileMenuEntry(
            icon: Icons.list_alt_rounded,
            label: 'Meus Eventos - Comunidade (Teste)',
            onTap: () => Navigator.pushNamed(context, '/meus-eventos-comunidade'),
          ),
        );
      }
    }

    return itens;
  }

  static Future<void> _sairDaConta(BuildContext context) async {
    await SessaoUsuario.instance.encerrarSessao();

    final NavigatorState? navigator = appNavigatorKey.currentState;
    if (navigator != null) {
      navigator.popUntil((Route<dynamic> route) => route.isFirst);
    }

    mostrarSnackBar('Você saiu da sua conta.');
  }

  static Future<void> show(
    BuildContext context, {
    required List<MobileMenuEntry> entries,
  }) {
    final BuildContext dialogContext =
        appNavigatorKey.currentContext ?? context;

    return showGeneralDialog<void>(
      context: dialogContext,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Fechar menu',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (BuildContext overlayContext, _, _) {
        final double largura = MediaQuery.sizeOf(overlayContext).width;
        final Set<MobileMenuEntry> expandedEntries = <MobileMenuEntry>{};

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: largura,
                child: Material(
                  color: BaileSulColors.dark,
                  elevation: 12,
                  shadowColor: Colors.black.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        for (final MobileMenuEntry entry in entries) ...[
                          _MobileMenuTile(
                            icon: entry.icon,
                            label: entry.label,
                            expanded: expandedEntries.contains(entry),
                            hasChildren: entry.children.isNotEmpty,
                            onTap: () {
                              if (entry.children.isNotEmpty) {
                                setState(() {
                                  if (expandedEntries.contains(entry)) {
                                    expandedEntries.remove(entry);
                                  } else {
                                    expandedEntries.add(entry);
                                  }
                                });
                                return;
                              }

                              Navigator.of(overlayContext).pop();
                              entry.onTap?.call();
                            },
                          ),
                          if (expandedEntries.contains(entry))
                            for (final MobileMenuEntry child in entry.children)
                              _MobileMenuTile(
                                icon: child.icon,
                                label: child.label,
                                isChild: true,
                                onTap: () {
                                  Navigator.of(overlayContext).pop();
                                  child.onTap?.call();
                                },
                              ),
                        ],
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return SlideTransition(position: slide, child: child);
      },
    );
  }
}

class _MobileMenuTile extends StatelessWidget {
  const _MobileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.expanded = false,
    this.hasChildren = false,
    this.isChild = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool expanded;
  final bool hasChildren;
  final bool isChild;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: BaileSulColors.accentLight,
        size: isChild ? 20 : 22,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: hasChildren
          ? Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
            )
          : null,
      onTap: onTap,
      minLeadingWidth: 26,
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isChild ? 36 : 20,
        vertical: 2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
