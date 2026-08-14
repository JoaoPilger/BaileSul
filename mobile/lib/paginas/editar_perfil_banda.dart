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
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

/// Edição completa da vitrine da banda: dados gerais, foto de perfil e
/// fotos da galeria.
class EditarPerfilBandaPage extends StatefulWidget {
  const EditarPerfilBandaPage({super.key});

  @override
  State<EditarPerfilBandaPage> createState() => _EditarPerfilBandaPageState();
}

class _EditarPerfilBandaPageState extends State<EditarPerfilBandaPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _estiloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();

  bool _loading = true;
  bool _salvando = false;
  bool _enviandoFoto = false;
  bool _enviandoFotoPerfil = false;
  int? _removendoMidiaId;
  String? _erroCarregar;
  String? _erroSalvar;

  String? _fotoPerfilUrl;
  List<Map<String, dynamic>> _midias = [];

  int? get _bandaId => SessaoUsuario.instance.usuarioId;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _estiloController.dispose();
    _descricaoController.dispose();
    _whatsappController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    final int? id = _bandaId;
    setState(() {
      _loading = true;
      _erroCarregar = null;
    });

    if (id == null) {
      setState(() {
        _loading = false;
        _erroCarregar = 'Faça login em uma conta de banda para editar o perfil.';
      });
      return;
    }

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/bandas/$id');
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
        _nomeController.text = decoded['nome_artistico']?.toString() ?? '';
        _estiloController.text = decoded['estilo_musical']?.toString() ?? '';
        _descricaoController.text = decoded['descricao']?.toString() ?? '';
        _whatsappController.text = decoded['whatsapp']?.toString() ?? '';
        _videoUrlController.text = decoded['video_url']?.toString() ?? '';
        final String fotoPerfil = decoded['foto_perfil_url']?.toString() ?? '';
        _fotoPerfilUrl = fotoPerfil.isNotEmpty ? fotoPerfil : null;
        _midias = midiasRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _erroCarregar = 'Não foi possível carregar o perfil da banda.';
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

  String? _validarVideoUrl(String? value) {
    final String texto = (value ?? '').trim();
    if (texto.isEmpty) return null;
    final Uri? uri = Uri.tryParse(texto);
    final bool valido = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.contains('.') &&
        uri.host.length >= 4;
    if (!valido) return 'Informe uma URL http(s) válida (ex.: https://youtube.com/...).';
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
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/bandas/me/perfil');
      final Map<String, dynamic> corpo = {
        'nome_artistico': _nomeController.text.trim(),
        'estilo_musical': _estiloController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'video_url': _videoUrlController.text.trim(),
      };

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
        const SnackBar(content: Text('Perfil da banda atualizado com sucesso.')),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erroSalvar = 'Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  MediaType _mediaTypeFromFilename(String filename, {bool video = false}) {
    final String lower = filename.toLowerCase();
    if (video) {
      if (lower.endsWith('.mov')) return MediaType('video', 'quicktime');
      if (lower.endsWith('.webm')) return MediaType('video', 'webm');
      if (lower.endsWith('.mkv')) return MediaType('video', 'x-matroska');
      if (lower.endsWith('.avi')) return MediaType('video', 'x-msvideo');
      return MediaType('video', 'mp4');
    }
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }

  // Envia uma nova mídia (foto ou vídeo) para a galeria da banda — espelha o
  // dropzone único do site, que aceita "image/*,video/*" num só input
  // (frontend/src/paginas/editar_perfil/editar_perfil.jsx).
  Future<void> _escolherEEnviarMidia(ImageSource source, {bool video = false}) async {
    final int? id = _bandaId;
    final String? token = SessaoUsuario.instance.token;
    if (id == null || token == null || token.isEmpty) return;

    XFile? picked;
    try {
      picked = video
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(
              source: source,
              maxWidth: 1920,
              maxHeight: 1920,
              imageQuality: 85,
            );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível selecionar ${video ? 'o vídeo' : 'a imagem'}.')),
      );
      return;
    }

    if (picked == null) return;

    setState(() => _enviandoFoto = true);

    try {
      final Uint8List bytes = await picked.readAsBytes();
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/bandas/me/midias'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'arquivo',
          bytes,
          filename: picked.name,
          contentType: _mediaTypeFromFilename(picked.name, video: video),
        ),
      );

      final http.StreamedResponse streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final http.Response response = await http.Response.fromStream(streamed);

      if (response.statusCode != 201) {
        throw Exception('Falha ao enviar mídia (${response.statusCode})');
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
        SnackBar(content: Text('Não foi possível enviar ${video ? 'o vídeo' : 'a foto'}.')),
      );
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  void _abrirSeletorDeMidia() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher foto da galeria'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _escolherEEnviarMidia(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Tirar foto'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _escolherEEnviarMidia(ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Escolher vídeo da galeria'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _escolherEEnviarMidia(ImageSource.gallery, video: true);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.videocam_outlined),
                  title: const Text('Gravar vídeo'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _escolherEEnviarMidia(ImageSource.camera, video: true);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _escolherEEnviarFotoPerfil(ImageSource source) async {
    final int? id = _bandaId;
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
        Uri.parse('${ApiConfig.baseUrl}/bandas/me/foto-perfil'),
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
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/bandas/me/midias/$midiaId');
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
      backgroundColor: BaileSulColors.pageBackground,
      body: Column(
        children: [
          MobileHeader(
            logoHeight: 58,
            horizontalPadding: 16,
            onMenuPressed: _abrirMenu,
          ),
          Expanded(
            child: Container(
              color: BaileSulColors.pageBackground,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: BaileSulColors.accent));
    }

    if (_erroCarregar != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            children: [
              Icon(Icons.music_note_outlined, size: 56, color: BaileSulColors.mutedText.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                _erroCarregar!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: BaileSulColors.mutedText, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _carregarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BaileSulColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Editar Perfil da Banda',
                    style: TextStyle(
                      color: BaileSulColors.headerText,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Atualize as informações públicas da sua vitrine e sua galeria de mídias.',
                    style: TextStyle(color: BaileSulColors.headerText.withValues(alpha: 0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 18),

                  // Card: foto de perfil
                  _EditCard(
                    icon: Icons.photo_camera_outlined,
                    title: 'Foto de Perfil (Avatar)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AvatarUpload(
                          fotoUrl: _fotoPerfilUrl,
                          enviando: _enviandoFotoPerfil,
                          onTap: _abrirSeletorDeFotoPerfil,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Formatos recomendados: JPG, PNG ou WEBP (Max 5MB).',
                          style: TextStyle(color: BaileSulColors.mutedText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card: informações gerais
                  _EditCard(
                    icon: Icons.music_note_outlined,
                    title: 'Informações Gerais',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CampoTexto(
                          label: 'Nome Artístico da Banda *',
                          controller: _nomeController,
                          placeholder: 'Ex: Banda Sul Som',
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Informe o nome artístico.' : null,
                        ),
                        const SizedBox(height: 12),
                        _CampoTexto(
                          label: 'Estilo Musical',
                          controller: _estiloController,
                          placeholder: 'Ex: Gaúcha, Bandinha, Sertanejo',
                        ),
                        const SizedBox(height: 12),
                        _CampoTexto(
                          label: 'WhatsApp de Contato',
                          controller: _whatsappController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: const [TelefoneTextInputFormatter()],
                          maxLength: 15,
                          validator: _validarWhatsapp,
                          placeholder: '(48) 9 0000-0000',
                          hint: 'Utilizado para direcionar mensagens dos clientes/contratantes.',
                        ),
                        const SizedBox(height: 12),
                        _CampoTexto(
                          label: 'Link do Vídeo em Destaque (YouTube/Vimeo)',
                          controller: _videoUrlController,
                          keyboardType: TextInputType.url,
                          validator: _validarVideoUrl,
                          placeholder: 'Ex: https://www.youtube.com/watch?v=...',
                        ),
                        const SizedBox(height: 12),
                        _CampoTexto(
                          label: 'Descrição / Biografia',
                          controller: _descricaoController,
                          maxLines: 4,
                          placeholder: 'Conte a história da banda, anos de estrada, '
                              'estrutura de som, repertório...',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card: galeria
                  _EditCard(
                    icon: Icons.image_outlined,
                    title: 'Galeria de Fotos e Vídeos',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fotos e vídeos exibidos na galeria pública da vitrine.',
                          style: TextStyle(color: BaileSulColors.mutedText, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        _GaleriaMidias(
                          midias: _midias,
                          enviando: _enviandoFoto,
                          removendoMidiaId: _removendoMidiaId,
                          onAdicionar: _abrirSeletorDeMidia,
                          onRemover: _removerFoto,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

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
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _salvando ? null : _salvar,
                          style: FilledButton.styleFrom(
                            backgroundColor: BaileSulColors.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: _salvando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined, size: 18),
                          label: Text(_salvando ? 'Salvando...' : 'Salvar Alterações'),
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
    );
  }
}

/// Card branco padrão das seções de edição, espelhando `.card`/`.cardTitle`
/// de editar_perfil.module.css (radius 18px, título com ícone accent).
class _EditCard extends StatelessWidget {
  const _EditCard({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaileSulColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: BaileSulColors.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: BaileSulColors.headerText,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
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
    this.inputFormatters,
    this.validator,
    this.placeholder,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final String? placeholder;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: BaileSulColors.headerText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: BaileSulColors.headerText, fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: BaileSulColors.mutedText.withValues(alpha: 0.7), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(hint!, style: TextStyle(color: BaileSulColors.mutedText, fontSize: 11.5)),
        ],
      ],
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 92,
          decoration: BoxDecoration(
            color: BaileSulColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BaileSulColors.accent, width: 3),
          ),
          clipBehavior: Clip.antiAlias,
          child: enviando
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: BaileSulColors.accent),
                  ),
                )
              : (url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.music_note, color: BaileSulColors.accent, size: 30),
                    )
                  : const Icon(Icons.music_note, color: BaileSulColors.accent, size: 30)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enviando ? null : onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: BaileSulColors.headerText,
              side: const BorderSide(color: BaileSulColors.cardBorder),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.upload_outlined, size: 16),
            label: Text(enviando ? 'Enviando foto...' : 'Alterar Foto'),
          ),
        ),
      ],
    );
  }
}

class _GaleriaMidias extends StatelessWidget {
  const _GaleriaMidias({
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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...midias.map((midia) {
          final int? id = int.tryParse('${midia['id'] ?? ''}');
          final bool isVideo = (midia['tipo']?.toString() ?? 'imagem') == 'video';
          final String url = ApiConfig.resolveMediaUrl(midia['url']?.toString());
          final bool removendo = removendoMidiaId != null && removendoMidiaId == id;

          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  color: isVideo ? Colors.black : Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: isVideo
                      ? const Icon(Icons.play_circle_outline, color: Colors.white70, size: 28)
                      : (url.isNotEmpty
                          ? Image.network(
                              url,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image, color: Colors.white70),
                            )
                          : const Icon(Icons.image, color: Colors.white70)),
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
                      onTap: () => onRemover(midia),
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
