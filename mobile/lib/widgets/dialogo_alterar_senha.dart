import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../paginas/home.dart' show BaileSulColors;
import '../services/sessao_usuario.dart';

/// Abre o formulário de troca de senha (senha atual + nova senha + confirmação).
Future<void> mostrarDialogoAlterarSenha(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AlterarSenhaSheet(),
  );
}

class _AlterarSenhaSheet extends StatefulWidget {
  const _AlterarSenhaSheet();

  @override
  State<_AlterarSenhaSheet> createState() => _AlterarSenhaSheetState();
}

class _AlterarSenhaSheetState extends State<_AlterarSenhaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _mostrarAtual = false;
  bool _mostrarNova = false;
  bool _mostrarConfirmar = false;
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  String? _validarNovaSenha(String? value) {
    final String senha = value ?? '';
    if (senha.isEmpty) return 'Informe a nova senha.';
    if (senha.length < 8) return 'Mínimo de 8 caracteres.';
    if (!RegExp(r'[a-zA-Z]').hasMatch(senha)) return 'Inclua pelo menos uma letra.';
    if (!RegExp(r'\d').hasMatch(senha)) return 'Inclua pelo menos um número.';
    return null;
  }

  String? _validarConfirmacao(String? value) {
    if ((value ?? '').isEmpty) return 'Confirme a nova senha.';
    if (value != _novaSenhaController.text) return 'As senhas não coincidem.';
    return null;
  }

  Future<void> _salvar() async {
    setState(() => _erro = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _salvando = true);

    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}/auth/senha');
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final String? token = SessaoUsuario.instance.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final http.Response resp = await http
          .put(
            url,
            headers: headers,
            body: jsonEncode({
              'senha_atual': _senhaAtualController.text,
              'nova_senha': _novaSenhaController.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha alterada com sucesso.')),
        );
        return;
      }

      String mensagem = 'Não foi possível alterar a senha. Tente novamente.';
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
                    'Alterar senha',
                    style: TextStyle(
                      color: BaileSulColors.headerText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Informe sua senha atual e escolha a nova senha.',
                    style: TextStyle(
                      color: BaileSulColors.mutedText.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _CampoSenha(
                    controller: _senhaAtualController,
                    label: 'Senha atual',
                    mostrar: _mostrarAtual,
                    onToggle: () => setState(() => _mostrarAtual = !_mostrarAtual),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha atual.' : null,
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: 14),
                  _CampoSenha(
                    controller: _novaSenhaController,
                    label: 'Nova senha',
                    mostrar: _mostrarNova,
                    onToggle: () => setState(() => _mostrarNova = !_mostrarNova),
                    validator: _validarNovaSenha,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 14),
                  _CampoSenha(
                    controller: _confirmarSenhaController,
                    label: 'Confirmar nova senha',
                    mostrar: _mostrarConfirmar,
                    onToggle: () => setState(() => _mostrarConfirmar = !_mostrarConfirmar),
                    validator: _validarConfirmacao,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
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
                      onPressed: _salvando ? null : _salvar,
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

class _CampoSenha extends StatelessWidget {
  const _CampoSenha({
    required this.controller,
    required this.label,
    required this.mostrar,
    required this.onToggle,
    required this.validator,
    required this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final bool mostrar;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final List<String> autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !mostrar,
      autofillHints: autofillHints,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: BaileSulColors.headerText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: BaileSulColors.mutedText.withValues(alpha: 0.8)),
        suffixIcon: IconButton(
          icon: Icon(
            mostrar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: BaileSulColors.mutedText,
          ),
          onPressed: onToggle,
        ),
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
