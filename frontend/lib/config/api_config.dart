/// Configuração central do endereço da API.
///
/// Para desenvolvimento local, aponta para o backend local.
/// Para produção, deve apontar para o URL do serviço no Render,
/// por exemplo: https://catequese-api.onrender.com
///
/// Passar em build/run com:
///   flutter run -d chrome --dart-define=API_BASE_URL=https://catequese-api.onrender.com
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
