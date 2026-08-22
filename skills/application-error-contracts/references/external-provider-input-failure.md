# External Provider Input Failure

Use this note when a third-party or AI provider returns a generic error for a document, image, media file, or uploaded artifact.

## Diagnostic order

1. Identify the artifact first: filename or fixture name, content type, byte length, checksum, source object metadata, and whether the name signals an abnormal fixture.
2. Validate the artifact locally with the smallest available parser or metadata tool before blaming request schema or provider configuration.
3. Compare retries and timestamps only after the artifact identity is known. Repeated failures of the same invalid artifact are usually permanent input failures, not transient outages.
4. Map corrupt, unsupported, missing, or intentionally abnormal input to a stable input error code. Reserve provider-unavailable codes for failures where the input is valid or unknown after validation.
5. Include safe diagnostic fields in logs: artifact name when non-sensitive, byte length, checksum or hash prefix, validation result, provider status/error class, and retry decision.

## Pitfall

A provider `400` or `INVALID_ARGUMENT` can be caused by a bad request shape, but it can also be the correct response to a corrupt artifact. Do not spend time reshaping provider config until the artifact identity and validity have been checked.
