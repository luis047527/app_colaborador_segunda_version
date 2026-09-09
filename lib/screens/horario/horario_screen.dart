import 'package:flutter/material.dart';

class HorarioScreen extends StatelessWidget {
  const HorarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text('Mi Horario (Semana 1 — placeholder)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF3F2924))),
        SizedBox(height: 8),
        Text('Aquí se mostrará el horario del día (GET /api/empleados/:id/horario-hoy).',
            style: TextStyle(color: Color(0xFF7D706B))),
        SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(Icons.schedule_outlined, color: Color(0xFF5A3024)),
            title: Text('Horario asignado'),
            subtitle: Text('Pendiente de conexión con /api/horarios'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.info_outline, color: Color(0xFF7D706B)),
            title: Text('Horas requeridas'),
            subtitle: Text('Se calculan por día (salida-entrada)-(ref_fin-ref_ini)'),
          ),
        ),
      ],
    );
  }
}
