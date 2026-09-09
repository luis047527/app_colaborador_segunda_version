import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/empleado_service.dart';
import '../../services/usuario_service.dart';

class AssignHorarioScreen extends StatefulWidget {
  const AssignHorarioScreen({super.key});
  @override
  State<AssignHorarioScreen> createState() => _AssignHorarioScreenState();
}

class _AssignHorarioScreenState extends State<AssignHorarioScreen> {
  final _form = GlobalKey<FormState>();
  final _empleadoId = TextEditingController();
  final _horarioId = TextEditingController();
  final _sedeId = TextEditingController();
  bool _loading = false;
  String? _msg;

  @override
  void dispose() { _empleadoId.dispose(); _horarioId.dispose(); _sedeId.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _msg = null; });
    try {
      final token = context.read<AuthService>().token!;
      final svc = EmpleadoService();
      final cambios = <String, dynamic>{};
      if (_horarioId.text.trim().isNotEmpty) cambios['horario_id'] = int.parse(_horarioId.text.trim());
      if (_sedeId.text.trim().isNotEmpty) cambios['sede_id'] = int.parse(_sedeId.text.trim());
      if (cambios.isEmpty) { setState(() => _msg = 'Ingresa horario_id o sede_id'); return; }
      final res = await svc.actualizarEmpleado(token: token, empleadoId: int.parse(_empleadoId.text.trim()), cambios: cambios);
      if (!mounted) return;
      setState(() => _msg = 'Empleado #${res['id']} actualizado → horario ${res['horario_id']} sede ${res['sede_id']}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_msg!)));
    } on ApiException catch (e) {
      setState(() => _msg = e.message);
    } catch (_) {
      setState(() => _msg = 'No se pudo conectar o ID inválido');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignar Horario / Sede')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_msg != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFEFEC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF2C7C0))), child: Text(_msg!, style: const TextStyle(color: Color(0xFFD85C4F)))),
            TextFormField(controller: _empleadoId, decoration: const InputDecoration(labelText: 'empleado_id (requerido)'), keyboardType: TextInputType.number, validator: (v) => int.tryParse(v ?? '') == null ? 'Entero requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _horarioId, decoration: const InputDecoration(labelText: 'horario_id (opcional, asignar)'), keyboardType: TextInputType.number, validator: (v) => v != null && v.trim().isNotEmpty && int.tryParse(v) == null ? 'Entero' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _sedeId, decoration: const InputDecoration(labelText: 'sede_id (opcional, traslado)'), keyboardType: TextInputType.number, validator: (v) => v != null && v.trim().isNotEmpty && int.tryParse(v) == null ? 'Entero' : null),
            const SizedBox(height: 20),
            SizedBox(height: 48, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Asignar'))),
            const SizedBox(height: 8),
            const Text('PUT /api/empleados/:id — valida FK sede/horario, fechas, duplicados', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            const Divider(),
            const Text('Tip: crea primero sede y horario, luego asigna aquí. Verifica con GET /api/empleados/:id/horario-hoy', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
