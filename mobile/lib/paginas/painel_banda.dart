import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart' show BaileSulColors;

/// Painel inicial exibido para contas do tipo "banda" — espelha o painel
/// web (frontend/src/paginas/painel/painel_banda.jsx), mas usando os
/// componentes e a linguagem visual já existentes no app mobile.
class PainelBandaPage extends StatefulWidget {
  const PainelBandaPage({super.key});

  @override
  State<PainelBandaPage> createState() => _PainelBandaPageState();
}

class _PainelBandaPageState extends State<PainelBandaPage> {
  final ScrollController _scrollController = ScrollController();

  bool _carregando = true;
  List<Map<String, dynamic>> _agenda = [];
  int? _processandoContratoId;

  @override
  void initState() {
    super.initState();
    _carregarAgenda();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarAgenda({bool mostrarLoading = true}) async {
    if (mostrarLoading) setState(() => _carregando = true);

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
        if (decoded is List) {
          _agenda = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          _agenda = [];
        }
      } else {
        _agenda = [];
      }
    } catch (_) {
      _agenda = [];
    }

    if (!mounted) return;
    setState(() => _carregando = false);
  }

  Future<void> _responder(int contratoId, dynamic eventoId, bool aceitar) async {
    setState(() => _processandoContratoId = contratoId);

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/eventos/$eventoId/contratos/$contratoId');
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final String? token = SessaoUsuario.instance.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final http.Response resp = await http
          .patch(
            url,
            headers: headers,
            body: jsonEncode({'status_aceite': aceitar ? 'aceito' : 'recusado'}),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // Recarrega a agenda real do servidor em vez de só editar o estado
        // local, garantindo que a UI nunca fique dessincronizada do banco.
        await _carregarAgenda(mostrarLoading: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível processar essa resposta. Tente novamente.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível conectar ao servidor. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _processandoContratoId = null);
    }
  }

  void _abrirMenu() {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  List<Map<String, dynamic>> get _pendentes =>
      _agenda.where((a) => a['status_aceite'] == 'pendente').toList();

  List<Map<String, dynamic>> get _aceitos =>
      _agenda.where((a) => a['status_aceite'] == 'aceito').toList();

  // "agendado" já exclui cancelados e finalizados — sobra só o que ainda vai
  // acontecer ou está acontecendo agora (espelha painel_banda.jsx).
  List<Map<String, dynamic>> get _marcados =>
      _agenda.where((a) => a['status_evento'] == 'agendado').toList();

  List<Map<String, dynamic>> get _proximos {
    final DateTime hoje = DateTime.now();
    final DateTime hojeBase = DateTime(hoje.year, hoje.month, hoje.day);

    final List<Map<String, dynamic>> comDias = _aceitos.map((a) {
      final String? raw = a['data_inicio']?.toString();
      final DateTime? data = raw != null ? DateTime.tryParse(raw) : null;
      int? dias;
      if (data != null) {
        final DateTime diaBase = DateTime(data.year, data.month, data.day);
        dias = diaBase.difference(hojeBase).inDays;
      }
      return {...a, '_dias': dias};
    }).where((a) {
      final int? dias = a['_dias'] as int?;
      return dias == null || dias >= 0;
    }).toList();

    comDias.sort((a, b) => ((a['_dias'] as int?) ?? 0).compareTo((b['_dias'] as int?) ?? 0));
    return comDias.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final String? email = SessaoUsuario.instance.email;
    final List<Map<String, dynamic>> pendentes = _pendentes;
    final List<Map<String, dynamic>> marcados = _marcados;
    final List<Map<String, dynamic>> proximos = _proximos;

    return Scaffold(
      backgroundColor: BaileSulColors.pageBackground,
      body: Column(
        children: [
          MobileHeader(onMenuPressed: _abrirMenu, logoHeight: 58, horizontalPadding: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregarAgenda,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                  const Text(
                                    'Painel da Banda',
                                    style: TextStyle(
                                      color: BaileSulColors.headerText,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Bem-vindo${email != null && email.isNotEmpty ? ', $email' : ''}. '
                                    'Seus contratos e agenda em um só lugar.',
                                    style: TextStyle(
                                      color: BaileSulColors.headerText.withValues(alpha: 0.6),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  if (_carregando)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 40),
                                      child: Center(child: CircularProgressIndicator()),
                                    )
                                  else ...[
                                    _StatsGrid(
                                      pendentes: pendentes.length,
                                      marcados: marcados.length,
                                    ),
                                    const SizedBox(height: 28),
                                    const _SectionTitle('Atalhos'),
                                    const SizedBox(height: 12),
                                    _AtalhosGrid(
                                      qtdPendentes: pendentes.length,
                                      onContratos: () => Navigator.pushNamed(context, '/contratos'),
                                      onEditarVitrine: () => Navigator.pushNamed(context, '/configuracoes'),
                                    ),
                                    if (pendentes.isNotEmpty) ...[
                                      const SizedBox(height: 28),
                                      const _SectionTitle('Convites pendentes'),
                                      const SizedBox(height: 12),
                                      _ConvitesList(
                                        itens: pendentes,
                                        processandoId: _processandoContratoId,
                                        onResponder: _responder,
                                      ),
                                    ],
                                    const SizedBox(height: 28),
                                    const _SectionTitle('Próximos eventos confirmados'),
                                    const SizedBox(height: 12),
                                    proximos.isNotEmpty
                                        ? _ProximosList(itens: proximos)
                                        : const _EmptyCard('Nenhum evento confirmado no momento.'),
                                    const SizedBox(height: 24),
                                  ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: BaileSulColors.headerText,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.pendentes,
    required this.marcados,
  });

  final int pendentes;
  final int marcados;

  @override
  Widget build(BuildContext context) {
    // Painel da banda tem só 2 cards (espelha painel.module.css
    // .pn-stats-grid--duplo), cada um ocupando metade da largura.
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool duasColunas = constraints.maxWidth >= 380;
        final double largura = duasColunas ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: largura,
              child: _StatCard(
                label: 'Contratos Pendentes',
                value: pendentes,
                icon: Icons.warning_amber_rounded,
                iconBg: const Color(0xFFB8862B).withValues(alpha: 0.12),
                iconColor: const Color(0xFFB8862B),
              ),
            ),
            SizedBox(
              width: largura,
              child: _StatCard(
                label: 'Eventos Marcados',
                value: marcados,
                icon: Icons.calendar_month_rounded,
                iconBg: const Color(0xFF185FA5).withValues(alpha: 0.12),
                iconColor: const Color(0xFF185FA5),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _AtalhosGrid extends StatelessWidget {
  const _AtalhosGrid({
    required this.qtdPendentes,
    required this.onContratos,
    required this.onEditarVitrine,
  });

  final int qtdPendentes;
  final VoidCallback onContratos;
  final VoidCallback onEditarVitrine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool duasColunas = constraints.maxWidth >= 420;
        final double largura = duasColunas ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: largura,
              child: _AtalhoCard(
                icon: Icons.description_outlined,
                titulo: 'Contratos',
                subtitulo: qtdPendentes > 0
                    ? '$qtdPendentes pendente${qtdPendentes > 1 ? 's' : ''}'
                    : 'Ver convites das comunidades',
                onTap: onContratos,
              ),
            ),
            SizedBox(
              width: largura,
              child: _AtalhoCard(
                icon: Icons.settings_outlined,
                titulo: 'Editar Vitrine',
                subtitulo: 'Nome, estilo, foto, biografia',
                onTap: onEditarVitrine,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AtalhoCard extends StatelessWidget {
  const _AtalhoCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BaileSulColors.cardBorder),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BaileSulColors.pageBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: BaileSulColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: BaileSulColors.headerText.withValues(alpha: 0.55),
                        fontSize: 12.5,
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

class _ConvitesList extends StatelessWidget {
  const _ConvitesList({
    required this.itens,
    required this.processandoId,
    required this.onResponder,
  });

  final List<Map<String, dynamic>> itens;
  final int? processandoId;
  final Future<void> Function(int contratoId, dynamic eventoId, bool aceitar) onResponder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: itens.map((a) {
        final int contratoId = (a['contrato_id'] as num).toInt();
        final dynamic eventoId = a['id'];
        final bool processando = processandoId == contratoId;
        final String comunidade = a['comunidade']?.toString() ?? '';
        final String cidade = a['cidade']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BaileSulColors.cardBorder),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a['titulo']?.toString() ?? '',
                style: const TextStyle(
                  color: BaileSulColors.headerText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                cidade.isNotEmpty ? '$comunidade · $cidade' : comunidade,
                style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: processando ? null : () => onResponder(contratoId, eventoId, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BaileSulColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Aceitar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: processando ? null : () => onResponder(contratoId, eventoId, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BaileSulColors.headerText,
                        side: const BorderSide(color: BaileSulColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Recusar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ProximosList extends StatelessWidget {
  const _ProximosList({required this.itens});

  final List<Map<String, dynamic>> itens;

  String _sufixo(int? dias) {
    if (dias == 0) return ' · Hoje';
    if (dias == 1) return ' · Amanhã';
    if (dias != null) return ' · Em $dias dias';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: itens.map((a) {
        final String comunidade = a['comunidade']?.toString() ?? '';
        final int? dias = a['_dias'] as int?;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BaileSulColors.cardBorder),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['titulo']?.toString() ?? '',
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$comunidade${_sufixo(dias)}',
                      style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF3E4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Aceito',
                  style: TextStyle(
                    color: Color(0xFF1C8A4B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Text(
        texto,
        style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 13.5),
      ),
    );
  }
}