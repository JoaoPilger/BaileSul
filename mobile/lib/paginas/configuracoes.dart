import 'package:flutter/material.dart';

import '../models/tipo_conta.dart';
import '../services/sessao_usuario.dart';
import '../widgets/dialogo_alterar_senha.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

const String _acaoAlterarSenha = 'alterar-senha';

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  void _abrirMenu(BuildContext context) {
    MobileAppMenu.show(
      context,
      entries: MobileAppMenu.entries(context),
    );
  }

  String _subtituloConta(TipoConta tipo) {
    switch (tipo) {
      case TipoConta.pessoal:
        return 'Gerencie seus dados pessoais e preferências.';
      case TipoConta.banda:
        return 'Gerencie o perfil e as configurações da sua banda.';
      case TipoConta.comunidade:
        return 'Gerencie o perfil e as configurações da comunidade.';
    }
  }

  List<_ConfiguracaoItem> _itensPorTipo(TipoConta tipo) {
    switch (tipo) {
      case TipoConta.pessoal:
        return const [
          _ConfiguracaoItem(
            icon: Icons.person_outline,
            titulo: 'Editar perfil',
            subtitulo: 'Nome, telefone e foto',
          ),
          _ConfiguracaoItem(
            icon: Icons.lock_outline,
            titulo: 'Alterar senha',
            subtitulo: 'Atualize sua senha de acesso',
            acao: _acaoAlterarSenha,
          ),
          _ConfiguracaoItem(
            icon: Icons.notifications_outlined,
            titulo: 'Notificações',
            subtitulo: 'Alertas de reservas e eventos',
          ),
        ];
      case TipoConta.banda:
        return const [
          _ConfiguracaoItem(
            icon: Icons.music_note_outlined,
            titulo: 'Perfil da banda',
            subtitulo: 'Nome artístico, estilo e descrição',
            rota: '/perfil-banda',
          ),
          _ConfiguracaoItem(
            icon: Icons.lock_outline,
            titulo: 'Alterar senha',
            subtitulo: 'Atualize sua senha de acesso',
            acao: _acaoAlterarSenha,
          ),
        ];
      case TipoConta.comunidade:
        return const [
          _ConfiguracaoItem(
            icon: Icons.apartment_outlined,
            titulo: 'Perfil da comunidade',
            subtitulo: 'Nome, endereço e descrição',
            rota: '/perfil-comunidade',
          ),
          _ConfiguracaoItem(
            icon: Icons.location_on_outlined,
            titulo: 'Localização',
            subtitulo: 'Endereço e mapa do espaço',
          ),
          _ConfiguracaoItem(
            icon: Icons.lock_outline,
            titulo: 'Alterar senha',
            subtitulo: 'Atualize sua senha de acesso',
            acao: _acaoAlterarSenha,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final SessaoUsuario sessao = SessaoUsuario.instance;
    final TipoConta? tipo = sessao.tipoConta;

    if (!sessao.autenticado || tipo == null) {
      return Scaffold(
        backgroundColor: MobileFooter.backgroundColor,
        body: Column(
          children: [
            MobileHeader(
              logoHeight: 58,
              horizontalPadding: 16,
              onMenuPressed: () => _abrirMenu(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: BaileSulColors.pageBackground,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: const Text(
                        'Faça login ou cadastre-se para acessar as configurações.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: BaileSulColors.mutedText,
                          fontSize: 15,
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

    final List<_ConfiguracaoItem> itens = _itensPorTipo(tipo);

    return Scaffold(
      backgroundColor: MobileFooter.backgroundColor,
      body: Column(
        children: [
          MobileHeader(
            logoHeight: 58,
            horizontalPadding: 16,
            onMenuPressed: () => _abrirMenu(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    color: BaileSulColors.pageBackground,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configurações',
                            style: TextStyle(
                              color: BaileSulColors.headerText,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _subtituloConta(tipo),
                            style: const TextStyle(
                              color: BaileSulColors.mutedText,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _ContaResumoCard(
                            tipo: tipo,
                            email: sessao.email,
                            autenticado: sessao.autenticado,
                          ),
                          const SizedBox(height: 16),
                          ...itens.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ConfiguracaoTile(item: item),
                            ),
                          ),
                          if (sessao.autenticado) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await sessao.encerrarSessao();
                                  if (!context.mounted) return;
                                  Navigator.of(context).popUntil(
                                    (Route<dynamic> route) => route.isFirst,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Você saiu da sua conta.'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.logout_rounded, size: 20),
                                label: const Text('Sair da conta'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFB42318),
                                  side: const BorderSide(color: Color(0xFFB42318)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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

class _ContaResumoCard extends StatelessWidget {
  const _ContaResumoCard({
    required this.tipo,
    required this.email,
    required this.autenticado,
  });

  final TipoConta tipo;
  final String? email;
  final bool autenticado;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BaileSulColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BaileSulColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conta ${tipo.rotulo}',
            style: const TextStyle(
              color: BaileSulColors.headerText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (email != null && email!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              email!,
              style: const TextStyle(
                color: BaileSulColors.mutedText,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            autenticado ? 'Sessão ativa' : 'Sessão não iniciada',
            style: TextStyle(
              color: autenticado
                  ? BaileSulColors.accent
                  : BaileSulColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfiguracaoItem {
  const _ConfiguracaoItem({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    this.rota,
    this.acao,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final String? rota;
  final String? acao;
}

class _ConfiguracaoTile extends StatelessWidget {
  const _ConfiguracaoTile({required this.item});

  final _ConfiguracaoItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BaileSulColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (item.acao == _acaoAlterarSenha) {
            mostrarDialogoAlterarSenha(context);
          } else if (item.rota != null) {
            Navigator.pushNamed(context, item.rota!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.titulo} em breve.')),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: BaileSulColors.cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 24,
                color: BaileSulColors.accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titulo,
                      style: const TextStyle(
                        color: BaileSulColors.headerText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitulo,
                      style: const TextStyle(
                        color: BaileSulColors.mutedText,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
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