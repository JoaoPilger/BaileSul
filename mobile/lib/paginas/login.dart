import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../models/tipo_conta.dart';
import '../services/auth_service.dart';
import '../services/sessao_usuario.dart';
import '../navigation/app_navigator.dart';
import '../widgets/cnpj_status_badge.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_header.dart';
import '../utils/formatadores.dart';
import 'home.dart';

/// Consulta pública o status do CNPJ na Receita (via backend), com debounce,
/// para dar feedback visual imediato nos formulários de cadastro.
Future<void> _verificarCnpjRemoto({
  required String cnpjFormatado,
  required void Function(CnpjStatus status, String? razaoSocial) onResultado,
}) async {
  try {
    final Uri url = Uri.parse(
      '${ApiConfig.baseUrl}/cnpj/verificar?cnpj=${Uri.encodeQueryComponent(cnpjFormatado)}',
    );
    final http.Response resp = await http.get(url).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      onResultado(CnpjStatus.idle, null);
      return;
    }
    final Map<String, dynamic> decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    if (decoded['api_disponivel'] != true) {
      onResultado(CnpjStatus.idle, null);
      return;
    }
    final bool valido = decoded['valido'] == true;
    onResultado(
      valido ? CnpjStatus.valido : CnpjStatus.invalido,
      decoded['razao_social']?.toString(),
    );
  } catch (_) {
    onResultado(CnpjStatus.idle, null);
  }
}

void _abrirMenu(BuildContext context) {
  MobileAppMenu.show(context, entries: MobileAppMenu.entries(context));
}

bool _senhaValida(String senha) =>
    senha.length >= 8 &&
    RegExp(r'[a-zA-Z]').hasMatch(senha) &&
    RegExp(r'\d').hasMatch(senha);

enum _RegistrationFieldMask { telefone, cpf, cnpj, cep }

const List<String> _estilosBanda = <String>[
  'Forró', 'Axé', 'Samba', 'Pagode', 'Baile Gaúcho', 'MPB',
  'Sertanejo', 'Rock', 'Pop', 'Eletrônico', 'Gospel', 'Outro',
];

