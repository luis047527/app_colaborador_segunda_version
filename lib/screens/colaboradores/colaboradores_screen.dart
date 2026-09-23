import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/lumibell_theme.dart';
import '../../widgets/lumibell_ui.dart';
import '../horarios/horarios_screen.dart';
import 'colaborador_form_screen.dart';

enum _EmployeeFilter { all, active, inactive }

class ColaboradoresScreen extends StatefulWidget {
  const ColaboradoresScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<ColaboradoresScreen> createState() => _ColaboradoresScreenState();
}

class _ColaboradoresScreenState extends State<ColaboradoresScreen> {
  final _searchController = TextEditingController();
  late Future<List<dynamic>> _future = _load();
  _EmployeeFilter _filter = _EmployeeFilter.all;
  String _query = '';

  Future<List<dynamic>> _load() async => List<dynamic>.from(await widget.api.get('/api/empleados'));

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ColaboradorEditorScreen(api: widget.api)),
    );
    if (created == true) _refresh();
  }

  Future<void> _changeStatus(Map<String, dynamic> employee, bool activate) async {
    final name = '${employee['nombre']} ${employee['apellido']}';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activate ? 'Activar colaborador' : 'Desactivar colaborador'),
        content: Text(activate
            ? '$name podrá volver a iniciar sesión.'
            : '$name ya no podrá iniciar sesión hasta ser activado nuevamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(activate ? 'Activar' : 'Desactivar')),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      final userId = employee['usuario_id'] as int;
      final employeeId = employee['id'] as int;
      await widget.api.put('/api/usuarios/$userId', {'estado': activate ? 'ACTIVO' : 'INACTIVO'});
      await widget.api.put('/api/empleados/$employeeId', {'estado': activate ? 'ACTIVO' : 'INACTIVO'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(activate ? 'Colaborador activado' : 'Colaborador desactivado')));
      _refresh();
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  List<dynamic> _filtered(List<dynamic> source) => source.where((item) {
    final employee = item as Map;
    final active = employee['estado'] == 'ACTIVO';
    if (_filter == _EmployeeFilter.active && !active) return false;
    if (_filter == _EmployeeFilter.inactive && active) return false;
    final value = '${employee['nombre']} ${employee['apellido']} ${employee['email']} ${employee['cargo']}'.toLowerCase();
    return value.contains(_query.toLowerCase().trim());
  }).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.chevron_left_rounded, size: 30)),
      title: const Text('Colaboradores'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.icon(
            onPressed: _openCreate,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 42), padding: const EdgeInsets.symmetric(horizontal: 13)),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Nuevo'),
          ),
        ),
      ],
    ),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Buscar colaborador...',
            filled: true,
            fillColor: LumibellColors.field,
            prefixIcon: const Icon(Icons.search_rounded, color: LumibellColors.navy),
            suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close_rounded)),
          ),
        ),
      ),
      FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const [];
          final active = rows.where((e) => e['estado'] == 'ACTIVO').length;
          return _filters(rows.length, active, rows.length - active);
        },
      ),
      const SizedBox(height: 10),
      Expanded(child: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LumibellLoadingView(message: 'Cargando colaboradores...');
          if (snapshot.hasError) return LumibellStateView(icon: Icons.cloud_off_rounded, title: 'No se pudo cargar', message: '${snapshot.error}', actionLabel: 'Reintentar', onAction: _refresh);
          final filtered = _filtered(snapshot.data ?? const []);
          if (filtered.isEmpty) return LumibellStateView(icon: Icons.groups_outlined, title: 'No se encontraron colaboradores', message: 'Intenta con otros filtros o crea un nuevo colaborador.', actionLabel: 'Crear colaborador', onAction: _openCreate);
          return RefreshIndicator(
            color: LumibellColors.copper,
            onRefresh: () async { _refresh(); await _future; },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
              itemCount: filtered.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                if (index == filtered.length) return Padding(padding: const EdgeInsets.only(top: 7), child: Text('Mostrando ${filtered.length} de ${snapshot.data!.length} colaboradores', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium));
                return _employeeCard(Map<String, dynamic>.from(filtered[index] as Map));
              },
            ),
          );
        },
      )),
    ]),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: LumibellColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) Navigator.maybePop(context);
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => HorariosScreen(api: widget.api)));
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

  Widget _filters(int total, int active, int inactive) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(children: [
      _filterChip(_EmployeeFilter.all, 'Todos ($total)'),
      const SizedBox(width: 8),
      _filterChip(_EmployeeFilter.active, 'Activos ($active)'),
      const SizedBox(width: 8),
      _filterChip(_EmployeeFilter.inactive, 'Inactivos ($inactive)'),
      const SizedBox(width: 8),
      OutlinedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El filtro por rol se incorporará con la edición de colaboradores.'))), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42), side: const BorderSide(color: LumibellColors.border), foregroundColor: LumibellColors.navy), icon: const Icon(Icons.tune_rounded, size: 18), label: const Text('Rol')),
    ]),
  );

  Widget _filterChip(_EmployeeFilter value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      label: Text(label),
      showCheckmark: false,
      selectedColor: LumibellColors.copper,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? LumibellColors.copper : LumibellColors.border),
      labelStyle: TextStyle(color: selected ? Colors.white : LumibellColors.navy, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
    );
  }

  Widget _employeeCard(Map<String, dynamic> employee) {
    final active = employee['estado'] == 'ACTIVO';
    final first = '${employee['nombre'] ?? ''}';
    final last = '${employee['apellido'] ?? ''}';
    final initials = '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'.toUpperCase();
    return LumibellCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
      onTap: () => _showDetails(employee),
      child: Row(children: [
        CircleAvatar(radius: 27, backgroundColor: LumibellColors.infoSoft, child: Text(initials, style: const TextStyle(color: LumibellColors.navy, fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$first $last', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: LumibellColors.navy, fontSize: 15, fontWeight: FontWeight.w800)),
          Text('${employee['rol'] == 'ADMINISTRADOR' ? 'Administrador' : employee['cargo'] ?? 'Colaborador'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: LumibellColors.navySoft, fontSize: 13)),
          Text('${employee['email'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: LumibellColors.navySoft, fontSize: 12)),
        ])),
        LumibellStatusChip(label: active ? 'Activo' : 'Inactivo', color: active ? LumibellColors.success : LumibellColors.danger, background: active ? LumibellColors.successSoft : LumibellColors.dangerSoft),
        PopupMenuButton<String>(
          color: Colors.white,
          onSelected: (value) {
            if (value == 'details') _showDetails(employee);
            if (value == 'edit') _openEdit(employee);
            if (value == 'status') _changeStatus(employee, !active);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'details', child: _MenuItem(Icons.visibility_outlined, 'Ver detalles')),
            const PopupMenuItem(value: 'edit', child: _MenuItem(Icons.edit_outlined, 'Editar')),
            PopupMenuItem(value: 'status', child: _MenuItem(active ? Icons.power_settings_new_rounded : Icons.check_circle_outline_rounded, active ? 'Desactivar' : 'Activar', danger: active)),
          ],
        ),
      ]),
    );
  }

  void _showDetails(Map<String, dynamic> employee) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${employee['nombre']} ${employee['apellido']}', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 18),
      _detail(Icons.badge_outlined, 'Cargo', '${employee['cargo'] ?? 'Sin cargo'}'),
      _detail(Icons.business_outlined, 'Sede', '${employee['sede_nombre'] ?? 'Sin sede'}'),
      _detail(Icons.calendar_month_outlined, 'Horario', '${employee['horario_nombre'] ?? 'Sin horario'}'),
      _detail(Icons.email_outlined, 'Correo', '${employee['email'] ?? ''}'),
    ]))),
  );

  Future<void> _openEdit(Map<String, dynamic> employee) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ColaboradorEditorScreen(api: widget.api, employee: employee),
      ),
    );
    if (updated == true) _refresh();
  }

  Widget _detail(IconData icon, String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(children: [Icon(icon, color: LumibellColors.copper), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodyMedium), Text(value, style: Theme.of(context).textTheme.titleMedium)]))]));
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(this.icon, this.label, {this.danger = false});
  final IconData icon; final String label; final bool danger;
  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, color: danger ? LumibellColors.danger : LumibellColors.navy, size: 21), const SizedBox(width: 11), Text(label, style: TextStyle(color: danger ? LumibellColors.danger : LumibellColors.navy))]);
}

