enum TipoConta {
  pessoal,
  comunidade,
  banda,
}

extension TipoContaExtension on TipoConta {
  static TipoConta fromApi(String value) {
    switch (value) {
      case 'comunidade':
        return TipoConta.comunidade;
      case 'banda':
        return TipoConta.banda;
      default:
        return TipoConta.pessoal;
    }
  }

  String toApi() {
    switch (this) {
      case TipoConta.comunidade:
        return 'comunidade';
      case TipoConta.banda:
        return 'banda';
      case TipoConta.pessoal:
        return 'pessoal';
    }
  }

  String get rotulo {
    switch (this) {
      case TipoConta.comunidade:
        return 'Comunidade';
      case TipoConta.banda:
        return 'Banda';
      case TipoConta.pessoal:
        return 'Pessoal';
    }
  }
}
