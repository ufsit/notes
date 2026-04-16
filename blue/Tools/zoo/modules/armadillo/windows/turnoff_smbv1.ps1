# Check SMBv1 status
$feature = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

if ($feature.State -eq "Enabled") {
    Write-Output "SMBv1 is currently ENABLED. Disabling now..."
    
    Disable-WindowsOptionalFeature `
        -Online `
        -FeatureName SMB1Protocol `
        -NoRestart `
        -ErrorAction Stop

    Write-Output "SMBv1 has been disabled. A restart may be required."
}
elseif ($feature.State -eq "Disabled") {
    Write-Output "SMBv1 is already disabled. No action required."
}
else {
    Write-Output "SMBv1 is in state: $($feature.State). No changes made."
}
