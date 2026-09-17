import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/lumibell_theme.dart';
import '../../widgets/lumibell_ui.dart';
import 'horario_colaborador_screen.dart';

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  final _search = TextEditingController();
  late Future<List<dynamic>> _employees = _load();
  String _query = '';

  Future<List<dynamic>> _load() async => List<dynamic>.from(await widget.api.get('/api/empleados'));

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _employees = _load());

  List<dynamic> _filtered(List<dynamic> rows) => rows.where((item) {
    final row = item as Map;
    return '${row['nombre']} ${row['apellido']} ${row['codigo_empleado']}'.toLowerCase().contains(_query.trim().toLowerCase());
  }).toList();

  Future<void> _open(Map<String, dynamic> employee) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => HorarioColaboradorScreen(api: widget.api, employee: employee)));
    _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.chevron_left_rounded, size: 30)),
      title: const Column(children: [
        Text('Asignar horario'),
        Text('Selecciona un colaborador', style: TextStyle(color: LumibellColors.navySoft, fontSize: 12, fontWeight: FontWeight.w400)),
      ]),
    ),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: TextField(
          controller: _search,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Buscar colaborador...',
            fillColor: LumibellColors.field,
            prefixIcon: const Icon(Icons.search_rounded, color: LumibellColors.navy),
            suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close_rounded)),
          ),
        ),
      ),
      Expanded(child: FutureBuilder<List<dynamic>>(
        future: _employees,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LumibellLoadingView(message: 'Cargando colaboradores...');
          if (snapshot.hasError) return LumibellStateView(icon: Icons.cloud_off_rounded, title: 'No se pudo cargar', message: '${snapshot.error}', actionLabel: 'Reintentar', onAction: _refresh);
          final rows = _filtered(snapshot.data ?? const []);
          if (rows.isEmpty) return const LumibellStateView(icon: Icons.groups_outlined, title: 'Sin colaboradores', message: 'No encontramos colaboradores para asignar un horario.');
          return RefreshIndicator(
            color: LumibellColors.copper,
            onRefresh: () async { _refresh(); await _employees; },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (_, index) => _employeeCard(Map<String, dynamic>.from(rows[index] as Map)),
            ),
          );
        },
      )),
    ]),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: LumibellColors.border))),
      child: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) Navigator.maybePop(context);
          if (index == 1) Navigator.maybePop(context);
          if (index == 3) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil estará disponible próximamente.')));
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Colaboradores'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Horarios'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    ),
  );

  Widget _employeeCard(Map<String, dynamic> employee) {
    final first = '${employee['nombre'] ?? ''}';
    final last = '${employee['apellido'] ?? ''}';
    final initials = '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'.toUpperCase();
    final hasSchedule = employee['horario_id'] != null;
    return LumibellCard(
      onTap: () => _open(employee),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(children: [
        CircleAvatar(radius: 28, backgroundColor: LumibellColors.infoSoft, child: Text(initials, style: const TextStyle(color: LumibellColors.navy, fontWeight: FontWeight.w800))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$first $last', style: const TextStyle(color: LumibellColors.navy, fontSize: 15, fontWeight: FontWeight.w800)),
          Text('${employee['cargo'] ?? 'Colaborador'}', style: Theme.of(context).textTheme.bodyMedium),
          Text(hasSchedule ? '${employee['horario_nombre']}' : 'Sin horario asignado', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: hasSchedule ? LumibellColors.success : LumibellColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: LumibellColors.navy, size: 28),
      ]),
    );
  }
}
