import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../widgets/map_location_preview.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class CriarEditarEventoPage extends StatefulWidget {
  const CriarEditarEventoPage({super.key, this.isComunidade = false});

  final bool isComunidade;

  @override
  State<CriarEditarEventoPage> createState() => _CriarEditarEventoPageState();
}

class _CriarEditarEventoPageState extends State<CriarEditarEventoPage> {
  static const Map<String, String> _tipoEventoLabels = <String, String>{
    'musical': 'Musical',
    'almoco': 'Almoço',
    'bingo': 'Bingo',
    'expos': 'Expos',
    'futebol': 'Futebol',
  };

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _bandaController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _capacidadeController = TextEditingController();
  final TextEditingController _dataInicioController = TextEditingController();
  final TextEditingController _dataFimController = TextEditingController();
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFimController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  String _tipoEvento = 'musical';

  Uint8List? _capaBytes;
  String _capaFilename = 'capa.jpg';
  bool _salvando = false;
  String? _erroSalvar;
  bool _buscandoCep = false;
  final FocusNode _cepFocusNode = FocusNode();

  final FocusNode _bandaFocusNode = FocusNode();
  Timer? _bandaDebounce;
  List<Map<String, dynamic>> _bandaSugestoes = [];
  bool _bandaBuscando = false;
  bool _bandaSugestoesOpen = false;
  int? _bandaId;

