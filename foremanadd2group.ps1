# Add machine to puppetng host group
# ------------------------------------
# This script grabs the hostname and adds the machine to the proper host group 

$NGFOREMAN_URL = $env:formanurl

$foremanUser   = "admin"
$foremanPassNG = -AsSecurestring #Read-Host "Please enter PuppetNG Foreman Admin password"

# ng api creds
$NGpair           = "$($foremanUser):$($foremanPassNG)"
$NGencodedCreds   = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($NGpair))
$NGbasicAuthValue = "Basic $NGencodedCreds"
$NGHeaders        = @{Authorization = $NGbasicAuthValue}

# adding this to bypass the certificate warning.
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


$name = hostname
write-host $name
$domain = wmic computersystem get domain
$server = "$name"+"."+"$domain"
write-host $server
$hg = $env:puppethostgroup

# obtain HG ID in ForemanNG
$hgsearch = Invoke-RestMethod -Uri $NGFOREMAN_URL/api/v2/hostgroups?search=$hg -Headers $NGHeaders -Method Get
[int]$hgID     = ($hgsearch.results | where {$_.title -eq $hg}).id

# move to correct HG on PuppetNG
$data = @{host= [ordered]@{"hostgroup_id"= "$hgID";}}
$body = $data | ConvertTo-Json

Write-Host "Moving $server to $hg hostgroup" -ForegroundColor Green
$server = $server.ToLower()
Invoke-RestMethod -Uri $NGFOREMAN_URL/api/v2/hosts/$server -Headers $NGHeaders -Method Put -Body $body -ContentType 'application/json' | Out-Null