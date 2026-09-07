param(
    [int]$Port = 8000,
    [string]$Root = "C:\Quizapp\build\web"
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $Root on http://localhost:$Port/"

$mimeTypes = @{
    ".html" = "text/html"; ".js" = "application/javascript"; ".json" = "application/json"
    ".css" = "text/css"; ".png" = "image/png"; ".jpg" = "image/jpeg"; ".jpeg" = "image/jpeg"
    ".svg" = "image/svg+xml"; ".ico" = "image/x-icon"; ".wasm" = "application/wasm"
    ".ttf" = "font/ttf"; ".otf" = "font/otf"; ".woff" = "font/woff"; ".woff2" = "font/woff2"
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    try {
        $path = $request.Url.LocalPath.TrimStart("/")
        if ([string]::IsNullOrEmpty($path)) { $path = "index.html" }
        $filePath = Join-Path $Root $path
        if (-not (Test-Path $filePath) -or (Get-Item $filePath).PSIsContainer) {
            $filePath = Join-Path $Root "index.html"
        }
        $ext = [System.IO.Path]::GetExtension($filePath)
        $contentType = $mimeTypes[$ext]
        if (-not $contentType) { $contentType = "application/octet-stream" }
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $response.ContentType = $contentType
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } catch {
        $response.StatusCode = 500
    } finally {
        $response.OutputStream.Close()
    }
}
