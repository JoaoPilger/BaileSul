import 'package:flutter/material.dart';

import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class MeusIngressosPage extends StatelessWidget {
  const MeusIngressosPage({super.key});

  void _abrirMenu(BuildContext context) {
    MobileAppMenu.show(
      context,
      entries: MobileAppMenu.entries(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaileSulColors.dark,
      body: Column(
        children: [
          MobileHeader(
            logoHeight: 58,
            horizontalPadding: 16,
            onMenuPressed: () => _abrirMenu(context),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: BaileSulColors.pageBackground,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meus Ingressos',
                    style: TextStyle(
                      color: BaileSulColors.headerText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Suas reservas e ingressos aparecerão aqui.',
                    style: TextStyle(
                      color: BaileSulColors.mutedText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
