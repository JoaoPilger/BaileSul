import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../paginas/home.dart' show BaileSulColors;
import '../services/notificacoes_service.dart';

/// Cabeçalho mobile com fundo escuro, logo à esquerda e menu à direita.
class MobileHeader extends StatelessWidget {
  const MobileHeader({
    super.key,
    this.onMenuPressed,
    this.logoHeight = 48,
    this.horizontalPadding = 20,
  });

  static const Color backgroundColor = BaileSulColors.dark;

  final VoidCallback? onMenuPressed;
  final double logoHeight;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final double barHeight = math.max(
      kToolbarHeight.toDouble(),
      logoHeight + 12,
    );

    return Material(
      color: backgroundColor,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: barHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'images/logo.png',
                  height: logoHeight,
                  fit: BoxFit.contain,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: NotificacoesService.instance,
                      builder: (context, child) {
                        final int count = NotificacoesService.instance.unreadCount;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/notificacoes');
                              },
                              style: IconButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(44, 44),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: Icon(
                                count > 0
                                    ? Icons.notifications_active_outlined
                                    : Icons.notifications_none_outlined,
                                size: 26,
                              ),
                              tooltip: 'Notificações',
                            ),
                            if (count > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3B30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 14,
                                    minHeight: 14,
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onMenuPressed,
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.menu, size: 26),
                      tooltip: 'Menu',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
