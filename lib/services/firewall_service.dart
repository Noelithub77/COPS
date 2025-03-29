import 'dart:io';
import 'dart:convert';

class FirewallService {
  final List<String> whitelist = ['codeforces.com'];
  Function(String) onMessageCallback;

  FirewallService({required this.onMessageCallback});

  Future<void> disableWhitelist() async {
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
        onMessageCallback(data);
      });
      process.stderr.transform(utf8.decoder).listen((err) {
        onMessageCallback("Error: $err");
      });
      await process.exitCode;
    } catch (e) {
      onMessageCallback('Error disabling COP: $e');
    }
  }

  Future<void> enableWhitelist() async {
    try {
      List<String> commands = [];
      commands.add("netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound");
      
      for (final domain in whitelist) {
        try {
          List<InternetAddress> addresses = await InternetAddress.lookup(domain);
          List<String> ipList = addresses.map((ip) => ip.address).toList();
          
          if (ipList.isNotEmpty) {
            String ips = ipList.join(',');
            commands.add("netsh advfirewall firewall add rule name='Allow $domain' dir=out action=allow protocol=any remoteip=$ips");
          } else {
            commands.add("Write-Output 'No IP address found for $domain'");
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
        onMessageCallback(data);
      });
      ruleProcess.stderr.transform(utf8.decoder).listen((err) {
        onMessageCallback("Error: $err");
      });
      await ruleProcess.exitCode;
      onMessageCallback("Whitelist enabled");
    } catch (e) {
      onMessageCallback('Error enabling whitelist: $e');
    }
  }

  Future<void> resetFirewall() async {
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
          onMessageCallback(line);
        });
      
      process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          onMessageCallback("Error: $line");
        });
      
      await process.exitCode;
    } catch (e) {
      onMessageCallback('Failed to reset firewall: $e\n${e.toString()}');
    }
  }
} 