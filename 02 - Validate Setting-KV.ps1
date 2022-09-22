# Make sure you are authenticated with 
# Connect-AzAccount
#Connect-AzAccount -TenantId 7f2c1900-9fd4-4b89-91d3-79a649996f0a -WarningAction SilentlyContinue
# LA workspace Resource ID
[string]$WorkspaceResourceID = '/subscriptions/fc6e9d72-7f73-4a05-83de-44204d69d3f7/resourcegroups/rg-go02-sea-d-gis-sasmgmt/providers/microsoft.operationalinsights/workspaces/la-go02-eas-d-gissasmgmt-workspace01'
[string]$WorkspaceResourceID2 = '/subscriptions/fc6e9d72-7f73-4a05-83de-44204d69d3f7/resourcegroups/rg-go02-sea-d-gis-sasmgmt/providers/microsoft.operationalinsights/workspaces/la-go02-sea-d-gissasmgmt-workspace01'
# CSV file
$inputCsvFile = "HK-akv.csv"

# CSV path
$inputPath = "."
# import csv
$inputCsv = Import-CSV -Path $inputPath\$inputCsvFile -Delimiter ";"
$SAlist = $inputCsv |
select AccountName |
Sort-Object * -Unique
# for output csv
$Results2 = @()
#create folder
#$date=$((Get-Date).ToString('yyyy-MM-dd-hhmm'))
#New-Item -ItemType Directory -Path ".\Generate Log SA-$date" -erroraction 'silentlycontinue'
# Loop SAlist - List of SA which is unique
 foreach ( $Row in $SAlist )
{
$Results = Get-AzKeyVault -name $Row.AccountName
$WorkspaceResourceID4 = Get-AzDiagnosticSetting -ResourceId $Results.ResourceId -WarningAction SilentlyContinue
[String]$WorkspaceResourceID3 = $WorkspaceResourceID4.WorkspaceId
#$WorkspaceResourceID3=$WorkspaceResourceID5.Trim()
$Results2 += New-Object PSObject -property @{ 
ResourceName = $Results.VaultName
ResourceGroup = $Results.ResourceGroupName
Location = $Results.Location
ResourceID = $Results.ResourceId
Tags = $Results.TagsTable
#PublicNetworkAccess = $Results.PublicNetworkAccess
DiagnosticSetting = if(($WorkspaceResourceID3.Trim() -eq $WorkspaceResourceID2) -Or ($WorkspaceResourceID3.Trim() -eq $WorkspaceResourceID)){'True'}else{'False'}
WhitelistIP = $Results.NetworkAcls.IpAddressRangesText
AllowPublicAccess = if(($Results.PublicNetworkAccess -eq 'Enabled')-and($Results.NetworkAcls.DefaultAction -eq 'Allow')){'True'}else{''}
RestrictAccess = if(($Results.PublicNetworkAccess -eq 'Enabled') -and ($Results.NetworkAcls.DefaultAction -eq 'Deny')){'True'}else{''}
DisableAccess = if(($Results.PublicNetworkAccess -eq "Disable")-and ($Results.NetworkAcls.DefaultAction -eq "Deny")){'True'}else{''}
}
}
$path= ".\02 - Validate Result-KV.CSV"
$Results2 | select ResourceName,ResourceGroup,ResourceID,Location,DiagnosticSetting,AllowPublicAccess,RestrictAccess,DisableAccess,WhitelistIP,Tags | Export-Csv -Path $path -NoTypeInformation
echo "02 - Validate Result-KV.CSV is generated !"
