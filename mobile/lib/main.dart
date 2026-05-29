import 'package:flutter/material.dart';

import 'paginas/criar_editar_evento.dart';
import 'paginas/home.dart';
import 'paginas/login.dart';
import 'paginas/configuracoes.dart';
import 'paginas/meus_eventos.dart';
import 'paginas/meus_ingressos.dart';
import 'paginas/pagina_evento.dart';
import 'navigation/app_navigator.dart';
import 'services/sessao_usuario.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessaoUsuario.instance.restaurar();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'BaileSul',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A4CFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/meus-ingressos': (_) => const MeusIngressosPage(),
        '/meus-eventos': (_) => const MeusEventosPage(),
        '/configuracoes': (_) => const ConfiguracoesPage(),
        '/criar-evento': (_) => const CriarEditarEventoPage(),
        '/evento': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return PaginaEvento(event: args! as EventItem);
        },
      },
    );
  }
}
