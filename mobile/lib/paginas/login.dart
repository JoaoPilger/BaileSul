import 'package:flutter/material.dart';

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

class PersonalRegistrationScreen extends StatelessWidget {
  const PersonalRegistrationScreen({super.key});

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
            _RegistrationField(label: 'Nome Completo'),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Email*',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'Telefone*',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _RegistrationField(
              label: 'CPF*',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Imagem de Perfil'),
            const SizedBox(height: 12),
            const _UploadBox(
              label: 'Clique para fazer upload de imagens',
              height: 160,
            ),
            const SizedBox(height: 8),
            const _TermsRow(),
            const SizedBox(height: 6),
            _ActionRow(
              primaryLabel: 'Cadastrar-se',
              secondaryLabel: 'Cancelar',
              onPrimary: () async {
                await SessaoUsuario.instance.definirTipoConta(TipoConta.pessoal);
                if (!context.mounted) return;
                Navigator.of(context).popUntil(
                  (Route<dynamic> route) => route.isFirst,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityRegistrationScreen extends StatelessWidget {
  const CommunityRegistrationScreen({super.key});

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
                  child: _RegistrationField(label: 'Nome da Comunidade*'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
                    label: 'Telefone*',
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
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
                    label: 'CNPJ*',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
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
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'Cidade *')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _RegistrationField(label: 'Bairro *')),
                const SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'Rua *')),
              ],
            ),
            const SizedBox(height: 12),
            _RegistrationField(label: 'Referência'),
            const SizedBox(height: 12),
            const _MapPreviewBox(height: 160),
            const SizedBox(height: 8),
            const _TermsRow(),
            const SizedBox(height: 6),
            _ActionRow(
              primaryLabel: 'Salvar',
              secondaryLabel: 'Cancelar',
              onPrimary: () async {
                await SessaoUsuario.instance.definirTipoConta(TipoConta.comunidade);
                if (!context.mounted) return;
                Navigator.of(context).popUntil(
                  (Route<dynamic> route) => route.isFirst,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BandRegistrationScreen extends StatelessWidget {
  const BandRegistrationScreen({super.key});

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
                Expanded(child: _RegistrationField(label: 'Nome da Banda*')),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
                    label: 'Telefone*',
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
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RegistrationField(
                    label: 'CNPJ*',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _UploadBox(label: 'Imagem da Banda', height: 100),
            const SizedBox(height: 20),
            const _SectionTitle('Localização'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _RegistrationField(
                    label: 'CEP *',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'Cidade *')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _RegistrationField(label: 'Bairro *')),
                const SizedBox(width: 16),
                Expanded(child: _RegistrationField(label: 'Rua *')),
              ],
            ),
            const SizedBox(height: 12),
            _RegistrationField(label: 'Referência'),
            const SizedBox(height: 8),
            const _TermsRow(),
            const SizedBox(height: 6),
            _ActionRow(
              primaryLabel: 'Salvar',
              secondaryLabel: 'Cancelar',
              onPrimary: () async {
                await SessaoUsuario.instance.definirTipoConta(TipoConta.banda);
                if (!context.mounted) return;
                Navigator.of(context).popUntil(
                  (Route<dynamic> route) => route.isFirst,
                );
              },
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
    this.keyboardType,
  });

  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        keyboardType: keyboardType,
        autocorrect: false,
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

class _UploadBox extends StatelessWidget {
  const _UploadBox({required this.label, required this.height});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFCFD8DF),
        border: Border.all(
          color: const Color(0xFF9DB8C8),
          width: 1,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF295F83)),
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
  const _TermsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: false, onChanged: (_) {}),
        Expanded(
          child: Text(
            'termos de compartilhamento de informações',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: BaileSulColors.headerText),
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
  });

  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;

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
              onPressed: onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0E5880),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: Text(primaryLabel),
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
