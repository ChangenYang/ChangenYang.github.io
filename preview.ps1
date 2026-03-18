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
Write-Host "Caching is disabled for preview responses. Refresh the page after edits."

if (-not $NoBrowser) {
    Start-Process $url
}

$serverScript = @'
import functools
import http.server
import os
import socketserver


class NoCacheRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


project_root = os.environ["PREVIEW_PROJECT_ROOT"]
port = int(os.environ["PREVIEW_PORT"])
Handler = functools.partial(NoCacheRequestHandler, directory=project_root)

with socketserver.TCPServer(("", port), Handler) as httpd:
    print(f"Preview server running at http://localhost:{port}")
    httpd.serve_forever()
'@

$env:PREVIEW_PROJECT_ROOT = $projectRoot
$env:PREVIEW_PORT = $Port.ToString()

$serverScript | & $selected.Command @($selected.Args + "-")
