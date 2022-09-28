# Make sure you are authenticated with 
# Connect-AzAccount
#Connect-AzAccount -TenantId 7f2c1900-9fd4-4b89-91d3-79a649996f0a
# LA workspace ID
[string]$WorkspaceID = 'aabecabb-3f4e-4d65-8a7c-17434a094cb6'
[string]$WorkspaceID2 = 'f486ca19-3cb9-4345-8639-7ccfe1fe149a'
# CSV file
$inputCsvFile = "02 - Validate Result-SA.csv"

# CSV path
$inputPath = "."
# import csv
$inputCsv = Import-CSV -Path $inputPath\$inputCsvFile -Delimiter ","
$SAlist = $inputCsv |
select ResourceName, AllowPublicAccess, IPwhitelist, VnetRules, PrivateEndpoint, TrustedService, Tags |
Sort-Object ResourceName -Unique
# for output csv
$SAoutput = @()
$SAoutput1 = @()
$SAoutput2 = @()
#create folder
#$date=$((Get-Date).ToString('yyyy-MM-dd-hhmm'))
#New-Item -ItemType Directory -Path ".\03 Generate Log\Generate Log SA-$date" -erroraction 'silentlycontinue'
# Loop SAlist - List of SA which is unique


echo "Raw data is generating"
 foreach ( $Row in $SAlist )
{
[string]$Query1 = "
StorageBlobLogs 
| union StorageFileLogs, StorageQueueLogs, StorageTableLogs
| where AccountName =="+" '"+$Row.ResourceName+"'"+"
    or AccountName =="+" '"+$Row.ResourceName.Toupper()+"'"+"
    or AccountName =="+" '"+$Row.ResourceName.Tolower()+"'"+"
| extend HKTimestamp = TimeGenerated + 8h 
| where TimeGenerated > ago(31d) and Uri !contains 'sk=system-1'
| extend CallerIpAddress = extract('(([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3}))',1,CallerIpAddress)
| sort by HKTimestamp, AccountName 
"

$Results1 = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID -Query $Query1
$Results3 = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID2 -Query $Query1
$SAoutput1 = $Results1.Results
$SAoutput1 += $Results3.Results
$path1= ".\03 Generate Log\03 – Generate Log Raw-SA-"+$Row.resourceName+".CSV"
$SAoutput1 | Export-Csv -Path $path1 -NoTypeInformation
echo "Raw data is generated to $path1"
}



echo "Count data is generating"
 foreach ( $Row in $SAlist )
{
[string]$Query = "
StorageBlobLogs 
| union StorageFileLogs, StorageQueueLogs, StorageTableLogs
| where AccountName == "+" '"+$Row.ResourceName+"'"+"
    or AccountName =="+" '"+$Row.ResourceName.Toupper()+"'"+"
    or AccountName =="+" '"+$Row.ResourceName.Tolower()+"'"+"
| where TimeGenerated > ago(31d) and Uri !contains 'sk=system-1'
| extend CallerIpAddress = extract('(([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3}))',1,CallerIpAddress)
| summarize Count=count() by CallerIpAddress, AccountName, ServiceType,StatusText, _ResourceId
| sort by AccountName 
"

$Results = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID -Query $Query
$Results2 = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID2 -Query $Query
$SAoutput += $Results.Results
$SAoutput += $Results2.Results
}
foreach($Row in $SAoutput){
foreach($row1 in $salist){
if ($row.AccountName -eq $row1.Resourcename){
break
}}
$SAoutput2 += ($row | Select-Object *,@{Name='AllowPublicAccess';Expression={$row1.allowpublicaccess}},@{Name='IPwhitelist';Expression={$row1.IPwhitelist}},@{Name='VnetRules';Expression={$row1.VnetRules}},@{Name='PrivateEndpoint';Expression={$row1.PrivateEndpoint}},@{Name='Tags';Expression={$row1.Tags}})
}
$path2= ".\03 Generate Log\03 – Generate Log By Count-SA.CSV"
$SAoutput2 | Export-Csv -Path $path2 -NoTypeInformation
echo "Count data is generated to $path2"

echo "All logs are generated."