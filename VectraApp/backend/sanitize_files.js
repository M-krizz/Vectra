const fs = require('fs');
const path = require('path');

const files = [
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
];

files.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
        let content = fs.readFileSync(filePath);
        let originalLen = content.length;

        // Filter out null bytes and other non-printables (keep newlines 0x0A, 0x0D and tab 0x09)
        // Valid ranges: 0x09, 0x0A, 0x0D, 0x20-0x7E, and UTF-8 multibyte sequences (0x80-0xFF)
        // Simple approach: remove 0x00.

        let newContent = [];
        let changed = false;

        for (let i = 0; i < content.length; i++) {
            if (content[i] === 0x00) {
                changed = true; // Skip null byte
            } else {
                newContent.push(content[i]);
            }
        }

        if (changed || content.length !== newContent.length) {
            console.log(`Sanitized ${file}: Removed ${content.length - newContent.length} null bytes.`);
            fs.writeFileSync(filePath, Buffer.from(newContent));
        } else {
            console.log(`No null bytes in ${file}`);
        }
    } else {
        console.log(`Missing: ${file}`);
    }
});
