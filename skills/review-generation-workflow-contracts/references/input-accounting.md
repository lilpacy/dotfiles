# Input Accounting Correction Pattern

## Failure pattern

A proposed feature considered two newly discussed images in isolation and omitted four reference images already required by the existing workflow. The first answer therefore understated the total contract even though its local two-input recommendation was internally coherent.

The durable correction is to inventory the full existing contract before discussing where a new input should go.

## Worked accounting shape

Suppose a workflow receives:

- one base composition image;
- one correction-direction image;
- four character reference images.

The external input total is six. A possible two-stage allocation might be:

| Stage | Inputs | Count |
|---|---|---:|
| First generation | base, correction, references A and B | 4 |
| Second generation | first-stage output, references C and D | 3 |

This table demonstrates the accounting method only. It does not prove that this allocation preserves quality or that a particular runtime supports those counts. Verify the actual graph, node arity, prompt semantics, and serialized request.

## Review checklist

- Enumerate old required inputs before adding the new one.
- Count external uploads separately from derived stage outputs.
- Record each input's semantic role; do not use anonymous `image1`, `image2` reasoning alone.
- Count inputs at every consuming stage, not just across the workflow as a whole.
- Confirm each existing input still has a consumer after rewiring.
- Confirm the new input does not silently displace an old one.
- Distinguish a preview composite from the generation source of truth.
- Validate the built graph before claiming the design works.
