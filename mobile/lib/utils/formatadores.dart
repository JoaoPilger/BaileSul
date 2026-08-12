import 'package:flutter/services.dart';

/// Máscaras e formatadores de input reutilizáveis (CNPJ, telefone, CPF, CEP).

String somenteDigitos(String value) => value.replaceAll(RegExp(r'\D'), '');

String somenteCaracteresCnpj(String value) =>
    value.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();

String formatarCnpj(String value) {
  final String chars = somenteCaracteresCnpj(value);
  if (chars.length != 14) return value.trim().toUpperCase();
  return '${chars.substring(0, 2)}.${chars.substring(2, 5)}.'
      '${chars.substring(5, 8)}/${chars.substring(8, 12)}-'
      '${chars.substring(12, 14)}';
}

bool cnpjFormatoValido(String cnpj) => RegExp(
  r'^[0-9A-Z]{2}\.[0-9A-Z]{3}\.[0-9A-Z]{3}/[0-9A-Z]{4}-[0-9A-Z]{2}$',
).hasMatch(cnpj.trim().toUpperCase());

class TelefoneTextInputFormatter extends TextInputFormatter {
  const TelefoneTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String trimmed = digits.length > 11
        ? digits.substring(0, 11)
        : digits;

    final StringBuffer result = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      if (i == 0) {
        result.write('(');
      }
      if (i == 2) {
        result.write(') ');
      }
      if (i == 7) {
        result.write('-');
      }
      result.write(trimmed[i]);
    }

    final String text = result.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class CpfTextInputFormatter extends TextInputFormatter {
  const CpfTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String trimmed = digits.length > 11
        ? digits.substring(0, 11)
        : digits;

    final StringBuffer result = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      if (i == 3 || i == 6) {
        result.write('.');
      }
      if (i == 9) {
        result.write('-');
      }
      result.write(trimmed[i]);
    }

    final String text = result.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class CnpjTextInputFormatter extends TextInputFormatter {
  const CnpjTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String chars = newValue.text
        .replaceAll(RegExp(r'[^0-9A-Za-z]'), '')
        .toUpperCase();
    final String trimmed = chars.length > 14 ? chars.substring(0, 14) : chars;

    final StringBuffer result = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      if (i == 2 || i == 5) {
        result.write('.');
      }
      if (i == 8) {
        result.write('/');
      }
      if (i == 12) {
        result.write('-');
      }
      result.write(trimmed[i]);
    }

    final String text = result.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class CepTextInputFormatter extends TextInputFormatter {
  const CepTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String trimmed = digits.length > 8 ? digits.substring(0, 8) : digits;

    final StringBuffer result = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      if (i == 5) {
        result.write('-');
      }
      result.write(trimmed[i]);
    }

    final String text = result.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
