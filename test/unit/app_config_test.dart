import 'package:flutter_test/flutter_test.dart';
import 'package:app_colaborador_segunda_version/config/app_config.dart';

void main() {
  test('AppConfig default apiBaseUrl es localhost:3000', () {
    // defaultValue defined in lib/config/app_config.dart:12
    expect(AppConfig.apiBaseUrl, 'http://localhost:3000');
  });
}
