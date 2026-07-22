import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/tipo_conta.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart' show BaileSulColors;

/// Página de Contratos — lista os convites de eventos recebidos pela banda,
/// com abas (Pendentes / Aceitos / Recusados) e busca. Espelha
/// frontend/src/paginas/contratos/contratos.jsx, usando os componentes já
/// existentes no app mobile.
class ContratosPage extends StatefulWidget {
  const ContratosPage({super.key});

  @override
  State<ContratosPage> createState() => _ContratosPageState();
}

class _ContratosMuted {
  static const Color texto = Color(0xFF6B7280);
  static const Color textoClaro = Color(0xFF9CA3AF);
  static const Color borda = Color(0xFFE5E7EB);
  static const Color fundoAba = Color(0xFFF9FAFB);
  static const Color verde = Color(0xFF16A34A);
  static const Color verdeClaro = Color(0xFFDCFCE7);
  static const Color vermelho = Color(0xFFEF4444);
  static const Color vermelhoClaro = Color(0xFFFEE2E2);
}

const List<Map<String, String>> _kAbas = [
  {'key': 'pendente', 'label': 'Pendentes'},
  {'key': 'aceito', 'label': 'Aceitos'},
  {'key': 'recusado', 'label': 'Recusados'},
];

class _ContratosPageState extends State<ContratosPage> {
  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _contratos = [];
  int? _processandoId;
  int? _feedbackId;

  String _abaAtiva = 'pendente';
  final TextEditingController _buscaController = TextEditingController();
  String _busca = '';

  bool get _ehBanda => SessaoUsuario.instance.tipoConta == TipoConta.banda;

