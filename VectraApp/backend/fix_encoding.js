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

        // Remove UTF-8 BOM if present at start
        if (content[0] === 0xEF && content[1] === 0xBB && content[2] === 0xBF) {
            content = content.slice(3);
        }

        let text = content.toString('utf8');

        // Remove BOMs that might be in the middle (EF BB BF in utf8 string is \uFEFF)
        // Also remove specific corruption if I appended garbage.
        // The check showed binary diff. 
        // Let's just strip non-printable chars or normalize.
        // Actually, replacing \uFEFF is enough for BOM.

        if (text.includes('\uFEFF')) {
            console.log(`Fixing BOM in ${file}`);
            text = text.replace(/\uFEFF/g, '');
        }

        // Normalize line endings to LF
        text = text.replace(/\r\n/g, '\n');

        // Trim trailing whitespace (including the space I appended)
        text = text.trim() + '\n';

        fs.writeFileSync(filePath, text, 'utf8');
    } else {
        console.log(`Missing: ${file}`);
    }
});
console.log("Encoding fix complete.");
