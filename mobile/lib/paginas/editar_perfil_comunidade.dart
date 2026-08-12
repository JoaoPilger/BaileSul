import 'dart:convert';

import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../services/sessao_usuario.dart';
import '../utils/formatadores.dart';
import '../widgets/map_location_picker.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

/// Edição completa da vitrine da comunidade: dados gerais, fotos e
/// localização (pino ajustável no mapa; se não for movido manualmente, o
/// servidor recalcula a localização a partir do endereço informado).
class EditarPerfilComunidadePage extends StatefulWidget {
  const EditarPerfilComunidadePage({super.key});

  @override
  State<EditarPerfilComunidadePage> createState() =>
      _EditarPerfilComunidadePageState();
}

class _EditarPerfilComunidadePageState
    extends State<EditarPerfilComunidadePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();

  bool _loading = true;
  bool _salvando = false;
  bool _enviandoFoto = false;
  bool _enviandoFotoPerfil = false;
  bool _buscandoCep = false;
  int? _removendoMidiaId;
  String? _erroCarregar;
  String? _erroSalvar;

  String? _fotoPerfilUrl;
  MapLocation? _localizacaoSelecionada;
  bool _localizacaoAlterada = false;
  List<Map<String, dynamic>> _midias = [];
  final FocusNode _cepFocusNode = FocusNode();

  int? get _comunidadeId => SessaoUsuario.instance.usuarioId;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
    _cepFocusNode.addListener(() {
      if (!_cepFocusNode.hasFocus) _buscarCep();
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _whatsappController.dispose();
    _cepController.dispose();
    _cepFocusNode.dispose();
    _enderecoController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _buscarCep() async {
    final String digits = somenteDigitos(_cepController.text);
    if (digits.length != 8) return;

    setState(() => _buscandoCep = true);
    try {
      final Uri url = Uri.parse('https://viacep.com.br/ws/$digits/json/');
      final http.Response resp = await http.get(url).timeout(const Duration(seconds: 10));
      final dynamic decoded = jsonDecode(resp.body);

      if (!mounted || decoded is! Map || decoded['erro'] == true) return;

      setState(() {
        final String logradouro = decoded['logradouro']?.toString() ?? '';
        final String bairro = decoded['bairro']?.toString() ?? '';
        final String enderecoViaCep = [
          logradouro,
          bairro,
        ].where((e) => e.isNotEmpty).join(', ');

        if (enderecoViaCep.isNotEmpty) _enderecoController.text = enderecoViaCep;
        final String cidade = decoded['localidade']?.toString() ?? '';
        if (cidade.isNotEmpty) _cidadeController.text = cidade;
        final String uf = decoded['uf']?.toString() ?? '';
        if (uf.isNotEmpty) _estadoController.text = uf;
      });
    } catch (_) {
      // Falha silenciosa: usuário pode preencher manualmente
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _carregarPerfil() async {
    final int? id = _comunidadeId;
    setState(() {
      _loading = true;
      _erroCarregar = null;
    });

    if (id == null) {
      setState(() {
        _loading = false;
        _erroCarregar = 'Faça login em uma conta de comunidade para editar o perfil.';
      });
      return;
    }

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/comunidades/$id');
      final http.Response resp =
          await http.get(url).timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        throw Exception('Falha ao carregar perfil (${resp.statusCode})');
      }

      final Map<String, dynamic> decoded =
          jsonDecode(resp.body) as Map<String, dynamic>;
      final List<dynamic> midiasRaw =
          decoded['midias'] is List ? decoded['midias'] as List<dynamic> : <dynamic>[];

      if (!mounted) return;
      setState(() {
        _nomeController.text = decoded['nome_entidade']?.toString() ?? '';
        _descricaoController.text = decoded['descricao']?.toString() ?? '';
        _whatsappController.text = decoded['whatsapp']?.toString() ?? '';
        _enderecoController.text = decoded['endereco']?.toString() ?? '';
        _cidadeController.text = decoded['cidade']?.toString() ?? '';
        _estadoController.text = decoded['estado']?.toString() ?? '';
        final String fotoPerfil = decoded['foto_perfil_url']?.toString() ?? '';
        _fotoPerfilUrl = fotoPerfil.isNotEmpty ? fotoPerfil : null;
        final double? lat = double.tryParse('${decoded['latitude'] ?? ''}');
        final double? lng = double.tryParse('${decoded['longitude'] ?? ''}');
        _localizacaoSelecionada =
            (lat != null && lng != null) ? MapLocation(latitude: lat, longitude: lng) : null;
        _localizacaoAlterada = false;
        _midias = midiasRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _erroCarregar = 'Não foi possível carregar o perfil da comunidade.';
        _loading = false;
      });
    }
  }

  Map<String, String> _authHeaders({bool json = false}) {
    final Map<String, String> headers = {};
    if (json) headers['Content-Type'] = 'application/json';
    final String? token = SessaoUsuario.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String? _validarWhatsapp(String? value) {
    final String texto = (value ?? '').trim();
    if (texto.isEmpty) return null;
    final String digits = texto.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Use de 10 a 15 dígitos (ex.: 5547999999999).';
    }
    return null;
  }

  String? _validarEstado(String? value) {
    final String texto = (value ?? '').trim();
    if (texto.isEmpty) return null;
    if (texto.length != 2) return 'Use a sigla do estado (ex.: SC).';
    return null;
  }

  Future<void> _salvar() async {
    setState(() => _erroSalvar = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String? token = SessaoUsuario.instance.token;
    if (token == null || token.isEmpty) {
      setState(() => _erroSalvar = 'Faça login novamente para salvar o perfil.');
      return;
    }

    setState(() => _salvando = true);

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/comunidades/me/perfil');
      final Map<String, dynamic> corpo = {
        'nome_entidade': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'endereco': _enderecoController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'estado': _estadoController.text.trim(),
      };
      if (_localizacaoAlterada && _localizacaoSelecionada != null) {
        corpo['latitude'] = _localizacaoSelecionada!.latitude;
        corpo['longitude'] = _localizacaoSelecionada!.longitude;
      }

      final http.Response resp = await http
          .put(
            url,
            headers: _authHeaders(json: true),
            body: jsonEncode(corpo),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        String mensagem = 'Não foi possível salvar o perfil. Tente novamente.';
        try {
          final dynamic decoded = jsonDecode(resp.body);
          if (decoded is Map && decoded['error'] is String) {
            mensagem = decoded['error'] as String;
          }
        } catch (_) {}
        setState(() => _erroSalvar = mensagem);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil da comunidade atualizado com sucesso.')),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erroSalvar = 'Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  MediaType _mediaTypeFromFilename(String filename) {
    final String lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }

  Future<void> _escolherEEnviarFoto(ImageSource source) async {
    final int? id = _comunidadeId;
    final String? token = SessaoUsuario.instance.token;
    if (id == null || token == null || token.isEmpty) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível selecionar a imagem.')),
      );
      return;
    }

    if (picked == null) return;

    setState(() => _enviandoFoto = true);

    try {
      final Uint8List bytes = await picked.readAsBytes();
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/comunidades/me/midias'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'arquivo',
          bytes,
          filename: picked.name,
          contentType: _mediaTypeFromFilename(picked.name),
        ),
      );

      final http.StreamedResponse streamed =
          await request.send().timeout(const Duration(seconds: 30));
      final http.Response response = await http.Response.fromStream(streamed);

      if (response.statusCode != 201) {
        throw Exception('Falha ao enviar foto (${response.statusCode})');
      }

      final Map<String, dynamic> midia =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _midias = [..._midias, midia];
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar a foto.')),
      );
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  void _abrirSeletorDeFoto() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _escolherEEnviarFoto(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Tirar foto'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _escolherEEnviarFoto(ImageSource.camera);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _escolherEEnviarFotoPerfil(ImageSource source) async {
    final int? id = _comunidadeId;
    final String? token = SessaoUsuario.instance.token;
    if (id == null || token == null || token.isEmpty) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível selecionar a imagem.')),
      );
      return;
    }

    if (picked == null) return;

    setState(() => _enviandoFotoPerfil = true);

    try {
      final Uint8List bytes = await picked.readAsBytes();
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/comunidades/me/foto-perfil'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'arquivo',
          bytes,
          filename: picked.name,
          contentType: _mediaTypeFromFilename(picked.name),
        ),
      );

      final http.StreamedResponse streamed =
          await request.send().timeout(const Duration(seconds: 30));
      final http.Response response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Falha ao enviar foto de perfil (${response.statusCode})');
      }

      final Map<String, dynamic> decoded =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _fotoPerfilUrl = decoded['foto_perfil_url']?.toString();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar a foto de perfil.')),
      );
    } finally {
      if (mounted) setState(() => _enviandoFotoPerfil = false);
    }
  }

  void _abrirSeletorDeFotoPerfil() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _escolherEEnviarFotoPerfil(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Tirar foto'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _escolherEEnviarFotoPerfil(ImageSource.camera);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removerFoto(Map<String, dynamic> midia) async {
    final int? midiaId = int.tryParse('${midia['id'] ?? ''}');
    final String? token = SessaoUsuario.instance.token;
    if (midiaId == null || token == null || token.isEmpty) return;

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remover foto'),
          content: const Text('Tem certeza que deseja remover esta foto da galeria?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remover', style: TextStyle(color: Color(0xFFB42318))),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    setState(() => _removendoMidiaId = midiaId);

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/comunidades/me/midias/$midiaId');
      final http.Response resp = await http
          .delete(url, headers: _authHeaders())
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        throw Exception('Falha ao remover foto (${resp.statusCode})');
      }

      if (!mounted) return;
      setState(() {
        _midias = _midias.where((m) => m['id'] != midia['id']).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível remover a foto.')),
      );
    } finally {
      if (mounted) setState(() => _removendoMidiaId = null);
    }
  }

  void _abrirMenu() {
    MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaileSulColors.dark,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MobileHeader(
              logoHeight: 58,
              horizontalPadding: 16,
              onMenuPressed: _abrirMenu,
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erroCarregar != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            children: [
              const Icon(Icons.apartment_outlined, size: 56, color: Colors.black26),
              const SizedBox(height: 16),
              Text(
                _erroCarregar!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _carregarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BaileSulColors.accent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Editar perfil da comunidade',
                style: TextStyle(
                  color: BaileSulColors.headerText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              const _SectionTitle('Informações gerais'),
              const SizedBox(height: 12),
              _CampoTexto(
                label: 'Nome da comunidade *',
                controller: _nomeController,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome da comunidade.' : null,
              ),
              const SizedBox(height: 12),
              _CampoTexto(
                label: 'Descrição',
                controller: _descricaoController,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _CampoTexto(
                label: 'WhatsApp',
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                validator: _validarWhatsapp,
              ),
              const SizedBox(height: 24),

              const _SectionTitle('Foto de perfil'),
              const SizedBox(height: 10),
              _AvatarUpload(
                fotoUrl: _fotoPerfilUrl,
                enviando: _enviandoFotoPerfil,
                onTap: _abrirSeletorDeFotoPerfil,
              ),
              const SizedBox(height: 24),

              const _SectionTitle('Fotos da comunidade'),
              const SizedBox(height: 4),
              const Text(
                'A primeira foto é usada como capa da vitrine.',
                style: TextStyle(color: BaileSulColors.mutedText, fontSize: 12),
              ),
              const SizedBox(height: 10),
              _GaleriaFotos(
                midias: _midias,
                enviando: _enviandoFoto,
                removendoMidiaId: _removendoMidiaId,
                onAdicionar: _abrirSeletorDeFoto,
                onRemover: _removerFoto,
              ),
              const SizedBox(height: 24),

              const _SectionTitle('Localização'),
              const SizedBox(height: 12),
              _CampoTexto(
                label: 'CEP',
                controller: _cepController,
                focusNode: _cepFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: const [CepTextInputFormatter()],
                suffixIcon: _buscandoCep
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              const Text(
                'Preenche endereço, cidade e estado automaticamente.',
                style: TextStyle(color: BaileSulColors.mutedText, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _CampoTexto(label: 'Endereço', controller: _enderecoController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _CampoTexto(label: 'Cidade', controller: _cidadeController),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CampoTexto(
                      label: 'Estado (UF)',
                      controller: _estadoController,
                      maxLength: 2,
                      validator: _validarEstado,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Toque no mapa para marcar o ponto exato da comunidade. Se você não '
                'marcar manualmente, a localização é calculada automaticamente a '
                'partir do endereço informado ao salvar.',
                style: TextStyle(color: BaileSulColors.mutedText, fontSize: 12),
              ),
              const SizedBox(height: 12),
              MapLocationPicker(
                height: 180,
                selectedLocation: _localizacaoSelecionada,
                onLocationChanged: (MapLocation location) {
                  setState(() {
                    _localizacaoSelecionada = location;
                    _localizacaoAlterada = true;
                  });
                },
              ),
              const SizedBox(height: 26),

              if (_erroSalvar != null) ...[
                Text(
                  _erroSalvar!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _salvando ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BaileSulColors.headerText,
                        side: const BorderSide(color: BaileSulColors.cardBorder),
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
                      onPressed: _salvando ? null : _salvar,
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
                          : const Text('Salvar alterações'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const MobileFooter(logoHeight: 52, horizontalPadding: 24),
            ],
          ),
        ),
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
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  const _CampoTexto({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.focusNode,
    this.inputFormatters,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: BaileSulColors.headerText, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: BaileSulColors.mutedText, fontSize: 13),
        counterText: maxLength != null ? '' : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF4F6F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: BaileSulColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: BaileSulColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: BaileSulColors.accent, width: 2),
        ),
      ),
    );
  }
}

class _AvatarUpload extends StatelessWidget {
  const _AvatarUpload({
    required this.fotoUrl,
    required this.enviando,
    required this.onTap,
  });

  final String? fotoUrl;
  final bool enviando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String url = ApiConfig.resolveMediaUrl(fotoUrl);

    return InkWell(
      onTap: enviando ? null : onTap,
      borderRadius: BorderRadius.circular(50),
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: BaileSulColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: BaileSulColors.cardBorder, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: enviando
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : (url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.apartment, color: Colors.white70, size: 36),
                      )
                    : const Icon(Icons.apartment, color: Colors.white70, size: 36)),
          ),
          if (!enviando)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }
}

class _GaleriaFotos extends StatelessWidget {
  const _GaleriaFotos({
    required this.midias,
    required this.enviando,
    required this.removendoMidiaId,
    required this.onAdicionar,
    required this.onRemover,
  });

  final List<Map<String, dynamic>> midias;
  final bool enviando;
  final int? removendoMidiaId;
  final VoidCallback onAdicionar;
  final void Function(Map<String, dynamic> midia) onRemover;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> fotos =
        midias.where((m) => (m['tipo']?.toString() ?? 'imagem') == 'imagem').toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...fotos.map((foto) {
          final int? id = int.tryParse('${foto['id'] ?? ''}');
          final String url = ApiConfig.resolveMediaUrl(foto['url']?.toString());
          final bool removendo = removendoMidiaId != null && removendoMidiaId == id;

          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  color: Colors.grey.shade200,
                  child: url.isNotEmpty
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image, color: Colors.white70),
                        )
                      : const Icon(Icons.image, color: Colors.white70),
                ),
                if (removendo)
                  Container(
                    width: 96,
                    height: 96,
                    color: Colors.black45,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  )
                else
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => onRemover(foto),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        InkWell(
          onTap: enviando ? null : onAdicionar,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BaileSulColors.cardBorder),
            ),
            child: enviando
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: BaileSulColors.accent, size: 22),
                        SizedBox(height: 4),
                        Text(
                          'Adicionar',
                          style: TextStyle(color: BaileSulColors.accent, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

