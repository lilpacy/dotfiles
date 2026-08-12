# JSONL Record Boundaries

## Durable rule

Treat the format's delimiter as the boundary, not the host language's broad definition of a “line.” For Codex transcript JSONL, split raw bytes on ASCII LF (`b"\n"`) and let the JSON parser accept an optional preceding CR as whitespace.

Do not use Python `str.splitlines()` to find JSONL records. It also splits on Unicode separators such as `U+0085`, `U+2028`, and `U+2029`; those characters can occur inside a valid JSON string and would turn one valid record into multiple invalid fragments.

## Failure signature

- The transcript is valid when parsed by its actual LF delimiters.
- A reader fails with `JSONDecodeError` at an apparently arbitrary position.
- The same record fails repeatedly in an incremental reader because its checkpoint is not advanced after the exception.
- Binary-derived or externally fetched text increases the chance that a Unicode separator appears inside a JSON string.

## Minimal fix

```python
records = [json.loads(line) for line in path.read_bytes().split(b"\n") if line.strip()]
```

For incremental reads, retain only bytes through the last complete LF, parse that prefix with the same byte delimiter, and advance the offset by the exact byte count consumed. Do not decode the whole chunk and then call `splitlines()`.

## Regression check

Create one record whose string value contains `U+0085` and `U+2028`, serialize it as UTF-8 JSON followed by LF, then assert that:

1. full-file reading returns exactly that record;
2. incremental reading returns exactly that record;
3. the next offset equals the file size.

Run the same fixture through every shared reader path. Fixing only the path named by the failure leaves sibling callers vulnerable.
