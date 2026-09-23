import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/api_service.dart';
import '../../theme/lumibell_theme.dart';
import '../../widgets/lumibell_ui.dart';
import '../perfil/perfil_colaborador_screen.dart';
import '../horarios/mi_horario_screen.dart';
import 'historial_asistencias_screen.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key, required this.api, required this.usuarioId, required this.onLogout});
  final ApiService api;
  final int usuarioId;
  final VoidCallback onLogout;

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  late Future<_AttendanceData> _future = _load();
  bool _registering = false;

  Future<_AttendanceData> _load() async {
    final employee = Map<String, dynamic>.from(await widget.api.get('/api/empleados/me'));
    Map<String, dynamic>? schedule;
    try {
      schedule = Map<String, dynamic>.from(await widget.api.get('/api/empleados/${employee['id']}/horario'));
    } on ApiException {
      schedule = null;
    }
    return _AttendanceData(employee: employee, schedule: schedule);
  }

  Future<void> _scan() async {
    final token = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (token == null || !mounted) return;
    setState(() => _registering = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw ApiException('Activa la ubicación GPS del dispositivo.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw ApiException('Debes permitir el acceso a la ubicación GPS.');
      }
      final position = await Geolocator.getCurrentPosition();
      final response = Map<String, dynamic>.from(await widget.api.post('/api/marcaciones', {
        'qr_token': token,
        'latitud': position.latitude,
        'longitud': position.longitude,
      }));
      if (!mounted) return;
      await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => MarcacionResultadoScreen.success(response)));
      setState(() => _future = _load());
    } on ApiException catch (error) {
      if (!mounted) return;
      await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => MarcacionResultadoScreen.error(error.message)));
    } catch (_) {
      if (!mounted) return;
      await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => const MarcacionResultadoScreen.error('No se pudo obtener la ubicación o conectar con el servidor.')));
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const SizedBox.shrink(),
      title: const Text('Registrar marcación'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(28),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(_fullDate(DateTime.now()), style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    ),
    body: FutureBuilder<_AttendanceData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LumibellLoadingView(message: 'Preparando tu jornada...');
        if (snapshot.hasError) return LumibellStateView(icon: Icons.cloud_off_rounded, title: 'No se pudo cargar', message: '${snapshot.error}', actionLabel: 'Reintentar', onAction: () => setState(() => _future = _load()));
        return _content(snapshot.data!);
      },
    ),
    bottomNavigationBar: _navigation(),
  );

  Widget _content(_AttendanceData data) {
    final schedule = data.schedule;
    final day = schedule?['dia'] is Map ? Map<String, dynamic>.from(schedule!['dia'] as Map) : null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(_clock(DateTime.now()), textAlign: TextAlign.center, style: const TextStyle(color: LumibellColors.navy, fontSize: 34, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: LumibellColors.peachSoft, borderRadius: BorderRadius.circular(999)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.schedule_rounded, color: LumibellColors.copper, size: 15), SizedBox(width: 5), Text('Hora oficial del dispositivo', style: TextStyle(color: LumibellColors.copper, fontSize: 11, fontWeight: FontWeight.w600))]))),
        const SizedBox(height: 24),
        Center(
          child: Semantics(
            button: true,
            label: 'Escanear código QR',
            child: InkWell(
              onTap: _registering ? null : _scan,
              customBorder: const CircleBorder(),
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(shape: BoxShape.circle, color: LumibellColors.copper, border: Border.all(color: LumibellColors.peach, width: 14), boxShadow: const [BoxShadow(color: Color(0x338D3517), blurRadius: 18, spreadRadius: 4)]),
                child: _registering
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 60), SizedBox(height: 9), Text('ESCANEAR QR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Presiona para escanear el código QR de la sede', textAlign: TextAlign.center, style: TextStyle(color: LumibellColors.navySoft)),
        const SizedBox(height: 22),
        LumibellCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _infoRow(Icons.login_rounded, LumibellColors.peachSoft, LumibellColors.copper, 'Próxima marcación', 'La secuencia se determina al registrar'),
            const Divider(height: 1),
            _infoRow(Icons.calendar_today_rounded, LumibellColors.infoSoft, LumibellColors.info, 'Horario de hoy', day == null ? 'Sin horario asignado' : '${_shortTime(day['entrada'])} - ${_shortTime(day['salida'])}'),
            const Divider(height: 1),
            _infoRow(Icons.location_on_rounded, LumibellColors.successSoft, LumibellColors.success, 'GPS', 'Ubicación lista para validar'),
          ]),
        ),
        if (schedule == null) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: LumibellColors.warningSoft, borderRadius: BorderRadius.circular(13)), child: const Row(children: [Icon(Icons.info_outline_rounded, color: LumibellColors.warning), SizedBox(width: 10), Expanded(child: Text('Aún no tienes un horario asignado. Puedes escanear el QR, pero solicita al administrador configurar tu jornada.', style: TextStyle(color: LumibellColors.navy, fontSize: 12)))])),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, Color background, Color color, String label, String value) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      CircleAvatar(radius: 21, backgroundColor: background, child: Icon(icon, color: color, size: 21)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodyMedium), Text(value, style: Theme.of(context).textTheme.titleMedium)])),
    ]),
  );

  Widget _navigation() => DecoratedBox(
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: LumibellColors.border))),
    child: NavigationBar(selectedIndex: 2, onDestinationSelected: (index) {
      if (index == 0) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El inicio del colaborador se incorporará próximamente.')));
      if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => MiHorarioScreen(api: widget.api, usuarioId: widget.usuarioId, onLogout: widget.onLogout)));
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

  String _shortTime(dynamic value) => value == null ? '—' : '$value'.substring(0, '$value'.length >= 5 ? 5 : '$value'.length);
  String _clock(DateTime value) => '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  String _fullDate(DateTime value) {
    const days = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${days[value.weekday - 1]}, ${value.day} de ${months[value.month - 1]} de ${value.year}';
  }
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});
  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _done = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Escanear QR de sede', style: TextStyle(color: Colors.white))),
    body: Stack(fit: StackFit.expand, children: [
      MobileScanner(onDetect: (capture) {
        if (_done || capture.barcodes.isEmpty) return;
        final value = capture.barcodes.first.rawValue;
        if (value != null) { _done = true; Navigator.pop(context, value); }
      }),
      Center(child: Container(width: 260, height: 260, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(24)))),
      const Positioned(left: 24, right: 24, bottom: 42, child: Text('Coloca el código QR dentro del recuadro', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
    ]),
  );
}

