import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/lumibell_theme.dart';
import '../../widgets/lumibell_ui.dart';
import '../horarios/mi_horario_screen.dart';
import '../perfil/perfil_colaborador_screen.dart';

enum _HistoryPeriod { today, week, month, custom }

class HistorialAsistenciasScreen extends StatefulWidget {
  const HistorialAsistenciasScreen({super.key, required this.api, required this.usuarioId, required this.onLogout});
  final ApiService api;
  final int usuarioId;
  final VoidCallback onLogout;

  @override
  State<HistorialAsistenciasScreen> createState() => _HistorialAsistenciasScreenState();
}

class _HistorialAsistenciasScreenState extends State<HistorialAsistenciasScreen> {
  _HistoryPeriod _period = _HistoryPeriod.week;
  late DateTimeRange _range = _rangeFor(_period);
  late Future<List<dynamic>> _future = _load();

  DateTimeRange _rangeFor(_HistoryPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (period) {
      _HistoryPeriod.today => DateTimeRange(start: today, end: today),
      _HistoryPeriod.week => DateTimeRange(start: today.subtract(Duration(days: today.weekday - 1)), end: today.add(Duration(days: 7 - today.weekday))),
      _HistoryPeriod.month => DateTimeRange(start: DateTime(today.year, today.month, 1), end: DateTime(today.year, today.month + 1, 0)),
      _HistoryPeriod.custom => _range,
    };
  }

  Future<List<dynamic>> _load() async {
    final response = Map<String, dynamic>.from(await widget.api.get('/api/marcaciones/mio?desde=${_date(_range.start)}&hasta=${_date(_range.end)}'));
    return List<dynamic>.from(response['marcaciones'] ?? const []);
  }

  void _selectPeriod(_HistoryPeriod period) {
    if (period == _HistoryPeriod.custom) { _pickRange(); return; }
    setState(() { _period = period; _range = _rangeFor(period); _future = _load(); });
  }

