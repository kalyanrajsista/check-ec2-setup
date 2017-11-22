# Windows System Prep for Slice HS Role


$InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit
$Propagation = [system.security.accesscontrol.PropagationFlags]"None"


#
# Add rights to EventLog key for Authenticate Users
#

$acl = Get-Acl HKLM:\SYSTEM\CurrentControlSet\Services\EventLog

$rule = New-Object System.Security.AccessControl.RegistryAccessRule ("NT AUTHORITY\Authenticated Users","FullControl", $InheritanceFlag, $Propagation, "Allow")

$acl.SetAccessRule($rule)

$acl | Set-Acl -Path HKLM:\SYSTEM\CurrentControlSet\Services\EventLog


#
# Add rights to Security key for NETWORK SERVICES
#

$acl = Get-Acl HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Security

$rule = New-Object System.Security.AccessControl.RegistryAccessRule ("NT AUTHORITY\NETWORK SERVICE","FullControl", $InheritanceFlag, $Propagation, "Allow")

$acl.SetAccessRule($rule)

$acl | Set-Acl -Path HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Security


