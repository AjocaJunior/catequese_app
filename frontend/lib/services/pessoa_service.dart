import '../models/pessoa.dart';
import 'api_client.dart';

class PessoaService {
  final ApiClient _client;
  PessoaService(String? token) : _client = ApiClient(token);

  /// Lista todas as pessoas — filtra localmente por nome no ecrã
  /// (mesmo padrão já usado para escolher o catequisando na Caixa).
  Future<List<Pessoa>> listar() async {
    final data = await _client.get('/pessoas') as List;
    return data.map((e) => Pessoa.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Pessoa> criar({
    required String nome,
    String? naturalDe,
    String? provincia,
    String? estadoCivil,
    String? profissao,
    String? residencia,
    String? comunidade,
    String? contacto,
  }) async {
    final resposta = await _client.post('/pessoas', {
      'nome': nome,
      if (naturalDe != null && naturalDe.isNotEmpty) 'natural_de': naturalDe,
      if (provincia != null && provincia.isNotEmpty) 'provincia': provincia,
      if (estadoCivil != null && estadoCivil.isNotEmpty) 'estado_civil': estadoCivil,
      if (profissao != null && profissao.isNotEmpty) 'profissao': profissao,
      if (residencia != null && residencia.isNotEmpty) 'residencia': residencia,
      if (comunidade != null && comunidade.isNotEmpty) 'comunidade': comunidade,
      if (contacto != null && contacto.isNotEmpty) 'contacto': contacto,
    });
    return Pessoa.fromJson(resposta as Map<String, dynamic>);
  }

  Future<Pessoa> atualizar(
    String id, {
    String? nome,
    String? naturalDe,
    String? provincia,
    String? estadoCivil,
    String? profissao,
    String? residencia,
    String? comunidade,
    String? contacto,
  }) async {
    final body = <String, dynamic>{
      if (nome != null) 'nome': nome,
      if (naturalDe != null) 'natural_de': naturalDe,
      if (provincia != null) 'provincia': provincia,
      if (estadoCivil != null) 'estado_civil': estadoCivil,
      if (profissao != null) 'profissao': profissao,
      if (residencia != null) 'residencia': residencia,
      if (comunidade != null) 'comunidade': comunidade,
      if (contacto != null) 'contacto': contacto,
    };
    final resposta = await _client.put('/pessoas/$id', body);
    return Pessoa.fromJson(resposta as Map<String, dynamic>);
  }

  Future<void> apagar(String id) => _client.delete('/pessoas/$id');

  Future<List<VinculoPessoa>> vinculos(String id) async {
    final data = await _client.get('/pessoas/$id/vinculos') as List;
    return data.map((e) => VinculoPessoa.fromJson(e as Map<String, dynamic>)).toList();
  }
}
