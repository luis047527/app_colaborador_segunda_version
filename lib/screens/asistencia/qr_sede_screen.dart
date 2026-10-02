import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/lumibell_theme.dart';
import '../../widgets/lumibell_ui.dart';

class QrSedeScreen extends StatefulWidget {
  const QrSedeScreen({super.key, required this.api, this.savePng});
  final ApiService api;
  final Future<void> Function(Uint8List bytes, String name)? savePng;
  @override
  State<QrSedeScreen> createState() => _QrSedeScreenState();
}

class _QrSedeScreenState extends State<QrSedeScreen> {
  List<Map<String, dynamic>> _sites = [];
  int? _siteId;
  Map<String, dynamic>? _qr;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  bool _canGenerate = false;

  @override
  void initState() { super.initState(); _loadSites(); }

  String _message(Object error) => error is ApiException
    ? error.message : 'No se pudo completar la operación. Vuelve a intentarlo.';

  Future<void> _loadSites() async {
    setState(() { _loading = true; _error = null; _qr = null; _canGenerate = false; });
    try {
      final rows = List<Map<String, dynamic>>.from(
        (await widget.api.get('/api/sedes') as List).map((row) => Map<String, dynamic>.from(row as Map)),
      ).where((site) => site['estado'] == 'ACTIVA').toList();
      if (!mounted) return;
      setState(() { _sites = rows; _siteId = rows.isEmpty ? null : (rows.first['id'] as num).toInt(); });
      if (_siteId != null) await _loadQr(_siteId!);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadQr(int id) async {
    setState(() { _siteId = id; _qr = null; _error = null; _busy = true; _canGenerate = false; });
    try {
      final result = Map<String, dynamic>.from(await widget.api.get('/api/sedes/$id/qr'));
      if (mounted) setState(() { _qr = result; _canGenerate = true; });
    } on ApiException catch (error) {
      if (!mounted) return;
      // Un 404 también puede significar sede inexistente.
      final missingQr = error.statusCode == 404 && error.message.startsWith('Sede sin QR generado');
      setState(() { _canGenerate = missingQr; _error = missingQr ? null : error.message; });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate() async {
    final id = _siteId;
    if (id == null || _busy || !_canGenerate) return;
    setState(() => _busy = true);
    try {
      if (_qr != null) {
        final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
          title: const Text('¿Regenerar QR?'),
          content: const Text('El QR actual dejará de funcionar. Tendrás que reemplazar las copias impresas de esta sede.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Regenerar')),
          ],
        ));
        if (confirmed != true || !mounted) return;
      }
      // Si se pierde la respuesta, el QR anterior podría estar invalidado.
      setState(() { _qr = null; _error = null; _canGenerate = false; });
      final result = Map<String, dynamic>.from(await widget.api.post('/api/sedes/$id/qr', {}));
      if (mounted) setState(() { _qr = result; _canGenerate = true; });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    final id = _siteId;
    if (id == null || _qr == null || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      // Ruta del propio servidor: no enviar el JWT a URLs externas.
      final bytes = await widget.api.getPng('/api/sedes/$id/qr?formato=png');
      final name = 'lumibell-sede-$id';
      if (widget.savePng != null) {
        await widget.savePng!(bytes, name);
      } else {
        await FileSaver.instance.saveFile(name: name, bytes: bytes, fileExtension: 'png', mimeType: MimeType.png);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR enviado a guardar como PNG.')));
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('QR de sede')),
    body: _loading ? const LumibellLoadingView(message: 'Consultando sedes…') : ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LumibellCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Sede', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          DropdownButtonHideUnderline(child: DropdownButton<int>(
            value: _siteId, isExpanded: true, hint: const Text('Sin sedes activas'),
            items: _sites.map((site) => DropdownMenuItem<int>(value: (site['id'] as num).toInt(), child: Text('${site['nombre']}'))).toList(),
            onChanged: _busy ? null : (id) { if (id != null) _loadQr(id); },
          )),
          const SizedBox(height: 8),
          const Text('QR estático: válido hasta regenerarlo. Puedes imprimirlo para tu sede.'),
        ])),
        const SizedBox(height: 16),
        if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        if (_error != null) ...[
          Semantics(liveRegion: true, child: Text(_error!, style: const TextStyle(color: LumibellColors.danger))),
          const SizedBox(height: 12),
        ],
        if (_qr != null) LumibellCard(child: Column(children: [
          Text('QR de marcación', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 280), child: AspectRatio(
            aspectRatio: 1, child: QrImageView(data: _qr!['qr_valor'] as String, backgroundColor: Colors.white),
          ))),
          const SizedBox(height: 12),
          const Text('Escanea este código desde Registrar marcación.', textAlign: TextAlign.center),
        ])),
        if (_qr == null && _canGenerate && !_busy) const Text('Esta sede aún no tiene un QR generado.'),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _busy || !_canGenerate ? null : _generate,
          icon: const Icon(Icons.qr_code_rounded), label: Text(_qr == null ? 'Generar QR' : 'Regenerar QR')),
        if (_qr != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _busy ? null : _download, icon: const Icon(Icons.download_rounded), label: const Text('Descargar PNG')),
        ],
        TextButton.icon(onPressed: _busy ? null : () { if (_siteId == null) { _loadSites(); } else { _loadQr(_siteId!); } },
          icon: const Icon(Icons.refresh_rounded), label: const Text('Actualizar')),
      ],
    ),
  );
}
