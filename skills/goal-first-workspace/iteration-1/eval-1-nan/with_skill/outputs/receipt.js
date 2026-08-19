const { parseAmount } = require("./utils");
const items = ["$25.00", "$13.50"];
const total = items.reduce((sum, s) => sum + parseAmount(s), 0);
console.log("Receipt total:", total);
