import-module au

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient
  try {
    if (!(Test-Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)")) {
      mkdir "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)" -ea silentlycontinue
    }
    $client.DownloadFile($Latest.URL, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)")
  }
  finally {
    $client.Dispose()
  }

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
  $packagename = "zoom"
  $releases = 'https://zoom.us/download#client_4meeting'
  $download_page = Invoke-WebRequest $releases -usebasicparsing
  [regex]$re = '(Version \d+.\d+.\d+ (\((.\d+|.\d+.\d+)\)))'
  $versionMatch = $re.Match($download_page.content)
  $recodeversion = $versionMatch.value -replace "Version ", ""
  $version1 = $recodeversion.Substring(0,$recodeversion.indexof(".",2)+2)
  $version2 = (($recodeversion.split(' ') | Select-Object -Index 1) -replace '[()]').split(".") | Select-Object -Index 0
  $version  = $version1 + '.' + $version2

  $URL = "https://zoom.us/client/$version/ZoomInstallerFull.msi?archType=x64"
  $filename = "ZoomInstallerFull.msi"


  $is =  "$($env:au_chocopackages)/$($packagename)/$($version)/$($filename)"

  @{ URL          = $URL
     Version      = $version
     internalsite = $is
     packagename  = $packagename
     filename     = $filename
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none