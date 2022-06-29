﻿################## Create Variables    ##################E

$Project_Name = Read-Host 'Please enter your project name'

$Drive_Letter_No_collon = Read-Host 'Please enter your drive letter'

$Drive_Letter_collon = "$Drive_Letter_No_collon" + ':\'

$Project_Path = ("$Drive_Letter_collon" + "$Project_Name")

$VM_Name = Read-Host 'Please enter your vm name'

$VM_Full_Name = "$Project_Name" + "-" + "$VM_Name"

$VM_Path = ("$Project_Path" + "\" + "$VM_Full_Name")

$VHD_Path = ("$VM_Path" + "\" + "$VM_Full_Name.vhdx")

Write-Host "Your project name is -- > $Project_Name"
Write-Host "Your drive letter is -- > $Drive_Letter_collon"

##################################################################################



################## Create Private Switch with your project name ##################

$VM_Switches = Get-VMSwitch | Out-String
if ($VM_Switches.Contains($Project_Name)){Write-Host "We found that your VM switch is already created before"}
else {New-VMSwitch "$Project_Name" -SwitchType Private}

################## Create Project folder with your project name ##################

$Test_Project_Path   = Test-Path -Path $Project_Path
if ($Test_Project_Path.Equals($false)){
New-Item -ItemType Directory -Name $Project_Name -Path $Drive_Letter_collon
Write-Host "We made a Project Folder on behalf of you to create your VM's inside it, You can find it under this path $Project_Path"
explorer.exe $Project_Path}
elseif ($Test_Project_Path.Equals($true)){
Write-Host "We found that Project Folder is already created before, You can find it under this path $Project_Path"
explorer.exe $Project_Path}

#################################################################################################################################


$Test_VM_Path   = Test-Path -Path $VM_Path
if ($Test_VM_Path.Equals($false)) {
New-VM -Name "$VM_Full_Name" -Generation 2 -MemoryStartupBytes 2GB  -NoVHD -Path "$Project_Path" -SwitchName "$Project_Name"
Set-VM -Name $VM_Full_Name -AutomaticCheckpointsEnabled 0 -CheckpointType Standard -MemoryMaximumBytes (2GB) -MemoryMinimumBytes (1GB) -MemoryStartupBytes (2GB)
Enable-VMIntegrationService -Name "Guest Service Interface" -VMName $VM_Full_Name
}
else 
{Write-Host "We found that your VM is already created before"}


$Test_VHD_Path = Test-Path $VHD_Path
if ( $Test_VHD_Path.Equals($false))
{
New-VHD -Path "$VHD_Path" -SizeBytes (100GB) -Dynamic
Add-VMHardDiskDrive -VMName $VM_Full_Name -ControllerLocation 0 -ControllerNumber 0 -ControllerType SCSI -Path $VHD_Path
Set-VM -Name $VM_Full_Name -AutomaticCheckpointsEnabled 0 -CheckpointType Standard -MemoryMaximumBytes (2GB) -MemoryMinimumBytes (1GB) -MemoryStartupBytes (2GB)
Enable-VMIntegrationService -Name "Guest Service Interface" -VMName $VM_Full_Name
Add-VMDvdDrive -VMName $VM_Full_Name -ControllerNumber 0 -ControllerLocation 1
}
else {
Write-Host "We found that your VHD is already created before"
}

### Add additional standard NIC connected to external switch ### 
Add-VMNetworkAdapter -VMName $VM_Full_Name -SwitchName External

### Enable TPM on VM ###
Enable-VMTPM -VMName $VM_Full_Name


### Boot Order DVD first ###
$vmDVD=Get-VMDvdDrive -VMName $VM_Full_Name 
$vmDrive= Get-VMHardDiskDrive -VMName $VM_Full_Name 
$vmNIC= Get-VMNetworkAdapter -VMName $VM_Full_Name
Set-VMFirmware -VMName $VM_Full_Name -EnableSecureBoot On -BootOrder $vmDVD,$vmDrive,$vmNIC  

### Boot Order VHD first ###
$vmDVD= Get-VMDvdDrive -VMName $VM_Full_Name
$vmDrive= Get-VMHardDiskDrive -VMName $VM_Full_Name  
$vmNIC= Get-VMNetworkAdapter -VMName $VM_Full_Name
Set-VMFirmware -VMName $VM_Full_Name -EnableSecureBoot On -BootOrder $vmDrive,$vmDVD,$vmNIC 

### Start VM ###
Start-VM $VM_Full_Name