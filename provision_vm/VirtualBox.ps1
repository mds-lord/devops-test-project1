# This script provisions virtual machine with unique name,
# installs RHEL on it and writes VM parameters (such as 
# name and IP) to rhel-web-vm.txt, and to standard output.
#
# VM parameters
$vmName = "RHEL-websrv-" + (Get-Date -f yyyyMMdd-HHmmss);
$vmMemory = "2048";

# Checking availability of VBoxManager
$vbm = "VBoxManage.exe";

if ($null -eq (Get-Command $vbm -ErrorAction SilentlyContinue)) {
  Write-Host "Unable to find VBoxManage in your PATH. Trying to correct...";

  $vbIsInstalled = $null -ne (Get-ItemProperty HKLM:\Software\Oracle\* | 
    Where-Object { $_.PSChildName -eq "VirtualBox" });

  if (-Not $vbIsInstalled) {
	  Write-Host "Oracle VirtualBox is not installed, or installed incorrectly.";
    Write-Host "Cannot continue.";
    exit(1);
  } else {
    $vbPath = (Get-ItemProperty HKLM:\Software\Oracle\VirtualBox\ -Name InstallDir).InstallDir;
    $vbm = $vbPath + $vbm;
    if ($null -eq (Get-Command $vbm -ErrorAction SilentlyContinue)) {
      Write-Host "Oracle VirtualBox found, but no VBoxManage.exe there.";
      Write-Host "Cannot continue.";
      exit(1);
    } else {
      Write-Host "VirtualBox found. Will use '$vbm'";
    }
  }
}

# Checking iso file for RHEL installation. Assuming it is in
# the parent directory.
# rhel-8.4-x86_64-dvd.iso is current at the moment of this 
# script creation.
if ($null -eq (Get-ItemProperty ..\rhel-*-x86_64-dvd.iso)) {
  Write-Host "Oops. No RHEL iso in Parent dir. Please, consider downloading it before";
  Write-Host "running this script. Cannot continue.";
  exit(1);
}

# Getting current location and initialising variables
$workDir = (Get-Location).Path;
# Checking if long paths are enabled
if (((Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem\ `
  -Name LongPathsEnabled).LongPathsEnabled -ne 1) -and 
  ($workDir.Length -gt 220))
  {
    Write-Host "Long paths are not enabled on your system. This may lead to issues with ";
    Write-Host "VM unique name generation, because of deep directory nesting. Generated ";
    Write-Host "VM filename will be 32 characters long.";
    $isUserAgreed = Read-Host -Prompt "Are you sure you wish to continue? [y/N]";
    if (($isUserAgreed -ne "y") -or ($isUserAgreed -ne "Y")) {
      Write-Host "Interrupting.";
      exit(1);
    }
  }

# Create and register VM
&$vbm createvm --name $vmName --basefolder $workDir --register;
&$vbm modifyvm $vmName --memory $vmMemory `
  --ostype "RedHat_64";
&$vbm showvminfo $vmName;
&$vbm unregistervm $vmName --delete;
