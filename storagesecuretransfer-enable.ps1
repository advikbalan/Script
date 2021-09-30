$Storagename = @("testsecureaccount","aicvsstorageaccount")
$ResourceGroupName = @("cvs_lab_1","cvs_lab_2")
$outputfilepath = 'C:\Code\File.txt'

for ($i=0; $i-lt $Storagename.Length; $i++)
	{
	Set-AzStorageAccount -ResourceGroupName $ResourceGroupName[$i] -Name $Storagename[$i] -EnableHttpsTrafficOnly $True
	get-AzStorageAccount -ResourceGroupName $ResourceGroupName[$i] -Name $Storagename[$i] | Out-File -FilePath $outputfilepath -Append
	}


