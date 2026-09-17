import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/api_service.dart';
import '../../theme/lumibell_theme.dart';
import '../../widgets/lumibell_ui.dart';
import '../asistencia/qr_sede_screen.dart';
import '../colaboradores/colaboradores_screen.dart';
import '../horarios/horarios_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.usuario, required this.token, required this.onLogout});
  final Usuario usuario;
  final String token;
  final VoidCallback onLogout;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final ApiService _api = ApiService(widget.token);
  late Future<List<dynamic>> _employees = _loadEmployees();

  Future<List<dynamic>> _loadEmployees() async => List<dynamic>.from(await _api.get('/api/empleados'));
  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  void _soon(String name) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name estará disponible próximamente.')));

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) {
      final mobileWidth = viewport.maxWidth > 430.0 ? 430.0 : viewport.maxWidth;
      return ColoredBox(
        color: const Color(0xFFF5F1ED),
        child: Center(
          child: SizedBox(
            width: mobileWidth,
            height: viewport.maxHeight,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A102650),
                    blurRadius: 24,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Scaffold(
    body: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: LumibellColors.copper,
        onRefresh: () async { setState(() => _employees = _loadEmployees()); await _employees; },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _header(), const SizedBox(height: 18), _hero(), const SizedBox(height: 20),
              LumibellSectionTitle(title: 'Resumen del equipo', action: 'Ver todos', onAction: () => _open(ColaboradoresScreen(api: _api))),
              const SizedBox(height: 10), _summary(), const SizedBox(height: 24),
              const LumibellSectionTitle(title: 'Accesos rápidos'), const SizedBox(height: 12), _actions(), const SizedBox(height: 24),
              LumibellSectionTitle(title: 'Actividad reciente', action: 'Ver más', onAction: () => _soon('Actividad reciente')),
              const SizedBox(height: 10), const _Activity(icon: Icons.person_add_alt_1_rounded, color: LumibellColors.success, background: LumibellColors.successSoft, title: 'Nuevo colaborador registrado', subtitle: 'Consulta la lista para ver los cambios'),
              const SizedBox(height: 9), const _Activity(icon: Icons.calendar_month_rounded, color: LumibellColors.info, background: LumibellColors.infoSoft, title: 'Horarios del equipo', subtitle: 'Crea y asigna jornadas personalizadas'),
              const SizedBox(height: 9), const _Activity(icon: Icons.qr_code_rounded, color: LumibellColors.copper, background: LumibellColors.peachSoft, title: 'Marcación por sede', subtitle: 'Genera un QR temporal para tu equipo'),
            ]),
          ],
        ),
      ),
    ),
    bottomNavigationBar: _navigation(),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _header() {
    final initials = '${widget.usuario.nombre.characters.first}${widget.usuario.apellido.characters.first}'.toUpperCase();
    return Row(children: [
      Container(width: 66, height: 66, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: LumibellColors.peach, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Color(0x18102650), blurRadius: 12, offset: Offset(0, 5))], image: widget.usuario.fotoUrl == null ? null : DecorationImage(image: NetworkImage(widget.usuario.fotoUrl!), fit: BoxFit.cover)), child: widget.usuario.fotoUrl == null ? Text(initials, style: const TextStyle(color: LumibellColors.copper, fontSize: 20, fontWeight: FontWeight.w800)) : null),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hola, ${widget.usuario.nombre}', style: Theme.of(context).textTheme.headlineMedium),
        const Text('Administrador', style: TextStyle(color: LumibellColors.navySoft, fontSize: 16)),
        const Text('Gestiona tu equipo con eficiencia', style: TextStyle(color: LumibellColors.navySoft, fontSize: 13)),
      ])),
      IconButton(tooltip: 'Cerrar sesión', onPressed: widget.onLogout, icon: const Badge(smallSize: 9, backgroundColor: LumibellColors.danger, child: Icon(Icons.notifications_none_rounded, color: LumibellColors.navy, size: 29))),
    ]);
  }

  Widget _hero() => Container(
    height: 142, width: double.infinity, clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(LumibellRadii.lg), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF5B4035), Color(0xFF9D7761)])),
    child: Stack(children: [
      Positioned(right: -35, top: -45, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08)))),
      const Positioned(left: 20, top: 24, child: Text('Juntos hacemos\nque cada día cuente', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, height: 1.25))),
      Positioned(right: 13, bottom: 10, child: Container(color: LumibellColors.peach.withValues(alpha: .92), padding: const EdgeInsets.symmetric(horizontal: 6), child: const LumibellLogo(height: 42))),
    ]),
  );

  Widget _summary() => FutureBuilder<List<dynamic>>(
    future: _employees,
    builder: (_, snapshot) {
      final rows = snapshot.data ?? const [];
      final active = rows.where((e) => e['estado'] == 'ACTIVO').length;
      final values = [
        ('${rows.length}', 'Colaboradores', Icons.groups_rounded, LumibellColors.info, LumibellColors.infoSoft),
        ('$active', 'Activos', Icons.person_rounded, LumibellColors.success, LumibellColors.successSoft),
        ('${rows.length - active}', 'Inactivos', Icons.access_time_filled_rounded, LumibellColors.danger, LumibellColors.dangerSoft),
        ('${rows.where((e) => e['horario_id'] != null).length}', 'Con horario', Icons.calendar_month_rounded, LumibellColors.violet, LumibellColors.violetSoft),
      ];
      return LayoutBuilder(builder: (_, box) => Wrap(spacing: 10, runSpacing: 10, children: values.map((v) => SizedBox(width: (box.maxWidth - 10) / 2, child: Container(height: 116, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: v.$5, borderRadius: BorderRadius.circular(14)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(v.$3, color: v.$4, size: 27), const SizedBox(height: 4), Text(snapshot.connectionState == ConnectionState.waiting ? '—' : v.$1, style: const TextStyle(color: LumibellColors.navy, fontSize: 25, fontWeight: FontWeight.w800)), Text(v.$2, style: const TextStyle(color: LumibellColors.navy, fontSize: 13))])))).toList()));
    },
  );

  Widget _actions() {
    final data = [
      ('Colaboradores', 'Crear y gestionar usuarios', Icons.groups_rounded, LumibellColors.infoSoft, () => _open(ColaboradoresScreen(api: _api))),
      ('Horarios', 'Crear y asignar horarios', Icons.calendar_month_rounded, LumibellColors.peachSoft, () => _open(HorariosScreen(api: _api))),
      ('Asistencias', 'Generar QR de sede', Icons.schedule_rounded, LumibellColors.infoSoft, () => _open(QrSedeScreen(api: _api))),
      ('Reportes', 'Consultar asistencias', Icons.bar_chart_rounded, LumibellColors.dangerSoft, () => _soon('Reportes')),
    ];
    return LayoutBuilder(builder: (_, box) => Wrap(spacing: 12, runSpacing: 12, children: data.map((v) => SizedBox(width: (box.maxWidth - 12) / 2, height: 112, child: LumibellCard(padding: const EdgeInsets.all(11), onTap: v.$5, child: Row(children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: v.$4, borderRadius: BorderRadius.circular(11)), child: Icon(v.$3, color: LumibellColors.copper, size: 24)), const SizedBox(width: 8), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: LumibellColors.navy, fontSize: 12.5, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(v.$2, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: LumibellColors.navySoft, fontSize: 11, height: 1.25))])), const Icon(Icons.chevron_right_rounded, color: LumibellColors.navy, size: 19)])))).toList()));
  }

  Widget _navigation() => DecoratedBox(
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: LumibellColors.border))),
    child: NavigationBar(selectedIndex: 0, onDestinationSelected: (i) { if (i == 1) _open(ColaboradoresScreen(api: _api)); if (i == 2) _open(HorariosScreen(api: _api)); if (i == 3) _soon('Perfil'); }, destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Colaboradores'),
      NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Horarios'),
      NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
    ]),
  );
}

class _Activity extends StatelessWidget {
  const _Activity({required this.icon, required this.color, required this.background, required this.title, required this.subtitle});
  final IconData icon; final Color color; final Color background; final String title; final String subtitle;
  @override
  Widget build(BuildContext context) => LumibellCard(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11), child: Row(children: [
    Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: background, shape: BoxShape.circle), child: Icon(icon, color: color, size: 21)), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: LumibellColors.navy, fontSize: 13.5, fontWeight: FontWeight.w700)), Text(subtitle, style: const TextStyle(color: LumibellColors.navySoft, fontSize: 12))])),
    const Icon(Icons.chevron_right_rounded, color: LumibellColors.navySoft),
  ]));
}
