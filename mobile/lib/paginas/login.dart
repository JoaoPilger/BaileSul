import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/tipo_conta.dart';
import '../services/auth_service.dart';
import '../services/sessao_usuario.dart';
import '../navigation/app_navigator.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

void _abrirMenu(BuildContext context) {
  MobileAppMenu.show(
    context,
    entries: MobileAppMenu.entries(context),
  );
}

bool _senhaValida(String senha) =>
    senha.length >= 8 &&
    RegExp(r'[a-zA-Z]').hasMatch(senha) &&
    RegExp(r'\d').hasMatch(senha);

String _somenteDigitos(String value) => value.replaceAll(RegExp(r'\D'), '');

String _formatarCnpj(String value) {
  final String digits = _somenteDigitos(value);
  if (digits.length != 14) return value.trim();
  return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.'
      '${digits.substring(5, 8)}/${digits.substring(8, 12)}-'
      '${digits.substring(12, 14)}';
}

bool _cnpjFormatoValido(String cnpj) =>
    RegExp(r'^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$').hasMatch(cnpj);

Widget _registrationErrorMessage(String? erro) {
  if (erro == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      erro,
      style: const TextStyle(
        color: Color(0xFFB42318),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() {
      _erro = null;
      _carregando = true;
    });

    try {
      await SessaoUsuario.instance.login(
        _emailController.text,
        _senhaController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      mostrarSnackBar('Login realizado com sucesso.');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileHeader(
            logoHeight: 58,
            horizontalPadding: 16,
            onMenuPressed: () => _abrirMenu(context),
          ),
          Expanded(
            child: Container(
              color: BaileSulColors.pageBackground,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 26,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: BaileSulColors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Login',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: BaileSulColors.headerText,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 42),
                              _LoginLabel('Email', context),
                              const SizedBox(height: 6),
                              _LoginField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !_carregando,
                              ),
                              const SizedBox(height: 24),
                              _LoginLabel('Senha', context),
                              const SizedBox(height: 6),
                              _LoginField(
                                controller: _senhaController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                enabled: !_carregando,
                                onSubmitted: (_) => _entrar(),
                              ),
                              if (_erro != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _erro!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFB42318),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 44,
                                child: FilledButton(
                                  onPressed: _carregando ? null : _entrar,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: BaileSulColors.headerText,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        BaileSulColors.mutedText,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: _carregando
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Entrar'),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'ou',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: BaileSulColors.headerText,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              const _SocialLoginButton(label: 'Google'),
                              const SizedBox(height: 10),
                              const _SocialLoginButton(label: 'Facebook'),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Não possui uma conta? ',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: BaileSulColors.headerText,
                                        ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const CadastroScreen(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: BaileSulColors.accent,
                                    ),
                                    child: Text(
                                      'Cadastro',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: BaileSulColors.accent,
                                            fontWeight: FontWeight.w500,
                                          ),
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
          ),
        ],
      ),
    );
  }
}

class CadastroScreen extends StatelessWidget {
  const CadastroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileHeader(
            logoHeight: 58,
            horizontalPadding: 16,
            onMenuPressed: () => _abrirMenu(context),
          ),
          Expanded(
            child: Container(
              color: BaileSulColors.pageBackground,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 26,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: BaileSulColors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Cadastro',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: BaileSulColors.headerText,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 26),
                              Text(
                                'Tipo de conta:',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: BaileSulColors.headerText,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              _AccountTypeButton(
                                label: 'Pessoal',
                                selected: true,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const PersonalRegistrationScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _AccountTypeButton(
                                label: 'Comunidade',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const CommunityRegistrationScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _AccountTypeButton(
                                label: 'Banda',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const BandRegistrationScreen(),
                                    ),
                                  );
                                },
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
          ),
        ],
      ),
    );
  }
}

class PersonalRegistrationScreen extends StatefulWidget {
  const PersonalRegistrationScreen({super.key});

  @override
  State<PersonalRegistrationScreen> createState() =>
      _PersonalRegistrationScreenState();
}

