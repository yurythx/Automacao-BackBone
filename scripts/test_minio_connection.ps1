$ErrorActionPreference = 'Stop'

$minioPublicUrl = if ($env:MINIO_PUBLIC_URL) { $env:MINIO_PUBLIC_URL } else { 'https://minio.projetoravenna.cloud' }
$chatwootOrigin = if ($env:CHATWOOT_ORIGIN) { $env:CHATWOOT_ORIGIN } else { 'https://atendimento.projetoravenna.cloud' }

Write-Host "MinIO URL: $minioPublicUrl"
Write-Host "Origin:   $chatwootOrigin"

try {
    $cors = Invoke-WebRequest -Uri $minioPublicUrl -Method Options -Headers @{
        Origin = $chatwootOrigin
        'Access-Control-Request-Method' = 'PUT'
    }
    Write-Host "CORS StatusCode: $($cors.StatusCode)"
    Write-Host "Access-Control-Allow-Origin: $($cors.Headers['Access-Control-Allow-Origin'])"
    Write-Host "Access-Control-Allow-Methods: $($cors.Headers['Access-Control-Allow-Methods'])"
} catch {
    Write-Host "CORS check failed: $($_.Exception.Message)"
}

try {
    $healthUrl = ($minioPublicUrl.TrimEnd('/') + '/minio/health/live')
    $health = Invoke-WebRequest -Uri $healthUrl -Method Get
    Write-Host "Health StatusCode: $($health.StatusCode)"
} catch {
    Write-Host "Health check failed: $($_.Exception.Message)"
}
