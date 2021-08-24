Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ": AAD_LicensedGroups : Start" -ForegroundColor Yellow

# Collection of all groups with assigned licenses
$AllLicensedGroups = Get-MsolGroup -All | Where{$_.Licenses}
$AllLicensedGroupsCount = $AllLicensedGroups.Count
$LicensedGroupCount = 0

# Creation of the results table
$arrGroupLicenses = New-Object System.Collections.Generic.List[System.Object] # [System.Collections.Generic.List[Object]]::new() # Create output file for report


# Parsing the different groups
foreach($group in $AllLicensedGroups){
    $LicensedGroupCount ++
    Write-Progress -Activity 'Extracting Groups assigned plans' -Status "Processing groups $($LicensedGroupCount) of $($AllLicensedGroupsCount)" -CurrentOperation $group.DisplayName -PercentComplete (($LicensedGroupCount / $AllLicensedGroupsCount) * 100)

    # Identification of the SKU assigned to a Group
    $groupLicenses = $group.Licenses.SkuPartNumber

    # Identification of the deactivated products per SKU
    $i = 0
    foreach($sku in $groupLicenses){

        $DisableServicePlans = $group.AssignedLicenses[$i] | Select -ExpandProperty DisabledServicePlans

        foreach($DisableServicePlan in $DisableServicePlans){

                $temp = $group.DisplayName + $sku + $DisableServicePlan

                $objLicense = New-Object PSObject
                $objLicense | Add-Member -MemberType NoteProperty -Name Numero -Value $LicensedGroupCount
                $objLicense | Add-Member -MemberType NoteProperty -Name Group -Value $group.DisplayName
                $objLicense | Add-Member -MemberType NoteProperty -Name SKU -Value $sku
                $objLicense | Add-Member -MemberType NoteProperty -Name Product -Value $DisableServicePlan
                $objLicense | Add-Member -MemberType NoteProperty -Name Status -Value "Disabled"
                $objLicense | Add-Member -MemberType NoteProperty -Name Temp -Value $temp

            $arrGroupLicenses.Add($objLicense)
            }
    #    }
            

        $i++

        # Collection of all products in a SKU
        $products = Get-MsolAccountSku | ?{$_.accountskuid -eq "CACOMMUN:"+$sku} | select -expand servicestatus

        foreach($product in $products){
            $temp = $group.DisplayName + $sku + $product.ServicePlan.ServiceName

        if($arrGroupLicenses.Temp -contains $temp){}
        Else{            
                $objLicense = New-Object PSObject
                $objLicense | Add-Member -MemberType NoteProperty -Name Numero -Value $LicensedGroupCount
                $ObjLicense | Add-Member -MemberType NoteProperty -Name Group -Value $group.DisplayName
                $ObjLicense | Add-Member -MemberType NoteProperty -Name SKU -Value $sku
                $ObjLicense | Add-Member -MemberType NoteProperty -Name Product -Value $product.ServicePlan.ServiceName
                $ObjLicense | Add-Member -MemberType NoteProperty -Name Status -Value $product.ProvisioningStatus
                $ObjLicense | Add-Member -MemberType NoteProperty -Name Temp -Value $temp

            $arrGroupLicenses.Add($objLicense)
           }
        }
    }
}

$arrGroupLicenses = $arrGroupLicenses | Select-Object Numero, Group, SKU, Product, Status | Sort Numero, Group, SKU, Status, Product

Write-Host "End of the group export" -ForegroundColor Yellow 

# Exportation of the results
Write-Progress -Activity 'Extracting Groups assigned plans' -Completed

Write-Host ""
Write-Host "AAD_GroupLicensed : Extracting Report ..."

# If you want to display the results directly in PowerShell
# $arrGroupLicenses | Sort Company, UserPrincipalName, SKU | Export-CSV -nti -Path "$((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss'))_AAD_GroupsLicensed.csv"
Write-Host "AAD_GroupLicensed : Extracting completed"

Write-Host (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') ": AAD_LicensedGroups : End" -ForegroundColor Yellow