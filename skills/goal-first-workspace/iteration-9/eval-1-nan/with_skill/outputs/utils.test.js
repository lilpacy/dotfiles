const assert = require("assert");
const { parseAmount } = require("./utils");

assert.strictEqual(parseAmount("$1,200.50"), 1200.5);
assert.strictEqual(parseAmount("$89.99"), 89.99);
assert.strictEqual(parseAmount("$345.00"), 345);
assert.strictEqual(parseAmount("-$50.25"), -50.25);
assert.strictEqual(parseAmount("1200"), 1200);
assert.throws(() => parseAmount("N/A"));
console.log("utils.test.js: ok");
