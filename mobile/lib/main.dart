import 'package:flutter/material.dart';

import 'widgets/mobile_header.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BaileSul',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: MobileHeader.backgroundColor,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color contentBackgroundColor = Color(0xFFD7D7D7);
  static const Color cardColor = Color(0xFFF2F2F2);
  static const Color inputColor = Color(0xFF6F94AA);
  static const Color socialButtonColor = Color(0xFFC8C8CA);
  static const Color textColor = Color(0xFF1A1A1A);
  static const Color linkColor = Color(0xFF2E40FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileHeader(
            onMenuPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu em breve')),
              );
            },
          ),
          Expanded(
            child: ColoredBox(
              color: contentBackgroundColor,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(28, 34, 28, 28),
                          child: _LoginForm(),
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

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: HomeScreen.textColor,
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(
          color: HomeScreen.textColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Login',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: HomeScreen.textColor,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 42),
        Text('Email', style: labelStyle),
        const SizedBox(height: 6),
        const _LoginInput(
          child: TextField(
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: HomeScreen.textColor),
            cursorColor: HomeScreen.textColor,
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Senha', style: labelStyle),
        const SizedBox(height: 6),
        _LoginInput(
          child: TextField(
            obscureText: _obscurePassword,
            style: const TextStyle(color: HomeScreen.textColor),
            cursorColor: HomeScreen.textColor,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: HomeScreen.textColor,
            ),
            tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: HomeScreen.textColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Entrar'),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'ou',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HomeScreen.textColor,
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: HomeScreen.textColor,
                  ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CadastroScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: HomeScreen.linkColor,
              ),
              child: Text(
                'Cadastro',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: HomeScreen.linkColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ],
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
            onMenuPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu em breve')),
              );
            },
          ),
          Expanded(
            child: ColoredBox(
              color: HomeScreen.contentBackgroundColor,
              child: SafeArea(
                top: false,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: HomeScreen.cardColor,
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
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: HomeScreen.textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 26),
                              Text(
                                'Tipo de conta:',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: HomeScreen.textColor,
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
                                      builder: (_) => const PersonalRegistrationScreen(),
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
                                      builder: (_) => const CommunityRegistrationScreen(),
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
                                      builder: (_) => const BandRegistrationScreen(),
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
          backgroundColor: HomeScreen.inputColor,
          foregroundColor: HomeScreen.textColor,
          side: BorderSide(
            color: selected ? const Color(0xFF1180E8) : HomeScreen.inputColor,
            width: selected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class CommunityRegistrationScreen extends StatelessWidget {
  const CommunityRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileHeader(
            onMenuPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu em breve')),
              );
            },
          ),
          Expanded(
            child: ColoredBox(
              color: HomeScreen.contentBackgroundColor,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: HomeScreen.cardColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(40, 30, 40, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Cadastro',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: HomeScreen.textColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFE9E9E9)),
                              const SizedBox(height: 20),
                              Text(
                                'Informações Básicas',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: HomeScreen.textColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              const Row(
                                children: [
                                  Expanded(child: _CommunityField(label: 'Nome da Comunidade*')),
                                  SizedBox(width: 16),
                                  Expanded(child: _CommunityField(label: 'Telefone*')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                children: [
                                  Expanded(child: _CommunityField(label: 'Email*')),
                                  SizedBox(width: 16),
                                  Expanded(child: _CommunityField(label: 'CNPJ*')),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Imagem de Capa',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: HomeScreen.textColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 84,
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
                                  'Clique para fazer upload de imagens',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF295F83),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Localização',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: HomeScreen.textColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              const Row(
                                children: [
                                  Expanded(child: _CommunityField(label: 'CEP *')),
                                  SizedBox(width: 16),
                                  Expanded(child: _CommunityField(label: 'Cidade *')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                children: [
                                  Expanded(child: _CommunityField(label: 'Bairro *')),
                                  SizedBox(width: 16),
                                  Expanded(child: _CommunityField(label: 'Rua *')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const _CommunityField(label: 'Referência'),
                              const SizedBox(height: 12),
                              Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAEAEA),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFD8D8D8)),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.map_outlined,
                                  size: 72,
                                  color: Color(0xFFFF6A00),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Checkbox(value: false, onChanged: (_) {}),
                                  Expanded(
                                    child: Text(
                                      'termos de compartilhamento de informações',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: HomeScreen.textColor,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
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
                                          foregroundColor: HomeScreen.textColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        child: const Text('Cancelar'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: SizedBox(
                                      height: 34,
                                      child: FilledButton(
                                        onPressed: () {},
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFF0E5880),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        child: const Text('Cadastrar-se'),
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

class _CommunityField extends StatelessWidget {
  const _CommunityField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HomeScreen.textColor,
                fontWeight: FontWeight.w400,
              ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 26,
          child: TextField(
            style: const TextStyle(color: HomeScreen.textColor, fontSize: 13),
            cursorColor: HomeScreen.textColor,
            decoration: InputDecoration(
              filled: true,
              fillColor: HomeScreen.inputColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

class BandRegistrationScreen extends StatelessWidget {
  const BandRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileHeader(
            onMenuPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu em breve')),
              );
            },
          ),
          Expanded(
            child: ColoredBox(
              color: HomeScreen.contentBackgroundColor,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: HomeScreen.cardColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF1487EE), width: 3),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(40, 30, 40, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Cadastro',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: HomeScreen.textColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFD5D5D5)),
                              const SizedBox(height: 20),
                              Text(
                                'Informações Básicas',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: HomeScreen.textColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              const Row(
                                children: [
                                  Expanded(child: _CommunityField(label: 'Nome da Banda*')),
                                  SizedBox(width: 16),
                                  Expanded(child: _CommunityField(label: 'Telefone*')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                children: [
                                  Expanded(child: _CommunityField(label: 'Email*')),
                                  SizedBox(width: 16),
                                  Expanded(child: _CommunityField(label: 'CNPJ*')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Row(
                                children: [
                                  Expanded(child: _CommunityField(label: 'Estilo Musical')),
                                  SizedBox(width: 16),
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      children: [
                                        Expanded(child: _CommunityField(label: 'Cidade de criação')),
                                        SizedBox(width: 12),
                                        SizedBox(
                                          width: 52,
                                          child: _CommunityField(label: 'Estado*'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Imagem de Capa',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: HomeScreen.textColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 98,
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
                                  'Clique para fazer upload de imagens',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF295F83),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Checkbox(value: false, onChanged: (_) {}),
                                  Expanded(
                                    child: Text(
                                      'termos de compartilhamento de informações',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: HomeScreen.textColor,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
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
                                          foregroundColor: HomeScreen.textColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        child: const Text('Cancelar'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: SizedBox(
                                      height: 34,
                                      child: FilledButton(
                                        onPressed: () {},
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFF0E5880),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        child: const Text('Cadastrar-se'),
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

class PersonalRegistrationScreen extends StatelessWidget {
  const PersonalRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MobileHeader(
            onMenuPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menu em breve')),
              );
            },
          ),
          Expanded(
            child: ColoredBox(
              color: HomeScreen.contentBackgroundColor,
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool wideLayout = constraints.maxWidth >= 820;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: HomeScreen.cardColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(40, 30, 40, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Cadastro',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: HomeScreen.textColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Divider(height: 1, thickness: 1, color: Color(0xFFD5D5D5)),
                                  const SizedBox(height: 20),
                                  if (wideLayout)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: const [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: _PersonalFormSection(),
                                            ),
                                            SizedBox(width: 18),
                                            Expanded(
                                              flex: 1,
                                              child: _ProfileImagePanel(),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        _PersonalTermsActionsSection(),
                                      ],
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: const [
                                        _PersonalFormSection(),
                                        SizedBox(height: 22),
                                        _ProfileImagePanel(),
                                        SizedBox(height: 12),
                                        _PersonalTermsActionsSection(),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalFormSection extends StatelessWidget {
  const _PersonalFormSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Informações Básicas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HomeScreen.textColor,
                fontWeight: FontWeight.w400,
              ),
        ),
        const SizedBox(height: 18),
        const _CommunityField(label: 'Nome Completo'),
        const SizedBox(height: 12),
        const _CommunityField(label: 'Email*'),
        const SizedBox(height: 12),
        const _CommunityField(label: 'Telefone*'),
        const SizedBox(height: 12),
        const _CommunityField(label: 'CNPJ*'),
      ],
    );
  }
}

class _PersonalTermsActionsSection extends StatelessWidget {
  const _PersonalTermsActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Checkbox(value: false, onChanged: (_) {}),
            Expanded(
              child: Text(
                'termos de compartilhamento de informações',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HomeScreen.textColor,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
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
                    foregroundColor: HomeScreen.textColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0E5880),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text('Cadastrar-se'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileImagePanel extends StatelessWidget {
  const _ProfileImagePanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Imagem de Perfil',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HomeScreen.textColor,
                fontWeight: FontWeight.w400,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(minHeight: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
            'Clique para fazer upload de imagens',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF295F83),
                ),
          ),
        ),
      ],
    );
  }
}

class _LoginInput extends StatelessWidget {
  const _LoginInput({required this.child, this.suffixIcon});

  final Widget child;

  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeScreen.inputColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            Expanded(child: child),
            if (suffixIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: suffixIcon,
              ),
          ],
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
    return Center(
      child: SizedBox(
        width: 180,
        height: 42,
        child: FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: HomeScreen.socialButtonColor,
            foregroundColor: HomeScreen.textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HomeScreen.textColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
