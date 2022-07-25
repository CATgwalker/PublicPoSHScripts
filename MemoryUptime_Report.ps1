$scriptpath = $MyInvocation.MyCommand.Definition 
$dir = Split-Path $scriptpath 

##Configure the list of servers
#defined as array
$computers = @("server1","server2","server3")
#read from file
#$computers = Get-Content "$dir\Serverlist.txt"

#No change needed from here!!!
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 2px;padding: 3px;border-style: solid;border-color: black;background-color: #C12530;color: white;}
TD {border-width: 2px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff;}
.even { background-color:#dddddd;}
</style>
<title> Uptime & Memory Usage 
</title>
"@
$TotVirtMemory = @{Name="Total Virtual Memory (GB)";expression={[math]::round(($_.TotalVirtualMemorySize / 1047553),3)}}
$TotVisMemory = @{Name="Total Physical Memory (GB)";expression={[math]::round(($_.TotalVisibleMemorySize / 1047553),3)}}
$FreeRAM = @{Name="Free (GB)";expression={[math]::round(($_.FreePhysicalMemory / 1047553),3)}}
$FreeVirtMemory = @{Name="Free Virtual Memory (GB)";expression={[math]::round(($_.FreeVirtualMemory / 1047553),3)}}
$uptime = @{Name="Last Reboot";expression={$_.ConvertToDateTime($_.LastBootUpTime)}}
$server = @{Name="Server";expression={$_.csname}}
$output = $computers | foreach-object {Get-WmiObject -Class Win32_OperatingSystem -Computer $_ | select $server,$TotVirtMemory,$TotVisMemory,$FreeRAM,$FreeVirtMemory,$uptime}
$output | ConvertTo-HTML -Head $header | Out-File $dir\memusage.htm
Invoke-Expression "$dir\memusage.htm"