const List<String> _estadosBrasil = <String>[
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG',
  'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
];

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
                              const Center(
                                child: _CardIconBadge(Icons.person_outline),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Bem-vindo de volta',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: BaileSulColors.headerText,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Entre com suas credenciais para continuar',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: BaileSulColors.mutedText),
                              ),
                              const SizedBox(height: 32),
                              _LoginLabel('E-mail', context),
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
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Não tem uma conta? ',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: BaileSulColors.mutedText,
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
                                      'Cadastre-se',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: BaileSulColors.accent,
                                            fontWeight: FontWeight.w600,
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
                              const Center(
                                child: _CardIconBadge(Icons.person_add_alt_1_outlined),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Criar conta',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: BaileSulColors.headerText,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Escolha o tipo de cadastro para continuar',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: BaileSulColors.mutedText),
                              ),
                              const SizedBox(height: 28),
                              _AccountTypeButton(
                                icon: Icons.person_outline,
                                label: 'Pessoal',
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
                                icon: Icons.groups_outlined,
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
                                icon: Icons.music_note_outlined,
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
                              const SizedBox(height: 24),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Já tem uma conta? ',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: BaileSulColors.mutedText,
                                        ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: BaileSulColors.accent,
                                    ),
                                    child: Text(
                                      'Entrar',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: BaileSulColors.accent,
                                            fontWeight: FontWeight.w600,
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

class PersonalRegistrationScreen extends StatefulWidget {
  const PersonalRegistrationScreen({super.key});

  @override
  State<PersonalRegistrationScreen> createState() =>
      _PersonalRegistrationScreenState();
}

class _PersonalRegistrationScreenState
    extends State<PersonalRegistrationScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _sobrenomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  bool _termosAceitos = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    setState(() {
      _erro = null;
      _carregando = true;
    });

    final String nome = _nomeController.text.trim();
    final String sobrenome = _sobrenomeController.text.trim();
    final String email = _emailController.text.trim();
    final String senha = _senhaController.text;
    final String confirmarSenha = _confirmarSenhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confirmarSenha.isEmpty) {
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

    if (senha != confirmarSenha) {
      setState(() {
        _erro = 'As senhas não coincidem.';
        _carregando = false;
      });
      return;
    }

    if (!_termosAceitos) {
      setState(() {
        _erro = 'Você precisa aceitar os termos de uso.';
        _carregando = false;
      });
      return;
    }

    final String nomeCompleto = <String>[
      nome,
      sobrenome,
    ].where((String s) => s.isNotEmpty).join(' ').trim();

    try {
      await SessaoUsuario.instance.cadastrar(
        email: email,
        senha: senha,
        tipo: TipoConta.pessoal,
        perfil: <String, dynamic>{'nome': nomeCompleto},
      );

      if (!mounted) return;

      mostrarSnackBar('Cadastro realizado com sucesso.');
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
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
        icon: Icons.person_add_alt_1_outlined,
        title: 'Criar conta',
        subtitle: 'Preencha os dados para começar',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Informações Básicas'),
            const SizedBox(height: 18),
            _RegistrationField(
              label: 'Nome*',
              controller: _nomeController,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Sobrenome',
              controller: _sobrenomeController,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'E-mail*',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Telefone',
              controller: _telefoneController,
              mask: _RegistrationFieldMask.telefone,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Senha*',
              controller: _senhaController,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Confirmar senha*',
              controller: _confirmarSenhaController,
              obscureText: true,
            ),
            const SizedBox(height: 8),
            _TermsRow(
              label: 'Li e aceito os Termos de Uso e a Política de Privacidade',
              value: _termosAceitos,
              onChanged: (bool value) => setState(() => _termosAceitos = value),
            ),
            _registrationErrorMessage(_erro),
            const SizedBox(height: 6),
            _ActionRow(
              primaryLabel: 'Criar conta',
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
  final TextEditingController _confirmarSenhaController =
      TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  bool _termosAceitos = false;
  bool _carregando = false;
  bool _buscandoCep = false;
  String? _erro;
  final FocusNode _cepFocusNode = FocusNode();
  CnpjStatus _cnpjStatus = CnpjStatus.idle;
  String? _cnpjRazaoSocial;
  Timer? _cnpjDebounce;

  @override
  void initState() {
    super.initState();
    _cepFocusNode.addListener(() {
      if (!_cepFocusNode.hasFocus) _buscarCep();
    });
    _cnpjController.addListener(_onCnpjChanged);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cnpjController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _cepController.dispose();
    _cepFocusNode.dispose();
    _cidadeController.dispose();
    _bairroController.dispose();
    _ruaController.dispose();
    _referenciaController.dispose();
    _cnpjDebounce?.cancel();
    super.dispose();
  }

  void _onCnpjChanged() {
    _cnpjDebounce?.cancel();
    final String cnpj = formatarCnpj(_cnpjController.text);
    if (!cnpjFormatoValido(cnpj)) {
      if (_cnpjStatus != CnpjStatus.idle) setState(() => _cnpjStatus = CnpjStatus.idle);
      return;
    }
    setState(() => _cnpjStatus = CnpjStatus.checking);
    _cnpjDebounce = Timer(const Duration(milliseconds: 600), () {
      _verificarCnpjRemoto(
        cnpjFormatado: cnpj,
        onResultado: (status, razaoSocial) {
          if (!mounted) return;
          setState(() {
            _cnpjStatus = status;
            _cnpjRazaoSocial = razaoSocial;
          });
        },
      );
    });
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

  Future<void> _cadastrar() async {
    setState(() {
      _erro = null;
      _carregando = true;
    });

    final String nome = _nomeController.text.trim();
    final String telefone = _telefoneController.text.trim();
    final String email = _emailController.text.trim();
    final String cnpj = formatarCnpj(_cnpjController.text);
    final String senha = _senhaController.text;
    final String confirmarSenha = _confirmarSenhaController.text;
    final String cidade = _cidadeController.text.trim();
    final String bairro = _bairroController.text.trim();
    final String rua = _ruaController.text.trim();
    final String referencia = _referenciaController.text.trim();

    if (nome.isEmpty ||
        telefone.isEmpty ||
        email.isEmpty ||
        cnpj.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      setState(() {
        _erro = 'Preencha todos os campos obrigatórios (incluindo CNPJ).';
        _carregando = false;
      });
      return;
    }

    if (!cnpjFormatoValido(cnpj)) {
      setState(() {
        _erro = 'CNPJ deve estar no formato AA.AAA.AAA/AAAA-DV.';
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

    if (senha != confirmarSenha) {
      setState(() {
        _erro = 'As senhas não coincidem.';
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

    final String endereco = <String>[
      rua,
      bairro,
      referencia,
    ].where((String s) => s.isNotEmpty).join(', ');

    try {
      await SessaoUsuario.instance.cadastrar(
        email: email,
        senha: senha,
        tipo: TipoConta.comunidade,
        perfil: <String, dynamic>{
          'nome_entidade': nome,
          'cnpj': cnpj,
          'whatsapp': somenteDigitos(telefone),
          'endereco': endereco.isNotEmpty ? endereco : rua,
          'cidade': cidade.isNotEmpty ? cidade : null,
        },
      );

      if (!mounted) return;

      mostrarSnackBar('Cadastro realizado com sucesso.');
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
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
        icon: Icons.groups_outlined,
        title: 'Cadastro de Comunidade',
        subtitle: 'Preencha os dados da sua comunidade',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Informações Básicas'),
            const SizedBox(height: 18),
            _RegistrationField(
              label: 'Nome da Comunidade*',
              controller: _nomeController,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Telefone*',
              controller: _telefoneController,
              mask: _RegistrationFieldMask.telefone,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Email*',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'CNPJ*',
              controller: _cnpjController,
              mask: _RegistrationFieldMask.cnpj,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: CnpjStatusBadge(status: _cnpjStatus, razaoSocial: _cnpjRazaoSocial),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Senha de acesso'),
            const SizedBox(height: 18),
            _RegistrationField(
              label: 'Senha*',
              controller: _senhaController,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Confirmar senha*',
              controller: _confirmarSenhaController,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Imagem de Capa'),
            const SizedBox(height: 12),
            const _UploadBox(
              label: 'Clique para fazer upload de imagens',
              height: 100,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Localização'),
            const SizedBox(height: 18),
            _RegistrationField(
              label: 'CEP *',
              controller: _cepController,
              mask: _RegistrationFieldMask.cep,
              focusNode: _cepFocusNode,
              loading: _buscandoCep,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Cidade *',
              controller: _cidadeController,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Bairro *',
              controller: _bairroController,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Rua *',
              controller: _ruaController,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Referência',
              controller: _referenciaController,
            ),
            const SizedBox(height: 8),
            _TermsRow(
              label: 'Aceito os Termos de compartilhamento de informações',
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
  final TextEditingController _confirmarSenhaController =
      TextEditingController();
  final TextEditingController _cidadeCriacaoController =
      TextEditingController();

  String? _estilo;
  String? _estadoCriacao;
  bool _termosAceitos = false;
  bool _carregando = false;
  String? _erro;
  CnpjStatus _cnpjStatus = CnpjStatus.idle;
  String? _cnpjRazaoSocial;
  Timer? _cnpjDebounce;

  @override
  void initState() {
    super.initState();
    _cnpjController.addListener(_onCnpjChanged);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cnpjController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _cidadeCriacaoController.dispose();
    _cnpjDebounce?.cancel();
    super.dispose();
  }

  void _onCnpjChanged() {
    _cnpjDebounce?.cancel();
    final String cnpj = formatarCnpj(_cnpjController.text);
    if (!cnpjFormatoValido(cnpj)) {
      if (_cnpjStatus != CnpjStatus.idle) setState(() => _cnpjStatus = CnpjStatus.idle);
      return;
    }
    setState(() => _cnpjStatus = CnpjStatus.checking);
    _cnpjDebounce = Timer(const Duration(milliseconds: 600), () {
      _verificarCnpjRemoto(
        cnpjFormatado: cnpj,
        onResultado: (status, razaoSocial) {
          if (!mounted) return;
          setState(() {
            _cnpjStatus = status;
            _cnpjRazaoSocial = razaoSocial;
          });
        },
      );
    });
  }

  Future<void> _cadastrar() async {
    setState(() {
      _erro = null;
      _carregando = true;
    });

    final String nome = _nomeController.text.trim();
    final String telefone = _telefoneController.text.trim();
    final String email = _emailController.text.trim();
    final String cnpj = formatarCnpj(_cnpjController.text);
    final String senha = _senhaController.text;
    final String confirmarSenha = _confirmarSenhaController.text;

    if (nome.isEmpty ||
        telefone.isEmpty ||
        email.isEmpty ||
        cnpj.isEmpty ||
        _estilo == null ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      setState(() {
        _erro = 'Preencha todos os campos obrigatórios (incluindo CNPJ e estilo).';
        _carregando = false;
      });
      return;
    }

    if (!cnpjFormatoValido(cnpj)) {
      setState(() {
        _erro = 'CNPJ deve estar no formato AA.AAA.AAA/AAAA-DV.';
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

    if (senha != confirmarSenha) {
      setState(() {
        _erro = 'As senhas não coincidem.';
        _carregando = false;
      });
      return;
    }

    if (!_termosAceitos) {
      setState(() {
        _erro = 'Você precisa aceitar os termos de uso.';
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
          'estilo_musical': _estilo?.toLowerCase(),
          'cnpj': cnpj,
          'whatsapp': somenteDigitos(telefone),
        },
      );

      if (!mounted) return;

      mostrarSnackBar('Cadastro realizado com sucesso.');
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
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
        icon: Icons.music_note_outlined,
        title: 'Cadastro de Banda',
        subtitle: 'Preencha os dados da sua banda',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Informações Básicas'),
            const SizedBox(height: 18),
            _RegistrationField(
              label: 'Nome da Banda*',
              controller: _nomeController,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Telefone*',
              controller: _telefoneController,
              mask: _RegistrationFieldMask.telefone,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Email*',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'CNPJ*',
              controller: _cnpjController,
              mask: _RegistrationFieldMask.cnpj,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: CnpjStatusBadge(status: _cnpjStatus, razaoSocial: _cnpjRazaoSocial),
            ),
            const SizedBox(height: 12),
            _RegistrationDropdown(
              label: 'Estilo da Banda*',
              value: _estilo,
              items: _estilosBanda,
              onChanged: (String? value) => setState(() => _estilo = value),
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Cidade de Criação',
              controller: _cidadeCriacaoController,
            ),
            const SizedBox(height: 12),
            _RegistrationDropdown(
              label: 'Estado',
              value: _estadoCriacao,
              items: _estadosBrasil,
              onChanged: (String? value) =>
                  setState(() => _estadoCriacao = value),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Senha de acesso'),
            const SizedBox(height: 18),
            _RegistrationField(
              label: 'Senha*',
              controller: _senhaController,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Confirmar senha*',
              controller: _confirmarSenhaController,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Imagem de Capa'),
            const SizedBox(height: 12),
            const _UploadBox(
              label: 'Clique para fazer upload de imagens',
              height: 100,
            ),
            const SizedBox(height: 8),
            _TermsRow(
              label: 'Li e aceito os Termos de Uso e a Política de Privacidade',
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

class _RegistrationScreenShell extends StatelessWidget {
  const _RegistrationScreenShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
                            Center(child: _CardIconBadge(icon)),
                            const SizedBox(height: 16),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: BaileSulColors.headerText,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: BaileSulColors.mutedText),
                            ),
                            const SizedBox(height: 22),
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

/// Campo de seleção (dropdown) usado nos formulários de cadastro, espelhando
/// os `<select class="field-input">` do web (ex.: estilo da banda, estado).
class _RegistrationDropdown extends StatelessWidget {
  const _RegistrationDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: BaileSulColors.headerText.withValues(alpha: 0.6),
        ),
        style: const TextStyle(color: BaileSulColors.headerText, fontSize: 14),
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: BaileSulColors.headerText.withValues(alpha: 0.45),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: BaileSulColors.headerText.withValues(alpha: 0.13)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: BaileSulColors.headerText.withValues(alpha: 0.13)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: BaileSulColors.accent,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        items: items
            .map(
              (String item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _RegistrationField extends StatefulWidget {
  const _RegistrationField({
    required this.label,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.mask,
    this.focusNode,
    this.loading = false,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final _RegistrationFieldMask? mask;
  final FocusNode? focusNode;
  final bool loading;

  @override
  State<_RegistrationField> createState() => _RegistrationFieldState();
}

class _RegistrationFieldState extends State<_RegistrationField> {
  late bool _obscureText = widget.obscureText;

  List<TextInputFormatter>? get _inputFormatters {
    switch (widget.mask) {
      case _RegistrationFieldMask.telefone:
        return const <TextInputFormatter>[TelefoneTextInputFormatter()];
      case _RegistrationFieldMask.cpf:
        return const <TextInputFormatter>[CpfTextInputFormatter()];
      case _RegistrationFieldMask.cnpj:
        return const <TextInputFormatter>[CnpjTextInputFormatter()];
      case _RegistrationFieldMask.cep:
        return const <TextInputFormatter>[CepTextInputFormatter()];
      case null:
        return null;
    }
  }

  TextInputType? get _effectiveKeyboardType {
    if (widget.keyboardType != null) return widget.keyboardType;
    switch (widget.mask) {
      case _RegistrationFieldMask.telefone:
      case _RegistrationFieldMask.cpf:
      case _RegistrationFieldMask.cep:
        return TextInputType.number;
      case _RegistrationFieldMask.cnpj:
        return TextInputType.text;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: _effectiveKeyboardType,
        inputFormatters: _inputFormatters,
        obscureText: _obscureText,
        autocorrect: false,
        enableSuggestions: !_obscureText,
        textCapitalization: widget.mask == _RegistrationFieldMask.cnpj
            ? TextCapitalization.characters
            : TextCapitalization.none,
        autofillHints: widget.obscureText
            ? const <String>[AutofillHints.newPassword]
            : null,
        style: const TextStyle(color: BaileSulColors.headerText, fontSize: 14),
        cursorColor: BaileSulColors.headerText,
        decoration: InputDecoration(
          hintText: widget.label,
          hintStyle: TextStyle(
            color: BaileSulColors.headerText.withValues(alpha: 0.45),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: BaileSulColors.headerText.withValues(alpha: 0.13)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: BaileSulColors.headerText.withValues(alpha: 0.13)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: BaileSulColors.accent,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: BaileSulColors.headerText.withValues(alpha: 0.65),
                  ),
                  onPressed: () {
                    setState(() => _obscureText = !_obscureText);
                  },
                )
              : (widget.loading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null),
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
        const SnackBar(content: Text('Não foi possível selecionar a imagem.')),
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
            border: Border.all(color: const Color(0xFF9DB8C8), width: 1),
            borderRadius: BorderRadius.circular(2),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF295F83)),
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

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
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
              label,
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
    this.secondaryLabel,
    this.onPrimary,
    this.carregando = false,
  });

  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPrimary;
  final bool carregando;

  Widget _buildPrimaryButton() {
    return SizedBox(
      height: 44,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? secondary = secondaryLabel;
    if (secondary == null) {
      // Espelha o cadastro pessoal no web, que tem apenas o botão de envio,
      // sem par Cancelar/Cadastrar-se.
      return _buildPrimaryButton();
    }

    // Espelha o site: em telas estreitas os botões empilham em coluna
    // reversa (ação principal em cima, cancelar embaixo), largura total.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPrimaryButton(),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
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
            child: Text(secondary),
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

class _LoginField extends StatefulWidget {
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
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  late bool _obscureText = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: widget.controller,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        enabled: widget.enabled,
        onSubmitted: widget.onSubmitted,
        autocorrect: false,
        enableSuggestions: !_obscureText,
        autofillHints: widget.obscureText
            ? const <String>[AutofillHints.password]
            : const <String>[AutofillHints.email],
        style: const TextStyle(color: BaileSulColors.headerText, fontSize: 15),
        cursorColor: BaileSulColors.headerText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: BaileSulColors.headerText.withValues(alpha: 0.13)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: BaileSulColors.headerText.withValues(alpha: 0.13)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: BaileSulColors.accent,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: BaileSulColors.headerText.withValues(alpha: 0.65),
                  ),
                  onPressed: widget.enabled
                      ? () {
                          setState(() => _obscureText = !_obscureText);
                        }
                      : null,
                )
              : null,
        ),
      ),
    );
  }
}

class _AccountTypeButton extends StatelessWidget {
  const _AccountTypeButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: BaileSulColors.cardBorder, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BaileSulColors.accent.withValues(alpha: 0.07),
                  border: Border.all(
                    color: BaileSulColors.accent.withValues(alpha: 0.15),
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: BaileSulColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: BaileSulColors.headerText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: BaileSulColors.mutedText.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Emblema circular com ícone destacado usado nos cabeçalhos dos cartões de
/// login/cadastro, espelhando `.card-icon` de login.module.css/cadastro.module.css.
class _CardIconBadge extends StatelessWidget {
  const _CardIconBadge(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: BaileSulColors.accent.withValues(alpha: 0.08),
        border: Border.all(color: BaileSulColors.accent.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 24, color: BaileSulColors.accent),
    );
  }
}
