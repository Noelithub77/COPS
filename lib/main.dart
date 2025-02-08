import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';

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
    final shell = Shell();
    try {
      var result = await shell.run('''
        powershell -Command "Start-Process powershell -ArgumentList '-Command \\"netsh advfirewall show allprofiles\\"' -Verb runAs -Wait"
      ''');
      setState(() {
        _firewallResult = result.outText;
      });
    } catch (e) {
      setState(() {
        _firewallResult = 'Failed to reset firewall: $e';
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
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: _resetFirewall,
              child: const Text('Reset Firewall'),
            ),
            Text(
              _firewallResult,
              style: Theme.of(context).textTheme.bodyMedium,
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
