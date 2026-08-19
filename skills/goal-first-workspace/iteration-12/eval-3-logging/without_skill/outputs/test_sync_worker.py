"""Self-check: a broken order must leave a diagnosable trace in sync_worker.log."""
import importlib
import logging
import sys

import sync_worker as sw


def demo():
    # force a KeyError inside transform() to simulate a malformed order
    sw.fetch_orders = lambda cursor: {
        "orders": [{"id": "bad-order-1", "items": []}],  # missing "shipping"
        "next_cursor": None,
    }
    sw.upload = lambda row: None

    for h in list(sw.logging.getLogger().handlers):
        h.flush()

    try:
        sw.main()
        raise AssertionError("expected transform() to raise on missing 'shipping'")
    except KeyError:
        pass

    with open(sw.LOG_PATH) as f:
        log_text = f.read()
    assert "bad-order-1" in log_text, "order id missing from log"
    assert "failed on order_id" in log_text, "failure marker missing from log"
    print("ok: failing order id is recoverable from sync_worker.log")


if __name__ == "__main__":
    demo()
