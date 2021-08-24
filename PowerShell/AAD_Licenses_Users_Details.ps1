Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ": AAD_UsersLicensedDetails : Start" -ForegroundColor Yellow


# Collection of all users with assigned licenses
Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ": Collect all licensed users" -ForegroundColor Yellow
$AllMsolUsersLicensed = Get-MsolUser -All | ?{$_.IsLicensed -eq $True} | Select UserPrincipalName, Licenses
$AllM365UsersCount = $AllMsolUsersLicensed.Count
$M365UsersCount = 0
Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ":" $AllMsolUsersLicensed.Count "licensed users identified"

# Creation of the results table
$arrLicensesDetails = [System.Collections.Generic.List[Object]]::new() # Create output file for report
$Export_Int = $false
$Export_Num = 0
$Export_Date = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
$Export_Path = $Export_Date + "_AAD_UsersLicensedDetails"


# Parsing the M365 users
Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ": Collect all details about licensed users" -ForegroundColor Yellow
ForEach ($M365User in $AllMsolUsersLicensed)
    {

    # Batches of 1000 users to limit memory usage
    if($M365UsersCount % 1000 -eq 0 -and $M365UsersCount -ne 0)
    {
        Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ":" $M365UsersCount "users"
        if($M365UsersCount % 1000000 -eq 0-and $M365UsersCount -ne 0){
            $Export_Num = $Export_Num + 1
            $Export_Path_Int = $Export_Path + "_" + $Export_Num + ".csv"
            $arrLicensesDetails | Sort Company, UserPrincipalName, SKU, Product | Export-CSV -nti -Path $Export_Path_Int
            Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ": Extract n°"$Export_Num
            $Export_Int = $false
            $arrLicensesDetails = [System.Collections.Generic.List[Object]]::new() # Create output file for report
        }
    }
    $M365UsersCount++

    Write-Progress -Activity 'Extracting M365 users assigned plans' -Status "Processing User $($M365UsersCount) of $($AllM365UsersCount)" -CurrentOperation $M365User.UserPrincipalName -PercentComplete (($M365UsersCount / $AllM365UsersCount) * 100)
        
    $M365UserUPN = $M365User.UserPrincipalName
    $M365UserLicenses = $M365User.Licenses

    Foreach($M365UserLicense in $M365UserLicenses){

        $M365UserSKU = $M365UserLicense.AccountSku.SkuPartNumber
        $M365UserProducts = $M365UserLicense.ServiceStatus

        Foreach($M365UserProduct in $M365UserProducts){

                  
            ###### If you want to select only the users with SharePoint Online and Microsoft Teams
            # if($M365UserProduct.ServicePlan.ServiceName -eq "TEAMS1" -or $M365UserProduct.ServicePlan.ServiceName -eq "SHAREPOINTENTERPRISE"){
            ######

            $objLicensesDetails = New-Object PSObject
            # $ObjLicensesDetails | Add-Member -MemberType NoteProperty -Name Company -Value $M365UserCompany
            $objLicensesDetails | Add-Member -MemberType NoteProperty -Name UserPrincipalName -Value $M365UserUPN
            $objLicensesDetails | Add-Member -MemberType NoteProperty -Name SKU -Value $M365UserSKU
            $objLicensesDetails | Add-Member -MemberType NoteProperty -Name Products -Value $M365UserProduct.ServicePlan.ServiceName
            $objLicensesDetails | Add-Member -MemberType NoteProperty -Name Status -Value $M365UserProduct.ProvisioningStatus
            
            $arrLicensesDetails.Add($objLicensesDetails)
            
            ###### If you want to select only the users with SharePoint Online and Microsoft Teams
            # }
            ######
            
            }  
    }
}


Write-Progress -Activity 'Extracting M365 users assigned plans' -Completed

# Exportation of the results
If($Export_Int -eq $true)
    {
        $Export_Num = $Export_Num + 1
        $Export_Path_Int = $Export_Path + "_" + $Export_Num + ".csv"
        $arrLicensesDetails | Sort Company, UserPrincipalName, SKU, Product | Export-CSV -nti -Path $Export_Path_Int
        Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ": Extract n°"$Export_Num
    } else
    {
        $Export_Num = $Export_Num + 1 
        $Export_Path_Final = $Export_Path + ".csv"
        $arrLicensesDetails | Sort Company, UserPrincipalName, SKU, Product | Export-CSV -nti -Path $Export_Path_Final   
        Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ": Extract n°"$Export_Num

    }

Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ": AAD_UsersLicensedDetails : the end!" -ForegroundColor Yellow