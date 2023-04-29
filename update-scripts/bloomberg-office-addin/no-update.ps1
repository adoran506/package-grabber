import-module au

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient
  try {
    $client.DownloadFile($Latest.URL, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)")
  }
  finally {
    $client.Dispose()
  }

  $Latest.ChecksumType = "sha256"
  $Latest.Checksum = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)" | foreach-object Hash

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

  $packagename = "bloomberg-office-addin"
  $ProgressPreference = "SilentlyContinue"
  $upstream_Url = 'https://www.bloomberg.com/professional/support/software-updates/'
  $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
  $headers.Add('Accept','text/html, application/xhtml+xml, image/jxr, */*')
  $headers.Add('Accept-Language','en-US')
  $headers.Add('Accept-Encoding','gzip, deflate')
  $headers.Add('User-Agent','Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; Touch; rv:11.0) like Gecko')
  $headers.Add('Host','www.bloomberg.com')
  $headers.Add('Cache-Control','max-age=900')
  $result = Invoke-WebRequest -Uri $upstream_Url -Headers $headers -UseBasicParsing

  $downloadLink = ($result.links | Where-object {($_.href -like "*bxla*.exe")} | select-object -first 1).href
  $filename = $downloadLink | split-path -leaf

  $versionRaw = $filename.Substring(4, $filename.Length-8)
  #adding a 2023 to the version to not break existing versioning, only uncomment if you have pre-2020 packages in your feed
  #$versionRaw = "2023." + $versionRaw
  $version = $versionRaw.Replace("_",".")

  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{ URL = $downloadLink
     Version = $version
     internalsite = $is
     packagename = $packagename
     filename = $filename
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none