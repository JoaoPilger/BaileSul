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
import '../widgets/map_location_picker.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class CriarEditarEventoPage extends StatefulWidget {
  const CriarEditarEventoPage({super.key, this.isComunidade = false});

  final bool isComunidade;

  @override
  State<CriarEditarEventoPage> createState() => _CriarEditarEventoPageState();
}

class _CriarEditarEventoPageState extends State<CriarEditarEventoPage> {
  final List<String> _vendedores = <String>['Banda Beta', 'Dj Aurora'];
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _bandaController = TextEditingController();
  final TextEditingController _estiloController = TextEditingController();
  final TextEditingController _dataInicioController = TextEditingController();
  final TextEditingController _dataFimController = TextEditingController();
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFimController = TextEditingController();
  final TextEditingController _vendedorController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  MapLocation? _localizacaoSelecionada;
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
    _bandaController.dispose();
    _bandaFocusNode.dispose();
    _bandaDebounce?.cancel();
    _estiloController.dispose();
    _dataInicioController.dispose();
    _dataFimController.dispose();
    _horaInicioController.dispose();
    _horaFimController.dispose();
    _vendedorController.dispose();
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
      if (_bandaController.text.trim().isNotEmpty)
        'Banda/Artista: ${_bandaController.text.trim()}',
      if (_estiloController.text.trim().isNotEmpty)
        'Estilo musical: ${_estiloController.text.trim()}',
    ].join('\n');

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
      request.fields['data_inicio'] = dataInicio;
      request.fields['data_fim'] = dataFim;
      if (descricao.isNotEmpty) request.fields['descricao'] = descricao;
      if (endereco.isNotEmpty) request.fields['local_endereco'] = endereco;
      if (_cidadeController.text.trim().isNotEmpty) {
        request.fields['local_nome'] = _cidadeController.text.trim();
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

  void _addVendedor() {
    if (_vendedores.contains('Novo vendedor')) {
      return;
    }

    setState(() {
      _vendedores.add('Novo vendedor');
    });
  }

  void _removeVendedor(String vendedor) {
    setState(() {
      _vendedores.remove(vendedor);
    });
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
              const MobileFooter(),
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Criar Evento',
                              style: TextStyle(
                                color: BaileSulColors.headerText,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(height: 1, color: BaileSulColors.cardBorder),
                            const SizedBox(height: 18),
                            const _SectionTitle('Informacoes Basicas'),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Titulo do Evento *',
                              controller: _tituloController,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
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
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _FormField(
                                    label: 'Estilo Musical *',
                                    controller: _estiloController,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const _SectionTitle('Data e Horarios'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _FormField(
                                    label: 'Data de Inicio *',
                                    controller: _dataInicioController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 10,
                                    inputFormatters: [_DateTextInputFormatter()],
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _FormField(
                                    label: 'Data de Termino *',
                                    controller: _dataFimController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 10,
                                    inputFormatters: [_DateTextInputFormatter()],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _FormField(
                                    label: 'Horario de Inicio *',
                                    controller: _horaInicioController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 5,
                                    inputFormatters: [_TimeTextInputFormatter()],
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _FormField(
                                    label: 'Horario de Termino *',
                                    controller: _horaFimController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 5,
                                    inputFormatters: [_TimeTextInputFormatter()],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const _SectionTitle('Imagem de Capa'),
                            const SizedBox(height: 10),
                            _CoverUploadBox(onChanged: _onCapaChanged),
                            const SizedBox(height: 24),
                            const _SectionTitle('Vendedores'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _FormField(
                                    label: 'nome do vendedor',
                                    controller: _vendedorController,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 34,
                                  child: FilledButton(
                                    onPressed: _addVendedor,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: BaileSulColors.accent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: const Text('Adicionar'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ..._vendedores.map(
                              (String vendedor) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _VendorItem(
                                  label: vendedor,
                                  onRemove: () => _removeVendedor(vendedor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _SectionTitle('Localizacao'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _FormField(
                                    label: 'CEP *',
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
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _FormField(
                                    label: 'Cidade *',
                                    controller: _cidadeController,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _FormField(
                                    label: 'Bairro *',
                                    controller: _bairroController,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _FormField(
                                    label: 'Rua *',
                                    controller: _ruaController,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _FormField(
                              label: 'Referencia',
                              controller: _referenciaController,
                            ),
                            const SizedBox(height: 14),
                            MapLocationPicker(
                              height: 170,
                              selectedLocation: _localizacaoSelecionada,
                              onLocationChanged: (MapLocation location) {
                                setState(() => _localizacaoSelecionada = location);
                              },
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
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
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const MobileFooter(),
                ],
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
    this.focusNode,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final FocusNode? focusNode;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.black,
            fontSize: 11,
          ),
          counterText: '',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          filled: true,
          fillColor: BaileSulColors.inputFill,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: Colors.black, fontSize: 13),
        cursorColor: Colors.black,
      ),
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

class _VendorItem extends StatelessWidget {
  const _VendorItem({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BaileSulColors.inputFill,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded, color: Color(0xFF24313F), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Remover vendedor',
          ),
        ],
      ),
    );
  }
}
