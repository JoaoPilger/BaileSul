import 'package:flutter/material.dart';

import '../paginas/home.dart' show BaileSulColors;
import '../services/vendedor_service.dart';

/// Abre a lista de comunidades (CTGs) às quais o usuário pessoal está
/// vinculado como vendedor.
Future<void> mostrarDialogoComunidadesVinculadas(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ComunidadesVinculadasSheet(),
  );
}

String? _formatarWhatsapp(dynamic numero) {
  final String digitos = (numero?.toString() ?? '').replaceAll(RegExp(r'\D'), '');
  if (digitos.isEmpty) return null;
  final String semDdi = digitos.startsWith('55') && digitos.length > 11
      ? digitos.substring(2)
      : digitos;
  if (semDdi.length == 11) {
    return '(${semDdi.substring(0, 2)}) ${semDdi.substring(2, 7)}-${semDdi.substring(7)}';
  }
  if (semDdi.length == 10) {
    return '(${semDdi.substring(0, 2)}) ${semDdi.substring(2, 6)}-${semDdi.substring(6)}';
  }
  return digitos;
}

class _ComunidadesVinculadasSheet extends StatefulWidget {
  const _ComunidadesVinculadasSheet();

  @override
  State<_ComunidadesVinculadasSheet> createState() => _ComunidadesVinculadasSheetState();
}

class _ComunidadesVinculadasSheetState extends State<_ComunidadesVinculadasSheet> {
  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _comunidades = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final List<Map<String, dynamic>> comunidades = await VendedorService.minhasComunidades();
      if (!mounted) return;
      setState(() => _comunidades = comunidades);
    } on VendedorException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar suas comunidades.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                'Comunidades vinculadas',
                style: TextStyle(
                  color: BaileSulColors.headerText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'CTGs que você representa como vendedor. Para deixar de representar '
                'uma comunidade, peça para ela remover seu vínculo.',
                style: TextStyle(
                  color: BaileSulColors.mutedText.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              if (_carregando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                )
              else if (_erro != null)
                Text(
                  _erro!,
                  style: const TextStyle(color: Color(0xFFB42318), fontSize: 13),
                )
              else if (_comunidades.isEmpty)
                Text(
                  'Você ainda não está vinculado a nenhuma comunidade.',
                  style: TextStyle(
                    color: BaileSulColors.mutedText.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _comunidades.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final Map<String, dynamic> c = _comunidades[index];
                      final String nome = c['comunidade_nome']?.toString() ?? 'Comunidade sem nome';
                      final String? whatsapp = _formatarWhatsapp(c['whatsapp']);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: BaileSulColors.cardBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: BaileSulColors.accentSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.apartment_outlined,
                                size: 18,
                                color: BaileSulColors.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nome,
                                    style: const TextStyle(
                                      color: BaileSulColors.headerText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (whatsapp != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 13,
                                          color: BaileSulColors.mutedText.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          whatsapp,
                                          style: TextStyle(
                                            color: BaileSulColors.mutedText.withValues(alpha: 0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
