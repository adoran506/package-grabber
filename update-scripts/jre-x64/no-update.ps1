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
  $Latest.Checksum = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)" | ForEach-Object Hash

}


function global:au_SearchReplace {
@{
  'tools\chocolateyInstall.ps1' = @{
    "(^\s*url64bit\s*=\s*)('.*')"      = "`$1'$($Latest.internalsite)'"
    "(^\s*checksum64\s*=\s*)('.*')" = "`$1'$($Latest.checksum)'"
  }
  'tools\chocolateyUninstall.ps1' = @{
    "(^[$]major\s*=\s*)('.*')" = "`$1'$($Latest.major)'"
    "(^[$]build\s*=\s*)('.*')" = "`$1'$($Latest.build)'"
  }
 }
}


function global:au_GetLatest {

  $packagename = "jre-x64"  
  $downloadEndPointUrl = 'https://www.java.com/en/download/manual.jsp'
  $versionRegEx = 'Version ([0-9]+) Update ([0-9]+)'
  $downloadUrlRegEx64 = 'Download Java software for Windows \(64\-Bit\)'
  $matches = $null
  $downloadPage = Invoke-WebRequest -UseBasicParsing -Uri $downloadEndPointUrl
  $versionInfo = $downloadPage.Content -match $versionRegEx

  if ($matches) {
      $major = $matches[1]
      $build = $matches[2]
  }

  $version = @{ $true = "$major.0.$build"; $false = "$major.$build"}[1 -eq $version.length]

  $downloadUrl64 = $downloadPage.links | Where-Object { $_.title -match $downloadUrlRegEx64 } | Select-Object -First 1 -Expand href

  
  $filename = "jre-$($major)u$($build)-windows-x64.exe"

  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{
      Version       = $version
      URL64         = $downloadUrl64
      packagename   = $packagename
      filename      = $filename
      internalsite  = $is
      major         = $major
      build         = $build
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none