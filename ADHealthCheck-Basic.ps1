$reportpath = "C:\Temp\ADReport.htm" 

if ((Test-Path $reportpath) -like $false) {
   New-Item $reportpath -type file
}
$timeout = "120"
$DCServers = $(Get-ADDomainController -Filter *).Name

###############################HTml Report Content############################
$report = $reportpath

Clear-Content $report 
Add-Content $report "<html>" 
Add-Content $report "<head>" 
Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
Add-Content $report '<title>AD Status Report</title>' 
Add-Content $report '<STYLE TYPE="text/css">' 
Add-Content $report  "<!--" 
Add-Content $report  "td {" 
Add-Content $report  "font-family: Tahoma;" 
Add-Content $report  "font-size: 11px;" 
Add-Content $report  "border-top: 1px solid #999999;" 
Add-Content $report  "border-right: 1px solid #999999;" 
Add-Content $report  "border-bottom: 1px solid #999999;" 
Add-Content $report  "border-left: 1px solid #999999;" 
Add-Content $report  "padding-top: 0px;" 
Add-Content $report  "padding-right: 0px;" 
Add-Content $report  "padding-bottom: 0px;" 
Add-Content $report  "padding-left: 0px;" 
Add-Content $report  "}" 
Add-Content $report  "body {" 
Add-Content $report  "margin-left: 5px;" 
Add-Content $report  "margin-top: 5px;" 
Add-Content $report  "margin-right: 0px;" 
Add-Content $report  "margin-bottom: 10px;" 
Add-Content $report  "" 
Add-Content $report  "table {" 
Add-Content $report  "border: thin solid #000000;" 
Add-Content $report  "}" 
Add-Content $report  "-->" 
Add-Content $report  "</style>" 
Add-Content $report "</head>" 
Add-Content $report "<body>" 
Add-Content $report  "<table width='100%'>" 
Add-Content $report  "<tr bgcolor='#7A6174'>" 
Add-Content $report  "<td colspan='7' height='25' align='center'>" 
Add-Content $report  "<font face='tahoma' color='#DFE0E2' size='4'><strong>Active Directory Health Check</strong></font>" 
Add-Content $report  "</td>" 
Add-Content $report  "</tr>" 
Add-Content $report  "</table>" 
 
Add-Content $report  "<table width='100%'>" 
Add-Content $report  "<tr bgcolor='#23B5D3'>" 
Add-Content $report  "<td width='5%' align='center'><B>Identity</B></td>" 
Add-Content $report  "<td width='10%' align='center'><B>PingSTatus</B></td>" 
Add-Content $report  "<td width='10%' align='center'><B>NetlogonService</B></td>" 
Add-Content $report  "<td width='10%' align='center'><B>NTDSService</B></td>" 
Add-Content $report  "<td width='10%' align='center'><B>DNSServiceStatus</B></td>" 
Add-Content $report  "<td width='10%' align='center'><B>NetlogonsTest</B></td>"
Add-Content $report  "<td width='10%' align='center'><B>ReplicationTest</B></td>"
Add-Content $report  "<td width='10%' align='center'><B>ServicesTest</B></td>"
Add-Content $report  "<td width='10%' align='center'><B>AdvertisingTest</B></td>"
Add-Content $report  "<td width='10%' align='center'><B>FSMOCheckTest</B></td>"
Add-Content $report  "<td width='10%' align='center'><B>TotalTimeElapsesd</B></td>"


Add-Content $report "</tr>" 

#####################################Get ALL DC Servers#################################



################Ping Test######

