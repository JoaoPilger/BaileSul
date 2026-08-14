import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'paginas/criar_editar_evento.dart';
import 'paginas/editar_perfil_banda.dart';
import 'paginas/editar_perfil_comunidade.dart';
import 'paginas/home.dart';
import 'paginas/calendario.dart';
import 'paginas/login.dart';
import 'paginas/configuracoes.dart';
import 'paginas/meusEventos_bandas.dart';
import 'paginas/meusEventos_comunidade.dart';
import 'paginas/meus_ingressos.dart';
import 'paginas/pagina_evento.dart';
import 'paginas/dashboard_evento_comunidade.dart';
import 'paginas/pesquisa_padrao_bandas.dart';
import 'paginas/pesquisa_padrao_comunidade.dart';
import 'paginas/pesquisa_padrao_eventos.dart';
import 'models/tipo_conta.dart';
import 'navigation/app_navigator.dart';
import 'services/sessao_usuario.dart';
import 'paginas/notificacoes.dart';
import 'paginas/perfil_banda.dart';
import 'paginas/perfil_comunidade.dart';
import 'paginas/vendedores.dart';
import 'paginas/painel_banda.dart';
import 'paginas/painel_comunidade.dart';
import 'paginas/contratos.dart';
import 'paginas/pagamentos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessaoUsuario.instance.restaurar();
  runApp(const MyApp());
}

/// Tela inicial mostrada em "/". Contas do tipo banda e comunidade vão direto
/// pro painel de trabalho delas, assim como já acontece na versão web — as
/// demais continuam vendo a home pública normalmente.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessaoUsuario.instance,
      builder: (context, _) {
        final TipoConta? tipo = SessaoUsuario.instance.tipoConta;
        if (tipo == TipoConta.banda) {
          return const PainelBandaPage();
        }
        if (tipo == TipoConta.comunidade) {
          return const PainelComunidadePage();
        }
        return const HomePage();
      },
    );
  }
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
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
      ),
      home: const RootGate(),
      routes: {
        '/painel': (_) =>
            SessaoUsuario.instance.tipoConta == TipoConta.comunidade
                ? const PainelComunidadePage()
                : const PainelBandaPage(),
        '/painel-comunidade': (_) => const PainelComunidadePage(),
        '/contratos': (_) => const ContratosPage(),
        '/notificacoes': (_) => const NotificacoesPage(),
        '/pesquisa-eventos': (_) => const PesquisaPadraoEventos(),
        '/pesquisa-comunidades': (_) => const PesquisaPadraoComunidade(),
        '/pesquisa-bandas': (_) => const PesquisaPadraoBandas(),
        '/pesquisa-padrao': (_) => const PesquisaPadraoEventos(),
        '/calendario': (_) => const CalendarioPage(),
        '/login': (_) => const LoginScreen(),
        '/meus-ingressos': (_) => const MeusIngressosPage(),
        '/meus-eventos': (context) {
          final TipoConta? tipo = SessaoUsuario.instance.tipoConta;
          if (tipo == TipoConta.banda) {
            return const MeusEventosBandasPage();
          }
          return const Scaffold(
            body: Center(
              child: Text('Apenas contas de banda podem acessar esta página.'),
            ),
          );
        },
        '/meus-eventos-bandas': (_) => const MeusEventosBandasPage(),
        // Exibição temporária de exemplo: passar `comunidadeId` para pré-visualizar a tela
        '/meus-eventos-comunidade': (_) => const MeusEventosComunidadePage(),
        '/configuracoes': (_) => const ConfiguracoesPage(),
        '/criar-evento': (_) => const CriarEditarEventoPage(),
        '/evento-dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return DashboardEventoPage(eventId: args! as int);
        },
        '/evento': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return PaginaEvento(event: args! as EventItem);
        },
        '/perfil-banda': (_) => const PerfilBandaPage(),
        '/perfil-comunidade': (_) => const PerfilComunidadePage(),
        '/editar-perfil-comunidade': (_) => const EditarPerfilComunidadePage(),
        '/editar-perfil-banda': (_) => const EditarPerfilBandaPage(),
        '/vendedores': (_) => const VendedoresPage(),
        '/pagamentos': (_) => const PagamentosPage(),
      },
    );
  }
}