function parseAmount(s) {
  const cleaned = String(s).replace(/[$,\s]/g, "");
  if (!/^-?\d+(\.\d+)?$/.test(cleaned)) {
    throw new Error(`parseAmount: cannot parse ${JSON.stringify(s)}`);
  }
  return Number(cleaned);
}
module.exports = { parseAmount };
