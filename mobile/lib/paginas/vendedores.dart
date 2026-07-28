import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tipo_conta.dart';
import '../services/sessao_usuario.dart';
import '../services/vendedor_service.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class VendedoresPage extends StatefulWidget {
  const VendedoresPage({super.key});

  @override
  State<VendedoresPage> createState() => _VendedoresPageState();
}

class _VendedoresPageState extends State<VendedoresPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _vendedores = [];
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _abrirMenu() {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Map<String, dynamic>> resultado = await VendedorService.listar();
      if (!mounted) return;
      setState(() => _vendedores = resultado);
    } on VendedorException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível carregar a lista de vendedores.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remover(Map<String, dynamic> vendedor) async {
    final String nome = vendedor['nome']?.toString() ?? 'este vendedor';
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover vendedor'),
        content: Text('Tem certeza que deseja remover "$nome"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: Color(0xFFB42318))),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    final int? id = vendedor['id'] is int ? vendedor['id'] as int : int.tryParse('${vendedor['id']}');
    if (id == null) return;

    try {
      await VendedorService.remover(id);
      if (!mounted) return;
      setState(() => _vendedores.removeWhere((v) => v['id'] == vendedor['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vendedor "$nome" removido.')),
      );
    } on VendedorException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao remover o vendedor.')),
      );
    }
  }

  Future<void> _abrirModalAdicionar() async {
    final bool? adicionou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NovoVendedorSheet(),
    );
    if (adicionou == true) {
      _carregar();
    }
  }

  List<Map<String, dynamic>> get _vendedoresFiltrados {
    final String termo = _busca.trim().toLowerCase();
    if (termo.isEmpty) return _vendedores;
    return _vendedores.where((v) {
      final String nome = (v['nome']?.toString() ?? '').toLowerCase();
      final String email = (v['usuario_email']?.toString() ?? '').toLowerCase();
      return nome.contains(termo) || email.contains(termo);
    }).toList();
  }

  String _formatarTelefone(dynamic raw) {
    final String digits = (raw?.toString() ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    if (digits.length == 13 && digits.startsWith('55')) {
      return '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 9)}-${digits.substring(9)}';
    }
    return raw?.toString() ?? '';
  }

  String _formatarMoeda(dynamic raw) {
    final double valor = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final SessaoUsuario sessao = SessaoUsuario.instance;

    if (!sessao.autenticado || sessao.tipoConta != TipoConta.comunidade) {
      return Scaffold(
        backgroundColor: MobileFooter.backgroundColor,
        body: Column(
          children: [
            MobileHeader(logoHeight: 58, horizontalPadding: 16, onMenuPressed: _abrirMenu),
            Expanded(
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      color: BaileSulColors.pageBackground,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: const Text(
                        'Apenas contas de comunidade podem gerenciar vendedores.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: BaileSulColors.mutedText, fontSize: 15),
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [MobileFooter()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final List<Map<String, dynamic>> lista = _vendedoresFiltrados;

    return Scaffold(
      backgroundColor: MobileFooter.backgroundColor,
      body: Column(
        children: [
          MobileHeader(logoHeight: 58, horizontalPadding: 16, onMenuPressed: _abrirMenu),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregar,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      color: BaileSulColors.pageBackground,
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.people_alt_outlined, color: BaileSulColors.headerText, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Vendedores',
                                style: TextStyle(
                                  color: BaileSulColors.headerText,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Adicione uma conta pessoal já existente como vendedora da sua comunidade.',
                            style: TextStyle(color: BaileSulColors.mutedText, fontSize: 13, height: 1.35),
                          ),
                          const SizedBox(height: 16),

                          // Busca
                          TextField(
                            onChanged: (v) => setState(() => _busca = v),
                            decoration: InputDecoration(
                              hintText: 'pesquisar por nome ou email',
                              hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
                              filled: true,
                              fillColor: BaileSulColors.inputFill,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 10),

                          // Botão adicionar
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: _abrirModalAdicionar,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Adicionar vendedor'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D496B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Conteúdo
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_error != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEDEC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFF5C6C0)),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Color(0xFFB42318), fontSize: 13),
                              ),
                            )
                          else if (lista.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              decoration: BoxDecoration(
                                color: BaileSulColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: BaileSulColors.cardBorder),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, color: Colors.grey.shade400, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    _busca.isEmpty
                                        ? 'Nenhum vendedor cadastrado ainda.'
                                        : 'Nenhum vendedor encontrado para essa busca.',
                                    style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (final v in lista) ...[
                                  _VendedorCard(
                                    vendedor: v,
                                    telefoneFormatado: _formatarTelefone(v['whatsapp']),
                                    vendasFormatadas: _formatarMoeda(v['vendas_totais']),
                                    onRemover: () => _remover(v),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ],
                            ),

                          const SizedBox(height: 10),
                          Text(
                            '${lista.length} de ${_vendedores.length} vendedores',
                            style: const TextStyle(
                              color: BaileSulColors.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [MobileFooter()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendedorCard extends StatelessWidget {
  const _VendedorCard({
    required this.vendedor,
    required this.telefoneFormatado,
    required this.vendasFormatadas,
    required this.onRemover,
  });

  final Map<String, dynamic> vendedor;
  final String telefoneFormatado;
  final String vendasFormatadas;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    final String nome = vendedor['nome']?.toString() ?? 'Sem nome';
    final String? email = vendedor['usuario_email']?.toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BaileSulColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BaileSulColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: BaileSulColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (email != null && email.isNotEmpty) ? email : 'Sem e-mail cadastrado',
                  style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  telefoneFormatado.isEmpty ? '—' : telefoneFormatado,
                  style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 12),
                    children: [
                      const TextSpan(text: 'Vendas Totais: '),
                      TextSpan(
                        text: 'R\$ $vendasFormatadas',
                        style: const TextStyle(color: BaileSulColors.headerText, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemover,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFB42318), size: 22),
            tooltip: 'Remover vendedor',
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet para vincular uma conta pessoal EXISTENTE como vendedora.
class _NovoVendedorSheet extends StatefulWidget {
  const _NovoVendedorSheet();

  @override
  State<_NovoVendedorSheet> createState() => _NovoVendedorSheetState();
}

enum _StatusSugestao { idle, buscando, encontrado, naoEncontrado }

class _NovoVendedorSheetState extends State<_NovoVendedorSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  _StatusSugestao _status = _StatusSugestao.idle;
  SugestaoUsuario? _sugestao;
  Timer? _debounce;

  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _debounce?.cancel();
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    _debounce?.cancel();
    final String email = value.trim();

    if (email.isEmpty || !email.contains('@') || email.length < 5) {
      setState(() {
        _status = _StatusSugestao.idle;
        _sugestao = null;
      });
      return;
    }

    setState(() => _status = _StatusSugestao.buscando);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final SugestaoUsuario? resultado = await VendedorService.buscarSugestao(email);
      if (!mounted) return;
      setState(() {
        _sugestao = resultado;
        _status = resultado != null ? _StatusSugestao.encontrado : _StatusSugestao.naoEncontrado;
      });
    });
  }

  Future<void> _adicionar() async {
    setState(() => _erro = null);

    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _erro = 'O e-mail do usuário é obrigatório.');
      return;
    }
    if (_status == _StatusSugestao.naoEncontrado) {
      setState(() => _erro = 'Nenhum usuário pessoal encontrado com esse e-mail.');
      return;
    }

    final String whatsapp = _whatsappController.text.replaceAll(RegExp(r'\D'), '');
    if (whatsapp.length < 10 || whatsapp.length > 15) {
      setState(() => _erro = 'WhatsApp inválido. Use de 10 a 15 dígitos.');
      return;
    }

    setState(() => _enviando = true);
    try {
      await VendedorService.adicionar(email: email, whatsapp: whatsapp);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on VendedorException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Erro ao adicionar o vendedor.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Novo Vendedor',
                    style: TextStyle(
                      color: BaileSulColors.headerText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Vincule uma conta pessoal já cadastrada no BaileSul como vendedora da sua comunidade.',
                style: TextStyle(color: BaileSulColors.mutedText, fontSize: 12.5, height: 1.35),
              ),
              const SizedBox(height: 18),

              if (_erro != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEDEC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF5C6C0)),
                  ),
                  child: Text(_erro!, style: const TextStyle(color: Color(0xFFB42318), fontSize: 12.5)),
                ),
              ],

              const Text(
                'E-mail do usuário *',
                style: TextStyle(color: BaileSulColors.headerText, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                enabled: !_enviando,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                onChanged: _onEmailChanged,
                decoration: InputDecoration(
                  hintText: 'Ex: joao@email.com',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: BaileSulColors.accent, width: 1.4),
                  ),
                ),
              ),

              if (_status == _StatusSugestao.buscando) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 8),
                    Text('Buscando usuário...', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ],

              if (_status == _StatusSugestao.naoEncontrado) ...[
                const SizedBox(height: 8),
                const Text(
                  'Nenhum usuário pessoal encontrado com esse e-mail.',
                  style: TextStyle(color: Color(0xFFB42318), fontSize: 12),
                ),
              ],

              if (_status == _StatusSugestao.encontrado && _sugestao != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF7F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFE3C4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: BaileSulColors.accentSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.person_outline, size: 18, color: BaileSulColors.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _sugestao!.nome,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: BaileSulColors.headerText),
                            ),
                            Text(
                              _sugestao!.email,
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const Text('Encontrado ✓', style: TextStyle(fontSize: 11, color: Color(0xFF1E7B34), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Text(
                'WhatsApp (com DDD) *',
                style: TextStyle(color: BaileSulColors.headerText, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _whatsappController,
                enabled: !_enviando,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Ex: 47999999999',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: BaileSulColors.accent, width: 1.4),
                  ),
                ),
              ),

              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _enviando ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        foregroundColor: BaileSulColors.headerText,
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _adicionar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: const Color(0xFF0D496B),
                        foregroundColor: Colors.white,
                      ),
                      child: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Adicionar Vendedor'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}