class _PersonalRegistrationScreenState extends State<PersonalRegistrationScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _termosAceitos = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    setState(() {
      _erro = null;
      _carregando = true;
    });

    final String nome = _nomeController.text.trim();
    final String email = _emailController.text.trim();
    final String senha = _senhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      setState(() {
        _erro = 'Preencha todos os campos obrigatórios.';
        _carregando = false;
      });
      return;
    }

    if (!_senhaValida(senha)) {
      setState(() {
        _erro =
            'A senha deve ter ao menos 8 caracteres, incluindo letras e números.';
        _carregando = false;
      });
      return;
    }

    if (!_termosAceitos) {
      setState(() {
        _erro = 'Você precisa aceitar os termos de compartilhamento.';
        _carregando = false;
      });
      return;
    }

    try {
      await SessaoUsuario.instance.cadastrar(
        email: email,
        senha: senha,
        tipo: TipoConta.pessoal,
        perfil: <String, dynamic>{'nome': nome},
      );

      if (!mounted) return;

      mostrarSnackBar('Cadastro realizado com sucesso.');
      Navigator.of(context).popUntil(
        (Route<dynamic> route) => route.isFirst,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _RegistrationScreenShell(
        title: 'Cadastro',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Informações Básicas'),
            const SizedBox(height: 18),
            _RegistrationField(
              label: 'Nome Completo',
              controller: _nomeController,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Email*',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Telefone*',
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Senha*',
              controller: _senhaController,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Imagem de Perfil'),
            const SizedBox(height: 12),
            _UploadBox(
              label: 'Clique para fazer upload de imagens',
              height: 160,
            ),
            const SizedBox(height: 8),
            _TermsRow(
              value: _termosAceitos,
              onChanged: (bool value) => setState(() => _termosAceitos = value),
            ),
            _registrationErrorMessage(_erro),
            const SizedBox(height: 6),
            _ActionRow(
              primaryLabel: 'Cadastrar-se',
              secondaryLabel: 'Cancelar',
              carregando: _carregando,
              onPrimary: _cadastrar,
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityRegistrationScreen extends StatefulWidget {
  const CommunityRegistrationScreen({super.key});

  @override
  State<CommunityRegistrationScreen> createState() =>
      _CommunityRegistrationScreenState();
}

class _CommunityRegistrationScreenState
    extends State<CommunityRegistrationScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  bool _termosAceitos = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cnpjController.dispose();
    _senhaController.dispose();
    _cepController.dispose();
    _cidadeController.dispose();
    _bairroController.dispose();
    _ruaController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    setState(() {
      _erro = null;
      _carregando = true;
    });

    final String nome = _nomeController.text.trim();
    final String telefone = _telefoneController.text.trim();
    final String email = _emailController.text.trim();
    final String cnpj = _formatarCnpj(_cnpjController.text);
    final String senha = _senhaController.text;
    final String cidade = _cidadeController.text.trim();
    final String bairro = _bairroController.text.trim();
    final String rua = _ruaController.text.trim();
    final String referencia = _referenciaController.text.trim();

    if (nome.isEmpty ||
        telefone.isEmpty ||
        email.isEmpty ||
        cnpj.isEmpty ||
        senha.isEmpty) {
      setState(() {
        _erro = 'Preencha todos os campos obrigatórios (incluindo CNPJ).';
        _carregando = false;
      });
      return;
    }

    if (!_cnpjFormatoValido(cnpj)) {
      setState(() {
        _erro = 'CNPJ deve estar no formato XX.XXX.XXX/XXXX-XX.';
        _carregando = false;
      });
      return;
    }

    if (!_senhaValida(senha)) {
      setState(() {
        _erro =
            'A senha deve ter ao menos 8 caracteres, incluindo letras e números.';
        _carregando = false;
      });
      return;
    }

    if (!_termosAceitos) {
      setState(() {
        _erro = 'Você precisa aceitar os termos de compartilhamento.';
        _carregando = false;
      });
      return;
    }

    final String endereco =
        <String>[rua, bairro, referencia].where((String s) => s.isNotEmpty).join(', ');

    try {
      await SessaoUsuario.instance.cadastrar(
        email: email,
        senha: senha,
        tipo: TipoConta.comunidade,
        perfil: <String, dynamic>{
          'nome_entidade': nome,
          'cnpj': cnpj,
          'whatsapp': _somenteDigitos(telefone),
          'endereco': endereco.isNotEmpty ? endereco : rua,
          'cidade': cidade.isNotEmpty ? cidade : null,
        },
      );

      if (!mounted) return;

      mostrarSnackBar('Cadastro realizado com sucesso.');
      Navigator.of(context).popUntil(
        (Route<dynamic> route) => route.isFirst,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _RegistrationScreenShell(
        title: 'Cadastro',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Informações Básicas'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _RegistrationField(
                    label: 'Nome da Comunidade*',
                    controller: _nomeController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
                    label: 'Telefone*',
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RegistrationField(
                    label: 'Email*',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
                    label: 'CNPJ*',
                    controller: _cnpjController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Senha*',
              controller: _senhaController,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Imagem de Capa'),
            const SizedBox(height: 12),
            const _UploadBox(
              label: 'Clique para fazer upload de imagens',
              height: 84,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Localização'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _RegistrationField(
                    label: 'CEP *',
                    controller: _cepController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
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
                  child: _RegistrationField(
                    label: 'Bairro *',
                    controller: _bairroController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
                    label: 'Rua *',
                    controller: _ruaController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Referência',
              controller: _referenciaController,
            ),
            const SizedBox(height: 12),
            const _MapPreviewBox(height: 160),
            const SizedBox(height: 8),
            _TermsRow(
              value: _termosAceitos,
              onChanged: (bool value) => setState(() => _termosAceitos = value),
            ),
            _registrationErrorMessage(_erro),
            const SizedBox(height: 6),
            _ActionRow(
              primaryLabel: 'Salvar',
              secondaryLabel: 'Cancelar',
              carregando: _carregando,
              onPrimary: _cadastrar,
            ),
          ],
        ),
      ),
    );
  }
}

class BandRegistrationScreen extends StatefulWidget {
  const BandRegistrationScreen({super.key});

  @override
  State<BandRegistrationScreen> createState() => _BandRegistrationScreenState();
}

class _BandRegistrationScreenState extends State<BandRegistrationScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  bool _termosAceitos = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cnpjController.dispose();
    _senhaController.dispose();
    _cepController.dispose();
    _cidadeController.dispose();
    _bairroController.dispose();
    _ruaController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    setState(() {
      _erro = null;
      _carregando = true;
    });

    final String nome = _nomeController.text.trim();
    final String telefone = _telefoneController.text.trim();
    final String email = _emailController.text.trim();
    final String cnpj = _formatarCnpj(_cnpjController.text);
    final String senha = _senhaController.text;

    if (nome.isEmpty ||
        telefone.isEmpty ||
        email.isEmpty ||
        cnpj.isEmpty ||
        senha.isEmpty) {
      setState(() {
        _erro = 'Preencha todos os campos obrigatórios (incluindo CNPJ).';
        _carregando = false;
      });
      return;
    }

    if (!_cnpjFormatoValido(cnpj)) {
      setState(() {
        _erro = 'CNPJ deve estar no formato XX.XXX.XXX/XXXX-XX.';
        _carregando = false;
      });
      return;
    }

    if (!_senhaValida(senha)) {
      setState(() {
        _erro =
            'A senha deve ter ao menos 8 caracteres, incluindo letras e números.';
        _carregando = false;
      });
      return;
    }

    if (!_termosAceitos) {
      setState(() {
        _erro = 'Você precisa aceitar os termos de compartilhamento.';
        _carregando = false;
      });
      return;
    }

    try {
      await SessaoUsuario.instance.cadastrar(
        email: email,
        senha: senha,
        tipo: TipoConta.banda,
        perfil: <String, dynamic>{
          'nome_artistico': nome,
          'cnpj': cnpj,
          'whatsapp': _somenteDigitos(telefone),
        },
      );

      if (!mounted) return;

      mostrarSnackBar('Cadastro realizado com sucesso.');
      Navigator.of(context).popUntil(
        (Route<dynamic> route) => route.isFirst,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _RegistrationScreenShell(
        title: 'Cadastro',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Informações da Banda'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _RegistrationField(
                    label: 'Nome da Banda*',
                    controller: _nomeController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
                    label: 'Telefone*',
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RegistrationField(
                    label: 'Email*',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
                    label: 'CNPJ*',
                    controller: _cnpjController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Senha*',
              controller: _senhaController,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _UploadBox(label: 'Imagem da Banda', height: 100),
            const SizedBox(height: 20),
            const _SectionTitle('Localização'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _RegistrationField(
                    label: 'CEP *',
                    controller: _cepController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
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
                  child: _RegistrationField(
                    label: 'Bairro *',
                    controller: _bairroController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
                    label: 'Rua *',
                    controller: _ruaController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Referência',
              controller: _referenciaController,
            ),
            const SizedBox(height: 8),
            _TermsRow(
              value: _termosAceitos,
              onChanged: (bool value) => setState(() => _termosAceitos = value),
            ),
            _registrationErrorMessage(_erro),
            const SizedBox(height: 6),
            _ActionRow(
              primaryLabel: 'Salvar',
              secondaryLabel: 'Cancelar',
              carregando: _carregando,
              onPrimary: _cadastrar,
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationScreenShell extends StatelessWidget {
  const _RegistrationScreenShell({required this.title, required this.content});

  final String title;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MobileHeader(
          logoHeight: 58,
          horizontalPadding: 16,
          onMenuPressed: () => _abrirMenu(context),
        ),
        Expanded(
          child: Container(
            color: BaileSulColors.pageBackground,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 26,
                ),
                child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: BaileSulColors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: BaileSulColors.headerText,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFE9E9E9),
                            ),
                            const SizedBox(height: 20),
                            content,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: BaileSulColors.headerText,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _RegistrationField extends StatelessWidget {
  const _RegistrationField({
    required this.label,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autocorrect: false,
        enableSuggestions: !obscureText,
        autofillHints: obscureText
            ? const <String>[AutofillHints.newPassword]
            : null,
        style: const TextStyle(
          color: BaileSulColors.headerText,
          fontSize: 14,
        ),
        cursorColor: BaileSulColors.headerText,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: BaileSulColors.headerText.withValues(alpha: 0.45),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: BaileSulColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(
              color: BaileSulColors.accent,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

class _UploadBox extends StatefulWidget {
  const _UploadBox({required this.label, required this.height});

  final String label;
  final double height;

  @override
  State<_UploadBox> createState() => _UploadBoxState();
}

class _UploadBoxState extends State<_UploadBox> {
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
      if (picked != null) {
        final Uint8List bytes = await picked.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível selecionar a imagem.'),
        ),
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
                  title: const Text('Câmera'),
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
        borderRadius: BorderRadius.circular(2),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFCFD8DF),
            border: Border.all(
              color: const Color(0xFF9DB8C8),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          clipBehavior: Clip.antiAlias,
          child: _imageBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.upload_file_rounded,
                        color: Color(0xFF295F83),
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF295F83),
                          ),
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

class _MapPreviewBox extends StatelessWidget {
  const _MapPreviewBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD8D8D8)),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.map_outlined, size: 72, color: Color(0xFFFF6A00)),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (bool? checked) => onChanged(checked ?? false),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              'termos de compartilhamento de informações',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: BaileSulColors.headerText),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.primaryLabel,
    required this.secondaryLabel,
    this.onPrimary,
    this.carregando = false,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 34,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD7D7D7),
                foregroundColor: BaileSulColors.headerText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: Text(secondaryLabel),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: SizedBox(
            height: 34,
            child: FilledButton(
              onPressed: carregando ? null : onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0E5880),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(primaryLabel),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginLabel extends StatelessWidget {
  const _LoginLabel(this.label, this.contextRef);

  final String label;
  final BuildContext contextRef;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(contextRef).textTheme.titleMedium?.copyWith(
        color: BaileSulColors.headerText,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        enabled: enabled,
        onSubmitted: onSubmitted,
        autocorrect: false,
        enableSuggestions: !obscureText,
        autofillHints: obscureText
            ? const <String>[AutofillHints.password]
            : const <String>[AutofillHints.email],
        style: const TextStyle(
          color: BaileSulColors.headerText,
          fontSize: 15,
        ),
        cursorColor: BaileSulColors.headerText,
        decoration: InputDecoration(
          filled: true,
          fillColor: BaileSulColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(
              color: BaileSulColors.accent,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: BaileSulColors.cardBorder,
          foregroundColor: BaileSulColors.headerText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AccountTypeButton extends StatelessWidget {
  const _AccountTypeButton({
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: BaileSulColors.inputFill,
          foregroundColor: BaileSulColors.headerText,
          side: BorderSide(
            color: selected
                ? const Color(0xFF1180E8)
                : BaileSulColors.inputFill,
            width: selected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
        child: Text(label),
      ),
    );
  }
}
