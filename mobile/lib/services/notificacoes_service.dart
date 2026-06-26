import 'package:flutter/material.dart';

class NotificacaoItem {
  final String id;
  final String titulo;
  final String mensagem;
  final String tempo;
  final bool isRead;
  final IconData icon;

  NotificacaoItem({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.tempo,
    this.isRead = false,
    required this.icon,
  });

  NotificacaoItem copyWith({
    String? id,
    String? titulo,
    String? mensagem,
    String? tempo,
    bool? isRead,
    IconData? icon,
  }) {
    return NotificacaoItem(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensagem: mensagem ?? this.mensagem,
      tempo: tempo ?? this.tempo,
      isRead: isRead ?? this.isRead,
      icon: icon ?? this.icon,
    );
  }
}

class NotificacoesService extends ChangeNotifier {
  NotificacoesService._();
  static final NotificacoesService instance = NotificacoesService._();

  final List<NotificacaoItem> _notificacoes = [
    NotificacaoItem(
      id: '1',
      titulo: 'Ingresso Confirmado',
      mensagem: 'Seu ingresso para o Baile da Primavera foi gerado com sucesso.',
      tempo: 'Há 5 min',
      isRead: false,
      icon: Icons.confirmation_number_outlined,
    ),
    NotificacaoItem(
      id: '2',
      titulo: 'Novo Show Disponível',
      mensagem: 'A banda "Os Serranos" acaba de agendar um novo show em Porto Alegre.',
      tempo: 'Há 2 horas',
      isRead: false,
      icon: Icons.event_outlined,
    ),
    NotificacaoItem(
      id: '3',
      titulo: 'Lembrete Importante',
      mensagem: 'O evento "Baile do Chopp" começa em 2 horas. Não se atrasar!',
      tempo: 'Ontem',
      isRead: false,
      icon: Icons.access_time,
    ),
  ];

  List<NotificacaoItem> get notificacoes => _notificacoes;

  int get unreadCount => _notificacoes.where((n) => !n.isRead).length;

  void marcarComoLida(String id) {
    final index = _notificacoes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notificacoes[index] = _notificacoes[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void marcarTodasComoLidas() {
    for (int i = 0; i < _notificacoes.length; i++) {
      _notificacoes[i] = _notificacoes[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void limparNotificacao(String id) {
    _notificacoes.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
