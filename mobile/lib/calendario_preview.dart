import 'package:flutter/material.dart';

import 'navigation/app_navigator.dart';
import 'paginas/configuracoes.dart';
import 'paginas/calendario.dart';
import 'paginas/criar_editar_evento.dart';
import 'paginas/login.dart';
import 'paginas/meus_eventos.dart';
import 'paginas/meus_ingressos.dart';

void main() {
  runApp(const _CalendarioPreviewApp());
}

class _CalendarioPreviewApp extends StatelessWidget {
  const _CalendarioPreviewApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Preview - Calendário',
      debugShowCheckedModeBanner: false,
      home: const CalendarioPage(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/meus-ingressos': (_) => const MeusIngressosPage(),
        '/meus-eventos': (_) => const MeusEventosPage(),
        '/configuracoes': (_) => const ConfiguracoesPage(),
        '/criar-evento': (_) => const CriarEditarEventoPage(),
      },
    );
  }
}
