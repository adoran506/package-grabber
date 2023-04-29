import-module au

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient
  try {
    $client.DownloadFile($Latest.URL64, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)")
  }
  finally {
    $client.Dispose()
  }

  $Latest.ChecksumType = "sha256"
  $Latest.Checksum64 = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)" | ForEach-Object Hash

}

function global:au_SearchReplace {
@{
  'tools\chocolateyInstall.ps1' = @{
    "(^\s*url64\s*=\s*)('.*')"      = "`$1'$($Latest.internalsite)'"
    "(^\s*checksum64\s*=\s*)('.*')" = "`$1'$($Latest.checksum64)'"
  }
 }
}


function global:au_GetLatest {
  $packagename = "tortoisegit"
  $releases = 'https://tortoisegit.org/download/'
  $download_page = Invoke-WebRequest -UseBasicParsing -Uri $releases
  $re  = "TortoiseGit-(.*)-64bit.msi"
  $url64 = $download_page.links | Where-Object href -match $re | Select-Object -First 1 -expand href
  $url64 = "https:" + $url64
  $filename = $url64 -split '/' | Select-Object -Last 1
  $version = $filename -split '-' | Select-Object -Skip 1 -First 1

  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"
  
    return @{
      URL64         = $url64 
      fileName      = $filename
      version       = $version
      internalsite  = $is
      packagename   = $packagename
    }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none