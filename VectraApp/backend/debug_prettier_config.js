const prettier = require('prettier');
console.log("Prettier Version:", prettier.version);
prettier.resolveConfig('src/app.module.ts').then(config => {
    console.log("Resolved Config:", JSON.stringify(config, null, 2));
});
