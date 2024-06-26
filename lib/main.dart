import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'js.dart' as js;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const uuid = Uuid();
    final guid = uuid.v4();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'GUID: $guid'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _title = "No MIDI access";

  @override
  Widget build(BuildContext context) {
    js.onMidiAccess = ((JSObject midiAccessFromJs) {
      setState(() {
        _title = midiAccessFromJs.toString();
      });
    }).toJS;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          key: const Key('title'),
          widget.title,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_title),
            TextButton(
              onPressed: () async {
                await js.requestPermissions().toDart;
              },
              child: const Text('Request permissions'),
            )
          ],
        ),
      ),
    );
  }
}
