import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/paginas/meus_ingressos.dart';
import 'package:mobile/services/sessao_usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessaoUsuario.instance.encerrarSessao();
    HttpOverrides.global = null;
  });

  testWidgets('mostra o layout e os ingressos do usuário no mobile', (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'bailesul_auth',
      jsonEncode({
        'token': 'abc123',
        'usuario_id': 1,
        'email': 'teste@teste.com',
        'tipo': 'pessoal',
      }),
    );
    await SessaoUsuario.instance.restaurar();

    HttpOverrides.global = _MockHttpOverrides();

    await tester.pumpWidget(const MaterialApp(home: MeusIngressosPage()));
    await tester.pumpAndSettle();

    expect(find.text('Meus ingressos:'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Reservados'), findsOneWidget);
    expect(find.text('Pagos'), findsOneWidget);
    expect(find.text('Festival de Verão'), findsOneWidget);
  });
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final List<int> body = utf8.encode(jsonEncode([
      {
        'id': 10,
        'evento': 'Festival de Verão',
        'evento_id': 5,
        'data_inicio': '2026-11-20T20:00:00.000Z',
        'status_pagamento': 'confirmado',
        'cidade': 'Florianópolis',
        'estado': 'SC',
        'tipo_evento': 'musical_gaucha',
        'foto_capa_url': 'https://example.com/evento.jpg',
        'banda': 'Banda do Sul',
      },
      {
        'id': 11,
        'evento': 'Roda de Chopp',
        'evento_id': 6,
        'data_inicio': '2026-10-10T19:30:00.000Z',
        'status_pagamento': 'pendente',
        'cidade': 'Joinville',
        'estado': 'SC',
        'tipo_evento': 'almoco',
        'foto_capa_url': 'https://example.com/evento2.jpg',
        'banda': 'Banda do Norte',
      },
    ]));

    return _ResponseRequest(
      statusCode: 200,
      headers: {'content-type': 'application/json'},
      body: body,
      url: url,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _ResponseRequest implements HttpClientRequest {
  _ResponseRequest({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.url,
  });

  final int statusCode;
  final Map<String, String> headers;
  final List<int> body;
  final Uri url;

  @override
  Future<HttpClientResponse> close() async {
    return _ResponseHttpClientResponse(statusCode, headers, body);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _ResponseHttpClientResponse extends HttpClientResponse {
  _ResponseHttpClientResponse(this.statusCode, this.headers, this.body);

  final int statusCode;
  final Map<String, String> headers;
  final List<int> body;

  @override
  int get statusCode => statusCode;

  @override
  Map<String, String> get headers => headers;

  @override
  Stream<List<int>> get transform => Stream.value(body);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