  @override
  void initState() {
    super.initState();
    _cepFocusNode.addListener(() {
      if (!_cepFocusNode.hasFocus) _buscarCep();
    });
    _bandaController.addListener(_onBandaChanged);
    _bandaFocusNode.addListener(() {
      if (!_bandaFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _bandaSugestoesOpen = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _bandaController.dispose();
    _bandaFocusNode.dispose();
    _bandaDebounce?.cancel();
    _precoController.dispose();
    _capacidadeController.dispose();
    _dataInicioController.dispose();
    _dataFimController.dispose();
    _horaInicioController.dispose();
    _horaFimController.dispose();
    _cepController.dispose();
    _cepFocusNode.dispose();
    _cidadeController.dispose();
    _bairroController.dispose();
    _ruaController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  void _onBandaChanged() {
    if (_bandaId != null && _bandaController.text.trim().isEmpty) {
      setState(() => _bandaId = null);
    }
    if (_bandaId != null) {
      setState(() => _bandaSugestoesOpen = false);
      return;
    }

    _bandaDebounce?.cancel();
    final String termo = _bandaController.text.trim();
    if (termo.length < 2) {
      setState(() {
        _bandaSugestoes = [];
        _bandaSugestoesOpen = false;
      });
      return;
    }
    _bandaDebounce = Timer(const Duration(milliseconds: 300), () => _buscarBandas(termo));
  }

  Future<void> _buscarBandas(String termo) async {
    final String? token = SessaoUsuario.instance.token;
    if (token == null || token.isEmpty) return;

    setState(() => _bandaBuscando = true);
    try {
      final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/bandas/sugestoes',
      ).replace(queryParameters: {'nome': termo});
      final http.Response resp = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (resp.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(resp.body) as List<dynamic>;
        setState(() {
          _bandaSugestoes = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _bandaSugestoesOpen = _bandaSugestoes.isNotEmpty;
        });
      }
    } catch (_) {
      // Falha silenciosa: usuário pode digitar o nome livremente
    } finally {
      if (mounted) setState(() => _bandaBuscando = false);
    }
  }

  void _selecionarBanda(Map<String, dynamic> banda) {
    setState(() {
      _bandaId = banda['usuario_id'] is int
          ? banda['usuario_id'] as int
          : int.tryParse('${banda['usuario_id']}');
      _bandaController.text = banda['nome_artistico']?.toString() ?? '';
      _bandaSugestoesOpen = false;
      _bandaSugestoes = [];
    });
  }

  Future<void> _buscarCep() async {
    final String digits = _cepController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return;

    setState(() => _buscandoCep = true);
    try {
      final Uri url = Uri.parse('https://viacep.com.br/ws/$digits/json/');
      final http.Response resp = await http.get(url).timeout(const Duration(seconds: 10));
      final dynamic decoded = jsonDecode(resp.body);

      if (!mounted || decoded is! Map || decoded['erro'] == true) return;

      setState(() {
        final String cidade = decoded['localidade']?.toString() ?? '';
        if (cidade.isNotEmpty) _cidadeController.text = cidade;
        final String bairro = decoded['bairro']?.toString() ?? '';
        if (bairro.isNotEmpty) _bairroController.text = bairro;
        final String rua = decoded['logradouro']?.toString() ?? '';
        if (rua.isNotEmpty) _ruaController.text = rua;
      });
    } catch (_) {
      // Falha silenciosa: usuário pode preencher manualmente
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  String? _formatarDataParaApi(String value) {
    final List<String> partes = value.trim().split('/');
    if (partes.length != 3) return null;

    final int? dia = int.tryParse(partes[0]);
    final int? mes = int.tryParse(partes[1]);
    final int? ano = int.tryParse(partes[2]);
    if (dia == null || mes == null || ano == null) return null;

    final DateTime data = DateTime(ano, mes, dia);
    if (data.day != dia || data.month != mes || data.year != ano) return null;

    final String mesFormatado = mes.toString().padLeft(2, '0');
    final String diaFormatado = dia.toString().padLeft(2, '0');
    return '$ano-$mesFormatado-$diaFormatado';
  }

  MediaType _mediaTypeFromFilename(String filename) {
    final String lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }

  void _onCapaChanged(Uint8List? bytes, String filename) {
    setState(() {
      _capaBytes = bytes;
      if (filename.isNotEmpty) {
        _capaFilename = filename;
      }
    });
  }

  Future<void> _salvarEvento() async {
    final String titulo = _tituloController.text.trim();
    final String? dataInicio = _formatarDataParaApi(_dataInicioController.text);
    final String? dataFim = _formatarDataParaApi(_dataFimController.text);

    if (titulo.isEmpty || dataInicio == null || dataFim == null) {
      setState(() {
        _erroSalvar =
            'Preencha titulo, data de inicio e data de termino validos.';
      });
      return;
    }

    final String? token = SessaoUsuario.instance.token;
    if (token == null || token.isEmpty) {
      setState(
        () => _erroSalvar = 'Faca login novamente para salvar o evento.',
      );
      return;
    }

    final String endereco = <String>[
      _ruaController.text.trim(),
      _bairroController.text.trim(),
      _referenciaController.text.trim(),
      _cidadeController.text.trim(),
      _cepController.text.trim(),
    ].where((String value) => value.isNotEmpty).join(', ');

    final String descricao = <String>[
      if (_descricaoController.text.trim().isNotEmpty)
        _descricaoController.text.trim(),
      if (_tipoEvento == 'musical' && _bandaId == null && _bandaController.text.trim().isNotEmpty)
        'Banda/Artista: ${_bandaController.text.trim()}',
    ].join('\n\n');

    final List<Map<String, String>> dias = <Map<String, String>>[];
    if (_horaInicioController.text.trim().isNotEmpty ||
        _horaFimController.text.trim().isNotEmpty) {
      dias.add(<String, String>{
        'data': dataInicio,
        if (_horaInicioController.text.trim().isNotEmpty)
          'hora_inicio': _horaInicioController.text.trim(),
        if (_horaFimController.text.trim().isNotEmpty)
          'hora_fim': _horaFimController.text.trim(),
      });
    }

    setState(() {
      _salvando = true;
      _erroSalvar = null;
    });

    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/eventos'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['titulo'] = titulo;
      request.fields['tipo_evento'] = _tipoEvento;
      request.fields['data_inicio'] = dataInicio;
      request.fields['data_fim'] = dataFim;
      if (descricao.isNotEmpty) request.fields['descricao'] = descricao;
      if (endereco.isNotEmpty) request.fields['local_endereco'] = endereco;
      if (_cidadeController.text.trim().isNotEmpty) {
        request.fields['local_nome'] = _cidadeController.text.trim();
      }
      final String precoTexto = _precoController.text.trim();
      if (precoTexto.isNotEmpty && !RegExp(r'^gr[aá]tis$', caseSensitive: false).hasMatch(precoTexto)) {
        final double? valor = double.tryParse(
          precoTexto.replaceAll(RegExp(r'^R\$\s*', caseSensitive: false), '').replaceAll(',', '.'),
        );
        if (valor != null && valor >= 0) {
          request.fields['valor_ingresso'] = valor.toString();
        }
      }
      if (_capacidadeController.text.trim().isNotEmpty) {
        request.fields['capacidade_maxima'] = _capacidadeController.text.trim();
      }

      if (_capaBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_capa',
            _capaBytes!,
            filename: _capaFilename,
            contentType: _mediaTypeFromFilename(_capaFilename),
          ),
        );
      }

      final http.StreamedResponse streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final http.Response response = await http.Response.fromStream(streamed);

      Map<String, dynamic> body = <String, dynamic>{};
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode != 201) {
        throw Exception(body['error']?.toString() ?? 'Erro ao salvar evento.');
      }

      final dynamic eventoCriado = body['evento'];
      final int? eventoId = eventoCriado is Map ? eventoCriado['id'] as int? : null;
      String mensagemSucesso = 'Evento salvo com sucesso.';

      if (_bandaId != null && eventoId != null) {
        try {
          final http.Response contratoResp = await http
              .post(
                Uri.parse('${ApiConfig.baseUrl}/eventos/$eventoId/contratos'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({'banda_id': _bandaId}),
              )
              .timeout(const Duration(seconds: 15));
          if (contratoResp.statusCode < 200 || contratoResp.statusCode >= 300) {
            mensagemSucesso =
                'Evento criado, mas não foi possível convidar a banda selecionada.';
          }
        } catch (_) {
          mensagemSucesso =
              'Evento criado, mas não foi possível convidar a banda selecionada.';
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemSucesso)),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroSalvar = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  void _showMenu() {
    MobileAppMenu.show(
      context,
      entries: MobileAppMenu.entries(
        context,
        onEventos: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SessaoUsuario.instance.podeCriarEvento) {
      return Scaffold(
        backgroundColor: BaileSulColors.pageBackground,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Text(
                    widget.isComunidade
                        ? 'Apenas contas Comunidade podem criar eventos.'
                        : 'Apenas contas Banda podem criar eventos.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: BaileSulColors.headerText,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BaileSulColors.pageBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileHeader(
            logoHeight: 58,
            horizontalPadding: 16,
            onMenuPressed: _showMenu,
          ),
          Expanded(
            child: Container(
              color: BaileSulColors.pageBackground,
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: BaileSulColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Criar Evento',
                              style: TextStyle(
                                color: BaileSulColors.headerText,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _SectionTitle('Informações Básicas'),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Título do Evento *',
                              controller: _tituloController,
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Descrição do Evento',
                              controller: _descricaoController,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 12),
                            if (_tipoEvento == 'musical') ...[
                              _FormField(
                                label: 'Banda/Artista *',
                                controller: _bandaController,
                                focusNode: _bandaFocusNode,
                                suffixIcon: _bandaBuscando
                                    ? const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : null,
                              ),
                              if (_bandaSugestoesOpen && _bandaSugestoes.isNotEmpty)
                                _BandaSugestoesList(
                                  sugestoes: _bandaSugestoes,
                                  onSelecionar: _selecionarBanda,
                                ),
                              const SizedBox(height: 12),
                            ],
                            _TipoEventoField(
                              value: _tipoEvento,
                              labels: _tipoEventoLabels,
                              onChanged: (value) => setState(() => _tipoEvento = value),
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Ingresso / Entrada',
                              controller: _precoController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Capacidade Máxima',
                              controller: _capacidadeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            const SizedBox(height: 24),
                            const _SectionTitle('Data e Horários'),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Data de Início *',
                              controller: _dataInicioController,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              inputFormatters: [_DateTextInputFormatter()],
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Data de Término *',
                              controller: _dataFimController,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              inputFormatters: [_DateTextInputFormatter()],
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Horário de Início',
                              controller: _horaInicioController,
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                              inputFormatters: [_TimeTextInputFormatter()],
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Horário de Término',
                              controller: _horaFimController,
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                              inputFormatters: [_TimeTextInputFormatter()],
                            ),
                            const SizedBox(height: 24),
                            const _SectionTitle('Imagem de Capa'),
                            const SizedBox(height: 10),
                            _CoverUploadBox(onChanged: _onCapaChanged),
                            const SizedBox(height: 24),
                            const _SectionTitle('Localização'),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'CEP',
                              controller: _cepController,
                              focusNode: _cepFocusNode,
                              keyboardType: TextInputType.number,
                              maxLength: 8,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              suffixIcon: _buscandoCep
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Cidade *',
                              controller: _cidadeController,
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Bairro',
                              controller: _bairroController,
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Rua',
                              controller: _ruaController,
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Referência',
                              controller: _referenciaController,
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: MapLocationPreview(
                                height: 170,
                                ruaController: _ruaController,
                                bairroController: _bairroController,
                                cidadeController: _cidadeController,
                                cepController: _cepController,
                              ),
                            ),
                            const SizedBox(height: 22),
                            if (_erroSalvar != null) ...[
                              Text(
                                _erroSalvar!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFB42318),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: BaileSulColors.headerText,
                                      side: const BorderSide(
                                        color: BaileSulColors.cardBorder,
                                      ),
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _salvando ? null : _salvarEvento,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: BaileSulColors.accent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _salvando
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Salvar Evento'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: BaileSulColors.headerText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _BandaSugestoesList extends StatelessWidget {
  const _BandaSugestoesList({required this.sugestoes, required this.onSelecionar});

  final List<Map<String, dynamic>> sugestoes;
  final void Function(Map<String, dynamic> banda) onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: BaileSulColors.cardBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: sugestoes.length,
        itemBuilder: (context, index) {
          final Map<String, dynamic> banda = sugestoes[index];
          final String nome = banda['nome_artistico']?.toString() ?? '';
          final String estilo = banda['estilo_musical']?.toString() ?? '';
          return InkWell(
            onTap: () => onSelecionar(banda),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome, style: const TextStyle(color: Colors.black, fontSize: 13)),
                  if (estilo.isNotEmpty)
                    Text(
                      estilo,
                      style: const TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.focusNode,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final FocusNode? focusNode;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: BaileSulColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: BaileSulColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: BaileSulColors.accent, width: 2),
            ),
          ),
          style: const TextStyle(color: BaileSulColors.headerText, fontSize: 14),
        ),
      ],
    );
  }
}

/// Seletor de "Tipo de Evento", espelhando o `<select>` de criar_evento.jsx.
class _TipoEventoField extends StatelessWidget {
  const _TipoEventoField({
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> labels;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Evento *',
          style: TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: BaileSulColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: BaileSulColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: BaileSulColors.accent, width: 2),
            ),
          ),
          style: const TextStyle(color: BaileSulColors.headerText, fontSize: 14),
          items: labels.entries
              .map((entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ))
              .toList(),
          onChanged: (String? novoValor) {
            if (novoValor != null) onChanged(novoValor);
          },
        ),
      ],
    );
  }
}

