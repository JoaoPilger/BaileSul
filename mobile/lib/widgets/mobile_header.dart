import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Cabeçalho mobile com fundo escuro, logo à esquerda e menu à direita.
class MobileHeader extends StatelessWidget {
  const MobileHeader({
    super.key,
    this.onMenuPressed,
    this.logoHeight = 106,
    this.horizontalPadding = 16,
  });

  static const Color backgroundColor = Color(0xFF0A0C12);

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
          ),
        ),
      ),
    );
  }
}
