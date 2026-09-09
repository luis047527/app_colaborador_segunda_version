import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().usuario;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xFFF4D9C0),
          child: Text(
            (usuario?.nombre.isNotEmpty ?? false) ? usuario!.nombre[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 28, color: Color(0xFF5A3024), fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          usuario?.nombreCompleto ?? 'Usuario',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF3F2924)),
        ),
        const SizedBox(height: 4),
        Text(
          usuario?.email ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7D706B)),
        ),
        const SizedBox(height: 4),
        Text(
          'Rol: ${usuario?.rol ?? '-'}  •  Estado: ${usuario?.estado ?? '-'}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7D706B), fontSize: 13),
        ),
        const SizedBox(height: 20),
        const Card(
          child: ListTile(
            leading: Icon(Icons.badge_outlined, color: Color(0xFF5A3024)),
            title: Text('Sede'),
            subtitle: Text('Pendiente de /api/empleados + /api/sedes'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.supervisor_account_outlined, color: Color(0xFF5A3024)),
            title: Text('Supervisor'),
            subtitle: Text('Modelado futuro: empleados.supervisor_id'),
          ),
        ),
      ],
    );
  }
}
