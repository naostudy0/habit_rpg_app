enum Environment {
  development,
  production,
}

class EnvironmentConfig {
  static Environment _environment = Environment.development;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static Environment get environment => _environment;

  static String get baseUrl {
    switch (_environment) {
      // 開発環境のURL
      case Environment.development:
        return 'http://habit_rpg_api.public.lvh.me';
      // 本番環境のURL
      case Environment.production:
        return 'http://habit_rpg_api.public.lvh.me';
    }
  }

  static String get apiUrl => '$baseUrl/api';

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isProduction => _environment == Environment.production;
}
