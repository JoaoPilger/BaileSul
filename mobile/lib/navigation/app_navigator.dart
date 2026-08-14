import 'package:flutter/material.dart';

/// Navigator global para diálogos, snackbars e rotas após login/logout.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Observer global de rotas — permite que uma tela de listagem (ex.: Meus
/// Eventos) recarregue os dados sozinha quando volta a ficar visível depois
/// de uma rota empilhada por cima ser fechada (ex.: criar evento pelo menu
/// hambúrguer), sem depender do usuário reconstruir a tela manualmente.
final RouteObserver<PageRoute<dynamic>> routeObserver = RouteObserver<PageRoute<dynamic>>();

void mostrarSnackBar(String mensagem) {
  final BuildContext? context = appNavigatorKey.currentContext;
  if (context == null) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(mensagem)),
  );
}
