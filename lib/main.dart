import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // for utf8 and LineSplitter
import 'package:socket_io_client/socket_io_client.dart' as IO; // new import

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
  
  // New: whitelist of allowed domains.
  final List<String> whitelist = ['codeforces.com'];
  bool _whitelistEnabled = false;
  
  // New: socket connection instance.
  late IO.Socket _socket;

  final TextEditingController _handleController = TextEditingController(); // new

  @override
  void initState() {
    super.initState();
    _initializeSocket(); // new: initialize socket
  }

  // New: initialize the socket connection.
  void _initializeSocket() {
    _socket = IO.io('http://127.0.0.1:6969', <String, dynamic>{
      'transports': ['websocket'],
    });
    _socket.on('connect', (_) {
      setState(() {
        _firewallResult += "Socket connected\n";
      });
    });
    _socket.on('response', (data) {
      setState(() {
        _firewallResult += "Response: $data\n";
      });
    });
    _socket.on('disconnect', (_) {
      setState(() {
        _firewallResult += "Socket disconnected\n";
      });
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // New: disables whitelist mode: allow all inbound/outbound.
  Future<void> _disableWhitelist() async {
    setState(() { _firewallResult = ''; });
    try {
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
      process.stdout.transform(utf8.decoder).listen((data) {
        setState(() { _firewallResult += data + "\n"; });
      });
      process.stderr.transform(utf8.decoder).listen((err) {
        setState(() { _firewallResult += "Error: " + err + "\n"; });
      });
      await process.exitCode;
    } catch (e) {
      setState(() {
        _firewallResult = 'Error disabling COP: $e';
      });
    }
  }

  // Updated: enables whitelist mode without using Where-Object and with adjusted quoting.
  Future<void> _enableWhitelist() async {
    setState(() { _firewallResult = ''; });
    try {
      List<String> commands = [];
      // Reset firewall policy to block traffic.
      commands.add("netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound");
      
      for (final domain in whitelist) {
        try {
          List<InternetAddress> addresses = await InternetAddress.lookup(domain);
          // Filter IPv4 addresses.
          List<String> ipList = addresses
              .where((ip) => ip.type == InternetAddressType.IPv4)
              .map((ip) => ip.address)
              .toList();
          if (ipList.isNotEmpty) {
            String ips = ipList.join(',');
            commands.add("netsh advfirewall firewall add rule name='Allow $domain' dir=out action=allow protocol=any remoteip=$ips");
          } else {
            commands.add("Write-Output 'No IPv4 address found for $domain'");
          }
        } catch (e) {
          commands.add("Write-Output 'Error resolving $domain: $e'");
        }
      }
      
      String innerCommand = commands.join("; ");
      
      String elevatedCommand = "Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-Command','${innerCommand.replaceAll("'", "''")}')";
      
      Process ruleProcess = await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy', 'Bypass',
          '-Command',
          elevatedCommand,
        ],
        runInShell: true,
      );
      
      ruleProcess.stdout.transform(utf8.decoder).listen((data) {
        setState(() { _firewallResult += data + "\n"; });
      });
      ruleProcess.stderr.transform(utf8.decoder).listen((err) {
        setState(() { _firewallResult += "Error: " + err + "\n"; });
      });
      await ruleProcess.exitCode;
      setState(() { _firewallResult += "Whitelist enabled\n"; });
    } catch (e) {
      setState(() {
        _firewallResult = 'Error enabling whitelist: $e';
      });
    }
  }

  // New: send Codeforces handle to backend.
  void _submitHandle() {
    final handle = _handleController.text;
    _socket.emit('handle', {'handle': handle});
    setState(() {
      _firewallResult += "Handle sent: $handle\n";
    });
  }
  
  // New: modified toggle method to emit toggle state and send handle when turned off.
  Future<void> _toggleWhitelistMode(bool enabled) async {
    setState(() { _whitelistEnabled = enabled; });
    // Always send toggle state.
    _socket.emit('toggle', {'state': enabled});
    // When turning off, update backend with the latest handle.
    if (!enabled) {
      _socket.emit('handle', {'handle': _handleController.text});
    }
    if (enabled) {
      await _enableWhitelist();
    } else {
      await _disableWhitelist();
    }
  }

  Future<void> _resetFirewall() async {
    setState(() { _firewallResult = ''; }); 
    try {
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
          '\'-NoProfile -ExecutionPolicy Bypass -NoExit -Command "netsh advfirewall reset"\'',
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
        title: SelectableText(widget.title), // updated
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // New: Codeforces handle input.
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
            // New: toggle switch for whitelist mode.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SelectableText("COP?"), // updated
                Switch(
                  value: _whitelistEnabled,
                  onChanged: _toggleWhitelistMode,
                ),
              ],
            ),
            SelectableText(_firewallResult), // updated
            SelectableText(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: _resetFirewall,
              child: const Text('Reset Firewall'),
            ),
            SingleChildScrollView(
              child: SelectableText( // updated
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
