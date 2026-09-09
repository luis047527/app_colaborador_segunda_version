import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/empleado_service.dart';
import '../../services/usuario_service.dart';

class CreateEmpleadoScreen extends StatefulWidget {
  const CreateEmpleadoScreen({super.key});
  @override
  State<CreateEmpleadoScreen> createState() => _CreateEmpleadoScreenState();
}

class _CreateEmpleadoScreenState extends State<CreateEmpleadoScreen> {
  final _form = GlobalKey<FormState>();
  final _usuarioId = TextEditingController();
  final _codigo = TextEditingController();
  final _cargo = TextEditingController();
  final _fechaIngreso = TextEditingController(text: '2024-01-15');
  final _sedeId = TextEditingController();
  final _horarioId = TextEditingController();
  String _modalidad = 'FULL_TIME';
  String _tipoHorario = 'FIJO';
  bool _loading = false;
  String? _msg;

  @override
  void dispose() { _usuarioId.dispose(); _codigo.dispose(); _cargo.dispose(); _fechaIngreso.dispose(); _sedeId.dispose(); _horarioId.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _msg = null; });
    try {
      final token = context.read<AuthService>().token!;
      final svc = EmpleadoService();
      final res = await svc.crearEmpleado(
        token: token,
        usuarioId: int.parse(_usuarioId.text.trim()),
        codigo: _codigo.text.trim(),
        cargo: _cargo.text.trim(),
        modalidad: _modalidad,
        tipoHorario: _tipoHorario,
        fechaIngreso: _fechaIngreso.text.trim(),
        sedeId: _sedeId.text.trim().isEmpty ? null : int.parse(_sedeId.text.trim()),
        horarioId: _horarioId.text.trim().isEmpty ? null : int.parse(_horarioId.text.trim()),
      );
      if (!mounted) return;
      setState(() => _msg = 'Empleado #${res['id']} creado');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_msg!)));
    } on ApiException catch (e) {
      setState(() => _msg = e.message);
    } catch (_) {
      setState(() => _msg = 'No se pudo conectar o dato inválido');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Empleado')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_msg != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFEFEC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF2C7C0))), child: Text(_msg!, style: const TextStyle(color: Color(0xFFD85C4F)))),
            TextFormField(controller: _usuarioId, decoration: const InputDecoration(labelText: 'usuario_id (FK usuarios.id)'), keyboardType: TextInputType.number, validator: (v) => int.tryParse(v ?? '') == null ? 'Entero requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _codigo, decoration: const InputDecoration(labelText: 'codigo_empleado (ej. LUM-0004)'), validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _cargo, decoration: const InputDecoration(labelText: 'cargo'), validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: _modalidad, decoration: const InputDecoration(labelText: 'modalidad_laboral'), items: const [DropdownMenuItem(value: 'FULL_TIME', child: Text('FULL_TIME')), DropdownMenuItem(value: 'PART_TIME', child: Text('PART_TIME'))], onChanged: (v) => setState(() => _modalidad = v!)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: _tipoHorario, decoration: const InputDecoration(labelText: 'tipo_horario'), items: const [DropdownMenuItem(value: 'FIJO', child: Text('FIJO')), DropdownMenuItem(value: 'FLEXIBLE', child: Text('FLEXIBLE')), DropdownMenuItem(value: 'ROTATIVO', child: Text('ROTATIVO')), DropdownMenuItem(value: 'PERSONALIZADO', child: Text('PERSONALIZADO'))], onChanged: (v) => setState(() => _tipoHorario = v!)),
            const SizedBox(height: 12),
            TextFormField(controller: _fechaIngreso, decoration: const InputDecoration(labelText: 'fecha_ingreso YYYY-MM-DD'), validator: (v) => v == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) ? 'YYYY-MM-DD' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _sedeId, decoration: const InputDecoration(labelText: 'sede_id (opcional)'), keyboardType: TextInputType.number, validator: (v) => v != null && v.trim().isNotEmpty && int.tryParse(v) == null ? 'Entero' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _horarioId, decoration: const InputDecoration(labelText: 'horario_id (opcional)'), keyboardType: TextInputType.number, validator: (v) => v != null && v.trim().isNotEmpty && int.tryParse(v) == null ? 'Entero' : null),
            const SizedBox(height: 20),
            SizedBox(height: 48, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear empleado'))),
            const SizedBox(height: 8),
            const Text('POST /api/empleados — valida modalidad/tipo, fechas, FK sede/horario', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
