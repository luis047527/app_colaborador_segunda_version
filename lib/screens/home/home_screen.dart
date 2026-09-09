import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../inicio/inicio_screen.dart';
import '../horario/horario_screen.dart';
import '../perfil/perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Inicio', 'Horario', 'Perfil'];

  Widget _bodyForIndex(int index) {
    switch (index) {
      case 0:
        return const InicioScreen();
      case 1:
        return const HorarioScreen();
      case 2:
        return const PerfilScreen();
      default:
        return const InicioScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _bodyForIndex(_index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Horario',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