class ColaboradorForm extends StatefulWidget {
  const ColaboradorForm({super.key, required this.api});
  final ApiService api;
  @override
  State<ColaboradorForm> createState() => _ColaboradorFormState();
}

class _ColaboradorFormState extends State<ColaboradorForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _role = TextEditingController();
  bool _loading = false;
  List<dynamic> _sites = [];
  int? _site;

  @override
  void initState() {
    super.initState();
    widget.api.get('/api/sedes').then((value) { if (mounted) setState(() => _sites = List<dynamic>.from(value)); });
  }

  @override
  void dispose() {
    for (final controller in [_name, _lastName, _email, _password, _code, _role]) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await widget.api.post('/api/usuarios', {'nombre': _name.text.trim(), 'apellido': _lastName.text.trim(), 'email': _email.text.trim(), 'password': _password.text, 'rol': 'COLABORADOR'});
      await widget.api.post('/api/empleados', {'usuario_id': user['id'], 'codigo_empleado': _code.text.trim(), 'cargo': _role.text.trim(), 'modalidad_laboral': 'FULL_TIME', 'tipo_horario': 'PERSONALIZADO', 'sede_id': _site, 'fecha_ingreso': DateTime.now().toIso8601String().substring(0, 10)});
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController controller, String label, {bool secret = false, TextInputType? type}) => Padding(padding: const EdgeInsets.only(bottom: 13), child: TextFormField(controller: controller, keyboardType: type, obscureText: secret, decoration: InputDecoration(labelText: label), validator: (value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear colaborador')),
    body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
      _field(_name, 'Nombres'), _field(_lastName, 'Apellidos'), _field(_email, 'Correo electrónico', type: TextInputType.emailAddress), _field(_password, 'Contraseña inicial', secret: true), _field(_code, 'Código de empleado'), _field(_role, 'Cargo'),
      DropdownButtonFormField<int>(value: _site, decoration: const InputDecoration(labelText: 'Sede'), items: _sites.map((site) => DropdownMenuItem(value: site['id'] as int, child: Text(site['nombre']))).toList(), onChanged: (value) => setState(() => _site = value)),
      const SizedBox(height: 24), FilledButton(onPressed: _loading ? null : _save, child: Text(_loading ? 'Guardando...' : 'Guardar colaborador')),
    ])),
  );
}
