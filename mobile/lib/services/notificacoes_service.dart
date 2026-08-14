import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'sessao_usuario.dart';

const Duration _pollInterval = Duration(seconds: 60);

String formatarQuando(DateTime data) {
  final Duration diff = DateTime.now().difference(data);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours}h';
  if (diff.inDays < 7) return 'há ${diff.inDays}d';
  return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}

class NotificacaoItem {
  NotificacaoItem({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.criadoEm,
    required this.isRead,
  });

  final String id;
  final String titulo;
  final String mensagem;
  final DateTime criadoEm;
  final bool isRead;

  String get tempo => formatarQuando(criadoEm);

  factory NotificacaoItem.fromJson(Map<String, dynamic> json) {
    return NotificacaoItem(
      id: json['id'].toString(),
      titulo: json['titulo']?.toString() ?? '',
      mensagem: json['mensagem']?.toString() ?? '',
      criadoEm: DateTime.tryParse(json['criado_em']?.toString() ?? '') ?? DateTime.now(),
      isRead: json['lida'] == true,
    );
  }

  NotificacaoItem copyWith({bool? isRead}) => NotificacaoItem(
        id: id,
        titulo: titulo,
        mensagem: mensagem,
        criadoEm: criadoEm,
        isRead: isRead ?? this.isRead,
      );
}

class NotificacoesPagina {
  const NotificacoesPagina({
    required this.itens,
    required this.total,
    required this.totalPaginas,
  });

  final List<NotificacaoItem> itens;
  final int total;
  final int totalPaginas;

  static const NotificacoesPagina vazia =
      NotificacoesPagina(itens: [], total: 0, totalPaginas: 0);
}

/// Contagem de notificações não lidas (usada pelo badge do sino no header,
/// espelhando `useNotificacoes` do frontend web). O histórico completo com
/// filtros/paginação e as ações de marcar como lida vivem na própria página
/// de notificações — este serviço só expõe a contagem reativa e as chamadas
/// de API cruas.
class NotificacoesService extends ChangeNotifier {
  NotificacoesService._() {
    Timer.periodic(_pollInterval, (_) => atualizarContagem());
  }

  static final NotificacoesService instance = NotificacoesService._();

  int unreadCount = 0;

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static String? get _token => SessaoUsuario.instance.token;

  Future<void> atualizarContagem() async {
    final String? token = _token;
    if (token == null || token.isEmpty) {
      if (unreadCount != 0) {
        unreadCount = 0;
        notifyListeners();
      }
      return;
    }
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/notificacoes/contagem');
      final http.Response resp =
          await http.get(url, headers: _headers(token)).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return;
      final Map<String, dynamic> decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final int novo = decoded['nao_lidas'] is int
          ? decoded['nao_lidas'] as int
          : int.tryParse('${decoded['nao_lidas']}') ?? 0;
      if (novo != unreadCount) {
        unreadCount = novo;
        notifyListeners();
      }
    } catch (_) {
      // Silencioso: badge apenas não atualiza nesse ciclo.
    }
  }

  /// GET /notificacoes?status=&pagina=&limite= — histórico paginado.
  Future<NotificacoesPagina> buscar({
    required String status,
    required int pagina,
    int limite = 10,
  }) async {
    final String? token = _token;
    if (token == null || token.isEmpty) return NotificacoesPagina.vazia;

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/notificacoes').replace(
      queryParameters: {
        'status': status,
        'pagina': '$pagina',
        'limite': '$limite',
      },
    );
    final http.Response resp =
        await http.get(url, headers: _headers(token)).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('Não foi possível carregar as notificações.');
    }

    final Map<String, dynamic> decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> dados = decoded['dados'] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic> paginacao =
        decoded['paginacao'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return NotificacoesPagina(
      itens: dados
          .map((dynamic e) => NotificacaoItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: paginacao['total'] is int
          ? paginacao['total'] as int
          : int.tryParse('${paginacao['total']}') ?? 0,
      totalPaginas: paginacao['total_paginas'] is int
          ? paginacao['total_paginas'] as int
          : int.tryParse('${paginacao['total_paginas']}') ?? 0,
    );
  }

  /// PATCH /notificacoes/:id/lida
  Future<void> marcarComoLida(String id) async {
    final String? token = _token;
    if (token == null || token.isEmpty) return;
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/notificacoes/$id/lida');
    await http.patch(url, headers: _headers(token)).timeout(const Duration(seconds: 10));
    unawaited(atualizarContagem());
  }

  /// PATCH /notificacoes/lidas
  Future<void> marcarTodasComoLidas() async {
    final String? token = _token;
    if (token == null || token.isEmpty) return;
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/notificacoes/lidas');
    await http.patch(url, headers: _headers(token)).timeout(const Duration(seconds: 10));
    unawaited(atualizarContagem());
  }
}
