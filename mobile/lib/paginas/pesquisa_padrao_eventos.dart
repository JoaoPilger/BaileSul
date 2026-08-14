import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';


/// Rótulos em PT-BR para cada `tipo_evento` aceito pela API — mesma lista
/// usada em `criar_editar_evento.dart` (_tipoEventoLabels), não inventar
/// novos tipos aqui.
const Map<String, String> _tipoEventoLabels = <String, String>{
  'musical': 'Musical',
  'almoco': 'Almoço',
  'bingo': 'Bingo',
  'expos': 'Expos',
  'futebol': 'Futebol',
};

String _formatTipoEvento(String tipo) => _tipoEventoLabels[tipo] ?? tipo;

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
  String _cidadeSelecionada = '';
  String _estiloSelecionado = '';
  String _sortBy = 'recent';

  List<String> get _cidadesDisponiveis {
    final Set<String> cidades = _todosEventos
        .map((EventoApi e) => e.comunidadeCidade)
        .where((String c) => c.isNotEmpty)
        .toSet();
    final List<String> lista = cidades.toList()..sort();
    return lista;
  }

  List<String> get _estilosDisponiveis {
    final Set<String> estilos = _todosEventos
        .map((EventoApi e) => e.tipoEvento)
        .where((String s) => s.isNotEmpty)
        .toSet();
    final List<String> lista = estilos.toList()..sort();
    return lista;
  }

  bool get _temFiltrosAtivos =>
      _buscaController.text.trim().isNotEmpty ||
      _cidadeSelecionada.isNotEmpty ||
      _estiloSelecionado.isNotEmpty;

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
          _aplicarFiltros();
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

  void _aplicarFiltros() {
    final String query = _buscaController.text.trim().toLowerCase();
    Iterable<EventoApi> out = _todosEventos;
    if (query.isNotEmpty) {
      out = out.where(
        (EventoApi e) =>
            e.titulo.toLowerCase().contains(query) ||
            e.localNome.toLowerCase().contains(query) ||
            e.comunidadeNome.toLowerCase().contains(query) ||
            e.comunidadeCidade.toLowerCase().contains(query),
      );
    }
    if (_cidadeSelecionada.isNotEmpty) {
      out = out.where((EventoApi e) => e.comunidadeCidade == _cidadeSelecionada);
    }
    if (_estiloSelecionado.isNotEmpty) {
      out = out.where((EventoApi e) => e.tipoEvento == _estiloSelecionado);
    }

    final List<EventoApi> resultado = out.toList();
    int? dataOrdenavel(EventoApi e) => DateTime.tryParse(e.dataInicio)?.millisecondsSinceEpoch;
    if (_sortBy == 'recent') {
      resultado.sort((a, b) => (dataOrdenavel(b) ?? 0).compareTo(dataOrdenavel(a) ?? 0));
    } else if (_sortBy == 'oldest') {
      resultado.sort((a, b) => (dataOrdenavel(a) ?? 0).compareTo(dataOrdenavel(b) ?? 0));
    }
    _eventosFiltrados = resultado;
  }

  void _onBuscaChanged(String texto) {
    setState(_aplicarFiltros);
  }

  void _onCidadeChanged(String? cidade) {
    setState(() {
      _cidadeSelecionada = cidade ?? '';
      _aplicarFiltros();
    });
  }

  void _onEstiloChanged(String? estilo) {
    setState(() {
      _estiloSelecionado = estilo ?? '';
      _aplicarFiltros();
    });
  }

  void _onSortByChanged(String? sortBy) {
    setState(() {
      _sortBy = sortBy ?? 'recent';
      _aplicarFiltros();
    });
  }

  void _limparFiltros() {
    _buscaController.clear();
    setState(() {
      _cidadeSelecionada = '';
      _estiloSelecionado = '';
      _aplicarFiltros();
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hero escuro — espelha .listing-hero de
                                  // listings.module.css (eventos.jsx): título
                                  // e subtítulo iguais aos do site.
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topRight,
                                        end: Alignment.bottomLeft,
                                        colors: [Color(0xFF0D2535), BaileSulColors.dark],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Todos os eventos disponíveis',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w700,
                                            height: 1.15,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Veja os eventos cadastrados e encontre os melhores da sua região.',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.75),
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                'Eventos Cadastrados',
                                                style: TextStyle(
                                                  color: BaileSulColors.headerText,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: BaileSulColors.accent.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${_eventosFiltrados.length} evento${_eventosFiltrados.length == 1 ? '' : 's'}',
                                                style: const TextStyle(
                                                  color: BaileSulColors.accent,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _CampoBusca(
                                          controller: _buscaController,
                                          onChanged: _onBuscaChanged,
                                          onClear: () {
                                            _buscaController.clear();
                                            setState(_aplicarFiltros);
                                          },
                                        ),
                                        if (_cidadesDisponiveis.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          _FiltroDropdown(
                                            value: _cidadeSelecionada,
                                            hint: 'Todas as cidades',
                                            items: _cidadesDisponiveis,
                                            onChanged: _onCidadeChanged,
                                          ),
                                        ],
                                        if (_estilosDisponiveis.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          _FiltroDropdown(
                                            value: _estiloSelecionado,
                                            hint: 'Todos os tipos',
                                            items: _estilosDisponiveis,
                                            labelBuilder: _formatTipoEvento,
                                            onChanged: _onEstiloChanged,
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        _FiltroDropdown(
                                          value: _sortBy,
                                          hint: 'Mais recente',
                                          allowClear: false,
                                          items: const <String>['recent', 'oldest'],
                                          labelBuilder: (String v) =>
                                              v == 'oldest' ? 'Mais antigo' : 'Mais recente',
                                          onChanged: _onSortByChanged,
                                        ),
                                      ],
                                    ),
                                  ),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      child: _EstadoVazio(
                                        icone: Icons.event_busy_rounded,
                                        titulo: 'Nenhum evento encontrado',
                                        subtitulo: _temFiltrosAtivos
                                            ? 'Tente ajustar seus filtros ou busque por outro termo.'
                                            : 'Ainda não há eventos cadastrados na plataforma.',
                                        labelBotao: _temFiltrosAtivos ? 'Limpar filtros' : 'Atualizar',
                                        onBotao: () {
                                          if (_temFiltrosAtivos) {
                                            _limparFiltros();
                                          } else {
                                            _carregarEventos();
                                          }
                                        },
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                                      child: Column(
                                        children: _eventosFiltrados.map((evento) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 18),
                                            child: _EventoCard(evento: evento),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
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
              hintText: 'Buscar evento...',
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

/// Dropdown branco arredondado reutilizado pelos filtros de cidade, estilo
/// e ordenação — mesmo estilo visual usado em pesquisa_padrao_bandas.dart e
/// pesquisa_padrao_comunidade.dart (não usar dropdown preenchido em azul).
class _FiltroDropdown extends StatelessWidget {
  const _FiltroDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.labelBuilder,
    this.allowClear = true,
  });

  final String value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String value)? labelBuilder;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value.isEmpty ? (allowClear ? null : items.first) : value,
          hint: Text(
            hint,
            style: TextStyle(color: BaileSulColors.mutedText, fontSize: 14),
          ),
          icon: const Icon(Icons.expand_more_rounded, color: BaileSulColors.mutedText),
          style: const TextStyle(color: BaileSulColors.headerText, fontSize: 14),
          items: <DropdownMenuItem<String>>[
            if (allowClear)
              DropdownMenuItem<String>(value: '', child: Text(hint)),
            ...items.map(
              (String v) => DropdownMenuItem<String>(
                value: v,
                child: Text(labelBuilder != null ? labelBuilder!(v) : v),
              ),
            ),
          ],
          onChanged: (String? v) => onChanged(v == '' ? null : v),
        ),
      ),
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

  static const List<String> _mesesAbreviados = <String>[
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  String? get _dia {
    final DateTime? inicio = DateTime.tryParse(evento.dataInicio);
    if (inicio == null) return null;
    return inicio.day.toString().padLeft(2, '0');
  }

  String? get _mes {
    final DateTime? inicio = DateTime.tryParse(evento.dataInicio);
    if (inicio == null) return null;
    return _mesesAbreviados[inicio.month - 1];
  }

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
                    // Selo de dia/mês (topo esquerda), espelhando
                    // .eventCardDateBadge de shared.module.css.
                    if (_dia != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _SeloData(dia: _dia!, mes: _mes!),
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
                    if (evento.comunidadeNome.isNotEmpty)
                      Text(
                        evento.comunidadeNome.toUpperCase(),
                        style: const TextStyle(
                          color: BaileSulColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                      ),
                    const SizedBox(height: 2),
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
                    const SizedBox(height: 8),
                    _MetaRow(
                      icon: Icons.location_on_rounded,
                      text: evento.localComCidadeEstado,
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

/// Selo de dia/mês sobre a imagem do card (mesmo design do home.dart).
class _SeloData extends StatelessWidget {
  const _SeloData({required this.dia, required this.mes});

  final String dia;
  final String mes;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BaileSulColors.accent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: BaileSulColors.accent.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dia,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            Text(
              mes.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                height: 1.1,
              ),
            ),
          ],
        ),
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
    required this.tipoEvento,
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
      tipoEvento: json['tipo_evento']?.toString() ?? '',
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
  final String tipoEvento;

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

