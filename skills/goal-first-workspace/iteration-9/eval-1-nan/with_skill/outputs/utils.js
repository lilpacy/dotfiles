function parseAmount(s) {
  // "$1,200.50" -> 1200.5 : parseFloat stops at "$" and truncates at ","
  const n = parseFloat(String(s).replace(/[^0-9.-]/g, ""));
  if (Number.isNaN(n)) throw new Error(`parseAmount: cannot parse ${JSON.stringify(s)}`);
  return n;
}
module.exports = { parseAmount };
