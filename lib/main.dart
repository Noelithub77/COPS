import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // for utf8 and LineSplitter

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COPS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 249, 55, 84)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'COPS'),
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
  int _counter = 0;
  String _firewallResult = '';

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _resetFirewall() async {
    setState(() { _firewallResult = ''; });  // Clear previous output
    try {
      // Start the process, streaming output to the UI.
      Process process = await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy', 'Bypass',
          '-Command',
          'Start-Process',
          'powershell.exe',
          '-Verb', 'RunAs',
          '-ArgumentList',
          '\'-NoProfile -ExecutionPolicy Bypass -NoExit -Command "netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound"\'',
        ],
        runInShell: true,
      );

      process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          setState(() {
            _firewallResult += line + '\n';
          });
        });
      
      // Listen to stderr
      process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          setState(() {
            _firewallResult += "Error: " + line + "\n";
          });
        });
      
      await process.exitCode;
    } catch (e) {
      setState(() {
        _firewallResult = 'Failed to reset firewall: $e\n${e.toString()}';
      });
    }
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
            Text(
              _firewallResult,
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: _resetFirewall,
              child: const Text('Reset Firewall'),
            ),
            SingleChildScrollView(
              child: Text(
                _firewallResult,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
