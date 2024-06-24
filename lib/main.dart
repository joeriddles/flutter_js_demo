import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'js.dart' as js;

JSObject? midiAccess;

void main() {
  js.onMidiAccess = ((JSObject midiAccessFromJs) {
    midiAccess = midiAccessFromJs;
  }).toJS;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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

  void _refreshTitle() {
    setState(() {
      if (midiAccess != null) {
        _title = midiAccess.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_title),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('refresh'),
        onPressed: _refreshTitle,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
