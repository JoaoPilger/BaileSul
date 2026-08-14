import 'package:flutter/material.dart';

import '../services/notificacoes_service.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
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
              child: AnimatedBuilder(
                animation: NotificacoesService.instance,
                builder: (context, child) {
                  final notifications = NotificacoesService.instance.notificacoes;
                  final unreadCount = NotificacoesService.instance.unreadCount;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notificações',
                              style: TextStyle(
                                color: BaileSulColors.headerText,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (unreadCount > 0)
                              TextButton(
                                onPressed: () {
                                  NotificacoesService.instance.marcarTodasComoLidas();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Todas as notificações foram marcadas como lidas.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: BaileSulColors.accent,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Marcar como lidas',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Fique por dentro das atualizações de ingressos, eventos e novidades.',
                          style: TextStyle(
                            color: BaileSulColors.mutedText,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: notifications.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final item = notifications[index];
                                    return _buildNotificationCard(item);
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BaileSulColors.cardBackground,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: BaileSulColors.mutedText,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma notificação',
            style: TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Você não tem novas notificações por enquanto.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: BaileSulColors.mutedText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificacaoItem item) {
    return GestureDetector(
      onTap: () {
        if (!item.isRead) {
          NotificacoesService.instance.marcarComoLida(item.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: item.isRead ? BaileSulColors.cardBackground : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isRead 
                ? BaileSulColors.cardBorder 
                : BaileSulColors.accentLight.withValues(alpha: 0.3),
            width: item.isRead ? 1.0 : 1.5,
          ),
          boxShadow: item.isRead 
              ? null 
              : [
                  BoxShadow(
                    color: BaileSulColors.accent.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.isRead 
                      ? BaileSulColors.pageBackground 
                      : BaileSulColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: item.isRead 
                      ? BaileSulColors.mutedText 
                      : BaileSulColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.titulo,
                            style: TextStyle(
                              color: BaileSulColors.headerText,
                              fontSize: 15,
                              fontWeight: item.isRead 
                                  ? FontWeight.w600 
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.mensagem,
                      style: const TextStyle(
                        color: BaileSulColors.mutedText,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.tempo,
                      style: TextStyle(
                        color: BaileSulColors.mutedText.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: BaileSulColors.mutedText.withValues(alpha: 0.5),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  NotificacoesService.instance.limparNotificacao(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notificação "${item.titulo}" removida.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
