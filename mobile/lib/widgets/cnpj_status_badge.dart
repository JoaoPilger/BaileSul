import 'package:flutter/material.dart';

enum CnpjStatus { idle, checking, valido, invalido }

/// Badge de status de verificação de CNPJ (consulta em tempo real à Receita).
class CnpjStatusBadge extends StatelessWidget {
  const CnpjStatusBadge({super.key, required this.status, this.razaoSocial});

  final CnpjStatus status;
  final String? razaoSocial;

  @override
  Widget build(BuildContext context) {
    if (status == CnpjStatus.idle) return const SizedBox.shrink();

    late final Color cor;
    late final String texto;
    late final String icone;

    switch (status) {
      case CnpjStatus.checking:
        cor = const Color(0xFF6B6B6B);
        texto = 'Verificando CNPJ...';
        icone = '⏳';
        break;
      case CnpjStatus.valido:
        cor = const Color(0xFF0F6E56);
        texto = razaoSocial != null && razaoSocial!.isNotEmpty
            ? 'CNPJ ativo — $razaoSocial'
            : 'CNPJ ativo na Receita Federal';
        icone = '✅';
        break;
      case CnpjStatus.invalido:
        cor = const Color(0xFFA32D2D);
        texto = 'CNPJ não encontrado ou inativo na Receita';
        icone = '⚠️';
        break;
      case CnpjStatus.idle:
        cor = Colors.transparent;
        texto = '';
        icone = '';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          border: Border.all(color: cor.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$icone $texto',
          style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
