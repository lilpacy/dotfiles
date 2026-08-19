// Normalizes internal errors into stable API error codes for clients.
function normalizeError(err) {
  if (err && err.name === "AIProviderError") {
    return {
      code: "ai_unavailable",
      httpStatus: 503,
      internals: {
        status: err.status,
        errorCode: err.code,
        details: err.details,
        message: err.message,
      },
    };
  }
  if (err && err.name === "ValidationError") {
    return { code: "invalid_request", httpStatus: 400 };
  }
  return { code: "internal_error", httpStatus: 500 };
}

module.exports = { normalizeError };
