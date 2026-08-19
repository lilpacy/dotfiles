const { parseAmount } = require("./utils");
const items = ["$1,200.50", "$89.99", "$345.00"];
const total = items.reduce((sum, s) => sum + parseAmount(s), 0);
console.log("Invoice total:", total);
