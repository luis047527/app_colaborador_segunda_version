import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/horario_service.dart';
import '../../services/usuario_service.dart';

class CreateHorarioScreen extends StatefulWidget {
  const CreateHorarioScreen({super.key});
  @override
  State<CreateHorarioScreen> createState() => _CreateHorarioScreenState();
}

class _CreateHorarioScreenState extends State<CreateHorarioScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController(text: 'Horario Full-time');
  final _vigenciaDesde = TextEditingController(text: '2026-01-01');
  final _tolerancia = TextEditingController(text: '10');
  final List<Map<String, TextEditingController>> _dias = List.generate(7, (i) {
    final isDom = i == 6;
    return {
      'entrada': TextEditingController(text: isDom ? '' : '10:00'),
      'refIni': TextEditingController(text: isDom ? '' : '13:00'),
      'refFin': TextEditingController(text: isDom ? '' : '14:00'),
      'salida': TextEditingController(text: isDom ? '' : '19:00'),
    };
  });
  final List<bool> _descanso = List.generate(7, (i) => i == 6);
  bool _loading = false;
  String? _msg;

  @override
  void dispose() {
    _nombre.dispose(); _vigenciaDesde.dispose(); _tolerancia.dispose();
    for (final d in _dias) { for (final c in d.values) { c.dispose(); } }
    super.dispose();
  }

  List<Map<String, dynamic>> _buildDias() {
    return List.generate(7, (i) {
      final dia = i + 1;
      if (_descanso[i]) {
        return {'dia_semana': dia, 'entrada': null, 'ref_inicio': null, 'ref_fin': null, 'salida': null, 'es_descanso': true};
      }
      String? norm(String s) => s.trim().isEmpty ? null : s.trim();
      return {
        'dia_semana': dia,
        'entrada': norm(_dias[i]['entrada']!.text),
        'ref_inicio': norm(_dias[i]['refIni']!.text),
        'ref_fin': norm(_dias[i]['refFin']!.text),
        'salida': norm(_dias[i]['salida']!.text),
        'es_descanso': false,
      };
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _msg = null; });
    try {
      final token = context.read<AuthService>().token!;
      final svc = HorarioService();
      final res = await svc.crearHorario(
        token: token,
        nombre: _nombre.text.trim(),
        vigenciaDesde: _vigenciaDesde.text.trim(),
        toleranciaMinutos: int.tryParse(_tolerancia.text.trim()) ?? 10,
        dias: _buildDias(),
      );
      if (!mounted) return;
      setState(() => _msg = 'Horario #${res['id']} creado');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_msg!)));
    } on ApiException catch (e) {
      setState(() => _msg = e.message);
    } catch (_) {
      setState(() => _msg = 'No se pudo conectar o tolerancia inválida');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const diasLabel = ['Lun (1)', 'Mar (2)', 'Mié (3)', 'Jue (4)', 'Vie (5)', 'Sáb (6)', 'Dom (7)'];
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Horario (7 días)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_msg != null) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFEFEC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF2C7C0))), child: Text(_msg!, style: const TextStyle(color: Color(0xFFD85C4F)))),
            TextFormField(controller: _nombre, decoration: const InputDecoration(labelText: 'nombre'), validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _vigenciaDesde, decoration: const InputDecoration(labelText: 'vigencia_desde YYYY-MM-DD'), validator: (v) => v == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) ? 'YYYY-MM-DD' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _tolerancia, decoration: const InputDecoration(labelText: 'tolerancia_minutos 0-180'), keyboardType: TextInputType.number, validator: (v) { final n = int.tryParse(v ?? ''); if (n == null || n < 0 || n > 180) return '0-180'; return null; }),
            const SizedBox(height: 16),
            const Text('Días (7 filas, salida>entrada, refs juntos o nulos)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...List.generate(7, (i) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(diasLabel[i], style: const TextStyle(fontWeight: FontWeight.w600))),
                        Row(children: [const Text('Descanso'), Checkbox(value: _descanso[i], onChanged: (v) => setState(() => _descanso[i] = v!))]),
                      ]),
                      if (!_descanso[i]) ...[
                        Row(children: [
                          Expanded(child: TextFormField(controller: _dias[i]['entrada'], decoration: const InputDecoration(labelText: 'entrada HH:MM'), validator: (v) => _descanso[i] || (v != null && v.trim().isNotEmpty) ? null : 'Req')),
                          const SizedBox(width: 8),
                          Expanded(child: TextFormField(controller: _dias[i]['salida'], decoration: const InputDecoration(labelText: 'salida HH:MM'), validator: (v) => _descanso[i] || (v != null && v.trim().isNotEmpty) ? null : 'Req')),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: TextFormField(controller: _dias[i]['refIni'], decoration: const InputDecoration(labelText: 'ref_ini HH:MM'))),
                          const SizedBox(width: 8),
                          Expanded(child: TextFormField(controller: _dias[i]['refFin'], decoration: const InputDecoration(labelText: 'ref_fin HH:MM'))),
                        ]),
                      ] else
                        const Text('Día descanso — sin horas', style: TextStyle(color: Colors.grey)),
                    ]),
                  ),
                )),
            const SizedBox(height: 12),
            SizedBox(height: 48, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear horario (transaccional 7 días)'))),
            const SizedBox(height: 8),
            const Text('POST /api/horarios — valida 7 días, salida>entrada, refs orden', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
