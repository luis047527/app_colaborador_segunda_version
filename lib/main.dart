import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/usuario.dart';
import 'services/auth_service.dart';
import 'screens/inicio/admin_home_screen.dart';
import 'screens/asistencia/asistencia_screen.dart';
import 'services/api_service.dart';
import 'screens/login/login_screen.dart';
import 'theme/lumibell_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'App Colaborador',
        debugShowCheckedModeBanner: false,
        theme: buildLumibellTheme(),
        builder: (context, child) => LayoutBuilder(
          builder: (context, viewport) {
            final mobileWidth = viewport.maxWidth > 430.0
                ? 430.0
                : viewport.maxWidth;
            return ColoredBox(
              color: const Color(0xFFF5F1ED),
              child: Center(
                child: SizedBox(
                  width: mobileWidth,
                  height: viewport.maxHeight,
                  child: child,
                ),
              ),
            );
          },
        ),
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (!auth.isAuthenticated) return LoginScreen(authService: auth);

            final usuario = auth.usuario!;
            if (usuario.rol == 'ADMINISTRADOR') {
              return AdminHomeScreen(usuario: usuario, token: auth.token!, onLogout: auth.logout);
            }
            return AsistenciaScreen(
              api: ApiService(auth.token!),
              usuarioId: usuario.id,
              onLogout: auth.logout,
            );
          },
        ),
      ),
    );
  }
}

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key, required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Center(
        child: Text('Bienvenido, ${usuario.nombreCompleto}'),
      ),
    );
  }
}
