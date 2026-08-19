// POST /api/generate — called from the production-management UI.
const { callProvider } = require("./aiClient");
const { normalizeError } = require("./errors");

async function generateHandler(req, res) {
  try {
    const result = await callProvider({
      prompt: req.body.prompt,
      vendorId: req.body.vendorId,
    });
    res.status(200).json({ ok: true, result });
  } catch (err) {
    const normalized = normalizeError(err);
    console.error(`generate failed: ${normalized.code}`);
    res.status(normalized.httpStatus).json({ ok: false, error: normalized.code });
  }
}

module.exports = { generateHandler };
