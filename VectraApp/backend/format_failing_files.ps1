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
    Write-Host "Formatting $file"
    npx prettier --write $file
}