foreach ($DC in $DCServers) {

   $start = Get-Date

   $Identity = $DC
   Add-Content $report "<tr>"
   if ( Test-Connection -ComputerName $DC -Count 1 -ErrorAction SilentlyContinue ) {
      Write-Host $DC `t $DC `t Ping Success -ForegroundColor Green
 
      Add-Content $report "<td bgcolor= '#87C6D3' align=center>  <B> $Identity</B></td>" 
      Add-Content $report "<td bgcolor= '#DFE0E2' align=center>  <B>Success</B></td>" 

      ##############Netlogon Service Status################
      $serviceStatus = Start-Job -ScriptBlock { Get-Service -ComputerName $($args[0]) -Name "Netlogon" -ErrorAction SilentlyContinue } -ArgumentList $DC
      Wait-Job $serviceStatus -Timeout $timeout
      if ($serviceStatus.state -like "Running") {
         Write-Host $DC `t Netlogon Service TimeOut -ForegroundColor Yellow
         Add-Content $report "<td bgcolor= 'Yellow' align=center><B>NetlogonTimeout</B></td>"
         Stop-Job $serviceStatus
      } else {
         $serviceStatus1 = Receive-Job $serviceStatus
         if ($serviceStatus1.status -eq "Running") {
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green 
            $svcName = $serviceStatus1.name 
            $svcState = $serviceStatus1.status          
            Add-Content $report "<td bgcolor= '#DFE0E2' align=center><B>$svcState</B></td>" 
         } else { 
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red 
         	  $svcName = $serviceStatus1.name 
         	  $svcState = $serviceStatus1.status          
         	  Add-Content $report "<td bgcolor= 'Red' align=center><B>$svcState</B></td>" 
         } 
      }
      ######################################################
      ##############NTDS Service Status################
      $serviceStatus = Start-Job -ScriptBlock { Get-Service -ComputerName $($args[0]) -Name "NTDS" -ErrorAction SilentlyContinue } -ArgumentList $DC
      Wait-Job $serviceStatus -Timeout $timeout
      if ($serviceStatus.state -like "Running") {
         Write-Host $DC `t NTDS Service TimeOut -ForegroundColor Yellow
         Add-Content $report "<td bgcolor= 'Yellow' align=center><B>NTDSTimeout</B></td>"
         Stop-Job $serviceStatus
      } else {
         $serviceStatus1 = Receive-Job $serviceStatus
         if ($serviceStatus1.status -eq "Running") {
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green 
            $svcName = $serviceStatus1.name 
            $svcState = $serviceStatus1.status          
            Add-Content $report "<td bgcolor= '#DFE0E2' align=center><B>$svcState</B></td>" 
         } else { 
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red 
         	  $svcName = $serviceStatus1.name 
         	  $svcState = $serviceStatus1.status          
         	  Add-Content $report "<td bgcolor= 'Red' align=center><B>$svcState</B></td>" 
         } 
      }
      ######################################################
      ##############DNS Service Status################
      $serviceStatus = Start-Job -ScriptBlock { Get-Service -ComputerName $($args[0]) -Name "DNS" -ErrorAction SilentlyContinue } -ArgumentList $DC
      Wait-Job $serviceStatus -Timeout $timeout
      if ($serviceStatus.state -like "Running") {
         Write-Host $DC `t DNS Server Service TimeOut -ForegroundColor Yellow
         Add-Content $report "<td bgcolor= 'Yellow' align=center><B>DNSTimeout</B></td>"
         Stop-Job $serviceStatus
      } else {
         $serviceStatus1 = Receive-Job $serviceStatus
         if ($serviceStatus1.status -eq "Running") {
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Green 
            $svcName = $serviceStatus1.name 
            $svcState = $serviceStatus1.status          
            Add-Content $report "<td bgcolor= '#DFE0E2' align=center><B>$svcState</B></td>" 
         } else { 
            Write-Host $DC `t $serviceStatus1.name `t $serviceStatus1.status -ForegroundColor Red 
         	  $svcName = $serviceStatus1.name 
         	  $svcState = $serviceStatus1.status          
         	  Add-Content $report "<td bgcolor= 'Red' align=center><B>$svcState</B></td>" 
         } 
      }
      ######################################################

      ####################Netlogons status##################
      Add-Type -AssemblyName microsoft.visualbasic 
      $cmp = "microsoft.visualbasic.strings" -as [type]
      $sysvol = Start-Job -ScriptBlock { dcdiag /test:netlogons /s:$($args[0]) } -ArgumentList $DC
      Wait-Job $sysvol -Timeout $timeout
      if ($sysvol.state -like "Running") {
         Write-Host $DC `t Netlogons Test TimeOut -ForegroundColor Yellow
         Add-Content $report "<td bgcolor= 'Yellow' align=center><B>NetlogonsTimeout</B></td>"
         Stop-Job $sysvol
      } else {
         $sysvol1 = Receive-Job $sysvol
         if ($cmp::instr($sysvol1, "passed test NetLogons")) {
            Write-Host $DC `t Netlogons Test passed -ForegroundColor Green
            Add-Content $report "<td bgcolor= '#DFE0E2' align=center><B>NetlogonsPassed</B></td>"
         } else {
            Write-Host $DC `t Netlogons Test Failed -ForegroundColor Red
            Add-Content $report "<td bgcolor= 'Red' align=center><B>NetlogonsFail</B></td>"
         }
      }
      ########################################################
      ####################Replications status##################
      Add-Type -AssemblyName microsoft.visualbasic 
      $cmp = "microsoft.visualbasic.strings" -as [type]
      $sysvol = Start-Job -ScriptBlock { dcdiag /test:Replications /s:$($args[0]) } -ArgumentList $DC
      Wait-Job $sysvol -Timeout $timeout
      if ($sysvol.state -like "Running") {
         Write-Host $DC `t Replications Test TimeOut -ForegroundColor Yellow
         Add-Content $report "<td bgcolor= 'Yellow' align=center><B>ReplicationsTimeout</B></td>"
         Stop-Job $sysvol
      } else {
         $sysvol1 = Receive-Job $sysvol
         if ($cmp::instr($sysvol1, "passed test Replications")) {
            Write-Host $DC `t Replications Test passed -ForegroundColor Green
            Add-Content $report "<td bgcolor= '#DFE0E2' align=center><B>ReplicationsPassed</B></td>"
         } else {
            Write-Host $DC `t Replications Test Failed -ForegroundColor Red
            Add-Content $report "<td bgcolor= 'Red' align=center><B>ReplicationsFail</B></td>"
         }
      }
      ########################################################
      ####################Services status##################
      Add-Type -AssemblyName microsoft.visualbasic 
      $cmp = "microsoft.visualbasic.strings" -as [type]
      $sysvol = Start-Job -ScriptBlock { dcdiag /test:Services /s:$($args[0]) } -ArgumentList $DC
      Wait-Job $sysvol -Timeout $timeout
      if ($sysvol.state -like "Running") {
         Write-Host $DC `t Services Test TimeOut -ForegroundColor Yellow
         Add-Content $report "<td bgcolor= 'Yellow' align=center><B>ServicesTimeout</B></td>"
         Stop-Job $sysvol
      } else {
         $sysvol1 = Receive-Job $sysvol
         if ($cmp::instr($sysvol1, "passed test Services")) {
            Write-Host $DC `t Services Test passed -ForegroundColor Green
            Add-Content $report "<td bgcolor= '#DFE0E2' align=center><B>ServicesPassed</B></td>"
         } else {
            Write-Host $DC `t Services Test Failed -ForegroundColor Red
            Add-Content $report "<td bgcolor= 'Red' align=center><B>ServicesFail</B></td>"
         }
      }
      ########################################################
      ####################Advertising status##################
      Add-Type -AssemblyName microsoft.visualbasic 
      $cmp = "microsoft.visualbasic.strings" -as [type]
      $sysvol = Start-Job -ScriptBlock { dcdiag /test:Advertising /s:$($args[0]) } -ArgumentList $DC
      Wait-Job $sysvol -Timeout $timeout
      if ($sysvol.state -like "Running") {
         Write-Host $DC `t Advertising Test TimeOut -ForegroundColor Yellow
         Add-Content $report "<td bgcolor= 'Yellow' align=center><B>AdvertisingTimeout</B></td>"
         Stop-Job $sysvol
      } else {
         $sysvol1 = Receive-Job $sysvol
         if ($cmp::instr($sysvol1, "passed test Advertising")) {
            Write-Host $DC `t Advertising Test passed -ForegroundColor Green
            Add-Content $report "<td bgcolor= '#DFE0E2' align=center><B>AdvertisingPassed</B></td>"
         } else {
            Write-Host $DC `t Advertising Test Failed -ForegroundColor Red
            Add-Content $report "<td bgcolor= 'Red' align=center><B>AdvertisingFail</B></td>"
         }
      }
      ########################################################
      ####################FSMOCheck status##################
      Add-Type -AssemblyName microsoft.visualbasic 
      $cmp = "microsoft.visualbasic.strings" -as [type]
      $sysvol = Start-Job -ScriptBlock { dcdiag /test:FSMOCheck /s:$($args[0]) } -ArgumentList $DC
      Wait-Job $sysvol -Timeout $timeout
      if ($sysvol.state -like "Running") {
         Write-Host $DC `t FSMOCheck Test TimeOut -ForegroundColor Yellow
         Add-Content $report "<td bgcolor= 'Yellow' align=center><B>FSMOCheckTimeout</B></td>"
         Stop-Job $sysvol
      } else {
         $sysvol1 = Receive-Job $sysvol
         if ($cmp::instr($sysvol1, "passed test FsmoCheck")) {
            Write-Host $DC `t FSMOCheck Test passed -ForegroundColor Green
            Add-Content $report "<td bgcolor= '#DFE0E2' align=center><B>FSMOCheckPassed</B></td>"
         } else {
            Write-Host $DC `t FSMOCheck Test Failed -ForegroundColor Red
            Add-Content $report "<td bgcolor= 'Red' align=center><B>FSMOCheckFail</B></td>"
         }
      }
      ########################################################


      $end = Get-Date               
      $endTime = ($end - $start).TotalSeconds
      Add-Content $report "<td bgcolor= '#DFE0E2' align=center><B>$endTime S</B></td>"                
   } else {
      Write-Host $DC `t $DC `t Ping Fail -ForegroundColor Red
      Add-Content $report "<td bgcolor= 'GainsBoro' align=center>  <B> $Identity</B></td>" 
      Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
      Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
      Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
      Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>" 
      Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
      Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
      Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
      Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
      Add-Content $report "<td bgcolor= 'Red' align=center>  <B>Ping Fail</B></td>"
   }   
} 

Add-Content $report "</tr>"
Add-Content $report  "</table>" 
Add-Content $report "</body>" 
Add-Content $report "</html>" 
