
const package = require("./package.json");
const fs = require("fs");
const path = require("path");
const yaml = require("yaml");




fs.writeFileSync(path.join(__dirname, "lib/src/version.dart"), `///Version of the package\nString flutterIdentityVersion = 'v${package.version}';\n`);


// Write version to pubspec.yaml
const pubspec = yaml.parse(fs.readFileSync(path.join(__dirname, "pubspec.yaml"), "utf8"));
pubspec.version = package.version;
fs.writeFileSync(path.join(__dirname, "pubspec.yaml"), yaml.stringify(pubspec));

console.log(`Wrote version ${package.version} to lib/src/version.dart and pubspec.yaml`);


