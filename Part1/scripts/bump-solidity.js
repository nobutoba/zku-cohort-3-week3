const fs = require("fs");
const solidityRegex = /pragma solidity \^\d+\.\d+\.\d+/

let content = fs.readFileSync("./contracts/verifier.sol", { encoding: 'utf-8' });
let bumped = content.replace(solidityRegex, 'pragma solidity ^0.8.0');

fs.writeFileSync("./contracts/verifier.sol", bumped);

let content_bonus = fs.readFileSync("./contracts/verifier_bonus.sol", { encoding: 'utf-8' });
let bumped_bonus = content_bonus.replace(solidityRegex, 'pragma solidity ^0.8.0');

fs.writeFileSync("./contracts/verifier_bonus.sol", bumped_bonus);