  Future<void> _pickRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: _range,
      helpText: 'Selecciona el periodo',
    );
    if (selected != null) setState(() { _period = _HistoryPeriod.custom; _range = selected; _future = _load(); });
  }

  Map<String, List<Map<String, dynamic>>> _group(List<dynamic> rows) {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final item in rows) {
      final row = Map<String, dynamic>.from(item as Map);
      final key = '${row['fecha']}'.substring(0, 10);
      result.putIfAbsent(key, () => []).add(row);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.chevron_left_rounded, size: 30)),
      title: const Text('Historial de asistencias'),
      actions: [IconButton(onPressed: _pickRange, icon: const Icon(Icons.filter_alt_outlined))],
    ),
    body: Column(children: [
      _periodFilters(),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: LumibellCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            const Icon(Icons.calendar_month_rounded, color: LumibellColors.copper),
            const SizedBox(width: 10),
            Expanded(child: Text('${_displayDate(_range.start)} – ${_displayDate(_range.end)}', style: Theme.of(context).textTheme.titleMedium)),
            IconButton(onPressed: () => _moveRange(-1), icon: const Icon(Icons.chevron_left_rounded)),
            IconButton(onPressed: () => _moveRange(1), icon: const Icon(Icons.chevron_right_rounded)),
          ]),
        ),
      ),
      Expanded(child: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LumibellLoadingView(message: 'Cargando asistencias...');
          if (snapshot.hasError) return LumibellStateView(icon: Icons.cloud_off_rounded, title: 'No se pudo cargar el historial', message: '${snapshot.error}', actionLabel: 'Reintentar', onAction: () => setState(() => _future = _load()));
          final rows = snapshot.data ?? const [];
          final grouped = _group(rows);
          if (rows.isEmpty) return const LumibellStateView(icon: Icons.event_note_outlined, title: 'Aún no hay marcaciones', message: 'Tus entradas y salidas aparecerán aquí después de registrar una marcación.');
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              _summary(grouped),
              const SizedBox(height: 14),
              ...grouped.entries.map((entry) => _dayCard(entry.key, entry.value)),
            ],
          );
        },
      )),
    ]),
    bottomNavigationBar: _navigation(),
  );

  Widget _periodFilters() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    child: Row(children: [
      _periodButton(_HistoryPeriod.today, 'Hoy'),
      _periodButton(_HistoryPeriod.week, 'Semana'),
      _periodButton(_HistoryPeriod.month, 'Mes'),
      _periodButton(_HistoryPeriod.custom, 'Personalizado', icon: Icons.calendar_month_outlined),
    ]),
  );

  Widget _periodButton(_HistoryPeriod value, String label, {IconData? icon}) {
    final selected = _period == value;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        selectedColor: LumibellColors.copper,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? LumibellColors.copper : LumibellColors.border),
        label: Row(mainAxisSize: MainAxisSize.min, children: [Text(label), if (icon != null) ...[const SizedBox(width: 5), Icon(icon, size: 17)]]),
        labelStyle: TextStyle(color: selected ? Colors.white : LumibellColors.navy, fontWeight: FontWeight.w600),
        onSelected: (_) => _selectPeriod(value),
      ),
    );
  }

  Widget _summary(Map<String, List<Map<String, dynamic>>> grouped) {
    var totalMinutes = 0;
    var complete = 0;
    for (final marks in grouped.values) {
      final entrada = _find(marks, 'ENTRADA');
      final salida = _find(marks, 'SALIDA');
      if (entrada != null && salida != null) {
        totalMinutes += _workedMinutes(marks);
        complete++;
      }
    }
    return LumibellCard(child: Column(children: [
      Row(children: [
        const CircleAvatar(radius: 24, backgroundColor: LumibellColors.infoSoft, child: Icon(Icons.schedule_rounded, color: LumibellColors.navy)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total de horas', style: TextStyle(color: LumibellColors.navySoft)), Text(_duration(totalMinutes), style: const TextStyle(color: LumibellColors.navy, fontSize: 24, fontWeight: FontWeight.w800))])),
        LumibellStatusChip(label: '$complete completos', color: LumibellColors.success, background: LumibellColors.successSoft),
      ]),
      const Divider(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _counter(Icons.check_circle_rounded, LumibellColors.success, '$complete', 'Completos'),
        _counter(Icons.pending_actions_rounded, LumibellColors.warning, '${grouped.length - complete}', 'Incompletos'),
        _counter(Icons.event_note_rounded, LumibellColors.violet, '${grouped.length}', 'Con registro'),
      ]),
    ]));
  }

  Widget _counter(IconData icon, Color color, String value, String label) => Column(children: [Icon(icon, color: color, size: 22), const SizedBox(height: 3), Text(value, style: const TextStyle(color: LumibellColors.navy, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: LumibellColors.navySoft, fontSize: 10))]);

  Widget _dayCard(String date, List<Map<String, dynamic>> marks) {
    final entrada = _find(marks, 'ENTRADA');
    final salida = _find(marks, 'SALIDA');
    final complete = entrada != null && salida != null;
    final minutes = complete ? _workedMinutes(marks) : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: LumibellCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        onTap: () => _showDay(date, marks),
        child: Row(children: [
          Container(width: 55, padding: const EdgeInsets.symmetric(vertical: 7), decoration: BoxDecoration(border: Border(left: BorderSide(color: complete ? LumibellColors.success : LumibellColors.warning, width: 4))), child: Column(children: [Text(_weekday(date), style: const TextStyle(color: LumibellColors.navy, fontWeight: FontWeight.w800)), Text(_dayNumber(date), style: const TextStyle(color: LumibellColors.navySoft, fontSize: 12))])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Entrada ${entrada == null ? '—' : _hour(entrada)}', style: const TextStyle(color: LumibellColors.navy, fontSize: 12)),
            Text('Salida ${salida == null ? '—' : _hour(salida)}', style: const TextStyle(color: LumibellColors.navy, fontSize: 12)),
            if (complete) Text('Jornada ${_duration(minutes)}', style: const TextStyle(color: LumibellColors.navySoft, fontSize: 11)),
          ])),
          LumibellStatusChip(label: complete ? 'Completo' : 'Incompleto', color: complete ? LumibellColors.success : LumibellColors.warning, background: complete ? LumibellColors.successSoft : LumibellColors.warningSoft),
          const Icon(Icons.chevron_right_rounded, color: LumibellColors.navySoft),
        ]),
      ),
    );
  }

  void _showDay(String date, List<Map<String, dynamic>> marks) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 26), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Detalle del ${_displayDate(DateTime.parse(date))}', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      ...marks.map((mark) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: mark['resultado'] == 'ACEPTADA' ? LumibellColors.successSoft : LumibellColors.dangerSoft, child: Icon(Icons.schedule_rounded, color: mark['resultado'] == 'ACEPTADA' ? LumibellColors.success : LumibellColors.danger)), title: Text(_type('${mark['tipo']}')), subtitle: Text('${mark['sede_nombre'] ?? 'Sede no disponible'}'), trailing: Text(_hour(DateTime.parse('${mark['timestamp_utc']}').toLocal()), style: const TextStyle(color: LumibellColors.navy, fontWeight: FontWeight.w800)))),
    ]))),
  );

  Widget _navigation() => DecoratedBox(
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: LumibellColors.border))),
    child: NavigationBar(selectedIndex: 3, onDestinationSelected: (index) {
      if (index == 0 || index == 2) Navigator.maybePop(context);
      if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => MiHorarioScreen(api: widget.api, usuarioId: widget.usuarioId, onLogout: widget.onLogout)));
      if (index == 4) Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilColaboradorScreen(api: widget.api, usuarioId: widget.usuarioId, onLogout: widget.onLogout)));
    }, destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Mi horario'),
      NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner_rounded), label: 'Marcar'),
      NavigationDestination(icon: Icon(Icons.history_rounded), selectedIcon: Icon(Icons.event_note_rounded), label: 'Historial'),
      NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
    ]),
  );

  void _moveRange(int direction) {
    final days = _range.duration.inDays + 1;
    setState(() { _range = DateTimeRange(start: _range.start.add(Duration(days: days * direction)), end: _range.end.add(Duration(days: days * direction))); _future = _load(); });
  }

  DateTime? _find(List<Map<String, dynamic>> marks, String type) {
    for (final mark in marks) { if (mark['tipo'] == type && mark['resultado'] == 'ACEPTADA') return DateTime.tryParse('${mark['timestamp_utc']}')?.toLocal(); }
    return null;
  }

  int _workedMinutes(List<Map<String, dynamic>> marks) {
    final entrada = _find(marks, 'ENTRADA');
    final salida = _find(marks, 'SALIDA');
    if (entrada == null || salida == null) return 0;
    var total = salida.difference(entrada).inMinutes;
    final breakStart = _find(marks, 'SALIDA_REFRIGERIO');
    final breakEnd = _find(marks, 'REGRESO_REFRIGERIO');
    if (breakStart != null && breakEnd != null) total -= breakEnd.difference(breakStart).inMinutes;
    return total < 0 ? 0 : total;
  }

  String _date(DateTime value) => '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _displayDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String _hour(DateTime value) => '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  String _duration(int minutes) => '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
  String _weekday(String raw) { const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']; return names[DateTime.parse(raw).weekday - 1]; }
  String _dayNumber(String raw) { final value = DateTime.parse(raw); return '${value.day} ${_month(value.month)}'; }
  String _month(int value) => const ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'][value - 1];
  String _type(String value) => switch (value) { 'ENTRADA' => 'Entrada', 'SALIDA_REFRIGERIO' => 'Salida a refrigerio', 'REGRESO_REFRIGERIO' => 'Regreso de refrigerio', 'SALIDA' => 'Salida', _ => value };
}
