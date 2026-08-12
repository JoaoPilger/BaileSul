import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../paginas/home.dart' show BaileSulColors;
import '../services/sessao_usuario.dart';

/// Abre o formulário de edição do perfil pessoal (nome, cidade, estado).
Future<void> mostrarDialogoEditarPerfilPessoal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EditarPerfilPessoalSheet(),
  );
}

class _EditarPerfilPessoalSheet extends StatefulWidget {
  const _EditarPerfilPessoalSheet();

  @override
  State<_EditarPerfilPessoalSheet> createState() => _EditarPerfilPessoalSheetState();
}

class _EditarPerfilPessoalSheetState extends State<_EditarPerfilPessoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  Map<String, String> get _headers {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final String? token = SessaoUsuario.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/auth/me/perfil');
      final http.Response resp =
          await http.get(url, headers: _headers).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(resp.body) as Map<String, dynamic>;
        _nomeController.text = (data['nome'] as String?) ?? '';
        _cidadeController.text = (data['cidade'] as String?) ?? '';
        _estadoController.text = (data['estado'] as String?) ?? '';
      } else {
        setState(() => _erro = 'Não foi possível carregar seu perfil. Tente novamente.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível conectar ao servidor.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    setState(() => _erro = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _salvando = true);

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/auth/me/perfil');
      final http.Response resp = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode({
              'nome': _nomeController.text.trim(),
              'cidade': _cidadeController.text.trim(),
              'estado': _estadoController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso.')),
        );
        return;
      }

      String mensagem = 'Não foi possível salvar o perfil. Tente novamente.';
      try {
        final dynamic decoded = jsonDecode(resp.body);
        if (decoded is Map && decoded['error'] is String) {
          mensagem = decoded['error'] as String;
        }
      } catch (_) {
        // mantém mensagem genérica
      }
      setState(() => _erro = mensagem);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível conectar ao servidor.');
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: BaileSulColors.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const Text(
                    'Editar perfil',
                    style: TextStyle(
                      color: BaileSulColors.headerText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Atualize seus dados pessoais.',
                    style: TextStyle(
                      color: BaileSulColors.mutedText.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_carregando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                    )
                  else ...[
                    _CampoTexto(
                      controller: _nomeController,
                      label: 'Nome',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe seu nome.' : null,
                    ),
                    const SizedBox(height: 14),
                    _CampoTexto(controller: _cidadeController, label: 'Cidade'),
                    const SizedBox(height: 14),
                    _CampoTexto(
                      controller: _estadoController,
                      label: 'Estado (UF)',
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                  if (_erro != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _erro!,
                      style: const TextStyle(color: Color(0xFFB42318), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: (_salvando || _carregando) ? null : _salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: BaileSulColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Salvar',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                    ),
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

class _CampoTexto extends StatelessWidget {
  const _CampoTexto({
    required this.controller,
    required this.label,
    this.validator,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 15, color: BaileSulColors.headerText),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        labelStyle: TextStyle(color: BaileSulColors.mutedText.withValues(alpha: 0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: BaileSulColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: BaileSulColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: BaileSulColors.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
