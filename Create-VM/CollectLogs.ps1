﻿$Ports = ("53","135","88","389")
#53  --> DNS
#135 --> RPC Locator
#88  --> Kerberos
#389 --> LDAP
cls
foreach ($Ports in $Ports)
{Test-NetConnection "DC2" -Port $Ports}



$Testpath = Test-Path  'C:\CollectLogs.ps1'

if ($Testpath -eq $true )
{
Remove-Item -Path C:\CollectLogs.ps1 -Force
New-Item -Path C:\ -Name CollectLogs.ps1 -ItemType File -Force
}
else
{
New-Item -Path C:\ -Name CollectLogs.ps1 -ItemType File -Force
}



$content1={

### Create main folder ###
c: ; cd\ ;cls
$HostName        = hostname
$getadcomputer   = Get-ADComputer $HostName | select name,ObjectGUID,sid
$w32tm           = w32tm /query /status
$Date            = Get-Date -Format 'dd.MMMM.yy   HH.mm.ss'
$folderFullName  = "MicrosoftLogs" + " - "  + "$HostName" + " - " + "$Date"
New-Item "$folderFullName" -ItemType directory
cd $folderFullName
### Create main folder ###


### Create main folders & files ###
New-Item "$HostName-MainInfo.txt" -ItemType file
New-Item "$HostName-UserTest.txt" -ItemType file
New-Item "$HostName-ComputerInfo.txt" -ItemType file
New-Item "$HostName-Services.txt" -ItemType file
New-Item "$HostName-LOGS" -ItemType Directory
New-Item "$HostName-Events" -ItemType Directory
New-Item "$HostName-Replication" -ItemType Directory
New-Item "$HostName-DFSR" -ItemType Directory
New-Item "$HostName-DFSR\$HostName-DFSR.txt" -ItemType file
New-Item "$HostName-Registery" -ItemType Directory
### Create main folders & files ###

### User test ###
$whoami          = whoami
$whoamiupn       = whoami /upn
$whoamiall       = whoami /all
Add-Content "$HostName-UserTest.txt" $whoami," ",$whoamiupn," ",$whoamiall
### User test ###

### Copy log files ###
Copy-Item 'C:\Windows\debug\*.log' "$HostName-LOGS"
### Copy log files ###

### Copy event viewrs files ###
Copy-Item 'C:\Windows\System32\Winevt\Logs\Application.evtx' "$HostName-Events\$HostName-Application.evtx" -Force
Copy-Item 'C:\Windows\System32\Winevt\Logs\DFS Replication.evtx' "$HostName-Events\$HostName-DFS Replication.evtx" -Force
Copy-Item 'C:\Windows\System32\Winevt\Logs\Directory Service.evtx' "$HostName-Events\$HostName-Directory Service.evtx" -Force
Copy-Item 'C:\Windows\System32\Winevt\Logs\DNS Server.evtx' "$HostName-Events\$HostName-DNS Server.evtx" -Force
Copy-Item 'C:\Windows\System32\Winevt\Logs\System.evtx' "$HostName-Events\$HostName-System.evtx" -Force
Copy-Item 'C:\Windows\System32\Winevt\Logs\Security.evtx' "$HostName-Events\$HostName-Security.evtx" -Force
### Copy event viewrs files ###


Get-ComputerInfo > $HostName-ComputerInfo.txt

### Test services ###
$NTDS=cmd.exe /c "sc query ntds"
$netlogon=cmd.exe /c "sc query netlogon"
$lanman=cmd.exe /c "sc query lanmanworkstation"
$LanmanServer=cmd.exe /c "sc query LanmanServer"
$Bowser=cmd.exe /c "sc query Bowser"
$MRxSmb20=cmd.exe /c "sc query MRxSmb20"
$NSI=cmd.exe /c "sc query NSI"
$dns=cmd.exe /c "sc query dns"
$rpc=cmd.exe /c "sc query rpcss"
$SamSS=cmd.exe /c "sc query SamSS"
$Srv2=cmd.exe /c "sc query Srv2"
Add-Content "$HostName-Services.txt" $NTDS," " ,$netlogon," ",$lanman," ",$dns," ",$rpc," ",$Bowser," ",$MRxSmb20," ",$NSI," " ,$LanmanServer," ",$SamSS," ",$Srv2
### Test services ###

### Registery values ###
cmd.exe /c "reg export HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\  $HostName-Registery\$HostName-Netlogon.reg"
cmd.exe /c "reg export HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters\  $HostName-Registery\$HostName-NTDS.reg" 
### Registery values ###


### Replication ###
$ReplSum = "Replsum" + ' ' + 'for' + ' ' + "$HostName"
repadmin /replsum > "$HostName-$ReplSum.txt"
Move-Item "c:\$folderFullName\$HostName-$ReplSum.txt" "$HostName-Replication"
repadmin /showrepl * > "$HostName-Replication\$HostName-ShowreplAll.txt" 
### Replication ###

### Domain function ###
$FSMO     = netdom query fsmo
$ADForest = Get-ADForest | select sites,rootdomain,forestmode
$ADDomain = Get-ADDomain | select name,domainmode
dcdiag.exe  /v  > "$HostName-DCDIAG.txt"
Add-Content "$HostName-MainInfo.txt" $HostName," ",$FSMO," ",$getadcomputer," ",$ADForest," ",$ADDomain," ",$w32tm
### Domain function ###

### DFSR ###
$DFSR_Global_State      = dfsrmig.exe /getglobalstate
$DFSR_Migration_State   = dfsrmig.exe /getmigrationstate
$DFSR_State             = Get-WmiObject -Namespace "root\MicrosoftDFS" -Class DfsrReplicatedFolderInfo | Select-Object ReplicatedFolderName,ReplicationGroupName,state 

<#
The "State" values can be: 
0 = Uninitialized 
1 = Initialized 
2 = Initial Sync 
3 = Auto Recovery 
4 = Normal 
5 = In Error   
#>

Add-Content "$HostName-DFSR\$HostName-DFSR.txt" "$DFSR_Global_State"," ","$DFSR_Migration_State"," ",$DFSR_State
### DFSR ###

cd\

Compress-Archive -Path "c:\$folderFullName\" -Verbose  -DestinationPath "c:\$folderFullName.zip" -Force
Remove-Item -Path "c:\$folderFullName" -Recurse -Force ; cls
}

Add-Content -Value $content1 -Path C:\CollectLogs.ps1


