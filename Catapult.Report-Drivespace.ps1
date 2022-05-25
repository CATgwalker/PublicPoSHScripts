Param (
[Parameter(Mandatory=$True,Position=0)][string[]] $ServerList = $(throw '- Need comma separated computer names')
)
$Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size (500, 300)
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath
$TimeStamp = (Get-Date).ToString('_yyyyMMdd-HHmmss')
####End Common Setup####

$Title="Hard Drive Report to HTML" 
$ReportFileName = "$scriptdir\Catapult.Report-Drivespace$Timestamp.html"
$fragments=@() 
[string]$g=[char]9608
$head = @"
		<Title>$Title</Title>
        <style>
            BODY{font-family: Arial; font-size: 8pt;}
            H1{font-size: 16px;}
            H2{font-size: 14px;}
            H3{font-size: 12px;}
            TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse; background-color:#D5EDFA}
            TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #94D4F7;}
            TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}        
        </style>
"@
####Finished Initializing Vars####
 
foreach ($server in $ServerList){
$data+=Get-WMIObject -ComputerName $server Win32_Volume -Filter "DriveType='3'"
}
$groups=$Data | Group-Object -Property SystemName         
ForEach ($computer in $groups) {   
    $fragments+="<H2>$($computer.Name)</H2>" 
    $Drives=$computer.group 
    $html=$drives | sort-object Name | Select @{Name="Volume";Expression={$_.Name;}}, 
    @{Name="Size (gb)";Expression={$_.Capacity/1GB  -as [int]}}, 
    @{Name="Used (gb)";Expression={"{0:N2}" -f (($_.Capacity - $_.Freespace)/1GB) }}, 
    @{Name="Free (gb)";Expression={"{0:N2}" -f ($_.FreeSpace/1GB) }},
    @{Name="% Free";Expression={"{0:N2}" -f ($_.freespace / $_.Capacity * 100) }}, 
    @{Name="Usage";Expression={ 
      $UsedPer=(($_.Capacity - $_.Freespace)/$_.Capacity)*100 
      $UsedGraph=$g * ($UsedPer/2) 
      $FreeGraph=$g * ((100-$UsedPer)/2) 
      "xopenFont color=Redxclose{0}xopen/FontxclosexopenFont Color=Greenxclose{1}xopen/fontxclose" -f $usedGraph,$FreeGraph 
    }} | ConvertTo-Html -Fragment  
    $html=$html -replace "xopen","<" 
    $html=$html -replace "xclose",">" 
    $Fragments+=$html 
    $fragments+="<br>" 
     
}
ConvertTo-Html -head $head -body $fragments  | Out-File $ReportFileName