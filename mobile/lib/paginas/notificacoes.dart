import 'package:flutter/material.dart';

import '../services/notificacoes_service.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

const int _porPagina = 10;

class _Aba {
  const _Aba(this.key, this.label);

  final String key;
  final String label;
}

const List<_Aba> _abas = [
  _Aba('todas', 'Todas'),
  _Aba('nao_lidas', 'Não vistas'),
  _Aba('lidas', 'Vistas'),
];

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  String _abaAtiva = 'todas';
  int _pagina = 1;

  bool _carregando = true;
  String? _erro;
  bool _marcandoTodas = false;
  List<NotificacaoItem> _notificacoes = <NotificacaoItem>[];
  int _total = 0;
  int _totalPaginas = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final NotificacoesPagina resultado = await NotificacoesService.instance.buscar(
        status: _abaAtiva,
        pagina: _pagina,
        limite: _porPagina,
      );
      if (!mounted) return;
      setState(() {
        _notificacoes = resultado.itens;
        _total = resultado.total;
        _totalPaginas = resultado.totalPaginas;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar as notificações.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _abrirMenu(BuildContext context) {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  void _mudarAba(String key) {
    if (key == _abaAtiva) return;
    setState(() {
      _abaAtiva = key;
      _pagina = 1;
    });
    _carregar();
  }

  void _mudarPagina(int pagina) {
    setState(() => _pagina = pagina);
    _carregar();
  }

  Future<void> _marcarLida(String id) async {
    final int index = _notificacoes.indexWhere((NotificacaoItem n) => n.id == id);
    if (index == -1 || _notificacoes[index].isRead) return;

    setState(() {
      // Na aba "Não vistas" o item some assim que deixa de ser não-lido,
      // espelhando o comportamento do site.
      if (_abaAtiva == 'nao_lidas') {
        _notificacoes.removeAt(index);
        _total = _total > 0 ? _total - 1 : 0;
      } else {
        _notificacoes[index] = _notificacoes[index].copyWith(isRead: true);
      }
    });

    try {
      await NotificacoesService.instance.marcarComoLida(id);
    } catch (_) {
      if (mounted) _carregar();
    }
  }

  Future<void> _marcarTodas() async {
    setState(() => _marcandoTodas = true);
    try {
      await NotificacoesService.instance.marcarTodasComoLidas();
      await _carregar();
    } catch (_) {
      // Ignorado: badge/lista continuam no estado anterior.
    } finally {
      if (mounted) setState(() => _marcandoTodas = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaileSulColors.pageBackground,
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
              child: RefreshIndicator(
                onRefresh: _carregar,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(context),
                      const SizedBox(height: 16),
                      _buildToolbar(_total),
                      const SizedBox(height: 14),
                      if (_carregando)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_erro != null)
                        _buildErro(_erro!)
                      else if (_notificacoes.isEmpty)
                        _buildEmptyState()
                      else
                        Column(
                          children: _notificacoes
                              .map((NotificacaoItem item) => _buildNotificationCard(item))
                              .toList(),
                        ),
                      if (!_carregando && _erro == null && _totalPaginas > 1) ...[
                        const SizedBox(height: 12),
                        _buildPaginacao(_pagina, _totalPaginas),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final bool mostrarBotao = _abaAtiva != 'lidas' && NotificacoesService.instance.unreadCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: BaileSulColors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    size: 22,
                    color: BaileSulColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Notificações',
                        style: TextStyle(
                          color: BaileSulColors.headerText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tudo que aconteceu por aqui, em um só lugar',
                        softWrap: true,
                        style: TextStyle(
                          color: BaileSulColors.mutedText.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (mostrarBotao)
            OutlinedButton.icon(
              onPressed: _marcandoTodas ? null : _marcarTodas,
              icon: const Icon(Icons.done_all, size: 15),
              label: Text(_marcandoTodas ? 'Marcando...' : 'Marcar todas como lidas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: BaileSulColors.accent,
                side: const BorderSide(color: BaileSulColors.accent, width: 1.4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar(int total) {
    // No site, o toolbar vira coluna (abas em cima, contagem embaixo) em
    // telas estreitas — aqui é sempre o caso, então já nasce em Column pra
    // as abas terem a largura toda pra elas, sem disputar espaço.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: _abas.map((_Aba aba) {
            final bool ativa = _abaAtiva == aba.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _mudarAba(aba.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: ativa ? BaileSulColors.accent : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: ativa ? BaileSulColors.accent : BaileSulColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    aba.label,
                    style: TextStyle(
                      color: ativa ? Colors.white : BaileSulColors.mutedText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          '$total notificaç${total == 1 ? 'ão' : 'ões'}',
          style: TextStyle(
            color: BaileSulColors.mutedText.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildErro(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        mensagem,
        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13.5),
      ),
    );
  }

  Widget _buildPaginacao(int paginaAtual, int totalPaginas) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left,
            onTap: paginaAtual > 1 ? () => _mudarPagina(paginaAtual - 1) : null,
          ),
          for (int n = 1; n <= totalPaginas; n++)
            _buildPageButton(label: '$n', ativo: n == paginaAtual, onTap: () => _mudarPagina(n)),
          _buildPageButton(
            icon: Icons.chevron_right,
            onTap: paginaAtual < totalPaginas ? () => _mudarPagina(paginaAtual + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    String? label,
    IconData? icon,
    bool ativo = false,
    VoidCallback? onTap,
  }) {
    final bool desabilitado = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ativo ? BaileSulColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ativo ? BaileSulColors.accent : BaileSulColors.cardBorder,
          ),
        ),
        child: icon != null
            ? Icon(
                icon,
                size: 18,
                color: desabilitado
                    ? BaileSulColors.mutedText.withValues(alpha: 0.35)
                    : BaileSulColors.mutedText,
              )
            : Text(
                label ?? '',
                style: TextStyle(
                  color: ativo ? Colors.white : BaileSulColors.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final String mensagem = switch (_abaAtiva) {
      'nao_lidas' => 'Nenhuma notificação não vista.',
      'lidas' => 'Nenhuma notificação vista ainda.',
      _ => 'Nenhuma notificação por aqui ainda.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
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
                size: 40,
                color: BaileSulColors.mutedText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BaileSulColors.mutedText,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificacaoItem item) {
    return GestureDetector(
      onTap: () => _marcarLida(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          // rgba(13, 73, 107, 0.1) no site — mesma cor de destaque (accent),
          // não a `accentSoft` (lilás) que não existe nessa tela no desktop.
          color: item.isRead ? Colors.white : BaileSulColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item.isRead ? Colors.transparent : BaileSulColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titulo,
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.mensagem.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.mensagem,
                        style: TextStyle(
                          color: BaileSulColors.mutedText.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      item.tempo,
                      style: TextStyle(
                        color: BaileSulColors.mutedText.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
