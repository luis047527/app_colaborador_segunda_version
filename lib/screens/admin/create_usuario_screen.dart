import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';

class CreateUsuarioScreen extends StatefulWidget {
  const CreateUsuarioScreen({super.key});
  @override
  State<CreateUsuarioScreen> createState() => _CreateUsuarioScreenState();
}

class _CreateUsuarioScreenState extends State<CreateUsuarioScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _rol = 'COLABORADOR';
  bool _loading = false;
  String? _msg;

  @override
  void dispose() {
    _nombre.dispose(); _apellido.dispose(); _email.dispose(); _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _msg = null; });
    try {
      final token = context.read<AuthService>().token!;
      final svc = UsuarioService();
      final res = await svc.crearUsuario(
        token: token, nombre: _nombre.text.trim(), apellido: _apellido.text.trim(),
        email: _email.text.trim(), password: _pass.text, rol: _rol,
      );
      if (!mounted) return;
      setState(() => _msg = 'Creado usuario #${res['id']} ${res['email']}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_msg!)));
    } on ApiException catch (e) {
      setState(() => _msg = e.message);
    } catch (_) {
      setState(() => _msg = 'No se pudo conectar');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_msg != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFEFEC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF2C7C0))), child: Text(_msg!, style: const TextStyle(color: Color(0xFFD85C4F)))),
            TextFormField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _apellido, decoration: const InputDecoration(labelText: 'Apellido'), validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || !v.contains('@') ? 'Email inválido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => v == null || v.length < 4 ? 'Mín 4 chars' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: _rol, decoration: const InputDecoration(labelText: 'Rol'), items: const [DropdownMenuItem(value: 'ADMINISTRADOR', child: Text('ADMINISTRADOR')), DropdownMenuItem(value: 'SUPERVISOR', child: Text('SUPERVISOR')), DropdownMenuItem(value: 'COLABORADOR', child: Text('COLABORADOR'))], onChanged: (v) => setState(() => _rol = v!)),
            const SizedBox(height: 20),
            SizedBox(height: 48, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear usuario'))),
            const SizedBox(height: 8),
            const Text('POST /api/usuarios — requiere token. Roles válidos: ADMINISTRADOR/SUPERVISOR/COLABORADOR', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
