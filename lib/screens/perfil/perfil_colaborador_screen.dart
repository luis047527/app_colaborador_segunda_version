import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/lumibell_theme.dart';
import '../../widgets/lumibell_ui.dart';

class PerfilColaboradorScreen extends StatefulWidget {
  const PerfilColaboradorScreen({
    super.key,
    required this.api,
    required this.usuarioId,
    required this.onLogout,
  });

  final ApiService api;
  final int usuarioId;
  final VoidCallback onLogout;

  @override
  State<PerfilColaboradorScreen> createState() => _PerfilColaboradorScreenState();
}

class _PerfilColaboradorScreenState extends State<PerfilColaboradorScreen> {
  late Future<Map<String, dynamic>> _profile = _load();

  Future<Map<String, dynamic>> _load() async =>
      Map<String, dynamic>.from(await widget.api.get('/api/empleados/me'));

  void _reload() => setState(() => _profile = _load());

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    bool obscure = true;
    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: TextField(
            controller: controller,
            obscureText: obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              helperText: 'Mínimo 6 caracteres',
              suffixIcon: IconButton(
                onPressed: () => setDialogState(() => obscure = !obscure),
                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (controller.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres.')));
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
    if (changed != true) { controller.dispose(); return; }
    try {
      await widget.api.put('/api/usuarios/${widget.usuarioId}', {'password': controller.text});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada correctamente.')));
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      controller.dispose();
    }
  }

  Future<void> _logout() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (accepted == true) widget.onLogout();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined))]),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LumibellLoadingView(message: 'Cargando tu perfil...');
        if (snapshot.hasError) return LumibellStateView(icon: Icons.person_off_outlined, title: 'No se pudo cargar el perfil', message: '${snapshot.error}', actionLabel: 'Reintentar', onAction: _reload);
        return _content(snapshot.data!);
      },
    ),
    bottomNavigationBar: _navigation(),
  );

  Widget _content(Map<String, dynamic> profile) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
    children: [
      _identity(profile),
      const SizedBox(height: 22),
      _sectionTitle(Icons.work_outline_rounded, 'Información laboral'),
      const SizedBox(height: 10),
      LumibellCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          _profileRow(Icons.badge_outlined, 'Cargo', '${profile['cargo'] ?? 'Sin cargo'}'),
          const Divider(height: 1),
          _profileRow(Icons.groups_2_outlined, 'Modalidad laboral', _workMode('${profile['modalidad_laboral'] ?? ''}')),
          const Divider(height: 1),
          _profileRow(Icons.schedule_outlined, 'Tipo de horario', _scheduleType('${profile['tipo_horario'] ?? ''}')),
          const Divider(height: 1),
          _profileRow(Icons.calendar_month_outlined, 'Horario semanal', '${profile['horario_nombre'] ?? 'Sin horario asignado'}', action: 'Ver horario'),
          const Divider(height: 1),
          _profileRow(Icons.event_available_outlined, 'Días laborables', profile['horario_id'] == null ? 'Sin configurar' : 'Consulta tu horario semanal'),
          const Divider(height: 1),
          _profileRow(Icons.location_on_outlined, 'Sede', '${profile['sede_nombre'] ?? 'Sin sede asignada'}'),
        ]),
      ),
      const SizedBox(height: 22),
      _sectionTitle(Icons.shield_outlined, 'Seguridad'),
      const SizedBox(height: 10),
      LumibellCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          _actionRow(Icons.lock_outline_rounded, 'Cambiar contraseña', 'Actualiza tu contraseña de acceso', _changePassword),
          const Divider(height: 1),
          _actionRow(Icons.devices_outlined, 'Dispositivos registrados', 'Funcionalidad opcional para el MVP', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La gestión de dispositivos estará disponible próximamente.')))),
        ]),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(foregroundColor: LumibellColors.copper, side: const BorderSide(color: LumibellColors.copper)),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Cerrar sesión'),
      ),
    ],
  );

  Widget _identity(Map<String, dynamic> profile) {
    final first = '${profile['nombre'] ?? ''}';
    final last = '${profile['apellido'] ?? ''}';
    final initials = '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'.toUpperCase();
    return LumibellCard(
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            CircleAvatar(radius: 47, backgroundColor: LumibellColors.peach, foregroundImage: profile['foto_url'] == null ? null : NetworkImage('${profile['foto_url']}'), child: profile['foto_url'] == null ? Text(initials, style: const TextStyle(color: LumibellColors.copper, fontSize: 25, fontWeight: FontWeight.w800)) : null),
            const Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Icon(Icons.camera_alt_outlined, color: LumibellColors.navy, size: 17))),
          ]),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$first $last', style: Theme.of(context).textTheme.headlineMedium),
            Text('${profile['cargo'] ?? 'Colaborador'}', style: const TextStyle(color: LumibellColors.copper, fontSize: 15)),
            const SizedBox(height: 5),
            Row(children: [const Icon(Icons.email_outlined, color: LumibellColors.navy, size: 18), const SizedBox(width: 6), Expanded(child: Text('${profile['email'] ?? ''}', overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium))]),
          ])),
        ]),
        const Divider(height: 26),
        Row(children: [
          Expanded(child: _miniInfo(Icons.location_on_outlined, 'Sede', '${profile['sede_nombre'] ?? 'Sin sede'}')),
          Container(width: 1, height: 45, color: LumibellColors.border),
          Expanded(child: _miniInfo(Icons.supervisor_account_outlined, 'Supervisor', 'Sin asignar')),
          Container(width: 1, height: 45, color: LumibellColors.border),
          Expanded(child: _miniInfo(Icons.calendar_month_outlined, 'Antigüedad', _seniority(profile['fecha_ingreso']))),
        ]),
      ]),
    );
  }

  Widget _miniInfo(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(children: [Icon(icon, color: LumibellColors.copper, size: 21), const SizedBox(height: 4), Text(label, style: const TextStyle(color: LumibellColors.navySoft, fontSize: 10)), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: LumibellColors.navy, fontSize: 11, fontWeight: FontWeight.w700))]),
  );

  Widget _sectionTitle(IconData icon, String title) => Row(children: [Icon(icon, color: LumibellColors.navy), const SizedBox(width: 9), Text(title, style: Theme.of(context).textTheme.titleLarge)]);

  Widget _profileRow(IconData icon, String title, String value, {String? action}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    child: Row(children: [
      CircleAvatar(radius: 21, backgroundColor: LumibellColors.peachSoft, child: Icon(icon, color: LumibellColors.copper, size: 21)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium)])),
      if (action != null) Text(action, style: const TextStyle(color: LumibellColors.copper, fontSize: 11, fontWeight: FontWeight.w700)),
      const SizedBox(width: 3),
      const Icon(Icons.chevron_right_rounded, color: LumibellColors.navy),
    ]),
  );

  Widget _actionRow(IconData icon, String title, String subtitle, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), child: Row(children: [
      CircleAvatar(radius: 21, backgroundColor: LumibellColors.peachSoft, child: Icon(icon, color: LumibellColors.copper, size: 21)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium)])),
      const Icon(Icons.chevron_right_rounded, color: LumibellColors.navy),
    ])),
  );

  Widget _navigation() => DecoratedBox(
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: LumibellColors.border))),
    child: NavigationBar(selectedIndex: 4, onDestinationSelected: (index) { if (index != 4) Navigator.maybePop(context); }, destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Mi horario'),
      NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner_rounded), label: 'Marcar'),
      NavigationDestination(icon: Icon(Icons.history_rounded), selectedIcon: Icon(Icons.event_note_rounded), label: 'Historial'),
      NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
    ]),
  );

  String _workMode(String value) => value == 'PART_TIME' ? 'Part time' : 'Full time';
  String _scheduleType(String value) => switch (value) { 'FIJO' => 'Fijo', 'FLEXIBLE' => 'Flexible', 'ROTATIVO' => 'Rotativo', _ => 'Personalizado' };

  String _seniority(dynamic raw) {
    final start = DateTime.tryParse('$raw');
    if (start == null) return 'Sin datos';
    final months = (DateTime.now().year - start.year) * 12 + DateTime.now().month - start.month;
    if (months < 1) return 'Menos de 1 mes';
    final years = months ~/ 12;
    final remainder = months % 12;
    if (years == 0) return '$remainder meses';
    return remainder == 0 ? '$years años' : '$years a, $remainder m';
  }
}
