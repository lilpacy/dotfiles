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
    // ai_unavailable は provider の疎通失敗・非2xx・タイムアウトを一つに畳んでいるため、
    // 切り分け用に元エラーの詳細(status/code/causeの中身)をここで残す。
    console.error(`generate failed: ${normalized.code}`, {
      name: err && err.name,
      message: err && err.message,
      status: err && err.status,
      code: err && err.code,
      cause: err && err.cause && { name: err.cause.name, message: err.cause.message },
    });
    res.status(normalized.httpStatus).json({ ok: false, error: normalized.code });
  }
}

module.exports = { generateHandler };
