Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ": AAD_LicensedUsers : Start" -ForegroundColor Yellow

# Collection of all users with assigned licenses
$AllMsolUsersLicensed = Get-MsolUser -All | ?{$_.IsLicensed -eq $True}
$AllM365UsersCount = $AllMsolUsersLicensed.Count
$M365UsersCount = 0

# Creation of the results table
$arrLicenses = [System.Collections.Generic.List[Object]]::new() # Create output file for report

# Parsing the M365 users
ForEach ($M365User in $AllMsolUsersLicensed)
    {
    $M365UsersCount++
    
    if($M365UsersCount % 1000 -eq 0){Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ":" $M365UsersCount "users"}

    Write-Progress -Activity 'Extracting M365 users assigned plans' -Status "Processing User $($M365UsersCount) of $($AllM365UsersCount)" -CurrentOperation $M365User.UserPrincipalName -PercentComplete (($M365UsersCount / $AllM365UsersCount) * 100)
    
    $M365UserLicenses = $M365User.Licenses

    Foreach($M365UserLicense in $M365UserLicenses){
        $LicenseDirect = 0
        $LicenseGroups = 0
        
        If($M365UserLicense.GroupsAssigningLicense.Capacity -eq 0){
            $LicenseDirect = 1
        } Else {
            If($M365UserLicense.GroupsAssigningLicense -contains $M365User.ObjectId){
                $LicenseDirect = 1
                $LicenseGroups = $M365UserLicense.GroupsAssigningLicense.Count - 1 
            } Else {
                $LicenseGroups = $M365UserLicense.GroupsAssigningLicense.Count
            }
        }
      
        $ObjLicenses = New-Object PSObject
        $ObjLicenses | Add-Member -MemberType NoteProperty -Name UserPrincipalName -Value $M365User.UserPrincipalName
        $ObjLicenses | Add-Member -MemberType NoteProperty -Name SKU -Value $M365UserLicense.AccountSku.SkuPartNumber
        $ObjLicenses | Add-Member -MemberType NoteProperty -Name ByDirect -Value $LicenseDirect
        $ObjLicenses | Add-Member -MemberType NoteProperty -Name ByGroup -Value $LicenseGroups

        $arrLicenses.Add($ObjLicenses)
    }
}

Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ":" $M365UsersCount "users"
Write-Progress -Activity 'Extracting M365 users assigned plans' -Completed

# Exportation of the results
Write-Host ""
Write-Host "AAD_UsersLicensed : Extracting Report ..."
$arrLicenses | Sort Company, UserPrincipalName, SKU | Export-CSV -nti -Path "$((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss'))_AAD_UsersLicensed.csv"
Write-Host "AAD_UsersLicensed : Extracting completed"

Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ": AAD_LicensedUsers : End" -ForegroundColor Yellow