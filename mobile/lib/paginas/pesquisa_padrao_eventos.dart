import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';


/// Rota: `/pesquisa-eventos`

class PesquisaPadraoEventos extends StatefulWidget {
  const PesquisaPadraoEventos({super.key});

  @override
  State<PesquisaPadraoEventos> createState() => _PesquisaPadraoEventosState();
}

class _PesquisaPadraoEventosState extends State<PesquisaPadraoEventos> {
  final TextEditingController _buscaController = TextEditingController();

  List<EventoApi> _todosEventos = <EventoApi>[];
  List<EventoApi> _eventosFiltrados = <EventoApi>[];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarEventos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/eventos');
      final http.Response response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> dados = _extrairListaEventos(decoded);
        final List<EventoApi> eventos = dados
            .whereType<Map>()
            .map((Map<dynamic, dynamic> item) =>
                EventoApi.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (!mounted) return;
        setState(() {
          _todosEventos = eventos;
          _eventosFiltrados = List<EventoApi>.from(eventos);
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = 'Erro ao buscar eventos (${response.statusCode}).';
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Não foi possível conectar ao servidor.';
        _carregando = false;
      });
    }
  }

  List<dynamic> _extrairListaEventos(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final dynamic eventos =
          decoded['dados'] ?? decoded['eventos'] ?? decoded['data'] ?? decoded['rows'];
      if (eventos is List) return eventos;
    }
    return <dynamic>[];
  }

  void _filtrarEventos(String termo) {
    final String query = termo.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _eventosFiltrados = List<EventoApi>.from(_todosEventos);
      } else {
        _eventosFiltrados = _todosEventos
            .where(
              (EventoApi e) =>
                  e.titulo.toLowerCase().contains(query) ||
                  e.localNome.toLowerCase().contains(query) ||
                  e.comunidadeNome.toLowerCase().contains(query) ||
                  e.comunidadeCidade.toLowerCase().contains(query),
            )
            .toList();
      }
    });
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
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              color: BaileSulColors.pageBackground,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Eventos',
                                    style: TextStyle(
                                      color: BaileSulColors.headerText,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Encontre os melhores bailes da região',
                                    style: TextStyle(
                                      color: BaileSulColors.mutedText.withValues(alpha: 0.8),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _CampoBusca(
                                    controller: _buscaController,
                                    onChanged: _filtrarEventos,
                                    onClear: () {
                                      _buscaController.clear();
                                      _filtrarEventos('');
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  if (_carregando)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 60),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: BaileSulColors.accent,
                                        ),
                                      ),
                                    )
                                  else if (_erro != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: _EstadoVazio(
                                        icone: Icons.error_outline_rounded,
                                        titulo: 'Ops!',
                                        subtitulo: _erro!,
                                        labelBotao: 'Tentar novamente',
                                        onBotao: _carregarEventos,
                                      ),
                                    )
                                  else if (_eventosFiltrados.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: _EstadoVazio(
                                        icone: Icons.event_busy_rounded,
                                        titulo: 'Nenhum evento encontrado',
                                        subtitulo: _buscaController.text.trim().isNotEmpty
                                            ? 'Tente outro termo de busca.'
                                            : 'Ainda não há eventos cadastrados na plataforma.',
                                        labelBotao: _buscaController.text.trim().isNotEmpty
                                            ? 'Limpar busca'
                                            : 'Atualizar',
                                        onBotao: () {
                                          if (_buscaController.text.trim().isNotEmpty) {
                                            _buscaController.clear();
                                            _filtrarEventos('');
                                          } else {
                                            _carregarEventos();
                                          }
                                        },
                                      ),
                                    )
                                  else
                                    Column(
                                      children: _eventosFiltrados.map((evento) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 18),
                                          child: _EventoCard(evento: evento),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets de UI
// ---------------------------------------------------------------------------

class _CampoBusca extends StatelessWidget {
  const _CampoBusca({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        final bool temTexto = controller.text.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BaileSulColors.cardBorder),
            boxShadow: BaileSulColors.cardShadow,
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar eventos por nome, local ou comunidade',
              hintStyle: TextStyle(
                color: BaileSulColors.mutedText.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: BaileSulColors.mutedText.withValues(alpha: 0.6),
                size: 22,
              ),
              suffixIcon: temTexto
                  ? IconButton(
                      onPressed: onClear,
                      icon: Icon(
                        Icons.close_rounded,
                        color: BaileSulColors.mutedText.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.labelBotao,
    required this.onBotao,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;
  final String labelBotao;
  final VoidCallback onBotao;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 52, color: BaileSulColors.mutedText),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BaileSulColors.mutedText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: onBotao,
              style: FilledButton.styleFrom(
                backgroundColor: BaileSulColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                labelBotao,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de evento seguindo o mesmo design do [_EventCard] do home.dart,
/// porém usando dados reais da API ([EventoApi]).
class _EventoCard extends StatelessWidget {
  const _EventoCard({required this.evento});

  final EventoApi evento;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: BaileSulColors.cardShadow,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Navega para a página de detalhe do evento real.
            Navigator.pushNamed(
              context,
              '/evento',
              arguments: EventItem(
                id: evento.id,
                title: evento.titulo,
                genre: evento.comunidadeNome,
                location: evento.localComCidadeEstado,
                dateTime: evento.dataFormatada,
                price: evento.valorFormatado,
                imageUrl: evento.fotoCapaUrl ??
                    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80',
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagem de capa
              SizedBox(
                height: 172,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (evento.fotoCapaUrl != null &&
                        evento.fotoCapaUrl!.isNotEmpty)
                      Image.network(
                        evento.fotoCapaUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholderImagem(),
                      )
                    else
                      _placeholderImagem(),
                    // Gradiente sobre a imagem
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    // Badge da comunidade (topo esquerda)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _BadgeEvento(
                        label: evento.comunidadeNome,
                        filled: true,
                      ),
                    ),
                    // Preço (canto inferior direito)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _BadgeEvento(
                        label: evento.valorFormatado,
                        filled: false,
                      ),
                    ),
                  ],
                ),
              ),
              // Informações do card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MetaRow(
                      icon: Icons.location_on_rounded,
                      text: evento.localComCidadeEstado,
                    ),
                    const SizedBox(height: 6),
                    _MetaRow(
                      icon: Icons.calendar_month_rounded,
                      text: evento.dataFormatada,
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

  Widget _placeholderImagem() {
    return Container(
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
        size: 52,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }
}

/// Badge reutilizável (mesmo design do home.dart).
class _BadgeEvento extends StatelessWidget {
  const _BadgeEvento({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: BaileSulColors.accent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: BaileSulColors.accent.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Linha de metadados (ícone + texto).
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: BaileSulColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: BaileSulColors.accent),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: BaileSulColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Modelo de dados da API
// ---------------------------------------------------------------------------

/// Representa um evento retornado pela API (`GET /api/eventos`).
class EventoApi {
  const EventoApi({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.dataInicio,
    required this.dataFim,
    required this.localNome,
    required this.valorIngresso,
    required this.status,
    required this.fotoCapaUrl,
    required this.latitude,
    required this.longitude,
    required this.comunidadeNome,
    required this.comunidadeCidade,
    required this.comunidadeEstado,
  });

  factory EventoApi.fromJson(Map<String, dynamic> json) {
    return EventoApi(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      titulo: json['titulo']?.toString() ?? 'Evento sem titulo',
      descricao: json['descricao']?.toString() ?? '',
      dataInicio: json['data_inicio']?.toString() ?? '',
      dataFim: json['data_fim']?.toString() ?? '',
      localNome: json['local_nome']?.toString() ?? 'Local nao informado',
      valorIngresso: json['valor_ingresso'],
      status: json['status']?.toString() ?? 'agendado',
      fotoCapaUrl: json['foto_capa_url']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      comunidadeNome:
          json['comunidade_nome']?.toString() ?? json['comunidade']?.toString() ?? 'Comunidade',
      comunidadeCidade: json['comunidade_cidade']?.toString() ?? json['cidade']?.toString() ?? '',
      comunidadeEstado: json['comunidade_estado']?.toString() ?? json['estado']?.toString() ?? '',
    );
  }

  final int id;
  final String titulo;
  final String descricao;
  final String dataInicio;
  final String dataFim;
  final String localNome;
  final dynamic valorIngresso;
  final String status;
  final String? fotoCapaUrl;
  final double? latitude;
  final double? longitude;
  final String comunidadeNome;
  final String comunidadeCidade;
  final String comunidadeEstado;

  /// Formata a data para exibição amigável (ex: "14 Jun · 22h").
  String get dataFormatada {
    try {
      final DateTime inicio = DateTime.parse(dataInicio);
      const List<String> meses = <String>[
        'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
        'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
      ];
      final String dia = inicio.day.toString();
      final String mes = meses[inicio.month - 1];
      final String hora =
          '${inicio.hour.toString().padLeft(2, '0')}h';
      return '$dia $mes · $hora';
    } catch (_) {
      return dataInicio;
    }
  }

  /// Formata o valor do ingresso (ex: "R\$ 50,00" ou "Grátis").
  String get valorFormatado {
    if (valorIngresso == null) return 'Grátis';
    final double? valor = double.tryParse(valorIngresso.toString());
    if (valor == null || valor <= 0) return 'Grátis';
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Retorna "Local, Cidade/UF" ou "Local" se cidade/estado vazios.
  String get localComCidadeEstado {
    final StringBuffer sb = StringBuffer(localNome);
    if (comunidadeCidade.isNotEmpty) {
      sb.write(', $comunidadeCidade');
      if (comunidadeEstado.isNotEmpty) {
        sb.write('/$comunidadeEstado');
      }
    }
    return sb.toString();
  }
}

