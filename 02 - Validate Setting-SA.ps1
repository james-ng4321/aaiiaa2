# Make sure you are authenticated with 
# Connect-AzAccount
#Connect-AzAccount -TenantId 7f2c1900-9fd4-4b89-91d3-79a649996f0a -WarningAction SilentlyContinue
# LA workspace Resource ID
[string]$WorkspaceResourceID = '/subscriptions/fc6e9d72-7f73-4a05-83de-44204d69d3f7/resourcegroups/rg-go02-sea-d-gis-sasmgmt/providers/microsoft.operationalinsights/workspaces/la-go02-eas-d-gissasmgmt-workspace01'
[string]$WorkspaceResourceID2 = '/subscriptions/fc6e9d72-7f73-4a05-83de-44204d69d3f7/resourcegroups/rg-go02-sea-d-gis-sasmgmt/providers/microsoft.operationalinsights/workspaces/la-go02-sea-d-gissasmgmt-workspace01'
# CSV file
$inputCsvFile = "HK-sa.csv"

# CSV path
$inputPath = "."
# import csv
$inputCsv = Import-CSV -Path $inputPath\$inputCsvFile -Delimiter ","
$SAlist = $inputCsv |
select AccountName |
Sort-Object * -Unique
# for output csv
$Results2 = @()
$Privateendpoint=Get-AzPrivateendpoint
#create folder
#$date=$((Get-Date).ToString('yyyy-MM-dd-hhmm'))
#New-Item -ItemType Directory -Path ".\Generate Log SA-$date" -erroraction 'silentlycontinue'
# Loop SAlist - List of SA which is unique
 foreach ( $Row in $SAlist )
{
$Results=Get-AzStorageAccount|Where-Object {$_.StorageAccountName -eq $Row.AccountName}
#$Results = Get-AzStorageAccount -name $Row.AccountName -ResourceGroupName
$resourceid2=$Results.Id
[String]$WorkspaceResourceID3 = (Get-AzDiagnosticSetting -ResourceId $resourceid2'/blobservices/default' -WarningAction SilentlyContinue).WorkspaceId
[String]$WorkspaceResourceID4 = (Get-AzDiagnosticSetting -ResourceId $resourceid2'/fileservices/default' -WarningAction SilentlyContinue).WorkspaceId
[String]$WorkspaceResourceID5 = (Get-AzDiagnosticSetting -ResourceId $resourceid2'/queueservices/default' -WarningAction SilentlyContinue).WorkspaceId
[String]$WorkspaceResourceID6 = (Get-AzDiagnosticSetting -ResourceId $resourceid2'/tableservices/default' -WarningAction SilentlyContinue).WorkspaceId
#$WorkspaceResourceID3=$WorkspaceResourceID5.Trim()
$Results2 += New-Object PSObject -property @{ 
ResourceName = $Results.StorageAccountName
ResourceGroup = $Results.ResourceGroupName
Location = $Results.Location
ResourceID = $Results.Id
Tags = $Results.Tags |Out-String
#PublicNetworkAccess = $Results.PublicNetworkAccess
DiagnosticSettingBlob = if(($WorkspaceResourceID3.Trim() -eq $WorkspaceResourceID2) -Or ($WorkspaceResourceID3.Trim() -eq $WorkspaceResourceID)){'True'}else{'False'}
DiagnosticSettingFile = if(($WorkspaceResourceID4.Trim() -eq $WorkspaceResourceID2) -Or ($WorkspaceResourceID4.Trim() -eq $WorkspaceResourceID)){'True'}else{'False'}
DiagnosticSettingQueue = if(($WorkspaceResourceID5.Trim() -eq $WorkspaceResourceID2) -Or ($WorkspaceResourceID5.Trim() -eq $WorkspaceResourceID)){'True'}else{'False'}
DiagnosticSettingTable = if(($WorkspaceResourceID6.Trim() -eq $WorkspaceResourceID2) -Or ($WorkspaceResourceID6.Trim() -eq $WorkspaceResourceID)){'True'}else{'False'}
IPwhitelist = $Results.NetworkRuleSet.IpAddressorRange | Out-String
VnetRules = $Results.NetworkRuleSet.VirtualNetworkRules | Out-String
AllowPublicAccess = if(($Results.NetworkRuleSet.DefaultAction -eq 'Allow')){'True'}else{'False'}
#RestrictAccess = if(($Results.PublicNetworkAccess -eq 'Enabled') -and ($Results.NetworkRuleSet.DefaultAction -eq 'Deny')){'True'}else{'False'}
#DisableAccess = if(($Results.PublicNetworkAccess -eq "Disable")-and ($Results.NetworkRuleSet.DefaultAction -eq "Deny")){'True'}else{'False'}
PrivateEndpoint = foreach ($pe in $Privateendpoint){if ($pe.privatelinkserviceconnections.privatelinkserviceid -eq $Results.Id){'True';break}}
TrustedService = $Results.NetworkRuleSet.Bypass
}
}
$path= ".\02 - Validate Result-SA.CSV"
$Results2 | select ResourceName,ResourceGroup,ResourceID,Location,DiagnosticSettingBlob,DiagnosticSettingFile,DiagnosticSettingQueue,DiagnosticSettingTable,AllowPublicAccess,IPwhitelist,VnetRules,PrivateEndpoint,TrustedService,Tags | Export-Csv -Path $path -NoTypeInformation
echo "02 - Validate Result-SA.CSV is generated !"
