using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Constant variables.
$resourceGroup = "main"
$ttl           = "60"

# Interact with query parameters or the body of the request.
$ipAddr  = $Request.Query.ipAddr
$zone    = $Request.Query.zone
$aRecord = $Request.Query.aRecord

# Parameter check.
if (-not $ipAddr -or -not $zone -or -not $aRecord) {
    $body = "ipAddr, zone, aRecord is required."
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = $body
    })
    return
}

# Update record in Azure DNS.
try {
    $rs = Get-AzDnsRecordSet -name "$aRecord" -RecordType A -ZoneName "$zone" -ResourceGroupName "$resourceGroup"
    $rs.Records[0].Ipv4Address = "$ipAddr"
    $rs.Ttl = "$ttl"
    Set-AzDnsRecordSet -RecordSet $rs
    # set request body and status code.
    $body = "Successed. $ipAddr, $zone, $aRecord"
    $statusCode = [HttpStatusCode]::OK
} catch {
    # set request body and status code.
    $body = "Failed. $ipAddr, $zone, $aRecord"
    $statusCode = [HttpStatusCode]::InternalServerError
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $statusCode
    Body = $body
})
