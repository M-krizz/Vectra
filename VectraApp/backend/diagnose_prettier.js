const fs = require('fs');
const prettier = require('prettier');

async function checkFile(filepath) {
    console.log(`\n=== Checking ${filepath} ===`);

    // Read raw bytes
    const raw = fs.readFileSync(filepath);
    const hasCRLF = raw.includes(Buffer.from('\r\n'));
    const hasLF = raw.includes(Buffer.from('\n'));
    console.log(`Raw bytes: ${hasCRLF ? 'CRLF' : ''} ${hasLF ? 'LF' : ''}`);

    // Get prettier config
    const config = await prettier.resolveConfig(filepath);
    console.log(`Prettier config:`, JSON.stringify(config));

    // Check if formatted
    const isFormatted = await prettier.check(fs.readFileSync(filepath, 'utf8'), {
        ...config,
        filepath
    });
    console.log(`Is formatted: ${isFormatted}`);

    // Get formatted version
    const formatted = await prettier.format(fs.readFileSync(filepath, 'utf8'), {
        ...config,
        filepath
    });

    // Check line endings in formatted version
    const formattedHasCRLF = formatted.includes('\r\n');
    const formattedHasLF = formatted.includes('\n');
    console.log(`Formatted would be: ${formattedHasCRLF ? 'CRLF' : ''} ${formattedHasLF ? 'LF' : ''}`);

    // Compare
    const original = fs.readFileSync(filepath, 'utf8');
    if (original === formatted) {
        console.log(`✓ File matches formatted output`);
    } else {
        console.log(`✗ File DIFFERS from formatted output`);
        console.log(`Original length: ${original.length}, Formatted length: ${formatted.length}`);
    }
}

checkFile('src/app.module.ts').catch(console.error);
