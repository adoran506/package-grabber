import-module au
import-module "$PSScriptRoot\..\_scripts\au_extensions.psm1"

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient

  if (!(Test-Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)")) {
    mkdir "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)" -ea silentlycontinue
  }
  
  # macabaus requires posting to http to get download. weird.
  $uri = 'https://macabacus.com/macros/getproduct/macabacus-pro-2016'
  $fullfilename = "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)"
  $headers = @{Accept='text/html, application/xhtml+xml, image/jxr, */*';'Accept-Encoding'='gzip, deflate';'Accept-Language'='en-US';'Cache-Control'='no-cache';'Referer'='https://macabacus/downloads';Host='macabacus.com'}
  $ContentType = 'multipart/form-data; boundary=---------------------------7e11a114303ac'
  $body = @('
-----------------------------7e11a114303ac
Content-Disposition: form-data; name="product"

macabacus-pro-2016
-----------------------------7e11a114303ac--
')

  $progressPreference = 'silentlyContinue'

  Invoke-Webrequest -Uri $uri -Method Post -Body $body -Headers $headers -ContentType $ContentType -UseBasicParsing -OutFile $fullfilename

  $Latest.ChecksumType = "sha256"
  $Latest.Checksum = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)" | ForEach-Object Hash
}


function global:au_SearchReplace {
@{
  'tools\chocolateyInstall.ps1' = @{
    "(^\s*url\s*=\s*)('.*')"      = "`$1'$($Latest.internalsite)'"
    "(^\s*checksum\s*=\s*)('.*')" = "`$1'$($Latest.checksum)'"
  }
 }
}


function global:au_GetLatest {
  $packagename = "macabacus"
  $releases = 'https://macabacus.com/macros/pro-version'
  $downloadPage = Invoke-WebRequest -Uri $releases -usebasicparsing
  $version = (convertfrom-json $downloadpage.content).version
  $filename = 'Macabacus2016.exe'
  
  $is =  "$($env:au_chocopackages)/$($packagename)/$($version)/$($filename)"

  @{
      Version       = $version
      packagename   = $packagename
      filename      = $filename
      internalsite  = $is
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none