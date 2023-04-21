[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
param()

function Remove-ObsoleteVersion {

  Param(
    [string]$Matcher,
    [string]$PackageName,
    [int32]$MaximumVersions,
    [string]$gitrepo = $env:au_gitrepo,
    [string]$SimpleServerPath = $env:au_SimpleServerPath
  )

  $ErrorActionPreference = "Stop"

  $tags = @()
  $filehash = ""
  $content = ""
  $matches = ""
  $lstree = ""

  $tags = git for-each-ref --sort=taggerdate --format="%(refname)" |Select-string -Pattern "^refs/tags/$($PackageName)-([0-9.]+)"
  [array]$tagObj = foreach ($tag in $tags) {
    [string]$cleantag = $tag
    $name = split-path $cleantag.Substring(0,$cleantag.LastIndexOf('-')) -leaf

    $splittag = $cleantag.split('-')

    [pscustomobject]@{
      name = $name
      ver=[System.Version]$splittag[-1]
      tag = $cleantag.Substring($cleantag.LastIndexOf("/") + 1)
    }
  }
  # we need the tags in system.version tag order not ascii
  $tagobj=$tagobj |Sort-Object ver

  if ($tagObj.count -gt $MaximumVersions) {
    $tagObj=$tagObj[0..($tagObj.Count-($MaximumVersions+1))]
    $total=$tags.count
    $i=0
    push-location "$($gitrepo)\$($packagename)"
    foreach ($item in $tagObj) {
      $content = $null
      # we stash to preserve non commited changes while we peruse historical commit tags/branches
      $matches = ''
      # git is case sensitive and we didn't historically enforce this
      $dirname = git ls-tree $item.tag
      $dirname | ForEach-Object {$_ -match "tools"}
      $chocofiles = git ls-tree $item.tag "$($matches[0])/"
      $matches=$null
      $ci = $chocofiles | ForEach-Object {$_ -match '(.*)(/chocolateyinstall.ps1)'}
      $filehash =  $matches[0].split(" ")[2].split("`t")[0]
      $content = git show $filehash
      $matches=$null
      $packagefile = $content | ForEach-Object {$_ -match $matcher}
      $matches
      if ($matches[1]) {
        try {
          remove-item "$($env:au_chocopackagepath)/$($PackageName)/$($matches[1])" -ErrorAction SilentlyContinue -debug -Confirm:$false
          $nupkgfilename = "$($item.name).$($item.ver).nupkg"

          # artifactory api call to remove nupkg from feed
          $user = "choco-publisher"
          $pass = $env:chocopublisherpw
          $pair = "${user}:${pass}"
          $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
          $base64 = [System.Convert]::ToBase64String($bytes)
          $IwrParams = @{
            Uri     = ""
            Method  = 'Delete'
            Headers = @{
                Authorization = "Basic $base64"
                Accept        = 'application/json'
            }
          }
          Invoke-RestMethod @iwrparams
          $i++
          git tag -d $item.tag
          git push -q upstream :$($item.tag)
          "removed $($item.tag) from repository as we store $($MaximumVersions) versions"
        }
        catch {
          "error removing items and tag deleting because $($matches[1]) empty"
        }
      }
      else {
        "Error with regex for parsing package history"
      }
    }
  pop-location
  }
}