for ($i=0;$i -le 60 ; $i++) {
    Start-Sleep -S 60
    write-host "doing stuff"
}

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

# vars
$User     =  $env:puppetuser
$Password = $env:puppetpw
$Uri      = $env:puppeturl
$name = hostname
$domain = $env:domain #wmic computersystem get domain
$tempName = "$name"+"."+"$domain"
$HostName = $tempName.ToLower()

# hack to pass creds to api authentication
$pair = "$($User):$($Password)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{Authorization = $basicAuthValue}

# try and catch of the API call
Try 
    {
        $Status = Invoke-WebRequest -Uri $Uri/$HostName/status -Headers $Headers -ErrorAction Stop
    }
    
Catch 
    {   $_.Exception
        Exit 0
    }


#if host is in Foreman
if ($Status.StatusDescription -eq 'OK')
    {
        $state = (($Status.Content).Split(":"))[1] -replace '["}]',''

        for ($i=0;$i -le 300 ; $i++) {
            Start-Sleep -S 60
            write-host "MDT thinks I crashed if I dont output something"
            if ($state = 'No Changes') {
                $i=301
                write-host "No Changes found"
            }
            else {
                write-host "Something went horribly wrong"
            }

        }
        
    }