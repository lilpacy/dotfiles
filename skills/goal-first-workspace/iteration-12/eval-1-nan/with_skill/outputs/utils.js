function parseAmount(s) {
  return parseFloat(s.replace(/[$,]/g, ""));
}
module.exports = { parseAmount };
