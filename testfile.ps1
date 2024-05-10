$swis = Connect-Swis -Hostname "localhost" -UserName "Admin" -Password ""


#$swis = Connect-Swis -Hostname "localhost" -trusted
$NodesList = Get-SwisData -SwisConnection $swis -Query "select top 1 n.caption, n.ip_address from orion.nodes n where n.vendor = @v" -Parameters @{ v = 'Cisco' }
# unmanage a node
$now = [DateTime]::UtcNow
$later = $now.adddays(1)
Invoke-SwisVerb $swis Orion.Nodes Unmanage @("N:1", $now, $later, "false")


$swis = Connect-Swis -Hostname "localhost" -UserName "Admin" -Password ""
$cpuQuery = @"
SELECT PollerID, PollerType, NetObject, NetObjectType, NetObjectID, Enabled, DisplayName, Description, InstanceType, Uri, InstanceSiteId
FROM Orion.Pollers
where enabled = 'false' and pollertype = 'N.Cpu.SNMP.HrProcessorLoad'
"@
$pollerToEnable = Get-SwisData $swis $cpuQuery
if( $pollerToEnable -eq $null ) {
    "No changes to make"
} else {
    "Changing to Enabled"
    Set-SwisObject $swis -Uri $pollerToEnable.uri -Properties @{ Enabled="True" }
    $checkChange = @"
    SELECT PollerID, PollerType, NetObject, NetObjectType, NetObjectID, Enabled, DisplayName, Description, InstanceType, Uri, InstanceSiteId
    FROM Orion.Pollers
    where pollerid = $($pollerToEnable.pollerid)
"@
    "Checking for changed data"
    (Get-SwisData $swis $checkChange).enabled
}
