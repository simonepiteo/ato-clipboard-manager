const fs = require('fs');
const plist = require('plist');
const path = require('path');

const packageJson = require('../package.json');
const version = packageJson.version;

const plistPath = path.join(
  __dirname,
  '../macos/atoClipboardManager-macOS/Info.plist',
);
const infoPlist = fs.readFileSync(plistPath, 'utf8');
const parsed = plist.parse(infoPlist);

parsed.CFBundleShortVersionString = version;
parsed.CFBundleVersion = version;

fs.writeFileSync(plistPath, plist.build(parsed));
console.log(`Updated Info.plist to version ${version}`);
