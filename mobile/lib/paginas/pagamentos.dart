import 'package:flutter/material.dart';

import '../models/tipo_conta.dart';
import '../services/sessao_usuario.dart';
import '../services/vendedor_service.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class PagamentosPage extends StatefulWidget {
  const PagamentosPage({super.key});

  @override
  State<PagamentosPage> createState() => _PagamentosPageState();
}

class _PagamentosPageState extends State<PagamentosPage> {
  bool _loading = true;
  String? _error;
  String _busca = '';
  String _abaAtiva = 'pendente';
  bool _ehVendedor = true;
  int? _processandoId;
  List<Map<String, dynamic>> _reservas = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<Map<String, dynamic>> comunidades = await VendedorService.minhasComunidades();
      final List<Map<String, dynamic>> reservas = await VendedorService.listarReservas();

      if (!mounted) return;
      setState(() {
        _ehVendedor = comunidades.isNotEmpty;
        _reservas = reservas;
      });
    } on VendedorException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os pagamentos.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmar(int id) async {
    setState(() {
      _processandoId = id;
      _error = null;
    });

    try {
      await VendedorService.confirmarReserva(id);
      if (!mounted) return;
      setState(() {
        _reservas = _reservas.map((reserva) {
          if (reserva['id'] == id) {
            return {...reserva, 'status_pagamento': 'confirmado'};
          }
          return reserva;
        }).toList();
      });
    } on VendedorException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível confirmar o pagamento.');
    } finally {
      if (mounted) setState(() => _processandoId = null);
    }
  }

  Future<void> _rejeitar(int id) async {
    setState(() {
      _processandoId = id;
      _error = null;
    });

    try {
      await VendedorService.rejeitarReserva(id);
      if (!mounted) return;
      setState(() {
        _reservas = _reservas.map((reserva) {
          if (reserva['id'] == id) {
            return {...reserva, 'status_pagamento': 'rejeitado'};
          }
          return reserva;
        }).toList();
      });
    } on VendedorException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível rejeitar o pagamento.');
    } finally {
      if (mounted) setState(() => _processandoId = null);
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    final String termo = _busca.trim().toLowerCase();
    return _reservas.where((reserva) {
      if (reserva['status_pagamento']?.toString() != _abaAtiva) return false;
      if (termo.isEmpty) return true;

      final String nome = reserva['comprador_nome']?.toString().toLowerCase() ?? '';
      final String email = reserva['comprador_email']?.toString().toLowerCase() ?? '';
      final String evento = reserva['evento']?.toString().toLowerCase() ?? '';
      return nome.contains(termo) || email.contains(termo) || evento.contains(termo);
    }).toList();
  }

  double get _totalConfirmado {
    return _reservas
        .where((reserva) => reserva['status_pagamento']?.toString() == 'confirmado')
        .fold(0.0, (double total, reserva) {
          final dynamic valor = reserva['valor_total'];
          final double numero = valor is num ? valor.toDouble() : double.tryParse('$valor') ?? 0.0;
          return total + numero;
        });
  }

  Map<String, int> get _contagem {
    return {
      'pendente': _reservas.where((r) => r['status_pagamento'] == 'pendente').length,
      'confirmado': _reservas.where((r) => r['status_pagamento'] == 'confirmado').length,
      'rejeitado': _reservas.where((r) => r['status_pagamento'] == 'rejeitado').length,
    };
  }

  Widget _buildTab(String key, String label) {
    final bool ativo = _abaAtiva == key;
    return GestureDetector(
      onTap: () => setState(() => _abaAtiva = key),
      child: Container(
        constraints: const BoxConstraints(minWidth: 96),
        height: 72,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ativo ? const Color(0xFF0D496B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ativo ? const Color(0xFF0D496B) : const Color(0xFFD1D5DB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ativo ? Colors.white : const Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_contagem[key] ?? 0}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ativo ? Colors.white : const Color(0xFF0D496B),
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> reserva) {
    final String status = reserva['status_pagamento']?.toString() ?? '';
    final String nome = reserva['comprador_nome']?.toString() ?? 'Usuário sem nome';
    final String email = reserva['comprador_email']?.toString() ?? '';
    final String evento = reserva['evento']?.toString() ?? 'Evento não informado';
    final int quantidade = reserva['quantidade'] is int ? reserva['quantidade'] as int : int.tryParse('${reserva['quantidade']}') ?? 0;
    final double valorTotal = reserva['valor_total'] is num ? (reserva['valor_total'] as num).toDouble() : double.tryParse('${reserva['valor_total']}') ?? 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline, color: Color(0xFF0D496B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Evento', style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
          const SizedBox(height: 4),
          Text(evento, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Valor Total', style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
                    const SizedBox(height: 4),
                    Text('R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ingressos', style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
                    const SizedBox(height: 4),
                    Text('$quantidade', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (status == 'pendente') ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _processandoId == reserva['id'] ? null : () => _confirmar(reserva['id'] as int),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D496B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _processandoId == reserva['id'] ? null : () => _rejeitar(reserva['id'] as int),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Rejeitar'),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: status == 'confirmado' ? const Color(0xFFEFF6EF) : const Color(0xFFFEE4E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status == 'confirmado' ? 'Confirmado' : 'Rejeitado',
                style: TextStyle(
                  color: status == 'confirmado' ? const Color(0xFF1E7B34) : const Color(0xFFB42318),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SessaoUsuario sessao = SessaoUsuario.instance;
    final bool isPessoal = sessao.tipoConta == TipoConta.pessoal;

    return Scaffold(
      backgroundColor: BaileSulColors.pageBackground,
      body: Column(
        children: [
          MobileHeader(
            logoHeight: 58,
            horizontalPadding: 16,
            onMenuPressed: () => MobileAppMenu.show(context, entries: MobileAppMenu.entries(context)),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregar,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFE8ECF0),
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.payment_outlined, color: Color(0xFF111111), size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Pagamentos',
                                style: TextStyle(
                                  color: Color(0xFF111111),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Gerencie as confirmações de pagamento',
                            style: TextStyle(color: Color(0xFF546173), fontSize: 13, height: 1.35),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: BaileSulColors.accent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL CONFIRMADO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'R\$ ${_totalConfirmado.toStringAsFixed(2).replaceAll('.', ',')}',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildTab('pendente', 'Pendente'),
                              _buildTab('confirmado', 'Confirmados'),
                              _buildTab('rejeitado', 'Rejeitados'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                const Icon(Icons.search, color: Color(0xFF667085), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    onChanged: (value) => setState(() => _busca = value),
                                    style: const TextStyle(fontSize: 15),
                                    decoration: const InputDecoration(
                                      hintText: 'Busca por nome, email ou evento',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFB7185)),
                              ),
                              child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_loading) ...[
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(height: 14),
                            Text('Carregando pagamentos...', style: TextStyle(color: Color(0xFF546173))),
                          ],
                        ),
                      ),
                    ),
                  ] else if (!isPessoal) ...[
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Text(
                            'Esta página só está disponível para contas pessoais.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF546173), fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ] else if (!_ehVendedor) ...[
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Text(
                            'Essa página é exclusiva para vendedores. Se você ainda não foi vinculado a nenhuma comunidade, peça para uma comunidade adicioná-lo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF546173), fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ] else if (_filtrados.isEmpty) ...[
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _reservas.isEmpty ? 'Nenhum pagamento encontrado para esta conta.' : 'Nenhum pagamento encontrado para essa aba ou busca.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF546173), fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildCard(_filtrados[index]),
                        childCount: _filtrados.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
