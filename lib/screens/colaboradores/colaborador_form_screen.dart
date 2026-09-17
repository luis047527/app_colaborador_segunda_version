import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/lumibell_theme.dart';
import '../../widgets/lumibell_ui.dart';

class ColaboradorEditorScreen extends StatefulWidget {
  const ColaboradorEditorScreen({super.key, required this.api, this.employee});

  final ApiService api;
  final Map<String, dynamic>? employee;

  bool get isEditing => employee != null;

  @override
  State<ColaboradorEditorScreen> createState() => _ColaboradorEditorScreenState();
}

class _ColaboradorEditorScreenState extends State<ColaboradorEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _code;
  late final TextEditingController _position;
  bool _obscurePassword = true;
  bool _active = true;
  bool _saving = false;
  List<dynamic> _sites = [];
  int? _siteId;
  String _workMode = 'FULL_TIME';
  String _scheduleType = 'PERSONALIZADO';

  Map<String, dynamic> get _employee => widget.employee ?? const {};

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: '${_employee['nombre'] ?? ''}');
    _lastName = TextEditingController(text: '${_employee['apellido'] ?? ''}');
    _email = TextEditingController(text: '${_employee['email'] ?? ''}');
    _password = TextEditingController();
    _code = TextEditingController(text: '${_employee['codigo_empleado'] ?? ''}');
    _position = TextEditingController(text: '${_employee['cargo'] ?? ''}');
    _siteId = _employee['sede_id'] as int?;
    _workMode = '${_employee['modalidad_laboral'] ?? 'FULL_TIME'}';
    _scheduleType = '${_employee['tipo_horario'] ?? 'PERSONALIZADO'}';
    _active = !widget.isEditing || _employee['estado'] == 'ACTIVO';
    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      final sites = List<dynamic>.from(await widget.api.get('/api/sedes'));
      if (mounted) setState(() => _sites = sites);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    _position.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_siteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una sede.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final userData = <String, dynamic>{
        'nombre': _name.text.trim(),
        'apellido': _lastName.text.trim(),
        'email': _email.text.trim(),
        'rol': 'COLABORADOR',
        'estado': _active ? 'ACTIVO' : 'INACTIVO',
      };
      if (_password.text.isNotEmpty) userData['password'] = _password.text;

      final employeeData = <String, dynamic>{
        'codigo_empleado': _code.text.trim(),
        'cargo': _position.text.trim(),
        'modalidad_laboral': _workMode,
        'tipo_horario': _scheduleType,
        'sede_id': _siteId,
        'estado': _active ? 'ACTIVO' : 'INACTIVO',
      };

      if (widget.isEditing) {
        await widget.api.put('/api/usuarios/${_employee['usuario_id']}', userData);
        await widget.api.put('/api/empleados/${_employee['id']}', employeeData);
      } else {
        userData['password'] = _password.text;
        final user = await widget.api.post('/api/usuarios', userData);
        if (!_active) {
          await widget.api.put('/api/usuarios/${user['id']}', {'estado': 'INACTIVO'});
        }
        employeeData.addAll({
          'usuario_id': user['id'],
          'fecha_ingreso': DateTime.now().toIso8601String().substring(0, 10),
        });
        await widget.api.post('/api/empleados', employeeData);
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const CircleAvatar(
            radius: 34,
            backgroundColor: LumibellColors.successSoft,
            child: Icon(Icons.check_rounded, color: LumibellColors.success, size: 42),
          ),
          title: Text(widget.isEditing ? 'Colaborador actualizado' : 'Colaborador creado'),
          content: Text(widget.isEditing
              ? 'La información se actualizó correctamente.'
              : 'El colaborador ya puede iniciar sesión con sus credenciales.'),
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

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;

  String? _emailValidator(String? value) {
    if (_required(value) != null) return 'Campo obligatorio';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim()) ? null : 'Ingresa un correo válido';
  }

  String? _passwordValidator(String? value) {
    if (!widget.isEditing && (value == null || value.isEmpty)) return 'Campo obligatorio';
    if (value != null && value.isNotEmpty && value.length < 6) return 'Debe tener al menos 6 caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.chevron_left_rounded, size: 30)),
      title: Text(widget.isEditing ? 'Editar colaborador' : 'Crear colaborador'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        children: [
          Text(widget.isEditing ? 'Actualiza la información del colaborador' : 'Completa la información del nuevo colaborador', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          _avatar(),
          const SizedBox(height: 22),
          _section(Icons.person_rounded, 'Información personal'),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _field(_name, 'Nombres *', validator: _required)),
            const SizedBox(width: 10),
            Expanded(child: _field(_lastName, 'Apellidos *', validator: _required)),
          ]),
          const SizedBox(height: 20),
          _section(Icons.email_rounded, 'Datos de acceso'),
          const SizedBox(height: 12),
          _field(_email, 'Correo electrónico *', validator: _emailValidator, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field(
            _password,
            widget.isEditing ? 'Contraseña (dejar en blanco para no cambiar)' : 'Contraseña inicial *',
            validator: _passwordValidator,
            obscureText: _obscurePassword,
            suffix: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            ),
          ),
          const SizedBox(height: 20),
          _section(Icons.work_rounded, 'Rol y sede'),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: DropdownButtonFormField<String>(value: 'COLABORADOR', decoration: const InputDecoration(labelText: 'Rol *'), items: const [DropdownMenuItem(value: 'COLABORADOR', child: Text('Colaborador'))], onChanged: (_) {})),
            const SizedBox(width: 10),
            Expanded(child: DropdownButtonFormField<int>(value: _sites.any((site) => site['id'] == _siteId) ? _siteId : null, isExpanded: true, decoration: const InputDecoration(labelText: 'Sede *'), items: _sites.map((site) => DropdownMenuItem<int>(value: site['id'] as int, child: Text('${site['nombre']}', overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => setState(() => _siteId = value))),
          ]),
          const SizedBox(height: 12),
          _field(_code, 'Código de empleado *', validator: _required),
          const SizedBox(height: 12),
          _field(_position, 'Cargo *', validator: _required),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: DropdownButtonFormField<String>(value: _workMode, decoration: const InputDecoration(labelText: 'Modalidad'), items: const [DropdownMenuItem(value: 'FULL_TIME', child: Text('Full time')), DropdownMenuItem(value: 'PART_TIME', child: Text('Part time'))], onChanged: (value) => setState(() => _workMode = value!))),
            const SizedBox(width: 10),
            Expanded(child: DropdownButtonFormField<String>(value: _scheduleType, isExpanded: true, decoration: const InputDecoration(labelText: 'Tipo de horario'), items: const [DropdownMenuItem(value: 'FIJO', child: Text('Fijo')), DropdownMenuItem(value: 'FLEXIBLE', child: Text('Flexible')), DropdownMenuItem(value: 'ROTATIVO', child: Text('Rotativo')), DropdownMenuItem(value: 'PERSONALIZADO', child: Text('Personalizado'))], onChanged: (value) => setState(() => _scheduleType = value!))),
          ]),
          const SizedBox(height: 20),
          _section(Icons.groups_rounded, 'Supervisor'),
          const SizedBox(height: 12),
          const TextField(enabled: false, decoration: InputDecoration(labelText: 'Supervisor (opcional)', hintText: 'Pendiente de soporte en el backend', suffixIcon: Icon(Icons.keyboard_arrow_down_rounded))),
          const SizedBox(height: 20),
          _section(Icons.badge_rounded, 'Estado'),
          const SizedBox(height: 8),
          LumibellCard(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _active,
              activeColor: LumibellColors.success,
              onChanged: (value) => setState(() => _active = value),
              title: Text(_active ? 'Activo' : 'Inactivo', style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(_active ? 'El colaborador podrá iniciar sesión' : 'El colaborador no podrá iniciar sesión'),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.3, color: Colors.white))
                : Text(widget.isEditing ? 'Actualizar colaborador' : 'Guardar colaborador'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _saving ? null : () => Navigator.maybePop(context), child: const Text('Cancelar')),
        ],
      ),
    ),
  );

  Widget _avatar() {
    final initials = '${_name.text.isEmpty ? '' : _name.text[0]}${_lastName.text.isEmpty ? '' : _lastName.text[0]}'.toUpperCase();
    return Center(child: Column(children: [
      Stack(clipBehavior: Clip.none, children: [
        CircleAvatar(radius: 42, backgroundColor: LumibellColors.field, child: Text(initials.isEmpty ? '—' : initials, style: const TextStyle(color: LumibellColors.navySoft, fontSize: 24, fontWeight: FontWeight.w700))),
        Positioned(right: -3, bottom: -2, child: CircleAvatar(radius: 16, backgroundColor: LumibellColors.copper, child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 17))),
      ]),
      const SizedBox(height: 8),
      const Text('Agregar foto (opcional)', style: TextStyle(color: LumibellColors.navySoft, fontSize: 12)),
    ]));
  }

  Widget _section(IconData icon, String title) => Row(children: [Icon(icon, color: LumibellColors.copper, size: 20), const SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.titleMedium)]);

  Widget _field(TextEditingController controller, String label, {String? Function(String?)? validator, TextInputType? keyboardType, bool obscureText = false, Widget? suffix}) => TextFormField(controller: controller, validator: validator, keyboardType: keyboardType, obscureText: obscureText, decoration: InputDecoration(labelText: label, suffixIcon: suffix));
}
