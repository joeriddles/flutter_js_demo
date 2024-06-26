import 'dart:js_interop';

@JS('onMidiAccess')
external set onMidiAccess(JSExportedDartFunction f);

@JS('requestPermissions')
external JSPromise requestPermissions();
