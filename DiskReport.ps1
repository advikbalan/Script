$Disk=Get-AzDisk
$Orphan=$Disk | Select-Object -Property @{label='Sub';expression={$_.id.Substring(15,36)}},Name,ResourceGroupName,Type,DiskSizeGB,DiskState
$a=$Orphan | Where-Object -Property DiskSizeGB -ge “1024”
$a | Export-Csv -Path c:\temp\DiskReport.csv -NoTypeInformation -Force
