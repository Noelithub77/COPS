import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../services/firewall_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _firewallResult = '';
  bool _whitelistEnabled = false;
  
  late SocketService _socketService;
  late FirewallService _firewallService;

  final TextEditingController _handleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _socketService = SocketService(
      onMessageCallback: (message) {
        setState(() {
          _firewallResult += "$message\n";
        });
      }
    );
    
    _firewallService = FirewallService(
      onMessageCallback: (message) {
        setState(() {
          _firewallResult += "$message\n";
        });
      }
    );
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _submitHandle() {
    final handle = _handleController.text;
    _socketService.sendHandle(handle);
  }
  
  Future<void> _toggleWhitelistMode(bool enabled) async {
    setState(() { _whitelistEnabled = enabled; });
    
    _socketService.toggleState(enabled, _handleController.text);
    
    if (enabled) {
      await _firewallService.enableWhitelist();
    } else {
      await _firewallService.disableWhitelist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: SelectableText(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _handleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Codeforces Handle',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _submitHandle,
              child: const Text('Submit Handle'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SelectableText("COP?"),
                Switch(
                  value: _whitelistEnabled,
                  onChanged: _toggleWhitelistMode,
                ),
              ],
            ),
            SelectableText(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: () => _firewallService.resetFirewall(),
              child: const Text('Reset Firewall'),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _firewallResult,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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