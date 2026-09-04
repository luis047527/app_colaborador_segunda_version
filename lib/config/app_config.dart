/// Configuracion centralizada de la aplicacion.
///
/// Para cambiar la URL sin editar codigo, inicia Flutter con:
/// `--dart-define=API_BASE_URL=http://localhost:3000`
class AppConfig {
  AppConfig._();

  /// URL base de la API durante desarrollo web y escritorio.
  ///
  /// En el emulador Android usa `http://10.0.2.2:3000`; en un telefono fisico,
  /// la IP local del equipo donde se ejecuta la API.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
