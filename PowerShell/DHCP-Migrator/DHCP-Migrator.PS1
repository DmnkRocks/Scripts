Clear-Host
Write-host "fancy DHCP Server Migration Script`nVersion 1.0 | by dmnk.rocks `n`nno Files only Powershell`n`nbuy me a Beer at https://dmnk.rock/beer`n`n"

# to-do's
#   function to change DHCP-Server Options like DNS
#   eg. like this       set-DhcpServerv4OptionValue -ScopeId 192.168.123.0  -DnsServer "192.168.123.10", "192.168.123.11"

# define variables
$targethost	= read-host "Provide Hostname for Target Server"

$srchost	= read-host "Provide Hostname for Source Server"
Write-Host "Checking Soruce Server for Existing Scopes"
Get-DhcpServerv4Scope -ComputerName $srchost | ft -a
$thescope	= read-host "Select Scope ID to migrate"

$theScropeStartRange    = (Get-DhcpServerv4Scope -ComputerName $srchost -ScopeId $thescope).StartRange
$theScropeEndRange      = (Get-DhcpServerv4Scope -ComputerName $srchost -ScopeId $thescope).EndRange
$theScopeSubnet         = (Get-DhcpServerv4Scope -ComputerName $srchost -ScopeId $thescope).SubnetMask
$theScopeName           = (Get-DhcpServerv4Scope -ComputerName $srchost -ScopeId $thescope).Name

Write-Warning "The following Scope will be created on $targethost `nStartRange $theScropeStartRange `nEndRange $theScropeEndRange `nSubnetMask $theScopeSubnet `nName $theScopeName"

$confirmation = Read-Host "Are you Sure You Want To Proceed: (y)es | (n)o"
if ($confirmation -eq 'y') {

 #scope migration

    #create scope - only the selected scope
    Add-DhcpServerv4Scope -ComputerName $targethost -StartRange $theScropeStartRange -EndRange $theScropeEndRange -SubnetMask $theScopeSubnet -Name $theScopeName

    #copy the reservations
    Get-DhcpServerv4Reservation -ComputerName $srchost -ScopeId "$thescope" | Add-DhcpServerv4Reservation -ScopeId "$thescope"

    #copy the Leases - ignore errors (they occur for inactive leases - we don't want a wall of red text here
    Get-DhcpServerv4Lease -ComputerName $srchost -ScopeId "$thescope" | Add-DhcpServerv4Lease -ComputerName $targethost -ScopeId "$thescope" -ErrorAction Continue

    #finally, copy the scope options and policies
    Get-DhcpServerv4OptionValue -ComputerName $srchost -ScopeId "$thescope" | Set-DhcpServerv4OptionValue -ComputerName $targethost -ScopeId "$thescope"
    Get-DhcpServerv4Policy -ComputerName $srchost -ScopeId "$thescope" | Set-DhcpServerv4Policy -ComputerName $targethost -ScopeId "$thescope"

    #select scope to choose

    Write-Host "Migration completed`nCheck for Errors`n`n"

    $confirmation = Read-Host "Disable Scope on Source Server?  `n   if you select (Y)es, the scope on the source server will be disabled`n   if you select (N)o, the scope on the new server will be set to Inactive"
        if ($confirmation -eq 'y') {
            Write-Host "Disabling Scope on Source Server"
            Set-DhcpServerv4Scope -ComputerName $srchost -ScopeId $thescope -State InActive
            Set-DhcpServerv4Scope -ComputerName $targethost -ScopeId $thescope -State Active
            $thescopeStateOld = (Get-DhcpServerv4Scope -ComputerName $srchost -ScopeId $thescope).State
            $thescopeStateNew = (Get-DhcpServerv4Scope -ComputerName $targethost -ScopeId $thescope).State
            Write-Host "State of Scope on Source Server is now: " -NoNewline
            Write-Host "$thescopeStateOld" -ForegroundColor Red
            Write-Host "State of Scope on Target Server is now: " -NoNewline
            Write-Host "$thescopeStateNew" -ForegroundColor green
        }
        if ($confirmation -eq 'n') {
            Write-Host "Disabling Scope on Target Server"
            Set-DhcpServerv4Scope -ComputerName $srchost -ScopeId $thescope -State Active
            Set-DhcpServerv4Scope -ComputerName $targethost -ScopeId $thescope -State InActive
            $thescopeStateOld = (Get-DhcpServerv4Scope -ComputerName $srchost -ScopeId $thescope).State
            $thescopeStateNew = (Get-DhcpServerv4Scope -ComputerName $targethost -ScopeId $thescope).State
            Write-Host "State of Scope on Source Server is now: " -NoNewline
            Write-Host "$thescopeStateOld" -ForegroundColor Green
            Write-Host "State of Scope on Target Server is now: " -NoNewline
            Write-Host "$thescopeStateNew" -ForegroundColor Red
        }
    
    #migrate Scope Options
    $confirmation = Read-Host "`n`nMigrate Server Options? (y)es|(N)o"
        if ($confirmation -eq 'y') {
            Write-Host "Migrating the following settings:"
            Get-DhcpServerv4OptionValue -ComputerName $srchost | ft -a
            Get-DhcpServerv4OptionValue -ComputerName $srchost | Set-DhcpServerv4OptionValue -ComputerName $targethost 
            Write-Host "`n`nThis are the General DHCP Options on the Target Host now"
            Get-DhcpServerv4OptionValue -ComputerName $targethost | ft -a
            }
        if ($confirmation -eq 'n') {
            Write-Host "ok, i will NOT migrate the Server options."



        }
        else {
            Write-Host "no valid selection has been made - I will not migrate the Server options - just to be sure. Make sure to set the correct options on the new Host"
        }

#summary of what we did

    Write-Host "here is the config on the target host:`n"
    Write-Host "State of Scope $theScopeName ($theScope) on " -NoNewline
    Write-Host "Source Server " -NoNewline -ForegroundColor Red
    Write-Host "is now: $thescopeStateOld"
    Write-Host "State of Scope $theScopeName ($theScope) on "-NoNewline
    Write-Host "Target Server "  -NoNewline -ForegroundColor Green
    Write-Host "is now: $thescopeStateNew `n`n" 
    Write-Host "Scope Config"
    Get-DhcpServerv4Scope -ComputerName $targethost -ScopeId $thescope | ft -a   
    Write-Host "Server Options"
    Get-DhcpServerv4OptionValue -ComputerName $targethost | ft -a

}
else {
    Write-Host "aborting script"
}
