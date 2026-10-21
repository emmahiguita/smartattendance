import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/localstore/secure_storage_provider.dart';
import '../../../../core/auth/session_controller.dart';

/// Autorización administrativa del dispositivo. El código se guarda únicamente
/// en el almacén cifrado de Android. No se incluye en logs, SQLite ni reportes.
class AdminAccess extends StateNotifier<bool> {
  AdminAccess(this.storage):super(false);
  final FlutterSecureStorage storage;
  Timer? _expiry;
  Future<bool> hasCode() async => await storage.read(key:'attendance_admin_code')!=null;
  Future<void> unlock(String code,{String? confirmation}) async {
    if(!RegExp(r'^\d{6,8}$').hasMatch(code))throw const FormatException('Usa un código de 6 a 8 dígitos.');
    final blocked=int.tryParse(await storage.read(key:'attendance_admin_blocked')??'0')??0;
    if(DateTime.now().toUtc().millisecondsSinceEpoch<blocked)throw const FormatException('Demasiados intentos. Reintenta en unos minutos.');
    final saved=await storage.read(key:'attendance_admin_code');
    if(saved==null){
      if(code!=confirmation)throw const FormatException('Los códigos no coinciden.');
      await storage.write(key:'attendance_admin_code',value:code);
    }else if(saved!=code){
      final attempts=(int.tryParse(await storage.read(key:'attendance_admin_attempts')??'0')??0)+1;
      await storage.write(key:'attendance_admin_attempts',value:'$attempts');
      if(attempts>=5){
        await storage.write(key:'attendance_admin_blocked',value:'${DateTime.now().toUtc().add(const Duration(minutes:5)).millisecondsSinceEpoch}');
        await storage.write(key:'attendance_admin_attempts',value:'0');
      }
      throw const FormatException('Código incorrecto.');
    }
    await storage.delete(key:'attendance_admin_attempts');
    await storage.delete(key:'attendance_admin_blocked');
    if(!mounted)return;
    state=true;
    _expiry?.cancel();
    _expiry=Timer(const Duration(minutes:10),lock);
  }
  void lock(){_expiry?.cancel();if(mounted)state=false;}
  @override
  void dispose(){_expiry?.cancel();super.dispose();}
}

/// Cambiar de sesión bloquea de nuevo. Un único timer caduca la autorización;
/// no existe un sondeo permanente ni una tarea en segundo plano.
final adminAccessProvider=StateNotifierProvider<AdminAccess,bool>((ref){
  ref.watch(sessionControllerProvider);
  return AdminAccess(ref.watch(secureStorageProvider));
});
