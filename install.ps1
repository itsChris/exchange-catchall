write-host " *** Exchange CatchAll Install Script ***" -f "blue"

# Exchange 2007 SP3 (8.3.*)
# Exchange 2010     (14.0.*)
# Exchange 2010 SP1 (14.1.*)
# Exchange 2010 SP2 (14.2.*)
# Exchange 2010 SP3 (14.3.*)
# Exchange 2013     (15.0.516.32)
# Exchange 2013 CU1 (15.0.620.29)
# Exchange 2013 CU2 (15.0.712.24)
# Exchange 2013 CU3 (15.0.775.38)
write-host "Detecting Exchange version ... " -f "cyan"
$hostname = hostname
$exchserver = Get-ExchangeServer -Identity $hostname
$EXDIR="C:\Program Files\Exchange CatchAll" 
$EXVER="Unknown"
if (($exchserver.admindisplayversion).major -eq 8 -and ($exchserver.admindisplayversion).minor -eq 3) {
	$EXVER="Exchange 2007 SP3"
} elseif (($exchserver.admindisplayversion).major -eq 14 -and ($exchserver.admindisplayversion).minor -eq 0) {
	$EXVER="Exchange 2010"
} elseif (($exchserver.admindisplayversion).major -eq 14 -and ($exchserver.admindisplayversion).minor -eq 1) {
	$EXVER="Exchange 2010 SP1"
} elseif (($exchserver.admindisplayversion).major -eq 14 -and ($exchserver.admindisplayversion).minor -eq 2) {
	$EXVER="Exchange 2010 SP2"
} elseif (($exchserver.admindisplayversion).major -eq 14 -and ($exchserver.admindisplayversion).minor -eq 3) {
	$EXVER="Exchange 2010 SP3"
} elseif (($exchserver.admindisplayversion).major -eq 15 -and ($exchserver.admindisplayversion).minor -eq 0 -and ($exchserver.admindisplayversion).build -eq 516) {
	$EXVER="Exchange 2013"
} elseif (($exchserver.admindisplayversion).major -eq 15 -and ($exchserver.admindisplayversion).minor -eq 0 -and ($exchserver.admindisplayversion).build -eq 620) {
	$EXVER="Exchange 2013 CU1"
} elseif (($exchserver.admindisplayversion).major -eq 15 -and ($exchserver.admindisplayversion).minor -eq 0 -and ($exchserver.admindisplayversion).build -eq 712) {
	$EXVER="Exchange 2013 CU2"
} elseif (($exchserver.admindisplayversion).major -eq 15 -and ($exchserver.admindisplayversion).minor -eq 0 -and ($exchserver.admindisplayversion).build -eq 775) {
	$EXVER="Exchange 2013 CU3"
}
else {
	throw "The exchange version is not yet supported: $exchserver.admindisplayversion"
}

$SRCDIR="CatchAllAgent\bin\$EXVER"

write-host "Found $EXVER" -f "green"

write-host "Creating registry key for EventLog" -f "green"
if (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\Exchange CatchAll") {
	write-host "Registry key for EventLog already exists. Continuing..." -f "yellow"
} else {
	New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\Exchange CatchAll"
}


net stop MSExchangeTransport 
 
write-host "Creating install directory: '$EXDIR' and copying data from '$SRCDIR'"  -f "green"
new-item -Type Directory -path $EXDIR -ErrorAction SilentlyContinue 

copy-item "$SRCDIR\ExchangeCatchAll.dll" $EXDIR -force 
$overwrite = read-host "Do you want to copy (and overwrite) the config file: '$SRCDIR\ExchangeCatchAll.dll'? [Y/N]"
if ($overwrite -eq "Y" -or $overwrite -eq "y") {
	copy-item "$SRCDIR\ExchangeCatchAll.dll.config" $EXDIR -force
} else {
	write-host "Not copying config file" -f "yellow"
}

copy-item "$SRCDIR\mysql.data.dll" $EXDIR -force 

read-host "Now open '$EXDIR\ExchangeCatchAll.dll.config' to configure Exchange CatchAll. When done and saved press 'Return'"

write-host "Registering agent" -f "green"
Install-TransportAgent -Name "Exchange CatchAll" -TransportAgentFactory "Exchange.CatchAll.CatchAllFactory" -AssemblyPath "$EXDIR\ExchangeCatchAll.dll"

write-host "Enabling agent" -f "green" 
enable-transportagent -Identity "Exchange CatchAll" 
get-transportagent 
 
write-host "Starting Edge Transport" -f "green" 
net start MSExchangeTransport 
 
write-host "Installation complete. Check previous outputs for any errors!" -f "yellow" 