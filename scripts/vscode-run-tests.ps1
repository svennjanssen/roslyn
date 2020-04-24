param (
  [Parameter(Mandatory = $true)][string]$filePath,
  [Parameter(Mandatory = $false)][string]$framework,
  [Parameter(Mandatory = $false)][string]$filter
)

Set-StrictMode -version 3.0
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "../eng/build-utils.ps1")

$fileInfo = Get-ItemProperty $filePath
$projectFileInfo = Get-ProjectFile $fileInfo
if ($projectFileInfo) {
  $dotnetPath = Resolve-Path (Ensure-DotNetSdk) -Relative
  $projectDir = Resolve-Path $projectFileInfo.Directory -Relative

  $filterArg = if ($filter) { " --filter $filter" } else { "" }
  $logFilePrefix = if ($filter) { $fileInfo.Name } else { $projectFileInfo.Name }
  $frameworkArg = if ($framework) { " --framework $framework" } else { "" }

  $resultsPath = Join-Path $PSScriptRoot ".." "artifacts/TestResults"
  $resultsPath = Resolve-Path (New-Item -ItemType Directory -Force -Path $resultsPath) -Relative

  # Remove old run logs with the same prefix
  Remove-Item (Join-Path $resultsPath "$logFilePrefix*.html")

  $invocation = "$dotnetPath test $projectDir" + $filterArg + $frameworkArg + " --logger `"html;LogFilePrefix=$logfilePrefix`" --results-directory $resultsPath"
  Write-Output "> $invocation"
  Invoke-Expression $invocation

  exit 0
}
else {
  Write-Host "Failed to run tests. $fileInfo is not part of a C# project."

  exit 1
}
