// Thin client for the external AI provider.
const PROVIDER_URL = process.env.AI_PROVIDER_URL || "https://ai.internal.example.com/v1/generate";

class AIProviderError extends Error {
  constructor(message, { cause, status, code } = {}) {
    super(message, { cause });
    this.name = "AIProviderError";
    this.status = status;
    this.code = code;
  }
}

async function callProvider(payload) {
  let res;
  try {
    res = await fetch(PROVIDER_URL, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(15000),
    });
  } catch (err) {
    throw new AIProviderError("provider request failed", { cause: err });
  }
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new AIProviderError("provider returned non-2xx", {
      status: res.status,
      code: res.headers.get("x-error-code"),
      cause: new Error(body.slice(0, 2000)),
    });
  }
  return res.json();
}

module.exports = { callProvider, AIProviderError };