class MarcacionResultadoScreen extends StatelessWidget {
  const MarcacionResultadoScreen.success(this.data, {super.key}) : errorMessage = null;
  const MarcacionResultadoScreen.error(this.errorMessage, {super.key}) : data = null;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  bool get success => data != null;

  @override
  Widget build(BuildContext context) {
    final mark = data?['marcacion'] is Map ? Map<String, dynamic>.from(data!['marcacion'] as Map) : const <String, dynamic>{};
    final type = _typeLabel('${mark['tipo'] ?? ''}');
    return Scaffold(
      appBar: AppBar(title: Text(success ? 'Marcación registrada' : 'Error en la marcación')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(children: [
          CircleAvatar(radius: 52, backgroundColor: success ? LumibellColors.successSoft : LumibellColors.dangerSoft, child: Icon(success ? Icons.check_rounded : Icons.close_rounded, color: success ? LumibellColors.success : LumibellColors.danger, size: 68)),
          const SizedBox(height: 22),
          Text(success ? '¡Marcación registrada!' : 'No se pudo registrar\nla marcación', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: success ? LumibellColors.success : LumibellColors.danger)),
          const SizedBox(height: 8),
          Text(success ? 'Tu $type fue registrada correctamente.' : errorMessage!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          if (success)
            LumibellCard(child: Column(children: [
              _resultRow(context, Icons.login_rounded, 'Tipo de marcación', type),
              const Divider(height: 24),
              _resultRow(context, Icons.schedule_rounded, 'Hora registrada', TimeOfDay.now().format(context)),
              const Divider(height: 24),
              _resultRow(context, Icons.calendar_month_rounded, 'Fecha', '${mark['fecha'] ?? ''}'),
              const Divider(height: 24),
              _resultRow(context, Icons.location_on_rounded, 'GPS', mark['fuera_radio'] == 1 ? 'Fuera del radio permitido' : 'Ubicación validada'),
            ]))
          else
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: LumibellColors.infoSoft, borderRadius: BorderRadius.circular(14)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Por favor, verifica que:', style: TextStyle(color: LumibellColors.navy, fontWeight: FontWeight.w800)), SizedBox(height: 10), Text('• Escanees el QR de la sede correcta.\n• El código esté vigente.\n• Te encuentres dentro del área permitida.\n• Tengas conexión a internet.', style: TextStyle(color: LumibellColors.navy, height: 1.7))])),
          const Spacer(),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: Text(success ? 'Volver al inicio' : 'Intentar nuevamente'))),
        ]),
      ),
    );
  }

  Widget _resultRow(BuildContext context, IconData icon, String label, String value) => Row(children: [
    CircleAvatar(backgroundColor: LumibellColors.successSoft, child: Icon(icon, color: LumibellColors.success)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodyMedium), Text(value, style: Theme.of(context).textTheme.titleMedium)])),
  ]);

  static String _typeLabel(String value) => switch (value) {
    'ENTRADA' => 'entrada',
    'SALIDA_REFRIGERIO' => 'salida a refrigerio',
    'REGRESO_REFRIGERIO' => 'regreso de refrigerio',
    'SALIDA' => 'salida',
    _ => 'marcación',
  };
}

class _AttendanceData {
  const _AttendanceData({required this.employee, required this.schedule});
  final Map<String, dynamic> employee;
  final Map<String, dynamic>? schedule;
}
