import-module au
import-module "$PSScriptRoot\..\_scripts\au_extensions.psm1"

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient
  try {
    $client.DownloadFile($Latest.URL64, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)")
  }
  finally {
    $client.Dispose()
  }

  $Latest.ChecksumType = "sha256"
  $Latest.Checksum = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)" | ForEach-Object Hash

}


function global:au_SearchReplace {
@{
  'tools\chocolateyInstall.ps1' = @{
    "(^\s*url64bit\s*=\s*)('.*')"      = "`$1'$($Latest.internalsite)'"
    "(^\s*checksum64\s*=\s*)('.*')" = "`$1'$($Latest.checksum)'"
  }
 }
}


function global:au_GetLatest {
    $releases = 'https://github.com/serge-rider/dbeaver/releases'
    $downloadPage = Invoke-WebRequest -Uri $releases -usebasicparsing
    $packagename = "dbeaver-ce"

    $re    = '\64-setup.exe$'
    $url   = $downloadPage.links | Where-Object href -match $re | Select-Object -Expand href -First 1 | ForEach-Object  { 'https://github.com' + $_ }

    $version  = $url -split '/' | Select-Object -Last 1 -Skip 1
    
    $filename = $URL.Substring($URL.LastIndexOf("/") + 1)
    $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

    @{
        Version      = $version
        URL64        = $url
        packagename  = $packagename
        filename     = $filename
        internalsite = $is
    }
}

function global:au_AfterUpdate ($Package)  {
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none