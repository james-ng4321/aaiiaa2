# Make sure you are authenticated with 
# Connect-AzAccount
#Connect-AzAccount -TenantId 7f2c1900-9fd4-4b89-91d3-79a649996f0a
# LA workspace ID
[string]$WorkspaceID = 'aabecabb-3f4e-4d65-8a7c-17434a094cb6'
[string]$WorkspaceID2 = 'f486ca19-3cb9-4345-8639-7ccfe1fe149a'
# CSV file
$inputCsvFile = "hk-akv.csv"

# CSV path
$inputPath = "."
# import csv
$inputCsv = Import-CSV -Path $inputPath\$inputCsvFile -Delimiter ";"
$SAlist = $inputCsv | 
select AccountName | 
Sort-Object * -Unique
# for output csv
$SAoutput = @()
#create folder
$date=$((Get-Date).ToString('yyyy-MM-dd-hhmm'))
New-Item -ItemType Directory -Path ".\Generate Log KV-$date" -erroraction 'silentlycontinue'
# Loop SAlist - List of SA which is unique
 foreach ( $Row in $SAlist )
{
[string]$Query = "
AzureDiagnostics
| where TimeGenerated > ago(31d)
| where Resource contains"+" '"+$Row.AccountName+"'"+"
| summarize  Count=count() by CallerIPAddress, Resource, ResourceGroup, ResourceId, ResourceType, ResultType
| sort by Resource
"

$Results = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID -Query $Query
$Results2 = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID2 -Query $Query
$SAoutput += $Results.Results
$SAoutput += $Results2.Results
}
$path2= ".\Generate Log KV-$date\03 – Generate Log By Count.CSV"
$SAoutput | Export-Csv -Path $path2 -NoTypeInformation
echo "03 – Generate Log By Count.CSV is generated"


 foreach ( $Row in $SAlist )
{
[string]$Query1 = "
AzureDiagnostics
| where Resource contains"+" '"+$Row.AccountName+"'"+"
| where TimeGenerated > ago(31d)
| extend HKTimestamp = TimeGenerated + 8h
| project TimeGenerated, HKTimestamp, Resource, ResourceType, CallerIPAddress,clientInfo_s , ResourceId, Category, ResourceGroup, httpStatusCode_d, requestUri_s, ResultType
| sort by HKTimestamp,Resource
"

$Results1 = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID -Query $Query1
$Results3 = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID2 -Query $Query1
$SAoutput1 = $Results1.Results
$SAoutput1 += $Results3.Results
$path1= ".\Generate Log KV-$date\03 – Generate Log Raw -"+$Row.AccountName+".CSV"
$SAoutput1 | Export-Csv -Path $path1 -NoTypeInformation
echo "Raw data is generated to $path1"
}

echo "All logs are generated."