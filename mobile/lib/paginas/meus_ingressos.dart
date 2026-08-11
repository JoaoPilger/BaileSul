import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class MeusIngressosPage extends StatefulWidget {
  const MeusIngressosPage({super.key});

  @override
  State<MeusIngressosPage> createState() => _MeusIngressosPageState();
}

class _MeusIngressosPageState extends State<MeusIngressosPage> {
  bool _loading = true;
  String? _error;
  String _busca = '';
  String _statusFiltro = 'todos';
  List<Map<String, dynamic>> _reservas = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _carregarReservas();
  }

  Future<void> _carregarReservas() async {
    if (!SessaoUsuario.instance.autenticado) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Faça login para ver seus ingressos.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final Uri uri = Uri.parse('${ApiConfig.baseUrl}/reservas/minhas');
      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'Authorization': 'Bearer ${SessaoUsuario.instance.token}',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Falha ao carregar reservas');
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> dados = decoded is List ? decoded : <dynamic>[];
      final List<Map<String, dynamic>> reservas = dados
          .whereType<Map>()
          .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
          .toList();

      if (!mounted) return;
      setState(() {
        _reservas = reservas;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar seus ingressos.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filtradas {
    final String termo = _busca.trim().toLowerCase();

    return _reservas.where((reserva) {
      final String status = (reserva['status_pagamento'] ?? '').toString();
      if (_statusFiltro != 'todos' && status != _statusFiltro) {
        return false;
      }

      if (termo.isEmpty) {
        return true;
      }

      final String evento = (reserva['evento'] ?? '').toString().toLowerCase();
      final String data = (reserva['data_inicio'] ?? '').toString().toLowerCase();
      final String cidade = [reserva['cidade'], reserva['estado']]
          .whereType<String>()
          .where((valor) => valor.trim().isNotEmpty)
          .join(', ')
          .toLowerCase();

      return evento.contains(termo) || data.contains(termo) || cidade.contains(termo);
    }).toList();
  }

  List<Map<String, dynamic>> get _pagos =>
      _filtradas.where((reserva) => (reserva['status_pagamento'] ?? '').toString() == 'confirmado').toList();

  List<Map<String, dynamic>> get _reservados =>
      _filtradas.where((reserva) => (reserva['status_pagamento'] ?? '').toString() == 'pendente').toList();

  void _abrirMenu() {
    MobileAppMenu.show(
      context,
      entries: MobileAppMenu.entries(context),
    );
  }

  Widget _buildFilterButton(String value, String label) {
    final bool ativo = _statusFiltro == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _statusFiltro = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ativo ? const Color(0xFF0D496B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: ativo ? const Color(0xFF0D496B) : const Color(0xFFD7DDE5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: ativo ? Colors.white : BaileSulColors.headerText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Data indisponível';
    try {
      final DateTime date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return raw;
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '00:00';
    try {
      final DateTime date = DateTime.parse(raw);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '00:00';
    }
  }

  EventItem _eventItemFromReserva(Map<String, dynamic> reserva) {
    final String data = (reserva['data_inicio'] ?? '').toString();
    final String cidade = [reserva['cidade'], reserva['estado']]
        .whereType<String>()
        .where((valor) => valor.trim().isNotEmpty)
        .join(', ');

    return EventItem(
      id: int.tryParse('${reserva['evento_id'] ?? 0}') ?? 0,
      title: (reserva['evento'] ?? 'Evento').toString(),
      genre: (reserva['tipo_evento'] ?? 'Evento').toString(),
      location: cidade.isNotEmpty ? cidade : 'Local a confirmar',
      dateTime: data.isNotEmpty ? '${_formatDate(data)} • ${_formatTime(data)}' : 'Data a confirmar',
      price: 'R\$ ${(reserva['valor_ingresso'] is num ? reserva['valor_ingresso'] as num : num.tryParse('${reserva['valor_ingresso']}') ?? 0)}',
      imageUrl: ApiConfig.resolveMediaUrl((reserva['foto_capa_url'] ?? '').toString()),
    );
  }

  void _abrirDetalhes(Map<String, dynamic> reserva) {
    Navigator.pushNamed(context, '/evento', arguments: _eventItemFromReserva(reserva));
  }

  Widget _buildCard(Map<String, dynamic> reserva) {
    final String evento = (reserva['evento'] ?? 'Evento').toString();
    final String banda = (reserva['banda'] ?? reserva['comunidade'] ?? 'Artista').toString();
    final String status = (reserva['status_pagamento'] ?? '').toString();
    final String data = (reserva['data_inicio'] ?? '').toString();
    final String cidade = [reserva['cidade'], reserva['estado']]
        .whereType<String>()
        .where((valor) => valor.trim().isNotEmpty)
        .join(', ');
    final String imageUrl = ApiConfig.resolveMediaUrl((reserva['foto_capa_url'] ?? '').toString());

    final bool pago = status == 'confirmado';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7DDE5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: SizedBox(
              width: 110,
              height: 150,
              child: Image.network(
                imageUrl.isNotEmpty
                    ? imageUrl
                    : 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=900&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFFE8ECF0),
                  child: const Icon(Icons.event, size: 36, color: BaileSulColors.mutedText),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento,
                    style: const TextStyle(
                      color: BaileSulColors.headerText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banda,
                    style: const TextStyle(
                      color: BaileSulColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: pago ? const Color(0xFF0D496B) : const Color(0xFFE8F4FB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pago ? 'Pago' : 'Reservado',
                      style: TextStyle(
                        color: pago ? Colors.white : const Color(0xFF0D496B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _MetaIcon(icon: Icons.calendar_month_outlined, text: _formatDate(data)),
                      _MetaIcon(icon: Icons.access_time_outlined, text: _formatTime(data)),
                      if (cidade.isNotEmpty) _MetaIcon(icon: Icons.location_on_outlined, text: cidade),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _abrirDetalhes(reserva),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0D496B),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: const Text('Ver detalhes'),
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

  Widget _buildContent() {
    final List<Map<String, dynamic>> lista = _filtradas;
    final bool mostrarPagos = _statusFiltro == 'todos' || _statusFiltro == 'confirmado';
    final bool mostrarReservados = _statusFiltro == 'todos' || _statusFiltro == 'pendente';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Meus ingressos:',
          style: const TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD7DDE5)),
          ),
          child: TextField(
            onChanged: (value) => setState(() => _busca = value),
            decoration: InputDecoration(
              hintText: 'Buscar por evento ou data...',
              prefixIcon: const Icon(Icons.search, color: BaileSulColors.mutedText),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildFilterButton('todos', 'Todos'),
            const SizedBox(width: 8),
            _buildFilterButton('pendente', 'Reservados'),
            const SizedBox(width: 8),
            _buildFilterButton('confirmado', 'Pagos'),
          ],
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD7DDE5)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          if (mostrarPagos) ...[
            const Text(
              'Comprado(s)',
              style: TextStyle(
                color: BaileSulColors.headerText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (_pagos.isEmpty)
              const _EmptyBox(text: 'Nenhum ingresso pago ainda.')
            else
              ..._pagos.map((reserva) => _buildCard(reserva)),
            const SizedBox(height: 18),
          ],
          if (mostrarReservados) ...[
            const Text(
              'Reservado(s)',
              style: TextStyle(
                color: BaileSulColors.headerText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (_reservados.isEmpty)
              const _EmptyBox(text: 'Nenhuma reserva pendente.')
            else
              ..._reservados.map((reserva) => _buildCard(reserva)),
          ],
          if (!mostrarPagos && !mostrarReservados && lista.isEmpty)
            _EmptyBox(text: 'Nenhum ingresso encontrado.'),
        ],
      ],
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
            child: Container(
              width: double.infinity,
              color: BaileSulColors.pageBackground,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 760,
                          child: _buildContent(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const MobileFooter(),
        ],
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  const _MetaIcon({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: BaileSulColors.mutedText),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: BaileSulColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7DDE5)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: BaileSulColors.mutedText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
