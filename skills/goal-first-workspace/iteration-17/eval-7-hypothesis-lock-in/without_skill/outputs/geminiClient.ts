// invoice-receive service: Gemini invocation wrapper.
// This is the file the prior diagnostic-logging PRs have all touched.
import { GoogleGenerativeAI } from "@google/generative-ai";

type InvoiceParseRequest = {
  jobId: string;
  attachmentId: string;
  model: string;
  schema: object;
  config: { temperature: number; responseMimeType: string };
};

export async function parseInvoice(req: InvoiceParseRequest, pdfBuffer: Buffer) {
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);
  const model = genAI.getGenerativeModel({ model: req.model });

  // staging-only diagnostic: request snapshot, added over three prior
  // rounds of "this still isn't enough to isolate it" feedback.
  if (process.env.NEXT_PUBLIC_SENTRY_ENVIRONMENT === "staging") {
    console.log(JSON.stringify({
      event: "invoice_receive_gemini_request_snapshot",
      jobId: req.jobId,
      model: req.model,
      schema: req.schema,
      config: req.config,
      pdfSizeBytes: pdfBuffer.length,
      pdfSha256: "…", // computed elsewhere
    }));
  }

  try {
    const result = await model.generateContent({
      contents: [{ role: "user", parts: [{ inlineData: { mimeType: "application/pdf", data: pdfBuffer.toString("base64") } }] }],
      generationConfig: req.config,
    });
    return result;
  } catch (err) {
    console.error(JSON.stringify({
      event: "invoice_receive_ai_unavailable_diagnostic",
      jobId: req.jobId,
      parserErrorName: "InvoiceReceiveAiParserError",
      causes: [{ name: "InvoiceAiAgentError", code: "provider_error", message: String(err) }],
    }));
    throw err;
  }
}
