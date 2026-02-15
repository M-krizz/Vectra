$files = @(
    "src/app.module.ts",
    "src/database/migrations/1769875200000-PoolingV1Update.ts",
    "src/integrations/redis/redis.module.ts",
    "src/modules/Authentication/auth/auth.controller.ts",
    "src/modules/chat/chat.gateway.ts",
    "src/modules/location/location.gateway.ts",
    "src/modules/pooling/pool-group.entity.ts",
    "src/modules/pooling/pooling.manager.ts",
    "src/modules/pooling/pooling.module.ts",
    "src/modules/pooling/pooling.service.ts",
    "src/modules/ride_requests/ride-request.entity.ts",
    "src/modules/ride_requests/ride-request.enums.ts",
    "src/modules/ride_requests/ride-requests.service.ts",
    "src/modules/safety/safety.controller.ts",
    "src/modules/safety/safety.service.ts"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content -Path $file -Raw
        # Normalize to LF
        $content = $content -replace "`r`n", "`n"
        Set-Content -Path $file -Value $content -NoNewline -Encoding utf8
        Write-Host "Normalized $file to LF"
    } else {
        Write-Warning "File not found: $file"
    }
}

# Run Prettier
Write-Host "Running Prettier..."
npx prettier --write $files

# Git Add
Write-Host "Staging files..."
git add $files
git status
