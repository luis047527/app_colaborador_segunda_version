import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().usuario;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.waving_hand_outlined, size: 48, color: Color(0xFF5A3024)),
            const SizedBox(height: 12),
            Text(
              'Bienvenido, ${usuario?.nombreCompleto ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF3F2924)),
            ),
            const SizedBox(height: 8),
            Text(
              usuario?.rol ?? '',
              style: const TextStyle(color: Color(0xFF7D706B)),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Semana 1 — Base técnica', style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text(
                      'Login conectado a /api/auth/login. Siguientes módulos: marcaciones, historial y vacaciones.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF7D706B)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
