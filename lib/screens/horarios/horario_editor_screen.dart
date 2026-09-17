import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/lumibell_theme.dart';
import '../../widgets/lumibell_ui.dart';

class HorarioEditorScreen extends StatefulWidget {
  const HorarioEditorScreen({super.key, required this.api, required this.employee, this.schedule});
  final ApiService api;
  final Map<String, dynamic> employee;
  final Map<String, dynamic>? schedule;

  @override
  State<HorarioEditorScreen> createState() => _HorarioEditorScreenState();
}

class _HorarioEditorScreenState extends State<HorarioEditorScreen> {
  late final TextEditingController _name;
  late final List<_DayDraft> _days;
  late int _tolerance;
  DateTime _validFrom = DateTime.now();
  bool _saving = false;

  static const _dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.schedule == null ? 'Horario de ${widget.employee['nombre']}' : '${widget.schedule!['nombre']}');
    _tolerance = (widget.schedule?['tolerancia_minutos'] as num?)?.toInt() ?? 10;
    final currentDays = List<dynamic>.from(widget.schedule?['dias'] ?? const []);
    _days = List.generate(7, (index) {
      Map<String, dynamic>? source;
      for (final item in currentDays) {
        final candidate = Map<String, dynamic>.from(item as Map);
        if (candidate['dia_semana'] == index + 1) source = candidate;
      }
      return _DayDraft.fromMap(index, source);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickValidFrom() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _validFrom,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: 'Vigencia del nuevo horario',
    );
    if (selected != null) setState(() => _validFrom = selected);
  }

  Future<void> _pickTime(_DayDraft day, _TimeField field) async {
    final initial = switch (field) {
      _TimeField.start => day.start,
      _TimeField.breakStart => day.breakStart,
      _TimeField.breakEnd => day.breakEnd,
      _TimeField.end => day.end,
    };
    final selected = await showTimePicker(context: context, initialTime: initial);
    if (selected == null) return;
    setState(() {
      switch (field) {
        case _TimeField.start: day.start = selected;
        case _TimeField.breakStart: day.breakStart = selected;
        case _TimeField.breakEnd: day.breakEnd = selected;
        case _TimeField.end: day.end = selected;
      }
    });
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Ingresa un nombre para el horario.';
    if (!_days.any((day) => day.enabled)) return 'Activa por lo menos un día laborable.';
    for (final day in _days.where((item) => item.enabled)) {
      final values = [day.start, day.breakStart, day.breakEnd, day.end].map(_minutes).toList();
      if (!(values[0] < values[1] && values[1] < values[2] && values[2] < values[3])) {
        return 'Revisa las horas del ${_dayNames[day.index].toLowerCase()}. Deben seguir el orden entrada, refrigerio y salida.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final validation = _validate();
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    setState(() => _saving = true);
    try {
      final created = await widget.api.post('/api/horarios', {
        'nombre': _name.text.trim(),
        'descripcion': 'Horario personalizado de ${widget.employee['nombre']} ${widget.employee['apellido']}',
        'tolerancia_minutos': _tolerance,
        'vigencia_desde': _date(_validFrom),
        'dias': _days.map((day) => day.toJson()).toList(),
      });
      await widget.api.put('/api/empleados/${widget.employee['id']}', {
        'horario_id': created['id'],
        'tipo_horario': 'PERSONALIZADO',
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const CircleAvatar(radius: 34, backgroundColor: LumibellColors.successSoft, child: Icon(Icons.check_rounded, color: LumibellColors.success, size: 42)),
          title: const Text('Horario actualizado'),
          content: Text('El nuevo horario de ${widget.employee['nombre']} se aplicará desde el ${_displayDate(_validFrom)}.'),
          actionsAlignment: MainAxisAlignment.center,
          actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Aceptar'))],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Editar horario de ${widget.employee['nombre']}')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        _employeeHeader(),
        const SizedBox(height: 16),
        LumibellCard(
          onTap: _pickValidFrom,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            const CircleAvatar(backgroundColor: LumibellColors.infoSoft, child: Icon(Icons.calendar_month_rounded, color: LumibellColors.navy)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Los cambios se aplicarán desde', style: Theme.of(context).textTheme.bodyMedium),
              Text(_displayDate(_validFrom), style: Theme.of(context).textTheme.titleMedium),
            ])),
            const Icon(Icons.chevron_right_rounded, color: LumibellColors.navy),
          ]),
        ),
        const SizedBox(height: 22),
        Text('Configuración general', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre del horario *')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<int>(value: 8, decoration: const InputDecoration(labelText: 'Horas requeridas'), items: const [DropdownMenuItem(value: 4, child: Text('4 horas')), DropdownMenuItem(value: 6, child: Text('6 horas')), DropdownMenuItem(value: 8, child: Text('8 horas'))], onChanged: (_) {})),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<int>(value: _tolerance, decoration: const InputDecoration(labelText: 'Tolerancia'), items: const [DropdownMenuItem(value: 0, child: Text('0 min')), DropdownMenuItem(value: 5, child: Text('5 min')), DropdownMenuItem(value: 10, child: Text('10 min')), DropdownMenuItem(value: 15, child: Text('15 min')), DropdownMenuItem(value: 20, child: Text('20 min')), DropdownMenuItem(value: 30, child: Text('30 min'))], onChanged: (value) => setState(() => _tolerance = value!))),
        ]),
        const SizedBox(height: 22),
        Text('Horario por día', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Activa los días laborables y define sus horas.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        ..._days.map(_dayEditor),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _saving ? null : () => Navigator.maybePop(context), child: const Text('Cancelar'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white)) : const Text('Guardar cambios'))),
        ]),
      ],
    ),
  );

  Widget _employeeHeader() {
    final first = '${widget.employee['nombre'] ?? ''}';
    final last = '${widget.employee['apellido'] ?? ''}';
    final initials = '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'.toUpperCase();
    return Row(children: [
      CircleAvatar(radius: 29, backgroundColor: LumibellColors.infoSoft, child: Text(initials, style: const TextStyle(color: LumibellColors.navy, fontWeight: FontWeight.w800))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$first $last', style: Theme.of(context).textTheme.titleLarge),
        Text('${widget.employee['cargo'] ?? 'Colaborador'}', style: Theme.of(context).textTheme.bodyMedium),
        Text('${widget.employee['sede_nombre'] ?? 'Sin sede'}', style: Theme.of(context).textTheme.bodyMedium),
      ])),
      const LumibellStatusChip(label: 'Activo', color: LumibellColors.success, background: LumibellColors.successSoft),
    ]);
  }

  Widget _dayEditor(_DayDraft day) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: LumibellCard(
      padding: const EdgeInsets.all(13),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(_dayNames[day.index], style: Theme.of(context).textTheme.titleMedium)),
          Text(day.enabled ? 'Laborable' : 'No laborable', style: TextStyle(color: day.enabled ? LumibellColors.success : LumibellColors.navySoft, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Switch.adaptive(value: day.enabled, activeColor: LumibellColors.success, onChanged: (value) => setState(() => day.enabled = value)),
        ]),
        if (day.enabled) ...[
          const Divider(height: 18),
          Row(children: [
            Expanded(child: _timeButton(day, _TimeField.start, 'Entrada', day.start)),
            const SizedBox(width: 7),
            Expanded(child: _timeButton(day, _TimeField.breakStart, 'Almuerzo', day.breakStart)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: Text('–')),
            Expanded(child: _timeButton(day, _TimeField.breakEnd, 'Regreso', day.breakEnd)),
            const SizedBox(width: 7),
            Expanded(child: _timeButton(day, _TimeField.end, 'Salida', day.end)),
          ]),
        ],
      ]),
    ),
  );

  Widget _timeButton(_DayDraft day, _TimeField field, String label, TimeOfDay value) => InkWell(
    onTap: () => _pickTime(day, field),
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
      decoration: BoxDecoration(color: LumibellColors.field, borderRadius: BorderRadius.circular(10), border: Border.all(color: LumibellColors.border)),
      child: Column(children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: LumibellColors.navySoft, fontSize: 9)),
        const SizedBox(height: 2),
        Text(_time(value), style: const TextStyle(color: LumibellColors.navy, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    ),
  );

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;
  String _time(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  String _date(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _displayDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

enum _TimeField { start, breakStart, breakEnd, end }

class _DayDraft {
  _DayDraft({required this.index, required this.enabled, required this.start, required this.breakStart, required this.breakEnd, required this.end});
  final int index;
  bool enabled;
  TimeOfDay start;
  TimeOfDay breakStart;
  TimeOfDay breakEnd;
  TimeOfDay end;

  factory _DayDraft.fromMap(int index, Map<String, dynamic>? map) {
    final defaultEnabled = index < 5;
    return _DayDraft(
      index: index,
      enabled: map == null ? defaultEnabled : !(map['es_descanso'] == 1 || map['es_descanso'] == true),
      start: _parse(map?['entrada'], const TimeOfDay(hour: 8, minute: 0)),
      breakStart: _parse(map?['ref_inicio'], const TimeOfDay(hour: 13, minute: 0)),
      breakEnd: _parse(map?['ref_fin'], const TimeOfDay(hour: 14, minute: 0)),
      end: _parse(map?['salida'], const TimeOfDay(hour: 17, minute: 0)),
    );
  }

  Map<String, dynamic> toJson() => {
    'dia_semana': index + 1,
    'entrada': enabled ? _format(start) : null,
    'ref_inicio': enabled ? _format(breakStart) : null,
    'ref_fin': enabled ? _format(breakEnd) : null,
    'salida': enabled ? _format(end) : null,
    'es_descanso': !enabled,
  };

  static TimeOfDay _parse(dynamic value, TimeOfDay fallback) {
    if (value == null) return fallback;
    final parts = '$value'.split(':');
    if (parts.length < 2) return fallback;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? fallback.hour, minute: int.tryParse(parts[1]) ?? fallback.minute);
  }

  static String _format(TimeOfDay value) => '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
