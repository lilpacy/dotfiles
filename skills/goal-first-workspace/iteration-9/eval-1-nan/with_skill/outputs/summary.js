const { parseAmount } = require("./utils");
const monthly = ["$4,500.00", "$3,200.75"];
const total = monthly.reduce((sum, s) => sum + parseAmount(s), 0);
console.log("Monthly summary:", total);
