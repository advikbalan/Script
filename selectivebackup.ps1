$resourceGroupName="ai-cloud-poc"
$recoveryServicesVaultName="vault329"
$virtualMachineName="backuptest"
$disks = ("0","1")
$vault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $recoveryServicesVaultName
Set-AzRecoveryServicesVaultContext -Vault $vault
$backupItem = Get-AzRecoveryServicesBackupItem -BackupManagementType "AzureVM" -WorkloadType "AzureVM" -VaultId $vault.ID | Where-Object {$_.Name -like "*$virtualMachineName*"}
Enable-AzRecoveryServicesBackupProtection -Item $backupItem -InclusionDisksList $disks -VaultId $Vault.ID