class _DateTextInputFormatter extends TextInputFormatter {
  const _DateTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String trimmed = digits.length > 8 ? digits.substring(0, 8) : digits;

    final StringBuffer result = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      if (i == 2 || i == 4) {
        result.write('/');
      }
      result.write(trimmed[i]);
    }

    final String text = result.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _TimeTextInputFormatter extends TextInputFormatter {
  const _TimeTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String trimmed = digits.length > 4 ? digits.substring(0, 4) : digits;

    final StringBuffer result = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      if (i == 2) {
        result.write(':');
      }
      result.write(trimmed[i]);
    }

    final String text = result.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _CoverUploadBox extends StatefulWidget {
  const _CoverUploadBox({required this.onChanged});

  final void Function(Uint8List? bytes, String filename) onChanged;

  @override
  State<_CoverUploadBox> createState() => _CoverUploadBoxState();
}

class _CoverUploadBoxState extends State<_CoverUploadBox> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
      widget.onChanged(bytes, picked.name);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel selecionar a imagem.')),
      );
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
              if (_imageBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Remover imagem',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _imageBytes = null);
                    widget.onChanged(null, '');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showSourcePicker,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: const Color(0xFFD9E5EE),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: const Color(0xFFB9CBD9),
              style: BorderStyle.solid,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _imageBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_imageBytes!, fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        color: BaileSulColors.accent,
                        size: 28,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Clique para fazer upload de imagens',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: BaileSulColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

