# Make sure you are authenticated with 
# Connect-AzAccount
#Connect-AzAccount -TenantId 7f2c1900-9fd4-4b89-91d3-79a649996f0a
# LA workspace ID
[string]$WorkspaceID = 'aabecabb-3f4e-4d65-8a7c-17434a094cb6'
[string]$WorkspaceID2 = 'f486ca19-3cb9-4345-8639-7ccfe1fe149a'
# CSV file
$inputCsvFile = "HK-SA.csv"

# CSV path
$inputPath = "."
# import csv
$inputCsv = Import-CSV -Path $inputPath\$inputCsvFile -Delimiter ","
$SAlist = $inputCsv |
select AccountName |
Sort-Object * -Unique
# for output csv
$SAoutput = @()
#create folder
$date=$((Get-Date).ToString('yyyy-MM-dd-hhmm'))
New-Item -ItemType Directory -Path ".\Generate Log SA-$date" -erroraction 'silentlycontinue'
# Loop SAlist - List of SA which is unique
 foreach ( $Row in $SAlist )
{
[string]$Query = "
StorageBlobLogs 
| union StorageFileLogs, StorageQueueLogs, StorageTableLogs
| where AccountName contains"+" '"+$Row.AccountName+"'"+"
| where TimeGenerated > ago(31d) and Uri !contains 'sk=system-1'
| extend IPaddress = extract('(([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3}))',1,CallerIpAddress)
| summarize Count=count() by IPaddress, AccountName, ServiceType,StatusText, _ResourceId
| sort by AccountName 
"

$Results = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID -Query $Query
$Results2 = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID2 -Query $Query
$SAoutput += $Results.Results
$SAoutput += $Results2.Results
}
$path2= ".\Generate Log SA-$date\03 – Generate Log By Count.CSV"
$SAoutput | Export-Csv -Path $path2 -NoTypeInformation
echo "03 – Generate Log By Count.CSV is generated"


 foreach ( $Row in $SAlist )
{
[string]$Query1 = "
StorageBlobLogs 
| union StorageFileLogs, StorageQueueLogs, StorageTableLogs
| where AccountName contains"+" '"+$Row.AccountName+"'"+"
| extend HKTimestamp = TimeGenerated + 8h 
| where TimeGenerated > ago(31d) and Uri !contains 'sk=system-1'
| extend IPaddress = extract('(([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3}))',1,CallerIpAddress)
| project TimeGenerated, HKTimestamp, AccountName, ServiceType, AuthenticationType, AuthenticationHash, RequesterUpn, StatusCode, StatusText, Uri, IPaddress, UserAgentHeader,ClientRequestId, Category,Type 
| sort by HKTimestamp, AccountName 
"

$Results1 = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID -Query $Query1
$Results3 = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID2 -Query $Query1
$SAoutput1 = $Results1.Results
$SAoutput1 += $Results3.Results
$path1= ".\Generate Log SA-$date\03 – Generate Log Raw -"+ $Row.AccountName +".CSV"
$SAoutput1 | Export-Csv -Path $path1 -NoTypeInformation
echo "Raw data is generated to $path1"
}

echo "All logs are generated."