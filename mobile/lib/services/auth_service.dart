import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/tipo_conta.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LoginResultado {
  const LoginResultado({
    required this.token,
    required this.usuarioId,
    required this.tipo,
    required this.email,
  });

  final String token;
  final int usuarioId;
  final TipoConta tipo;
  final String email;
}

abstract final class AuthService {
  static Future<LoginResultado> login({
    required String email,
    required String senha,
  }) async {
    final String emailNorm = email.trim().toLowerCase();

    if (emailNorm.isEmpty || senha.isEmpty) {
      throw AuthException('Preencha e-mail e senha.');
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(<String, String>{
              'email': emailNorm,
              'senha': senha,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw AuthException(
        'Não foi possível conectar ao servidor. Verifique se a API está rodando.',
      );
    }

    Map<String, dynamic> body = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw AuthException('Resposta inválida do servidor.');
      }
    }

    if (response.statusCode == 200) {
      final String? token = body['token'] as String?;
      final dynamic usuarioIdRaw = body['usuario_id'];
      final String? tipoRaw = body['tipo']?.toString();

      if (token == null || token.isEmpty || usuarioIdRaw == null || tipoRaw == null) {
        throw AuthException('Resposta de login incompleta.');
      }

      final int usuarioId = usuarioIdRaw is int
          ? usuarioIdRaw
          : usuarioIdRaw is num
          ? usuarioIdRaw.toInt()
          : int.parse('$usuarioIdRaw');

      return LoginResultado(
        token: token,
        usuarioId: usuarioId,
        tipo: TipoContaExtension.fromApi(tipoRaw),
        email: emailNorm,
      );
    }

    final String mensagem = body['error'] as String? ??
        (response.statusCode == 401
            ? 'E-mail ou senha incorretos.'
            : 'Erro ao entrar (${response.statusCode}).');

    throw AuthException(mensagem);
  }

  static Future<LoginResultado> register({
    required String email,
    required String senha,
    required TipoConta tipo,
    required Map<String, dynamic> perfil,
  }) async {
    final String emailNorm = email.trim().toLowerCase();

    if (emailNorm.isEmpty || senha.isEmpty) {
      throw AuthException('Preencha e-mail e senha.');
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/auth/register');

    http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{
              'email': emailNorm,
              'senha': senha,
              'tipo': tipo.toApi(),
              'perfil': perfil,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw AuthException(
        'Não foi possível conectar ao servidor. Verifique se a API está rodando.',
      );
    }

    Map<String, dynamic> body = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw AuthException('Resposta inválida do servidor.');
      }
    }

    if (response.statusCode == 201) {
      final String? token = body['token'] as String?;
      final dynamic usuarioIdRaw = body['usuario_id'];
      final String? tipoRaw = body['tipo']?.toString();

      if (token == null || token.isEmpty || usuarioIdRaw == null || tipoRaw == null) {
        throw AuthException('Resposta de cadastro incompleta.');
      }

      final int usuarioId = usuarioIdRaw is int
          ? usuarioIdRaw
          : usuarioIdRaw is num
          ? usuarioIdRaw.toInt()
          : int.parse('$usuarioIdRaw');

      return LoginResultado(
        token: token,
        usuarioId: usuarioId,
        tipo: TipoContaExtension.fromApi(tipoRaw),
        email: emailNorm,
      );
    }

    final String mensagem = body['error'] as String? ??
        (response.statusCode == 409
            ? 'E-mail ou CNPJ já cadastrado.'
            : 'Erro ao cadastrar (${response.statusCode}).');

    throw AuthException(mensagem);
  }
}
