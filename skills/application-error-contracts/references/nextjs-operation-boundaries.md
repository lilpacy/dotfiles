# Next.js operation-boundary reference

This reference condenses a verified migration pattern for Next.js applications that mix Server Actions, Route Handlers, typed use cases, and client-side message mapping.

## Server Action

Expected failures are serializable return values. Unknown failures retain their exception semantics.

```ts
type PlaceOrderCode =
  | "approver_conflict"
  | "approver_missing"
  | "order_prohibited";

type PlaceOrderResult =
  | { ok: true; value: { orderId: string } }
  | { ok: false; error: { code: PlaceOrderCode } };

export async function placeOrder(): Promise<PlaceOrderResult> {
  try {
    return await placeOrderUseCase();
  } catch (error) {
    if (error instanceof KnownPlaceOrderError) {
      return { ok: false, error: { code: error.code } };
    }

    reportError(error);
    throw error;
  }
}
```

Do not turn an unknown exception into a fresh `Error` merely to hide its message; that loses the original stack unless `cause` is preserved. Reporting plus rethrowing the original error keeps observability and lets Next.js unexpected-error handling do its job.

Framework control signals such as `redirect()` and `notFound()` must pass through according to the installed Next.js version's contract. Keep control-flow calls outside broad catches when possible.

## Route Handler

Known failures map to deliberate statuses and stable codes. Unknown exceptions are reported and receive a generic response.

```ts
try {
  const result = await updateUseCase();
  if (!result.ok) {
    return Response.json({ code: result.reason }, { status: 409 });
  }
  return Response.json(result.value);
} catch (error) {
  reportError(error);
  return Response.json({ code: "unexpected_error" }, { status: 500 });
}
```

HTTP status can be sufficient for conventional authentication, authorization, and not-found behavior. Add an application code only when consumers must distinguish multiple meanings with the same status or present different recovery actions.

## UI mapping

```ts
const messages = {
  approver_conflict: "Set different users for the approval roles.",
  approver_missing: "Assign an approver, then try again.",
  order_prohibited: "Orders cannot be placed with this vendor.",
} satisfies Record<PlaceOrderCode, string>;
```

The mapping should be exhaustive. A generic fallback remains necessary for unknown faults, but it must not conceal a known recoverable code.

## Audit checklist

- Inventory single-item and bulk variants separately.
- Follow wrapper actions to the implementation rather than counting forwarding functions as independent defects.
- Inspect use-case results as well as thrown exceptions; structured information is often lost in adapters.
- Check that every Route Handler reports thrown exceptions, including public-link, replay, PDF, and other secondary routes.
- Check that UI consumers inspect returned codes rather than status or message alone.
- Check field-name continuity: a producer's `.kind` cannot help a consumer that only reads `.code`.
- Re-run the inventory after the patch and test both known-return and unknown-throw paths.
