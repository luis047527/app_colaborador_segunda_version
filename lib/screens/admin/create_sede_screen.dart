import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/sede_service.dart';
import '../../services/usuario_service.dart';

class CreateSedeScreen extends StatefulWidget {
  const CreateSedeScreen({super.key});
  @override
  State<CreateSedeScreen> createState() => _CreateSedeScreenState();
}

class _CreateSedeScreenState extends State<CreateSedeScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  final _lat = TextEditingController(text: '-12.046374');
  final _lon = TextEditingController(text: '-77.042793');
  final _radio = TextEditingController(text: '100');
  bool _loading = false;
  String? _msg;

  @override
  void dispose() { _nombre.dispose(); _direccion.dispose(); _lat.dispose(); _lon.dispose(); _radio.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _msg = null; });
    try {
      final token = context.read<AuthService>().token!;
      final svc = SedeService();
      final res = await svc.crearSede(
        token: token,
        nombre: _nombre.text.trim(),
        direccion: _direccion.text.trim(),
        latitud: double.parse(_lat.text.trim()),
        longitud: double.parse(_lon.text.trim()),
        radio: double.parse(_radio.text.trim()),
      );
      if (!mounted) return;
      setState(() => _msg = 'Sede #${res['id']} creada');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_msg!)));
    } on ApiException catch (e) {
      setState(() => _msg = e.message);
    } catch (_) {
      setState(() => _msg = 'No se pudo conectar o número inválido');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Sede')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_msg != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFEFEC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF2C7C0))), child: Text(_msg!, style: const TextStyle(color: Color(0xFFD85C4F)))),
            TextFormField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _direccion, decoration: const InputDecoration(labelText: 'Dirección'), validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _lat, decoration: const InputDecoration(labelText: 'Latitud (-90 a 90)'), keyboardType: TextInputType.number, validator: (v) { final n = double.tryParse(v ?? ''); if (n == null || n < -90 || n > 90) return 'Entre -90 y 90'; return null; }),
            const SizedBox(height: 12),
            TextFormField(controller: _lon, decoration: const InputDecoration(labelText: 'Longitud (-180 a 180)'), keyboardType: TextInputType.number, validator: (v) { final n = double.tryParse(v ?? ''); if (n == null || n < -180 || n > 180) return 'Entre -180 y 180'; return null; }),
            const SizedBox(height: 12),
            TextFormField(controller: _radio, decoration: const InputDecoration(labelText: 'Radio (m) >0'), keyboardType: TextInputType.number, validator: (v) { final n = double.tryParse(v ?? ''); if (n == null || n <= 0) return '>0'; return null; }),
            const SizedBox(height: 20),
            SizedBox(height: 48, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear sede'))),
            const SizedBox(height: 8),
            const Text('POST /api/sedes — valida geo + estado API', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
