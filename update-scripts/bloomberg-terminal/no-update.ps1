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
  $Latest.Checksum64 = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)" | ForEach-Object Hash

}

function global:au_SearchReplace {
@{
  'tools\chocolateyInstall.ps1' = @{
    "(^\s*url64bit\s*=\s*)('.*')"      = "`$1'$($Latest.internalsite)'"
    "(^\s*checksum64\s*=\s*)('.*')" = "`$1'$($Latest.checksum64)'"
  }
 }
}

function global:au_GetLatest {
  $packagename = "bloomberg-terminal"
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

  $downloadLink = ($result.links | Where-Object {($_.href -like "*sotr*.exe")} | select-object -first 1).href

  $filename = $downloadLink | split-path -leaf

  $versionRaw = $filename.Substring(4, $filename.Length-8)
  #adding a 2023 to the version to not break existing versioning, only uncomment if you have pre 2020 versions in your feed
  #$versionRaw = "2023." + $versionRaw
  $version = $versionRaw.Replace("_",".")

  # 11/18/2020 Preserving old method should BBG role back binary file name to sotrDDmmYYYY.exe
  # they have now changed versioning for an arbitrary version and renamed the binary accordingly, this logic is depracated until it isnt...
  # code above now greps the correct version and replaces _ with .
  #
  #$version_unparsed = ($filename.Substring(0, $filename.LastIndexOf('.'))).substring(5)
  #
  #if (($version_unparsed).length -eq 6) {
  #  $dateformat = "MMddyy"
  #} else {
  #  $dateformat = "MMddyyyy"
  #}
  #
  ## convert date into semver
  #$version = [datetime]::parseExact($version_unparsed,$dateformat,$null).toString("yyyy.MM.dd")
  #
  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{ URL64 = $downloadLink
     Version = $version
     internalsite = $is
     packagename = $packagename
     filename = $filename
  }
}

function global:au_AfterUpdate ($Package)  {
  
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none