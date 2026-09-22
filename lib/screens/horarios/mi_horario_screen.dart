import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/lumibell_theme.dart';
import '../../widgets/lumibell_ui.dart';
import '../perfil/perfil_colaborador_screen.dart';
import '../asistencia/historial_asistencias_screen.dart';

class MiHorarioScreen extends StatefulWidget {
  const MiHorarioScreen({super.key, required this.api, required this.usuarioId, required this.onLogout});
  final ApiService api;
  final int usuarioId;
  final VoidCallback onLogout;

  @override
  State<MiHorarioScreen> createState() => _MiHorarioScreenState();
}

class _MiHorarioScreenState extends State<MiHorarioScreen> {
  late Future<Map<String, dynamic>> _today = _loadToday();

  Future<Map<String, dynamic>> _loadToday() async {
    final employee = Map<String, dynamic>.from(await widget.api.get('/api/empleados/me'));
    return Map<String, dynamic>.from(await widget.api.get('/api/empleados/${employee['id']}/horario'));
  }

  void _reload() => setState(() => _today = _loadToday());

  Future<void> _showWeekly() async {
    try {
      final schedule = Map<String, dynamic>.from(await widget.api.get('/api/empleados/me/horario'));
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .72,
          maxChildSize: .92,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              Text('${schedule['nombre']}', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 5),
              Text('Tolerancia: ${schedule['tolerancia_minutos']} minutos', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              ...List<dynamic>.from(schedule['dias'] ?? const []).map((item) => _weeklyDay(Map<String, dynamic>.from(item as Map))),
            ],
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.chevron_left_rounded, size: 30)),
      title: const Text('Mi horario de hoy'),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _today,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LumibellLoadingView(message: 'Consultando tu horario...');
        if (snapshot.hasError) return LumibellStateView(icon: Icons.event_busy_outlined, title: 'No tienes un horario disponible', message: '${snapshot.error}', actionLabel: 'Reintentar', onAction: _reload);
        return _content(snapshot.data!);
      },
    ),
    bottomNavigationBar: _navigation(),
  );

  Widget _content(Map<String, dynamic> data) {
    final day = Map<String, dynamic>.from(data['dia'] as Map);
    final schedule = Map<String, dynamic>.from(data['horario'] as Map);
    final rest = day['es_descanso'] == 1 || day['es_descanso'] == true;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
      Row(children: [
        const Icon(Icons.calendar_month_rounded, color: LumibellColors.copper, size: 30),
        const SizedBox(width: 10),
        Expanded(child: Text(_displayDate('${data['fecha']}'), style: const TextStyle(color: LumibellColors.navy, fontSize: 17, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 22),
      LumibellCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Horario asignado', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          if (rest)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Column(children: [Icon(Icons.weekend_outlined, size: 52, color: LumibellColors.navySoft), SizedBox(height: 10), Text('Día no laborable', style: TextStyle(color: LumibellColors.navy, fontSize: 18, fontWeight: FontWeight.w800))])))
          else ...[
            _timeRow(Icons.login_rounded, LumibellColors.successSoft, LumibellColors.success, 'Entrada', _shortTime(day['entrada'])),
            const Divider(height: 22),
            _timeRow(Icons.lunch_dining_outlined, LumibellColors.warningSoft, LumibellColors.warning, 'Refrigerio', '${_shortTime(day['ref_inicio'])} - ${_shortTime(day['ref_fin'])}'),
            const Divider(height: 22),
            _timeRow(Icons.logout_rounded, LumibellColors.dangerSoft, LumibellColors.danger, 'Salida', _shortTime(day['salida'])),
          ],
          const Divider(height: 28),
          Row(children: [
            Expanded(child: _summary(Icons.schedule_outlined, 'Horas requeridas', '${((data['horas_requeridas_min'] as num?)?.toInt() ?? 0) ~/ 60} h')),
            Container(width: 1, height: 55, color: LumibellColors.border),
            Expanded(child: _summary(Icons.shield_outlined, 'Tolerancia', '${schedule['tolerancia_minutos'] ?? 0} minutos')),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: rest ? LumibellColors.field : LumibellColors.successSoft, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [Icon(rest ? Icons.weekend_outlined : Icons.check_box_rounded, color: rest ? LumibellColors.navySoft : LumibellColors.success), const SizedBox(width: 10), Text(rest ? 'Hoy es un día no laborable' : 'Hoy es un día laborable', style: TextStyle(color: rest ? LumibellColors.navy : LumibellColors.success, fontSize: 16, fontWeight: FontWeight.w800))]),
      ),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: LumibellColors.infoSoft, borderRadius: BorderRadius.circular(14)), child: const Row(children: [Icon(Icons.info_rounded, color: LumibellColors.info, size: 28), SizedBox(width: 11), Expanded(child: Text('Recuerda registrar todas tus marcaciones desde la sede de trabajo.', style: TextStyle(color: LumibellColors.navy)))])),
      const SizedBox(height: 18),
      LumibellCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          _actionRow(Icons.calendar_view_week_outlined, 'Horario semanal', 'Consulta tu horario asignado por día', 'Ver horario', _showWeekly),
          const Divider(height: 1),
          _actionRow(Icons.event_available_outlined, 'Días laborables', _workingDays(schedule), null, _showWeekly),
        ]),
      ),
    ]);
  }

  Widget _timeRow(IconData icon, Color background, Color color, String label, String value) => Row(children: [
    CircleAvatar(radius: 23, backgroundColor: background, child: Icon(icon, color: color)),
    const SizedBox(width: 13),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodyMedium), Text(value, style: const TextStyle(color: LumibellColors.navy, fontSize: 18, fontWeight: FontWeight.w800))])),
  ]);

  Widget _summary(IconData icon, String label, String value) => Column(children: [Icon(icon, color: LumibellColors.copper, size: 26), const SizedBox(height: 5), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: LumibellColors.navySoft, fontSize: 11)), Text(value, style: const TextStyle(color: LumibellColors.navy, fontSize: 16, fontWeight: FontWeight.w800))]);

  Widget _actionRow(IconData icon, String title, String subtitle, String? action, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      CircleAvatar(backgroundColor: LumibellColors.peachSoft, child: Icon(icon, color: LumibellColors.copper)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)])),
      if (action != null) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: LumibellColors.peachSoft, borderRadius: BorderRadius.circular(9)), child: Text(action, style: const TextStyle(color: LumibellColors.copper, fontSize: 11, fontWeight: FontWeight.w700))),
      const Icon(Icons.chevron_right_rounded, color: LumibellColors.navy),
    ])),
  );

  Widget _weeklyDay(Map<String, dynamic> day) {
    const names = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final index = (((day['dia_semana'] as num?)?.toInt() ?? 1) - 1).clamp(0, 6).toInt();
    final rest = day['es_descanso'] == 1 || day['es_descanso'] == true;
    return Padding(padding: const EdgeInsets.only(bottom: 9), child: LumibellCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
      SizedBox(width: 82, child: Text(names[index], style: Theme.of(context).textTheme.titleMedium)),
      Expanded(child: Text(rest ? 'No laborable' : '${_shortTime(day['entrada'])} - ${_shortTime(day['salida'])}', style: TextStyle(color: rest ? LumibellColors.navySoft : LumibellColors.navy, fontWeight: FontWeight.w600))),
      LumibellStatusChip(label: rest ? 'Libre' : 'Laborable', color: rest ? LumibellColors.navy : LumibellColors.success, background: rest ? LumibellColors.field : LumibellColors.successSoft),
    ])));
  }

  Widget _navigation() => DecoratedBox(
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: LumibellColors.border))),
    child: NavigationBar(selectedIndex: 1, onDestinationSelected: (index) {
      if (index == 0 || index == 2) Navigator.maybePop(context);
      if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => HistorialAsistenciasScreen(api: widget.api, usuarioId: widget.usuarioId, onLogout: widget.onLogout)));
      if (index == 4) Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilColaboradorScreen(api: widget.api, usuarioId: widget.usuarioId, onLogout: widget.onLogout)));
    }, destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Mi horario'),
      NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner_rounded), label: 'Marcar'),
      NavigationDestination(icon: Icon(Icons.history_rounded), selectedIcon: Icon(Icons.event_note_rounded), label: 'Historial'),
      NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
    ]),
  );

  String _shortTime(dynamic value) { if (value == null) return '—'; final text = '$value'; return text.length >= 5 ? text.substring(0, 5) : text; }
  String _workingDays(Map<String, dynamic> _) => 'Consulta los días configurados';
  String _displayDate(String raw) {
    final value = DateTime.tryParse(raw) ?? DateTime.now();
    const days = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    final text = '${days[value.weekday - 1]}, ${value.day} de ${months[value.month - 1]} de ${value.year}';
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}
