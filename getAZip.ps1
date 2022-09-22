$subs = Get-AzSubscription -SubscriptionID 9b491dd6-598e-498c-98a0-d3bbd2290821
foreach ($Sub in $Subs) { 
    Select-AzSubscription -SubscriptionName $Sub.Name | Out-Null
    $networks = Get-AzVirtualNetwork | ForEach-Object {
        New-Object PSObject -Property @{
            name         = $_.name
            subnets      = $_.subnets.name -join ';'
            addressSpace = $_.AddressSpace.AddressPrefixes -join ';'
        }
    }
    $networks | Export-Csv -NoTypeInformation azVnet.csv
}

Get-AzPublicIpAddress | Select-Object Name,IpAddress | Export-Csv -Path "azPublicIP.csv" -NoTypeInformation