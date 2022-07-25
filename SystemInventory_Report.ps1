$scriptpath = $MyInvocation.MyCommand.Definition 
$dir = Split-Path $scriptpath 

##Configure the list of servers
#defined as array
$computers = @("server1","server2","server3")
#read from file
#$computers = Get-Content "$dir\Serverlist.txt"

#No change needed from here!!!
#Run the commands for each server in the list
$infoColl = @()
Foreach ($s in $computers)
{
	$CPUInfo = Get-WmiObject Win32_Processor -ComputerName $s
	$OSInfo = Get-WmiObject Win32_OperatingSystem -ComputerName $s
	$PhysicalMemory = Get-WmiObject CIM_PhysicalMemory -ComputerName $s | Measure-Object -Property capacity -Sum | % { [Math]::Round(($_.sum / 1GB), 2) }
	Foreach ($CPU in $CPUInfo)
	{
		$infoObject = New-Object PSObject
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "Server" -value $CPU.SystemName
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "Processor" -value $CPU.Name
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "Physical Cores" -value $CPU.NumberOfCores
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS Name" -value $OSInfo.Caption
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "OS Version" -value $OSInfo.Version
		Add-Member -inputObject $infoObject -memberType NoteProperty -name "TotalPhysical Memory GB" -value $PhysicalMemory
		$infoColl += $infoObject
	}
}
$infoColl | Export-Csv -path $dir\Server_Inventory_$((Get-Date).ToString('MM-dd-yyyy')).csv -NoTypeInformation
