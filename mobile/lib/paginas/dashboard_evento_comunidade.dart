import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart' show BaileSulColors;

class DashboardEventoPage extends StatefulWidget {
  const DashboardEventoPage({super.key, required this.eventId});

  final int eventId;

  @override
  State<DashboardEventoPage> createState() => _DashboardEventoPageState();
}

class _DashboardEventoPageState extends State<DashboardEventoPage> {
  static const List<_DashboardTab> _tabs = <_DashboardTab>[
    _DashboardTab('geral', 'Visão Geral'),
    _DashboardTab('reservas', 'Reservas'),
    _DashboardTab('vendedores', 'Vendedores'),
    _DashboardTab('bandas', 'Bandas'),
    _DashboardTab('dias', 'Dias'),
    _DashboardTab('historico', 'Histórico'),
  ];

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _dados;
  int _selectedTabIndex = 0;
  String _reservaFiltro = 'todos';
  String _reservaBusca = '';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final String? token = SessaoUsuario.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/eventos/${widget.eventId}/dashboard',
      );
      final http.Response resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        final dynamic body = resp.body.isNotEmpty
            ? jsonDecode(resp.body)
            : null;
        final String message = body is Map && body['error'] is String
            ? body['error'] as String
            : 'Falha ao carregar o dashboard.';
        throw Exception(message);
      }

      final dynamic decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Resposta inválida do servidor.');
      }

      if (!mounted) return;
      setState(() {
        _dados = decoded;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _abrirMenu() {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  Map<String, dynamic> get _evento =>
      _dados?['evento'] as Map<String, dynamic>? ?? <String, dynamic>{};
  Map<String, dynamic> get _metricas =>
      _dados?['metricas'] as Map<String, dynamic>? ?? <String, dynamic>{};
  List<dynamic> get _reservas =>
      _dados?['reservas'] as List<dynamic>? ?? <dynamic>[];
  List<dynamic> get _vendedores =>
      _dados?['vendedores'] as List<dynamic>? ?? <dynamic>[];
  List<dynamic> get _bandas =>
      _dados?['bandas'] as List<dynamic>? ?? <dynamic>[];
  List<dynamic> get _dias => _dados?['dias'] as List<dynamic>? ?? <dynamic>[];
  List<dynamic> get _historico =>
      _dados?['historico_pagamentos'] as List<dynamic>? ?? <dynamic>[];
  List<dynamic> get _crescimento =>
      _dados?['crescimento'] as List<dynamic>? ?? <dynamic>[];

  List<dynamic> get _reservasFiltradas {
    final String query = _reservaBusca.trim().toLowerCase();
    return _reservas.where((dynamic item) {
      if (item is! Map<String, dynamic>) return false;
      final String status = (item['status_pagamento']?.toString() ?? '')
          .toLowerCase();
      if (_reservaFiltro != 'todos' && status != _reservaFiltro) {
        return false;
      }

      if (query.isEmpty) return true;
      final String comprador = (item['comprador_nome']?.toString() ?? '')
          .toLowerCase();
      final String email = (item['comprador_email']?.toString() ?? '')
          .toLowerCase();
      final String vendedor = (item['vendedor_nome']?.toString() ?? '')
          .toLowerCase();
      return comprador.contains(query) ||
          email.contains(query) ||
          vendedor.contains(query);
    }).toList();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    final String raw = value.toString();
    if (raw.isEmpty) return '—';
    try {
      final DateTime dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      if (raw.length >= 10) return raw.substring(0, 10);
      return raw;
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '—';
    final String raw = value.toString();
    if (raw.isEmpty) return '—';
    try {
      final DateTime dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  String _formatBRL(dynamic value) {
    if (value == null) return 'R\$ 0,00';
    final double? number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString());
    if (number == null) return 'R\$ 0,00';
    return 'R\$ ${number.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _buildStatusBadge(String status) {
    final Map<String, Color> map = {
      'pendente': Colors.amber,
      'confirmado': Colors.green,
      'cancelado': Colors.red,
      'rejeitado': Colors.red,
      'aceito': Colors.green,
      'recusado': Colors.red,
      'agendado': Colors.blue,
      'finalizado': Colors.green,
    };
    final String label =
        {
          'pendente': 'Pendente',
          'confirmado': 'Confirmado',
          'cancelado': 'Cancelado',
          'rejeitado': 'Rejeitado',
          'aceito': 'Aceito',
          'recusado': 'Recusado',
          'agendado': 'Agendado',
          'finalizado': 'Realizado',
        }[status.toLowerCase()] ??
        status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            map[status.toLowerCase()]?.withValues(alpha: 0.12) ??
            Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              map[status.toLowerCase()]?.withValues(alpha: 0.28) ??
              Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: map[status.toLowerCase()] ?? Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final String imageUrl = ApiConfig.resolveMediaUrl(
      _evento['foto_capa_url']?.toString(),
    );
    final String heroUrl = imageUrl.isNotEmpty
        ? imageUrl
        : 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=1200&q=80';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              heroUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: BaileSulColors.dark),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_evento['status'] != null &&
                      _evento['status'].toString().isNotEmpty)
                    _buildStatusBadge(_evento['status'].toString()),
                  const SizedBox(height: 10),
                  Text(
                    _evento['titulo']?.toString() ?? 'Evento',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: BaileSulColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: BaileSulColors.headerText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: BaileSulColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_evento['tipo_evento'] != null &&
                  _evento['tipo_evento'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: BaileSulColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _evento['tipo_evento']?.toString().replaceAll('_', ' ') ??
                        '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BaileSulColors.accent,
                    ),
                  ),
                ),
              if (_evento['status'] != null &&
                  _evento['status'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _evento['status']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _evento['titulo']?.toString() ?? 'Evento',
            style: const TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _buildMetaItem(
            Icons.calendar_month_outlined,
            _evento['data_inicio']?.toString() == null
                ? 'Data não informada'
                : '${_formatDate(_evento['data_inicio'])}${_evento['data_fim'] != null && _evento['data_fim'] != _evento['data_inicio'] ? ' – ${_formatDate(_evento['data_fim'])}' : ''}',
          ),
          const SizedBox(height: 10),
          if (_evento['local_nome'] != null &&
              _evento['local_nome'].toString().isNotEmpty)
            _buildMetaItem(
              Icons.location_on_outlined,
              _evento['local_nome'].toString(),
            ),
          if (_evento['local_endereco'] != null &&
              _evento['local_endereco'].toString().isNotEmpty)
            const SizedBox(height: 10),
          if (_evento['local_endereco'] != null &&
              _evento['local_endereco'].toString().isNotEmpty)
            _buildMetaItem(
              Icons.map_outlined,
              _evento['local_endereco'].toString(),
            ),
          const SizedBox(height: 10),
          if (_evento['comunidade'] != null &&
              _evento['comunidade'].toString().isNotEmpty)
            _buildMetaItem(
              Icons.apartment_outlined,
              _evento['comunidade'].toString(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(_tabs.length, (int index) {
              final bool active = index == _selectedTabIndex;
              final String label = _tabs[index].label;
              final bool hasBadge =
                  _tabs[index].key == 'reservas' &&
                  (_metricas['reservas_pendentes'] as int? ?? 0) > 0;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label),
                      if (hasBadge) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_metricas['reservas_pendentes']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  selected: active,
                  onSelected: (_) => setState(() => _selectedTabIndex = index),
                  selectedColor: BaileSulColors.accent,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: active ? Colors.white : BaileSulColors.headerText,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: active
                        ? Colors.transparent
                        : BaileSulColors.cardBorder,
                  ),
                  avatar: null,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value, {
    IconData? icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (color ?? BaileSulColors.accent).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: color ?? BaileSulColors.accent,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final int capMax = _metricas['capacidade_maxima'] as int? ?? 0;
    final int confirmados =
        _metricas['total_ingressos_confirmados'] as int? ?? 0;
    final int pct = capMax > 0 ? (confirmados * 100 ~/ capMax) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: _buildStatCard(
            'Reservas Totais',
            '${_metricas['total_reservas'] ?? 0}',
            icon: Icons.event_note,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildStatCard(
            'Confirmadas',
            '${_metricas['reservas_confirmadas'] ?? 0}',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildStatCard(
            'Pendentes',
            '${_metricas['reservas_pendentes'] ?? 0}',
            icon: Icons.hourglass_top,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildStatCard(
            'Ingressos',
            '${_metricas['total_ingressos_confirmados'] ?? 0}',
            icon: Icons.confirmation_number_outlined,
            color: BaileSulColors.accent,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildStatCard(
            'Receita Estimada',
            _formatBRL(_metricas['receita_estimada']),
            icon: Icons.payments_outlined,
            color: const Color(0xFF0F6E56),
          ),
        ),
        const SizedBox(height: 16),
        if (capMax > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BaileSulColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ocupação de Ingressos',
                  style: TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$confirmados de $capMax confirmados',
                      style: const TextStyle(
                        color: BaileSulColors.mutedText,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 10,
                    color: BaileSulColors.accent,
                    backgroundColor: BaileSulColors.cardBorder,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BaileSulColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Crescimento de Reservas por Dia',
                style: TextStyle(
                  color: BaileSulColors.headerText,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              GrowthChart(dados: _crescimento),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReservaItem(Map<String, dynamic> reserva) {
    final String status = reserva['status_pagamento']?.toString() ?? '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reserva['comprador_nome']?.toString().isNotEmpty == true
                      ? reserva['comprador_nome'].toString()
                      : (reserva['comprador_email']?.toString() ??
                            'Comprador desconhecido'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Quantidade: ${reserva['quantidade'] ?? '—'}',
            style: const TextStyle(
              color: BaileSulColors.mutedText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pagamento: ${reserva['forma_pagamento'] ?? '—'}',
            style: const TextStyle(
              color: BaileSulColors.mutedText,
              fontSize: 13,
            ),
          ),
          if (reserva['vendedor_nome'] != null &&
              reserva['vendedor_nome'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Vendedor: ${reserva['vendedor_nome']}',
              style: const TextStyle(
                color: BaileSulColors.mutedText,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Criado em: ${_formatDateTime(reserva['criado_em'])}',
            style: const TextStyle(
              color: BaileSulColors.mutedText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservasTab() {
    final List<dynamic> reservas = _reservasFiltradas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por comprador ou vendedor...',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: BaileSulColors.mutedText,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: BaileSulColors.cardBorder),
            ),
          ),
          onChanged: (value) => setState(() => _reservaBusca = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              ['todos', 'pendente', 'confirmado', 'cancelado', 'rejeitado'].map(
                (String filtro) {
                  final bool ativo = _reservaFiltro == filtro;
                  final String label = filtro == 'todos'
                      ? 'Todos'
                      : filtro[0].toUpperCase() + filtro.substring(1);
                  return ChoiceChip(
                    label: Text(label),
                    selected: ativo,
                    onSelected: (_) => setState(() => _reservaFiltro = filtro),
                    selectedColor: BaileSulColors.accent,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: ativo ? Colors.white : BaileSulColors.headerText,
                    ),
                    side: BorderSide(
                      color: ativo
                          ? Colors.transparent
                          : BaileSulColors.cardBorder,
                    ),
                  );
                },
              ).toList(),
        ),
        const SizedBox(height: 16),
        if (reservas.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Text('Nenhuma reserva encontrada.'),
            ),
          )
        else
          Column(
            children: reservas.map((dynamic reserva) {
              if (reserva is Map<String, dynamic>) {
                return _buildReservaItem(reserva);
              }
              return const SizedBox.shrink();
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendedor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BaileSulColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  (vendedor['nome']?.toString().isNotEmpty == true
                          ? vendedor['nome'].toString()[0]
                          : 'V')
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: BaileSulColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendedor['nome']?.toString() ?? 'Vendedor',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      vendedor['whatsapp']?.toString() ??
                          'WhatsApp não informado',
                      style: const TextStyle(
                        color: BaileSulColors.mutedText,
                        fontSize: 13,
                      ),
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
                child: Text(
                  'Ingressos: ${vendedor['ingressos_vendidos_evento'] ?? 0}',
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Receita: ${_formatBRL(vendedor['receita_evento'])}',
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVendedoresTab() {
    if (_vendedores.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('Nenhum vendedor ativo.'),
        ),
      );
    }
    return Column(
      children: _vendedores.map((dynamic item) {
        if (item is Map<String, dynamic>) {
          return _buildVendorCard(item);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildBandasTab() {
    if (_bandas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('Nenhuma banda convidada para este evento.'),
        ),
      );
    }
    return Column(
      children: _bandas.map((dynamic item) {
        if (item is Map<String, dynamic>) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BaileSulColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nome_artistico']?.toString() ?? 'Banda',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Estilo: ${item['estilo_musical'] ?? '—'}',
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Status do contrato: ${item['status_aceite'] ?? '—'}',
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Assinado em: ${_formatDateTime(item['data_assinatura'])}',
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildDiasTab() {
    if (_dias.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('Nenhum dia cadastrado para este evento.'),
        ),
      );
    }
    return Column(
      children: _dias.map((dynamic item) {
        if (item is Map<String, dynamic>) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BaileSulColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data: ${_formatDate(item['data'])}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Início: ${item['hora_inicio']?.toString().padRight(5, ' ') ?? '—'}',
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fim: ${item['hora_fim']?.toString().padRight(5, ' ') ?? '—'}',
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Observação: ${item['observacao']?.toString() ?? '—'}',
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildHistoricoTab() {
    if (_historico.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text('Nenhuma alteração de pagamento registrada ainda.'),
        ),
      );
    }
    return Column(
      children: _historico.map((dynamic item) {
        if (item is Map<String, dynamic>) {
          final String anterior = item['status_anterior']?.toString() ?? '—';
          final String novo = item['status_novo']?.toString() ?? '—';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BaileSulColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reserva #${item['reserva_id'] ?? '—'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Status: $anterior → $novo',
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Operador: ${item['operador_nome'] ?? item['operador_email'] ?? 'Sistema'}',
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Data: ${_formatDateTime(item['criado_em'])}',
                  style: const TextStyle(
                    color: BaileSulColors.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildTabContent() {
    switch (_tabs[_selectedTabIndex].key) {
      case 'geral':
        return _buildOverviewTab();
      case 'reservas':
        return _buildReservasTab();
      case 'vendedores':
        return _buildVendedoresTab();
      case 'bandas':
        return _buildBandasTab();
      case 'dias':
        return _buildDiasTab();
      case 'historico':
        return _buildHistoricoTab();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaileSulColors.pageBackground,
      body: Column(
        children: [
          MobileHeader(
            onMenuPressed: _abrirMenu,
            logoHeight: 58,
            horizontalPadding: 16,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _carregarDados,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),
                            _buildHeroSection(),
                            const SizedBox(height: 16),
                            _buildHeaderCard(),
                            const SizedBox(height: 16),
                            _buildTabBar(),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildTabContent(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class GrowthChart extends StatelessWidget {
  const GrowthChart({super.key, required this.dados});

  final List<dynamic> dados;

  @override
  Widget build(BuildContext context) {
    if (dados.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Nenhuma reserva registrada ainda.',
            style: TextStyle(color: BaileSulColors.mutedText),
          ),
        ),
      );
    }

    final List<_GrowthPoint> pontos = dados.map((dynamic item) {
      final String data = item is Map<String, dynamic>
          ? item['data']?.toString() ?? '—'
          : '—';
      final int valor = item is Map<String, dynamic>
          ? (item['novas_reservas'] is int
                ? item['novas_reservas'] as int
                : int.tryParse('${item['novas_reservas'] ?? 0}') ?? 0)
          : 0;
      return _GrowthPoint(data: data, value: valor);
    }).toList();

    final int maxValue = pontos
        .map((p) => p.value)
        .fold(
          1,
          (int previous, int element) =>
              element > previous ? element : previous,
        );

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: pontos.map((p) {
          final double ratio = maxValue > 0 ? p.value / maxValue : 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 80 * ratio + 14,
                    decoration: BoxDecoration(
                      color: BaileSulColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.data.substring(5).replaceAll('-', '/'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: BaileSulColors.mutedText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GrowthPoint {
  const _GrowthPoint({required this.data, required this.value});

  final String data;
  final int value;
}

class _DashboardTab {
  const _DashboardTab(this.key, this.label);

  final String key;
  final String label;
}
