import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Preview do endereço no mapa, atualizado automaticamente por
/// geocodificação (Nominatim) conforme rua/bairro/cidade/CEP são
/// preenchidos — espelha o `<iframe>` que atualiza sozinho em
/// `criar_evento.jsx` no site (debounce de 800ms, mesma cascata de 3
/// tentativas de busca). Não é um seletor por toque: o site também não
/// tem isso, a localização enviada ao servidor vem da geocodificação do
/// endereço, não de um pino marcado manualmente.
class MapLocationPreview extends StatefulWidget {
  const MapLocationPreview({
    super.key,
    required this.height,
    required this.ruaController,
    required this.bairroController,
    required this.cidadeController,
    required this.cepController,
  });

  final double height;
  final TextEditingController ruaController;
  final TextEditingController bairroController;
  final TextEditingController cidadeController;
  final TextEditingController cepController;

  @override
  State<MapLocationPreview> createState() => _MapLocationPreviewState();
}

class _MapLocationPreviewState extends State<MapLocationPreview> {
  static const LatLng _defaultCenter = LatLng(-27.75, -50.5);

  final MapController _mapController = MapController();
  Timer? _debounce;
  LatLng? _marcador;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    widget.ruaController.addListener(_onEnderecoChanged);
    widget.bairroController.addListener(_onEnderecoChanged);
    widget.cidadeController.addListener(_onEnderecoChanged);
    widget.cepController.addListener(_onEnderecoChanged);
  }

  @override
  void dispose() {
    widget.ruaController.removeListener(_onEnderecoChanged);
    widget.bairroController.removeListener(_onEnderecoChanged);
    widget.cidadeController.removeListener(_onEnderecoChanged);
    widget.cepController.removeListener(_onEnderecoChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onEnderecoChanged() {
    _debounce?.cancel();
    if (widget.cidadeController.text.trim().isEmpty) {
      if (_marcador != null && mounted) setState(() => _marcador = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 800), _geocodificar);
  }

  Future<Map<String, dynamic>?> _buscarNominatim(Map<String, String> params) async {
    final Uri url = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
      queryParameters: {'format': 'json', 'limit': '1', ...params},
    );
    try {
      final http.Response resp = await http
          .get(url, headers: {'Accept-Language': 'pt-BR'})
          .timeout(const Duration(seconds: 8));
      final dynamic decoded = jsonDecode(resp.body);
      if (decoded is List && decoded.isNotEmpty) {
        return Map<String, dynamic>.from(decoded.first as Map);
      }
    } catch (_) {
      // Falha silenciosa: mantém o mapa no estado anterior.
    }
    return null;
  }

  Future<void> _geocodificar() async {
    final String rua = widget.ruaController.text.trim();
    final String bairro = widget.bairroController.text.trim();
    final String cidade = widget.cidadeController.text.trim();
    final String cep = widget.cepController.text.trim();
    if (cidade.isEmpty) return;

    if (mounted) setState(() => _carregando = true);

    Map<String, dynamic>? resultado;
    if (rua.isNotEmpty) {
      resultado = await _buscarNominatim({'country': 'Brasil', 'city': cidade, 'street': rua});
    }
    resultado ??= await _buscarNominatim({
      'q': '${[rua, bairro, cidade, cep].where((String s) => s.isNotEmpty).join(', ')}, Brasil',
    });
    resultado ??= await _buscarNominatim({'q': '$cidade, Brasil'});

    if (!mounted) return;
    if (resultado != null) {
      final double? lat = double.tryParse('${resultado['lat']}');
      final double? lon = double.tryParse('${resultado['lon']}');
      if (lat != null && lon != null) {
        final LatLng ponto = LatLng(lat, lon);
        setState(() => _marcador = ponto);
        _mapController.move(ponto, 15);
      }
    }
    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFEAEAEA),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFD8D8D8)),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _marcador ?? _defaultCenter,
              initialZoom: _marcador == null ? 6.7 : 15,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mobile',
              ),
              if (_marcador != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _marcador!,
                      width: 46,
                      height: 46,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFFFF6A00),
                        size: 46,
                        shadows: [
                          Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (_carregando)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text('Atualizando mapa…', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
