import 'package:flutter/material.dart';
import 'create_usuario_screen.dart';
import 'create_sede_screen.dart';
import 'create_empleado_screen.dart';
import 'create_horario_screen.dart';
import 'assign_horario_screen.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Tile('Crear Usuario', Icons.person_add_outlined, 'POST /api/usuarios', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateUsuarioScreen()))),
      _Tile('Crear Sede', Icons.location_on_outlined, 'POST /api/sedes + geo', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSedeScreen()))),
      _Tile('Crear Empleado', Icons.badge_outlined, 'POST /api/empleados', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEmpleadoScreen()))),
      _Tile('Crear Horario (7 días)', Icons.schedule_outlined, 'POST /api/horarios transaccional', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateHorarioScreen()))),
      _Tile('Asignar Horario/Sede', Icons.swap_horiz_outlined, 'PUT /api/empleados/:id', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignHorarioScreen()))),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Administración (Semana 1)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF3F2924))),
        const SizedBox(height: 4),
        const Text('Crear usuarios, sedes, empleados, horarios y asignaciones.', style: TextStyle(color: Color(0xFF7D706B))),
        const SizedBox(height: 16),
        ...tiles.map((t) => Card(
              child: ListTile(
                leading: Icon(t.icon, color: const Color(0xFF5A3024)),
                title: Text(t.title),
                subtitle: Text(t.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: t.onTap,
              ),
            )),
      ],
    );
  }
}

class _Tile {
  final String title;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;
  _Tile(this.title, this.icon, this.subtitle, this.onTap);
}
