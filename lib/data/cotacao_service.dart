import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cotacao.dart';

/// Integração com servidor via API REST (critério de comunicação com
/// servidores do projeto): consome a AwesomeAPI de cotações
/// (https://docs.awesomeapi.com.br/api-de-moedas), pública e sem chave,
/// sobre HTTPS (RNF04).
///
/// Estratégia offline-first (RNF03): a última resposta bem-sucedida fica em
/// cache local; sem conexão, o app exibe o cache com a data da última
/// atualização em vez de falhar.
class CotacaoService {
  static const _endpoint =
      'https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL,BTC-BRL';
  static const _cacheKey = 'cotacoes_cache';
  static const _pares = ['USDBRL', 'EURBRL', 'BTCBRL'];

  final http.Client _client;

  CotacaoService({http.Client? client}) : _client = client ?? http.Client();

  Future<({List<Cotacao> cotacoes, bool doCache})> buscar() async {
    try {
      final response = await _client
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw http.ClientException('HTTP ${response.statusCode}');
      }
      final cotacoes = parseResposta(response.body);
      await _salvarCache(response.body);
      return (cotacoes: cotacoes, doCache: false);
    } catch (_) {
      final cache = await _lerCache();
      if (cache != null) return (cotacoes: cache, doCache: true);
      rethrow;
    }
  }

  /// Público para permitir teste unitário do parse.
  static List<Cotacao> parseResposta(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return _pares
        .where(json.containsKey)
        .map((par) => Cotacao.fromJson(json[par] as Map<String, dynamic>))
        .toList();
  }

  Future<void> _salvarCache(String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, body);
  }

  Future<List<Cotacao>?> _lerCache() async {
    final prefs = await SharedPreferences.getInstance();
    final body = prefs.getString(_cacheKey);
    if (body == null) return null;
    try {
      return parseResposta(body);
    } catch (_) {
      return null;
    }
  }
}
