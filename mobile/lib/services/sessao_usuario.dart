import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tipo_conta.dart';
import '../services/vendedor_service.dart';
import 'auth_service.dart';

const String _storageKey = 'bailesul_auth';

/// Sessão local do usuário logado (token, tipo e permissões).
class SessaoUsuario extends ChangeNotifier {
  SessaoUsuario._();

  static final SessaoUsuario instance = SessaoUsuario._();

  String? _token;
  int? _usuarioId;
  String? _email;
  TipoConta? _tipoConta;
  bool _ehVendedor = false;

  String? get token => _token;
  int? get usuarioId => _usuarioId;
  String? get email => _email;
  TipoConta? get tipoConta => _tipoConta;
  bool get ehVendedor => _ehVendedor;

  bool get autenticado => _token != null && _token!.isNotEmpty;

  bool get podeCriarEvento => _tipoConta == TipoConta.comunidade;

  Future<void> restaurar() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final Map<String, dynamic> data =
          jsonDecode(raw) as Map<String, dynamic>;
      _token = data['token'] as String?;
      _usuarioId = _lerInteiro(data['usuario_id']);
      _email = data['email'] as String?;
      final String? tipo = data['tipo'] as String?;

      if (autenticado) {
        _tipoConta = tipo != null ? TipoContaExtension.fromApi(tipo) : null;
        await _atualizarStatusVendedor();
      } else {
        _token = null;
        _usuarioId = null;
        _email = null;
        _tipoConta = null;
        _ehVendedor = false;
        await prefs.remove(_storageKey);
      }

      notifyListeners();
    } catch (_) {
      await prefs.remove(_storageKey);
    }
  }

  int? _lerInteiro(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  Future<void> _atualizarStatusVendedor() async {
    if (!autenticado || _tipoConta != TipoConta.pessoal) {
      _ehVendedor = false;
      return;
    }

    try {
      final List<Map<String, dynamic>> comunidades = await VendedorService.minhasComunidades();
      _ehVendedor = comunidades.isNotEmpty;
    } catch (_) {
      _ehVendedor = false;
    }
  }

  Future<void> login(String email, String senha) async {
    final LoginResultado resultado = await AuthService.login(
      email: email,
      senha: senha,
    );

    _token = resultado.token;
    _usuarioId = resultado.usuarioId;
    _email = resultado.email;
    _tipoConta = resultado.tipo;

    await _persistirSessao();
    await _atualizarStatusVendedor();
    notifyListeners();
  }

  Future<void> cadastrar({
    required String email,
    required String senha,
    required TipoConta tipo,
    required Map<String, dynamic> perfil,
  }) async {
    final LoginResultado resultado = await AuthService.register(
      email: email,
      senha: senha,
      tipo: tipo,
      perfil: perfil,
    );

    _token = resultado.token;
    _usuarioId = resultado.usuarioId;
    _email = resultado.email;
    _tipoConta = resultado.tipo;

    await _persistirSessao();
    await _atualizarStatusVendedor();
    notifyListeners();
  }

  /// Usado após cadastro local; o menu só libera recursos com [autenticado].
  Future<void> definirTipoConta(TipoConta tipo) async {
    if (!autenticado) {
      _tipoConta = null;
      _ehVendedor = false;
      notifyListeners();
      return;
    }

    _tipoConta = tipo;
    await _atualizarStatusVendedor();
    await _persistirSessao();
    notifyListeners();
  }

  Future<void> _persistirSessao() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!autenticado) {
      await prefs.remove(_storageKey);
      return;
    }

    await prefs.setString(
      _storageKey,
      jsonEncode(<String, dynamic>{
        'token': _token,
        'usuario_id': _usuarioId,
        'email': _email,
        'tipo': _tipoConta?.toApi(),
      }),
    );
  }

  Future<void> encerrarSessao() async {
    _token = null;
    _usuarioId = null;
    _email = null;
    _tipoConta = null;
    _ehVendedor = false;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}
