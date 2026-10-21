import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_access.dart';

/// Acceso dentro de Configuración; no agrega otra pantalla ni modifica Inicio.
/// Cerrar el diálogo libera inmediatamente los campos que contienen el código.
class AdminUnlockButton extends ConsumerWidget {
  const AdminUnlockButton({super.key});
  Future<void> _open(BuildContext context,WidgetRef ref) async {
    final exists=await ref.read(adminAccessProvider.notifier).hasCode();
    if(!context.mounted)return;
    await showDialog<void>(context:context,barrierDismissible:false,
      builder:(_)=>_CodeDialog(exists:exists));
  }
  @override
  Widget build(BuildContext context,WidgetRef ref){
    final unlocked=ref.watch(adminAccessProvider);
    return ListTile(contentPadding:EdgeInsets.zero,leading:Icon(unlocked?Icons.lock_open:Icons.lock_outline),
      title:Text(unlocked?'Administración habilitada':'Acceso del administrador'),
      subtitle:const Text('Código local. La autorización caduca en 10 minutos.'),
      trailing:TextButton(onPressed:()=>unlocked?ref.read(adminAccessProvider.notifier).lock():_open(context,ref),
        child:Text(unlocked?'Bloquear':'Desbloquear')));
  }
}
class _CodeDialog extends ConsumerStatefulWidget {
  const _CodeDialog({required this.exists});
  final bool exists;
  @override
  ConsumerState<_CodeDialog> createState()=>_CodeDialogState();
}
class _CodeDialogState extends ConsumerState<_CodeDialog>{
  final _code=TextEditingController(),_confirmation=TextEditingController();
  bool _busy=false;
  String? _error;
  @override
  void dispose(){_code.dispose();_confirmation.dispose();super.dispose();}
  Future<void> _unlock()async{
    setState((){_busy=true;_error=null;});
    try{
      await ref.read(adminAccessProvider.notifier).unlock(_code.text,confirmation:_confirmation.text);
      if(mounted)Navigator.pop(context);
    }catch(e){if(mounted)setState(()=>_error=e is FormatException?e.message:'No se pudo acceder al almacén seguro.');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context)=>PopScope(canPop:!_busy,child:AlertDialog(
    title:Text(widget.exists?'Acceso administrativo':'Configurar código del administrador'),
    content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:_code,obscureText:true,enableSuggestions:false,autocorrect:false,
        keyboardType:TextInputType.number,maxLength:8,decoration:const InputDecoration(labelText:'Código de 6 a 8 dígitos')),
      if(!widget.exists)TextField(controller:_confirmation,obscureText:true,enableSuggestions:false,autocorrect:false,
        keyboardType:TextInputType.number,maxLength:8,decoration:const InputDecoration(labelText:'Confirmar código')),
      if(!widget.exists)const Text('El administrador de la empresa debe configurar y conservar este código. No se envía a un servidor.'),
      if(_error!=null)Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
    ])),actions:[TextButton(onPressed:_busy?null:()=>Navigator.pop(context),child:const Text('Cancelar')),
      FilledButton(onPressed:_busy?null:_unlock,child:Text(_busy?'Procesando…':'Continuar'))]));
}
