param(
    [int]$Port = 8000,
    [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$pythonCandidates = @(
    @{ Label = "python"; Command = "python"; Args = @() },
    @{ Label = "py -3"; Command = "py"; Args = @("-3") },
    @{ Label = "conda python"; Command = "D:\miniconda\envs\yolo11v2.0\python.exe"; Args = @() }
)

$selected = $null
foreach ($candidate in $pythonCandidates) {
    try {
        & $candidate.Command @($candidate.Args + "--version") *> $null
        if ($LASTEXITCODE -eq 0) {
            $selected = $candidate
            break
        }
    } catch {
    }
}

if (-not $selected) {
    throw "Python was not found. Install Python or edit preview.ps1 with your local Python path."
}

$url = "http://localhost:$Port"
Write-Host "Serving $projectRoot at $url using $($selected.Label)"
Write-Host "Press Ctrl+C to stop the preview server."

if (-not $NoBrowser) {
    Start-Process $url
}

& $selected.Command @($selected.Args + @("-m", "http.server", $Port))