  @override
  void initState() {
    super.initState();
    if (_ehBanda) {
      _carregar();
    } else {
      _carregando = false;
    }
    _buscaController.addListener(() {
      setState(() => _busca = _buscaController.text);
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar({bool mostrarLoading = true}) async {
    setState(() {
      if (mostrarLoading) _carregando = true;
      _erro = null;
    });

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/bandas/me/agenda');
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final String? token = SessaoUsuario.instance.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final http.Response resp =
          await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final dynamic decoded = jsonDecode(resp.body);
        _contratos = decoded is List
            ? decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
      } else {
        _erro = 'Não foi possível carregar seus contratos.';
      }
    } catch (_) {
      _erro = 'Não foi possível carregar seus contratos.';
    }

    if (!mounted) return;
    setState(() => _carregando = false);
  }

  Future<void> _responder(int contratoId, dynamic eventoId, bool aceitar) async {
    setState(() => _processandoId = contratoId);

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/eventos/$eventoId/contratos/$contratoId');
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final String? token = SessaoUsuario.instance.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final String novoStatus = aceitar ? 'aceito' : 'recusado';
      final http.Response resp = await http
          .patch(url, headers: headers, body: jsonEncode({'status_aceite': novoStatus}))
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode >= 200 && resp.statusCode < 300 && mounted) {
        // Recarrega os contratos reais do servidor em vez de só editar o
        // estado local, garantindo que a UI nunca fique dessincronizada do banco.
        await _carregar(mostrarLoading: false);
        if (!mounted) return;
        setState(() => _feedbackId = contratoId);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _feedbackId = null);
        });
      } else if (mounted) {
        setState(() => _erro = 'Não foi possível processar essa resposta.');
      }
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível processar essa resposta.');
    } finally {
      if (mounted) setState(() => _processandoId = null);
    }
  }

  void _abrirMenu() {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  Map<String, int> get _contagem => {
        'pendente': _contratos.where((c) => c['status_aceite'] == 'pendente').length,
        'aceito': _contratos.where((c) => c['status_aceite'] == 'aceito').length,
        'recusado': _contratos.where((c) => c['status_aceite'] == 'recusado').length,
      };

  List<Map<String, dynamic>> get _filtrados {
    final String q = _busca.trim().toLowerCase();
    return _contratos.where((c) {
      if (c['status_aceite'] != _abaAtiva) return false;
      if (q.isEmpty) return true;
      final String titulo = (c['titulo']?.toString() ?? '').toLowerCase();
      final String comunidade = (c['comunidade']?.toString() ?? '').toLowerCase();
      final String cidade = (c['cidade']?.toString() ?? '').toLowerCase();
      return titulo.contains(q) || comunidade.contains(q) || cidade.contains(q);
    }).toList();
  }

  String _formatarData(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final DateTime d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          MobileHeader(onMenuPressed: _abrirMenu, logoHeight: 58, horizontalPadding: 16),
          Expanded(
            child: !_ehBanda
                ? const _AcessoNegado()
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _Hero(contagem: _contagem),
                                    const SizedBox(height: 16),
                                    _Abas(
                                      abaAtiva: _abaAtiva,
                                      contagem: _contagem,
                                      onSelecionar: (key) => setState(() => _abaAtiva = key),
                                    ),
                                    const SizedBox(height: 16),
                                    _Busca(controller: _buscaController),
                                    const SizedBox(height: 16),
                                    if (_carregando)
                                      const _VazioCard('Carregando contratos...')
                                    else if (_erro != null)
                                      _VazioCard(_erro!, danger: true)
                                    else
                                      _Lista(
                                        itens: _filtrados,
                                        abaAtiva: _abaAtiva,
                                        processandoId: _processandoId,
                                        feedbackId: _feedbackId,
                                        formatarData: _formatarData,
                                        onResponder: _responder,
                                      ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MobileFooter(logoHeight: 44, horizontalPadding: 20),
                            ],
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

class _AcessoNegado extends StatelessWidget {
  const _AcessoNegado();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Esta página é exclusiva para bandas. Faça login com uma conta de banda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BaileSulColors.headerText.withValues(alpha: 0.6), fontSize: 14),
              ),
            ),
          ),
        ),
        const MobileFooter(),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.contagem});

  final Map<String, int> contagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isNarrow = constraints.maxWidth < 520;
          final titulo = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BaileSulColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined, size: 22, color: BaileSulColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contratos',
                      style: TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aceite ou recuse os convites das comunidades',
                      style: TextStyle(color: _ContratosMuted.texto.withValues(alpha: 0.9), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          );

          final stats = Container(
            decoration: BoxDecoration(
              color: _ContratosMuted.fundoAba,
              border: Border.all(color: _ContratosMuted.borda),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
              children: [
                _heroStat('Pendentes', contagem['pendente'] ?? 0, BaileSulColors.headerText, isNarrow),
                _divisor(),
                _heroStat('Aceitos', contagem['aceito'] ?? 0, _ContratosMuted.verde, isNarrow),
                _divisor(),
                _heroStat('Recusados', contagem['recusado'] ?? 0, _ContratosMuted.vermelho, isNarrow),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [titulo, const SizedBox(height: 16), stats],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titulo),
              const SizedBox(width: 16),
              stats,
            ],
          );
        },
      ),
    );
  }

  Widget _divisor() => Container(width: 1, height: 34, color: _ContratosMuted.borda);

  Widget _heroStat(String label, int valor, Color cor, bool expandir) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$valor', style: TextStyle(color: cor, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: _ContratosMuted.textoClaro,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
    return expandir ? Expanded(child: Center(child: content)) : content;
  }
}

class _Abas extends StatelessWidget {
  const _Abas({required this.abaAtiva, required this.contagem, required this.onSelecionar});

