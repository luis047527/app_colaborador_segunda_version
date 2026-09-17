import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';

/// QR que se muestra en un dispositivo de la sede para que el colaborador lo escanee.
class QrSedeScreen extends StatefulWidget {
  const QrSedeScreen({super.key, required this.api});
  final ApiService api;
  @override State<QrSedeScreen> createState() => _QrSedeScreenState();
}
class _QrSedeScreenState extends State<QrSedeScreen> {
  List<dynamic> _sedes=[]; int? _sedeId; Map<String,dynamic>? _qr; String? _error;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async { try { _sedes=List<dynamic>.from(await widget.api.get('/api/sedes')); if(_sedes.isNotEmpty)_sedeId=_sedes.first['id'] as int; } on ApiException catch(e){_error=e.message;} if(mounted)setState((){}); }
  Future<void> _generate() async { if(_sedeId==null)return; try{final data=await widget.api.post('/api/marcaciones/qr/sede/$_sedeId',{});setState(()=>_qr=Map<String,dynamic>.from(data));}on ApiException catch(e){setState(()=>_error=e.message);} }
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('QR de marcación')),body:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[DropdownButtonFormField<int>(value:_sedeId,decoration:const InputDecoration(labelText:'Sede'),items:_sedes.map((s)=>DropdownMenuItem(value:s['id'] as int,child:Text(s['nombre']))).toList(),onChanged:(v)=>setState(()=>_sedeId=v)),const SizedBox(height:16),FilledButton(onPressed:_generate,child:const Text('Generar QR temporal')),if(_error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(_error!,style:const TextStyle(color:Colors.red))),if(_qr!=null)...[const SizedBox(height:28),Center(child:QrImageView(data:_qr!['token'] as String,size:260)),const SizedBox(height:12),Text('Vence: ${_qr!['expira_en']}',textAlign:TextAlign.center),const Text('Se renueva cada 2 minutos.',textAlign:TextAlign.center)] ])));
}
