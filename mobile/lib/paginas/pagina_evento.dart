import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class PaginaEvento extends StatefulWidget {
  const PaginaEvento({super.key, required this.event});

  final EventItem event;

  @override
  State<PaginaEvento> createState() => _PaginaEventoState();
}

class _PaginaEventoState extends State<PaginaEvento> {
  bool _reservado = false;
  bool _processandoReserva = false;

  Future<void> _fazerReserva({
    required String quantidade,
    required String formaPagamento,
    required String nomeRetirada,
  }) async {
    if (!SessaoUsuario.instance.autenticado) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para reservar um ingresso.')),
      );
      return;
    }

    setState(() => _processandoReserva = true);

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/reservas/eventos/${widget.event.id}');
      final http.Response response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${SessaoUsuario.instance.token}',
            },
            body: jsonEncode({
              'quantidade': int.tryParse(quantidade) ?? 1,
              'forma_pagamento': formaPagamento,
              'nome_retirada': nomeRetirada.trim().isNotEmpty ? nomeRetirada.trim() : null,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      final dynamic decoded = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
      final String mensagem = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : (decoded is Map && decoded['error'] != null ? decoded['error'].toString() : 'Não foi possível concluir a reserva.');

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(mensagem);
      }

      setState(() => _reservado = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _processandoReserva = false);
      }
    }
  }

  void _abrirModalReserva() {
    if (_reservado || _processandoReserva) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
          child: _ModalReservaIngresso(
            onProsseguir: ({
              required String quantidade,
              required String formaPagamento,
              required String nomeRetirada,
            }) async {
              Navigator.pop(dialogContext);
              await _fazerReserva(
                quantidade: quantidade,
                formaPagamento: formaPagamento,
                nomeRetirada: nomeRetirada,
              );
            },
          ),
        );
      },
    );
  }

  void _abrirMenu() {
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
            onMenuPressed: _abrirMenu,
          ),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: BaileSulColors.pageBackground,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: _EventoConteudo(
                      event: widget.event,
                      reservado: _reservado,
                      onReservar: _abrirModalReserva,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: MobileFooter(
                    logoHeight: 52,
                    horizontalPadding: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventoConteudo extends StatelessWidget {
  const _EventoConteudo({
    required this.event,
    required this.reservado,
    required this.onReservar,
  });

  final EventItem event;
  final bool reservado;
  final VoidCallback onReservar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ImagemEvento(imageUrl: event.imageUrl),
        const SizedBox(height: 12),
        _ChipGenero(label: event.genre),
        const SizedBox(height: 8),
        Text(
          event.title,
          style: const TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          event.location,
          style: TextStyle(
            color: BaileSulColors.accent.withValues(alpha: 0.85),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sobre o Evento',
                style: TextStyle(
                  color: BaileSulColors.headerText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                event.description.isNotEmpty
                    ? event.description
                    : 'Nenhuma descrição disponível para este evento.',
                style: const TextStyle(
                  color: BaileSulColors.headerText,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LinhaInfo(
                icon: Icons.calendar_month_outlined,
                text: event.dateTime,
              ),
              if (event.startDateTime.isNotEmpty && event.endDateTime.isNotEmpty) ...[
                const SizedBox(height: 8),
                _LinhaInfo(
                  icon: Icons.access_time_outlined,
                  text: '${event.startDateTime} → ${event.endDateTime}',
                ),
              ],
              const SizedBox(height: 8),
              _LinhaInfo(
                icon: Icons.location_on_outlined,
                text: event.location,
              ),
              if (event.address.isNotEmpty) ...[
                const SizedBox(height: 8),
                _LinhaInfo(
                  icon: Icons.map_outlined,
                  text: event.address,
                ),
              ],
              if (event.organizer.isNotEmpty) ...[
                const SizedBox(height: 8),
                _LinhaInfo(
                  icon: Icons.apartment_outlined,
                  text: event.organizer,
                ),
              ],
              if (event.status.isNotEmpty) ...[
                const SizedBox(height: 8),
                _LinhaInfo(
                  icon: Icons.circle_outlined,
                  text: 'Status: ${event.status}',
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1, color: BaileSulColors.cardBorder),
              const SizedBox(height: 10),
              const Text(
                'Valor do Ingresso',
                style: TextStyle(
                  color: BaileSulColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      event.price,
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: reservado ? null : onReservar,
                    style: FilledButton.styleFrom(
                      backgroundColor: reservado
                          ? BaileSulColors.mutedText
                          : BaileSulColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: BaileSulColors.mutedText,
                      disabledForegroundColor: Colors.white,
                      elevation: reservado ? 0 : 3,
                      shadowColor: BaileSulColors.accent.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      minimumSize: const Size(120, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(reservado ? 'Reservado' : 'Reservar'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Compartilhar evento'),
            style: FilledButton.styleFrom(
              backgroundColor: BaileSulColors.accent,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: BaileSulColors.accent.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Localização',
          style: TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: BaileSulColors.styleSurfaceA,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BaileSulColors.cardBorder),
          ),
        ),
      ],
    );
  }
}

class _ImagemEvento extends StatelessWidget {
  const _ImagemEvento({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C9AB1), Color(0xFF0D496B)],
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.music_note_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipGenero extends StatelessWidget {
  const _ChipGenero({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: BaileSulColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_note_rounded,
            size: 14,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BaileSulColors.styleSurfaceA,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  const _LinhaInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: BaileSulColors.headerText),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

enum _FormaPagamento { presencial, whatsapp }

/// Cores do modal de reserva (mockup).
abstract final class _ModalReservaCores {
  static const Color fundo = Color(0xFFD9D9D9);
  static const Color campo = Color(0xFFB0BEC5);
  static const Color botao = Color(0xFF104E6E);
  static const Color borda = Color(0xFF1A1A1A);
  static const Color radioAtivo = Color(0xFF2563EB);
  static const Color textoOpcao = Color(0xFF6B7280);
  static const Color sombra = Color(0x66000000);
  static const double larguraCampoAcao = 240;
  static const double alturaCampoAcao = 48;
}

class _ModalReservaIngresso extends StatefulWidget {
  const _ModalReservaIngresso({required this.onProsseguir});

  final Future<void> Function({
    required String quantidade,
    required String formaPagamento,
    required String nomeRetirada,
  }) onProsseguir;

  @override
  State<_ModalReservaIngresso> createState() => _ModalReservaIngressoState();
}

class _ModalReservaIngressoState extends State<_ModalReservaIngresso> {
  static const List<String> _quantidades = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];

  static const TextStyle _tituloSecao = TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  String _quantidade = '1';
  _FormaPagamento _formaPagamento = _FormaPagamento.presencial;
  final TextEditingController _nomeController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: _ModalReservaCores.fundo,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: _ModalReservaCores.borda, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Reserve seu Ingresso',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Quantidade:', style: _tituloSecao),
                    const SizedBox(width: 14),
                    _CampoDropdown(
                      value: _quantidade,
                      items: _quantidades,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _quantidade = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Forma de pagamento:',
                textAlign: TextAlign.center,
                style: _tituloSecao,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _OpcaoPagamento(
                    label: 'Presencial',
                    selected: _formaPagamento == _FormaPagamento.presencial,
                    onTap: () => setState(
                      () => _formaPagamento = _FormaPagamento.presencial,
                    ),
                  ),
                  const SizedBox(width: 28),
                  _OpcaoPagamento(
                    label: 'Via WhatsApp',
                    selected: _formaPagamento == _FormaPagamento.whatsapp,
                    onTap: () => setState(
                      () => _formaPagamento = _FormaPagamento.whatsapp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Nome para retirada:',
                textAlign: TextAlign.center,
                style: _tituloSecao,
              ),
              const SizedBox(height: 14),
              _CampoTextoComSombra(
                controller: _nomeController,
                hint: 'Digite o nome Completo',
              ),
              const SizedBox(height: 30),
              _BotaoProsseguirModal(
                onPressed: () async {
                  await widget.onProsseguir(
                    quantidade: _quantidade,
                    formaPagamento: _formaPagamento == _FormaPagamento.whatsapp ? 'whatsapp' : 'presencial',
                    nomeRetirada: _nomeController.text,
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

/// Caixa fixa compartilhada pelo campo de nome e pelo botão do modal.
class _CaixaAcaoModal extends StatelessWidget {
  const _CaixaAcaoModal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ModalReservaCores.larguraCampoAcao,
      height: _ModalReservaCores.alturaCampoAcao,
      child: child,
    );
  }
}

class _CampoComSombra extends StatelessWidget {
  const _CampoComSombra({required this.child, this.height = 44});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: _ModalReservaCores.campo,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: _ModalReservaCores.sombra,
            blurRadius: 5,
            offset: Offset(2, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _CampoDropdown extends StatelessWidget {
  const _CampoDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: _CampoComSombra(
        height: 42,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: Colors.black.withValues(alpha: 0.5),
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _CampoTextoComSombra extends StatelessWidget {
  const _CampoTextoComSombra({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return _CaixaAcaoModal(
      child: _CampoComSombra(
        height: _ModalReservaCores.alturaCampoAcao,
        child: Align(
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.black.withValues(alpha: 0.75),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.15,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isCollapsed: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoProsseguirModal extends StatelessWidget {
  const _BotaoProsseguirModal({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return _CaixaAcaoModal(
      child: Material(
        color: _ModalReservaCores.botao,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await onPressed();
          },
          child: const Center(
            child: Text(
              'Prosseguir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcaoPagamento extends StatelessWidget {
  const _OpcaoPagamento({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _ModalReservaCores.radioAtivo,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _ModalReservaCores.textoOpcao,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
