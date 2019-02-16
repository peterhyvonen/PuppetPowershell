Set-ExecutionPolicy unrestricted

$apps = Get-WmiObject -Class Win32_Product | Where-Object { 
    $_.Name -match "Puppet" 
}
if ($apps) {
    foreach ($app in $apps) {
        $app.delete()
        Remove-Item C:\ProgramData\PuppetLabs -Recurse -Force
    }
}
New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR

Set-Location HKCR:


$keys = Get-ChildItem "HKCR:\Installer\Products"
$string = "Installer\Products\"

foreach($key in $keys){
    $product = $key.getvalue(“ProductName”)

    if ($product -match 'Puppet'){
        Write-Host "Found Puppet GUID"
        $id = ($key.Name).Split("\")

        $id[3]
        $string += $id[3]
        Remove-Item $string -Recurse
    }
}