function parseAmount(s) {
  const n = parseFloat(String(s).replace(/[^\d.-]/g, ""));
  if (Number.isNaN(n)) throw new TypeError(`parseAmount: 解析できません: ${JSON.stringify(s)}`);
  return n;
}
module.exports = { parseAmount };
