# Set variables
$subscriptionId="7a5c5d51-5694-47a7-99a8-821caef3a826"
$resourceGroup = "ai-cloud-poc"
$vmName = "poc"
$NewvmName = "New-vm"
$location = "uksouth" #VM Location
$zone = "3" #1 2 or 3

 
#Login to the Azure
Login-AzAccount
 
#Set the subscription
Set-AzContext -Subscription $subscriptionId
 
# Get the details of the VM to be moved to the Availability Set
$originalVM = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName
 
# Stop the VM to take snapshot
#Stop-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Force 
 
# Create a SnapShot of the OS disk and then, create an Azure Disk with Zone information
$snapshotOSConfig = New-AzSnapshotConfig -SourceUri $originalVM.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy -SkuName Standard_ZRS
$OSSnapshot = New-AzSnapshot -Snapshot $snapshotOSConfig -SnapshotName ($originalVM.StorageProfile.OsDisk.Name + "-snapshot") -ResourceGroupName $resourceGroup 
$diskSkuOS = (Get-AzDisk -DiskName $originalVM.StorageProfile.OsDisk.Name -ResourceGroupName $originalVM.ResourceGroupName).Sku.Name
 
$diskConfig = New-AzDiskConfig -Location $OSSnapshot.Location -SourceResourceId $OSSnapshot.Id -CreateOption Copy -SkuName  $diskSkuOS -Zone $zone 
$OSdisk = New-AzDisk -Disk $diskConfig -ResourceGroupName $resourceGroup -DiskName ($NewvmName + '-OSdisk')
 
 
# Create a Snapshot from the Data Disks and the Azure Disks with Zone information
foreach ($disk in $originalVM.StorageProfile.DataDisks) 
   { 
   
   $snapshotDataConfig = New-AzSnapshotConfig -SourceUri $disk.ManagedDisk.Id -Location $location -CreateOption copy -SkuName Standard_ZRS
   $DataSnapshot = New-AzSnapshot -Snapshot $snapshotDataConfig -SnapshotName ($disk.Name + '-snapshot') -ResourceGroupName $resourceGroup
 
   $diskSkuData = (Get-AzDisk -DiskName $disk.Name -ResourceGroupName $originalVM.ResourceGroupName).Sku.Name
   $datadiskConfig = New-AzDiskConfig -Location $DataSnapshot.Location -SourceResourceId $DataSnapshot.Id -CreateOption Copy -SkuName $diskSkuData -Zone $zone
   $datadisk = New-AzDisk -Disk $datadiskConfig -ResourceGroupName $resourceGroup -DiskName ($NewvmName + "-disk-" + $disk.Lun )
   
  }

# Remove the original VM
#Remove-AzVM -ResourceGroupName $resourceGroup -Name $vmName  -Force
 
# Create the basic configuration for the replacement VM
$newVM = New-AzVMConfig -VMName $NewvmName -VMSize $originalVM.HardwareProfile.VmSize -Zone $zone
 
# Add the pre-existed OS disk 
Set-AzVMOSDisk -VM $newVM -CreateOption Attach -ManagedDiskId $OSdisk.Id -Name $OSdisk.Name -Windows
 
# Add the pre-existed data disks
foreach ($disk in $originalVM.StorageProfile.DataDisks) { 
	
    $datadisk = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName ($NewvmName + "-disk-" + $disk.Lun)
    Add-AzVMDataDisk -VM $newVM -Name $datadisk.Name -ManagedDiskId $datadisk.Id -Caching $disk.Caching -Lun $disk.Lun -DiskSizeInGB $disk.DiskSizeGB -CreateOption Attach 

}
 
# Add NIC(s) and keep the same NIC as primary
# If there is a Public IP from the Basic SKU remove it because it doesn't supports zones
foreach ($nic in $originalVM.NetworkProfile.NetworkInterfaces) {  
   $netInterface = Get-AzNetworkInterface -ResourceId $nic.Id 
 
if ($nic.Primary -eq "True")
   {
      $vmnic = New-AzNetworkInterface -Name ($NewvmName + "_Nic" ) -ResourceGroupName $resourceGroup -Location $location -SubnetId $netInterface.IpConfigurations.Subnet.Id -IpConfigurationName "IPConfiguration1"
	  Add-AzVMNetworkInterface -VM $newVM -Id $vmnic.Id -Primary
   }
   else
   {
      $vmnic = New-AzNetworkInterface -Name ($NewvmName + "_Nic" ) -ResourceGroupName $resourceGroup -Location $location -SubnetId $netInterface.IpConfigurations.Subnet.Id -IpConfigurationName "IPConfiguration1"
	  Add-AzVMNetworkInterface -VM $newVM -Id $vmnic.Id
   }
   
}
 
# Recreate the VM
New-AzVM -ResourceGroupName $resourceGroup -Location $originalVM.Location -VM $newVM -DisableBginfoExtension
 
# If the machine is SQL server, create a new SQL Server object
# New-AzSqlVM -ResourceGroupName $resourceGroup -Name $newVM.Name -Location $location -LicenseType PAYG
