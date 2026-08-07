import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'sessao_usuario.dart';

class VendedorException implements Exception {
  VendedorException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SugestaoUsuario {
  const SugestaoUsuario({required this.id, required this.nome, required this.email});

  final int id;
  final String nome;
  final String email;

  factory SugestaoUsuario.fromJson(Map<String, dynamic> json) {
    return SugestaoUsuario(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      nome: json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

/// Serviço de comunicação com a API de vendedores (RF08).
abstract final class VendedorService {
  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static String? get _token => SessaoUsuario.instance.token;

  /// GET /vendedores – lista vendedores ativos da comunidade autenticada.
  static Future<List<Map<String, dynamic>>> listar() async {
    final String? token = _token;
    if (token == null || token.isEmpty) {
      throw VendedorException('Faça login para gerenciar vendedores.');
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vendedores');

    http.Response response;
    try {
      response = await http.get(url, headers: _headers(token)).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw VendedorException('Não foi possível conectar ao servidor.');
    }

    if (response.statusCode != 200) {
      throw VendedorException(_erroDoCorpo(response.body, response.statusCode));
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// GET /vendedores/sugestoes?email=... – busca usuário pessoal existente pelo e-mail.
  static Future<SugestaoUsuario?> buscarSugestao(String email) async {
    final String? token = _token;
    if (token == null || token.isEmpty) return null;

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vendedores/sugestoes')
        .replace(queryParameters: {'email': email});

    http.Response response;
    try {
      response = await http.get(url, headers: _headers(token)).timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }

    if (response.statusCode != 200) return null;

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) return null;
    try {
      return SugestaoUsuario.fromJson(Map<String, dynamic>.from(decoded.first as Map));
    } catch (_) {
      return null;
    }
  }

  /// POST /vendedores – adiciona (ou reativa) uma conta pessoal existente como vendedora.
  static Future<void> adicionar({required String email, required String whatsapp}) async {
    final String? token = _token;
    if (token == null || token.isEmpty) {
      throw VendedorException('Faça login para gerenciar vendedores.');
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vendedores');

    http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: _headers(token),
            body: jsonEncode(<String, String>{'email': email, 'whatsapp': whatsapp}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw VendedorException('Não foi possível conectar ao servidor.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw VendedorException(_erroDoCorpo(response.body, response.statusCode));
    }
  }

  /// DELETE /vendedores/:id – desativa (remove) um vendedor da comunidade.
  static Future<void> remover(int id) async {
    final String? token = _token;
    if (token == null || token.isEmpty) {
      throw VendedorException('Faça login para gerenciar vendedores.');
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vendedores/$id');

    http.Response response;
    try {
      response = await http.delete(url, headers: _headers(token)).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw VendedorException('Não foi possível conectar ao servidor.');
    }

    if (response.statusCode != 200) {
      throw VendedorException(_erroDoCorpo(response.body, response.statusCode));
    }
  }

  /// GET /vendedores/me – lista as comunidades vinculadas ao usuário pessoal.
  static Future<List<Map<String, dynamic>>> minhasComunidades() async {
    final String? token = _token;
    if (token == null || token.isEmpty) {
      throw VendedorException('Faça login para ver suas comunidades.');
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vendedores/me');

    http.Response response;
    try {
      response = await http.get(url, headers: _headers(token)).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw VendedorException('Não foi possível conectar ao servidor.');
    }

    if (response.statusCode != 200) {
      throw VendedorException(_erroDoCorpo(response.body, response.statusCode));
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// GET /vendedores/reservas – lista as reservas do vendedor autenticado.
  static Future<List<Map<String, dynamic>>> listarReservas() async {
    final String? token = _token;
    if (token == null || token.isEmpty) {
      throw VendedorException('Faça login para ver seus pagamentos.');
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vendedores/reservas');

    http.Response response;
    try {
      response = await http.get(url, headers: _headers(token)).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw VendedorException('Não foi possível conectar ao servidor.');
    }

    if (response.statusCode != 200) {
      throw VendedorException(_erroDoCorpo(response.body, response.statusCode));
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// PATCH /vendedores/reservas/:id/confirmar – confirma pagamento.
  static Future<void> confirmarReserva(int id) async {
    final String? token = _token;
    if (token == null || token.isEmpty) {
      throw VendedorException('Faça login para confirmar o pagamento.');
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vendedores/reservas/$id/confirmar');
    http.Response response;
    try {
      response = await http.patch(url, headers: _headers(token)).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw VendedorException('Não foi possível conectar ao servidor.');
    }

    if (response.statusCode != 200) {
      throw VendedorException(_erroDoCorpo(response.body, response.statusCode));
    }
  }

  /// PATCH /vendedores/reservas/:id/rejeitar – rejeita pagamento.
  static Future<void> rejeitarReserva(int id) async {
    final String? token = _token;
    if (token == null || token.isEmpty) {
      throw VendedorException('Faça login para rejeitar o pagamento.');
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/vendedores/reservas/$id/rejeitar');
    http.Response response;
    try {
      response = await http.patch(url, headers: _headers(token)).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw VendedorException('Não foi possível conectar ao servidor.');
    }

    if (response.statusCode != 200) {
      throw VendedorException(_erroDoCorpo(response.body, response.statusCode));
    }
  }

  static String _erroDoCorpo(String body, int statusCode) {
    if (body.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(body) as Map<String, dynamic>;
        final String? erro = parsed['error'] as String?;
        if (erro != null && erro.isNotEmpty) return erro;
      } catch (_) {
        // ignora corpo não-JSON
      }
    }
    return 'Erro ao comunicar com o servidor ($statusCode).';
  }
}