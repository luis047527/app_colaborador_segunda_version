import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/lumibell_theme.dart';
import '../../widgets/lumibell_ui.dart';
import 'horario_editor_screen.dart';

class HorarioColaboradorScreen extends StatefulWidget {
  const HorarioColaboradorScreen({super.key, required this.api, required this.employee});
  final ApiService api;
  final Map<String, dynamic> employee;

  @override
  State<HorarioColaboradorScreen> createState() => _HorarioColaboradorScreenState();
}

class _HorarioColaboradorScreenState extends State<HorarioColaboradorScreen> {
  late Map<String, dynamic> _employee = Map<String, dynamic>.from(widget.employee);
  late Future<Map<String, dynamic>?> _schedule = _loadSchedule();

  Future<Map<String, dynamic>?> _loadSchedule() async {
    final id = _employee['horario_id'];
    if (id == null) return null;
    return Map<String, dynamic>.from(await widget.api.get('/api/horarios/$id'));
  }

  Future<void> _assign() async {
    try {
      final schedules = List<dynamic>.from(await widget.api.get('/api/horarios'));
      if (!mounted) return;
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Seleccionar horario', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (schedules.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('No hay horarios creados.')),
              ...schedules.map((item) {
                final schedule = Map<String, dynamic>.from(item as Map);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: LumibellColors.peachSoft, child: Icon(Icons.calendar_month_rounded, color: LumibellColors.copper)),
                  title: Text('${schedule['nombre']}', style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text('Tolerancia: ${schedule['tolerancia_minutos']} minutos'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, schedule),
                );
              }),
            ]),
          ),
        ),
      );
      if (selected == null) return;
      await widget.api.put('/api/empleados/${_employee['id']}', {'horario_id': selected['id'], 'tipo_horario': 'PERSONALIZADO'});
      setState(() {
        _employee = {..._employee, 'horario_id': selected['id'], 'horario_nombre': selected['nombre']};
        _schedule = _loadSchedule();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horario asignado correctamente.')));
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _edit(Map<String, dynamic>? schedule) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HorarioEditorScreen(
          api: widget.api,
          employee: _employee,
          schedule: schedule,
        ),
      ),
    );
    if (updated == true) {
      final employees = List<dynamic>.from(await widget.api.get('/api/empleados'));
      final current = employees.cast<Map>().firstWhere((item) => item['id'] == _employee['id']);
      setState(() {
        _employee = Map<String, dynamic>.from(current);
        _schedule = _loadSchedule();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Horario de ${_employee['nombre']}')),
    body: FutureBuilder<Map<String, dynamic>?>(
      future: _schedule,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LumibellLoadingView(message: 'Cargando horario...');
        if (snapshot.hasError) return LumibellStateView(icon: Icons.event_busy_rounded, title: 'No se pudo cargar el horario', message: '${snapshot.error}', actionLabel: 'Reintentar', onAction: () => setState(() => _schedule = _loadSchedule()));
        return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
          _employeeHeader(),
          const SizedBox(height: 18),
          if (snapshot.data == null)
            LumibellCard(child: Column(children: [
              const Icon(Icons.calendar_month_outlined, color: LumibellColors.navySoft, size: 50),
              const SizedBox(height: 12),
              Text('Sin horario asignado', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('Selecciona un horario para este colaborador.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: _assign, icon: const Icon(Icons.add_rounded), label: const Text('Asignar horario')),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: () => _edit(null), icon: const Icon(Icons.edit_calendar_rounded), label: const Text('Crear horario personalizado')),
            ]))
          else
            _scheduleContent(snapshot.data!),
        ]);
      },
    ),
  );

  Widget _employeeHeader() {
    final first = '${_employee['nombre'] ?? ''}';
    final last = '${_employee['apellido'] ?? ''}';
    final initials = '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'.toUpperCase();
    return Row(children: [
      CircleAvatar(radius: 34, backgroundColor: LumibellColors.infoSoft, child: Text(initials, style: const TextStyle(color: LumibellColors.navy, fontSize: 18, fontWeight: FontWeight.w800))),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$first $last', style: Theme.of(context).textTheme.titleLarge),
        Text('${_employee['cargo'] ?? 'Colaborador'}', style: Theme.of(context).textTheme.bodyMedium),
        Text('${_employee['sede_nombre'] ?? 'Sin sede'}', style: Theme.of(context).textTheme.bodyMedium),
      ])),
      LumibellStatusChip(label: _employee['estado'] == 'ACTIVO' ? 'Activo' : 'Inactivo', color: _employee['estado'] == 'ACTIVO' ? LumibellColors.success : LumibellColors.danger, background: _employee['estado'] == 'ACTIVO' ? LumibellColors.successSoft : LumibellColors.dangerSoft),
    ]);
  }

  Widget _scheduleContent(Map<String, dynamic> schedule) {
    final days = List<dynamic>.from(schedule['dias'] ?? const []);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton.icon(onPressed: () => _edit(schedule), icon: const Icon(Icons.edit_calendar_rounded), label: const Text('Editar horario')),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: _assign, icon: const Icon(Icons.swap_horiz_rounded), label: const Text('Asignar otro horario')),
      const SizedBox(height: 20),
      Text('Horario semanal', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      LumibellCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(children: List.generate(days.length, (index) {
          final day = Map<String, dynamic>.from(days[index] as Map);
          return Column(children: [
            _dayRow(day),
            if (index < days.length - 1) const Divider(height: 1),
          ]);
        })),
      ),
      const SizedBox(height: 14),
      LumibellCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Resumen', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _summaryRow(Icons.schedule_rounded, 'Horario asignado', '${schedule['nombre']}'),
          const SizedBox(height: 10),
          _summaryRow(Icons.shield_outlined, 'Tolerancia', '${schedule['tolerancia_minutos']} minutos'),
        ]),
      ),
    ]);
  }

  Widget _dayRow(Map<String, dynamic> day) {
    const names = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final rest = day['es_descanso'] == 1 || day['es_descanso'] == true;
    final dayIndex = ((day['dia_semana'] as num?)?.toInt() ?? 1) - 1;
    final input = _shortTime(day['entrada']);
    final output = _shortTime(day['salida']);
    final breakStart = _shortTime(day['ref_inicio']);
    final breakEnd = _shortTime(day['ref_fin']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        SizedBox(width: 78, child: Text(names[dayIndex.clamp(0, 6).toInt()], style: const TextStyle(color: LumibellColors.navy, fontWeight: FontWeight.w700))),
        Expanded(child: rest
            ? const Text('No laborable', style: TextStyle(color: LumibellColors.navySoft))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$input - $output', style: const TextStyle(color: LumibellColors.navy, fontWeight: FontWeight.w700)),
                Text('Almuerzo: $breakStart - $breakEnd', style: const TextStyle(color: LumibellColors.navySoft, fontSize: 11)),
              ])),
        LumibellStatusChip(label: rest ? 'Libre' : 'Laborable', color: rest ? LumibellColors.navy : LumibellColors.success, background: rest ? LumibellColors.field : LumibellColors.successSoft),
      ]),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) => Row(children: [
    CircleAvatar(radius: 18, backgroundColor: LumibellColors.successSoft, child: Icon(icon, color: LumibellColors.navy, size: 19)),
    const SizedBox(width: 11),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodyMedium), Text(value, style: Theme.of(context).textTheme.titleMedium)])),
  ]);

  String _shortTime(dynamic value) {
    if (value == null) return '—';
    final text = '$value';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }
}