  final String abaAtiva;
  final Map<String, int> contagem;
  final ValueChanged<String> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _kAbas.map((aba) {
        final String key = aba['key']!;
        final bool ativa = key == abaAtiva;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: key != _kAbas.last['key'] ? 8 : 0),
            child: Material(
              color: ativa ? Colors.white : _ContratosMuted.fundoAba,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelecionar(key),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ativa ? BaileSulColors.accent : _ContratosMuted.borda, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        aba['label']!,
                        style: TextStyle(color: _ContratosMuted.texto, fontSize: 11.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${contagem[key] ?? 0}',
                        style: TextStyle(
                          color: ativa ? BaileSulColors.accent : BaileSulColors.headerText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Busca extends StatelessWidget {
  const _Busca({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: BaileSulColors.headerText),
      decoration: InputDecoration(
        hintText: 'Buscar por evento, comunidade ou cidade...',
        hintStyle: const TextStyle(color: _ContratosMuted.textoClaro, fontSize: 13.5),
        prefixIcon: const Icon(Icons.search, size: 19, color: _ContratosMuted.textoClaro),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _ContratosMuted.borda, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _ContratosMuted.borda, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BaileSulColors.accent, width: 2),
        ),
      ),
    );
  }
}

class _VazioCard extends StatelessWidget {
  const _VazioCard(this.texto, {this.danger = false});

  final String texto;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: danger ? Border.all(color: const Color(0xFFFCA5A5)) : null,
      ),
      padding: EdgeInsets.symmetric(vertical: danger ? 20 : 40, horizontal: 20),
      alignment: Alignment.center,
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: danger ? _ContratosMuted.vermelho : _ContratosMuted.textoClaro,
          fontSize: 13.5,
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({
    required this.itens,
    required this.abaAtiva,
    required this.processandoId,
    required this.feedbackId,
    required this.formatarData,
    required this.onResponder,
  });

  final List<Map<String, dynamic>> itens;
  final String abaAtiva;
  final int? processandoId;
  final int? feedbackId;
  final String Function(String?) formatarData;
  final Future<void> Function(int contratoId, dynamic eventoId, bool aceitar) onResponder;

  String _mensagemVazia() {
    switch (abaAtiva) {
      case 'pendente':
        return 'Nenhum convite pendente no momento.';
      case 'aceito':
        return 'Nenhum contrato aceito ainda.';
      default:
        return 'Nenhum contrato recusado.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return _VazioCard(_mensagemVazia());

    return Column(
      children: itens.map((c) {
        final int contratoId = (c['contrato_id'] as num).toInt();
        final dynamic eventoId = c['id'];
        final bool processando = processandoId == contratoId;
        final bool flash = feedbackId == contratoId;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: flash ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 1))],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: BaileSulColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined, size: 18, color: BaileSulColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['titulo']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BaileSulColors.accent,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c['comunidade']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _ContratosMuted.texto, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetaCampo(
                      icon: Icons.calendar_month_rounded,
                      label: 'Data',
                      valor: formatarData(c['data_inicio']?.toString()),
                    ),
                  ),
                  Expanded(
                    child: _MetaCampo(
                      icon: Icons.location_on_rounded,
                      label: 'Local',
                      valor: [
                        c['local_nome']?.toString().isNotEmpty == true ? c['local_nome'].toString() : '—',
                        if (c['cidade']?.toString().isNotEmpty == true) c['cidade'].toString(),
                      ].join(' · '),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (abaAtiva == 'pendente')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: processando ? null : () => onResponder(contratoId, eventoId, true),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Aceitar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ContratosMuted.verde,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: processando ? null : () => onResponder(contratoId, eventoId, false),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Recusar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ContratosMuted.vermelho,
                          side: const BorderSide(color: _ContratosMuted.vermelho, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: abaAtiva == 'aceito' ? _ContratosMuted.verdeClaro : _ContratosMuted.vermelhoClaro,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      abaAtiva == 'aceito' ? '✓ Aceito' : '✕ Recusado',
                      style: TextStyle(
                        color: abaAtiva == 'aceito' ? _ContratosMuted.verde : _ContratosMuted.vermelho,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MetaCampo extends StatelessWidget {
  const _MetaCampo({required this.icon, required this.label, required this.valor});

  final IconData icon;
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: _ContratosMuted.textoClaro),
            const SizedBox(width: 3),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: _ContratosMuted.textoClaro,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: BaileSulColors.headerText, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}