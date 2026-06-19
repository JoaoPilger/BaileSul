import 'package:flutter/material.dart';

import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class PesquisaPadraoBandas extends StatelessWidget {
  const PesquisaPadraoBandas({super.key});

  void _showMenu(BuildContext context) {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaileSulColors.dark,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MobileHeader(onMenuPressed: () => _showMenu(context)),
            Expanded(
              child: Container(
                width: double.infinity,
                color: BaileSulColors.pageBackground,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Banda',
                      style: TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pesquise bandas cadastradas na plataforma.',
                      style: TextStyle(
                        color: BaileSulColors.mutedText,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
