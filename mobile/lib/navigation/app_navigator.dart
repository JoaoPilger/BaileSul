import 'package:flutter/material.dart';

/// Navigator global para diálogos, snackbars e rotas após login/logout.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void mostrarSnackBar(String mensagem) {
  final BuildContext? context = appNavigatorKey.currentContext;
  if (context == null) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(mensagem)),
  );
}
