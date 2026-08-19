// POST /api/generate — called from the production-management UI.
const { callProvider } = require("./aiClient");
const { normalizeError } = require("./errors");

async function generateHandler(req, res) {
  try {
    const payload = {
      prompt: req.body.prompt,
      vendorId: req.body.vendorId,
    };
    const result = await callProvider(payload);
    res.status(200).json({ ok: true, result });
  } catch (err) {
    const normalized = normalizeError(err);
    const logContext = {
      error: normalized.code,
      httpStatus: normalized.httpStatus,
      request: {
        promptLength: req.body.prompt ? req.body.prompt.length : 0,
        vendorId: req.body.vendorId,
      },
      provider: normalized.internals,
    };
    console.error("generate failed:", JSON.stringify(logContext, null, 2));
    res.status(normalized.httpStatus).json({ ok: false, error: normalized.code });
  }
}

module.exports = { generateHandler };
