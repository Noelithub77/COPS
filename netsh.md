## To block:
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound
## To allow:
 netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound
## To reset:
netsh advfirewall reset
## To show the current settings:
netsh advfirewall show allprofiles
## To show the current settings in a more readable format:
netsh advfirewall show allprofiles | findstr "State"
## ip lookup from dns:-
$ips = (Resolve-DnsName codeforces.com -ErrorAction Stop |
        Where-Object { $_.IPAddress -match '^\d+\.\d+\.\d+\.\d+$' } |
        Select-Object -ExpandProperty IPAddress) -join ','
## allow only specific ip address:-
netsh advfirewall firewall add rule name="Allow Codeforces" dir=out action=allow protocol=any remoteip=$ips

## To see our rules:-
![alt text](image.png)
netsh advfirewall firewall show rule name="Allow Codeforces"
-continusly check if the rule is enabled if not trigger an alert to the server

## All enabled rules, if some other rules cut:
Get-NetFirewallRule -PolicyStore PersistentStore | Where-Object { $_.Enabled -eq $true } | Format-Table -AutoSize
