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
  $packagename = "notepadplusplus"
  $tags = "https://github.com/notepad-plus-plus/notepad-plus-plus/tags"
  $release = Invoke-WebRequest $tags -UseBasicParsing
  $new = (( $release.links -match "v\d+\.\d+\.\d+" ) -split " " | select-object -First 10 | select-object -Last 1 )
  $new = $new.Substring(0,$new.Length-1)
  $releases = "https://notepad-plus-plus.org/downloads/$new"
  $upstream_Url  = "https://notepad-plus-plus.org"
  $download_page = Invoke-WebRequest $releases -UseBasicParsing
  $url_i         = $download_page.Links | Where-Object href -match '.exe$' | Select-Object -Last 3 | ForEach-Object href
  $URL64_i = ($url_i -match 'x64')

  $Version_raw = (Split-Path (Split-Path $url_i[0]) -Leaf) -match "[0-9].*"
  $Version = $Matches[0]


  $filename = $URL64_i.Substring($URL64_i.LastIndexOf("/") + 1)
  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{ URL64        = "$url64_i"
     Version      = $version
     internalsite = $is
     packagename  = $packagename
     filename     = $filename
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none