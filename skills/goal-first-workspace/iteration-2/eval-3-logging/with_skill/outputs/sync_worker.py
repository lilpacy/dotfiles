"""Nightly sync worker. Deployed to production via CI (deploy takes ~40 min).
Runs once per night; failures are only observable in next morning's log.

Diagnostics: logs go to stderr AND to SYNC_WORKER_LOG (default
/var/log/sync_worker.log) because cron discards stdout/stderr. Level is DEBUG
on purpose -- we get exactly one run per night, so over-collect.
"""
import json
import logging
import os
import sys
import time
import traceback
import urllib.error
import urllib.request

API_BASE = "https://internal-api.example.com"
LOG_PATH = os.environ.get("SYNC_WORKER_LOG", "/var/log/sync_worker.log")
HTTP_TIMEOUT = 60
BODY_SNIPPET = 2000
MAX_DETAILED_FAILURES = 50  # ponytail: cap log volume, raise if 50 isn't enough

log = logging.getLogger("sync_worker")


def setup_logging():
    handlers = [logging.StreamHandler(sys.stderr)]
    try:
        handlers.append(logging.FileHandler(LOG_PATH))
    except OSError as e:
        print(f"cannot open log file {LOG_PATH}: {e!r}", file=sys.stderr)
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
        handlers=handlers,
        force=True,
    )
    log.info(
        "start pid=%s python=%s api_base=%s log_path=%s",
        os.getpid(), sys.version.split()[0], API_BASE, LOG_PATH,
    )


def _snippet(obj):
    """Truncated JSON for log lines. May contain customer data -- see reply."""
    try:
        return json.dumps(obj, ensure_ascii=False)[:BODY_SNIPPET]
    except (TypeError, ValueError):
        return repr(obj)[:BODY_SNIPPET]


def _request(req, what):
    """urlopen + full error detail. HTTPError body is the single most useful
    thing here and urllib swallows it unless read explicitly."""
    t0 = time.monotonic()
    try:
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as res:
            body = res.read()
        log.debug(
            "%s ok status=%s bytes=%d ms=%d url=%s",
            what, getattr(res, "status", "?"), len(body),
            (time.monotonic() - t0) * 1000, req.full_url,
        )
        return body
    except urllib.error.HTTPError as e:
        try:
            detail = e.read()[:BODY_SNIPPET].decode("utf-8", "replace")
        except Exception:  # noqa: BLE001 - never let logging break the raise
            detail = "<unreadable>"
        log.error(
            "%s HTTPError status=%s url=%s ms=%d headers=%s body=%s",
            what, e.code, req.full_url, (time.monotonic() - t0) * 1000,
            dict(e.headers or {}), detail,
        )
        raise
    except urllib.error.URLError as e:
        log.error(
            "%s URLError url=%s ms=%d reason=%r",
            what, req.full_url, (time.monotonic() - t0) * 1000, e.reason,
        )
        raise
    except Exception:
        log.exception("%s unexpected error url=%s", what, req.full_url)
        raise


def fetch_orders(cursor):
    req = urllib.request.Request(f"{API_BASE}/orders?cursor={cursor}")
    raw = _request(req, "fetch_orders")
    try:
        return json.loads(raw)
    except ValueError:
        log.exception(
            "fetch_orders bad JSON cursor=%r raw=%r",
            cursor, raw[:BODY_SNIPPET],
        )
        raise


def transform(order):
    return {
        "id": order["id"],
        "total": sum(i["price"] * i["qty"] for i in order["items"]),
        "region": order["shipping"]["address"]["region"],
    }


def upload(row):
    req = urllib.request.Request(
        f"{API_BASE}/warehouse/rows",
        data=json.dumps(row).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    _request(req, "upload")


def main():
    setup_logging()
    cursor = ""
    synced = 0
    failures = []
    page_no = 0
    t0 = time.monotonic()
    try:
        while True:
            page_no += 1
            log.info("page=%d fetch cursor=%r synced_so_far=%d", page_no, cursor, synced)
            page = fetch_orders(cursor)
            orders = page.get("orders") or []
            log.info(
                "page=%d got orders=%d keys=%s next_cursor=%r",
                page_no, len(orders), sorted(page.keys()), page.get("next_cursor"),
            )
            for idx, order in enumerate(orders):
                order_id = order.get("id") if isinstance(order, dict) else None
                try:
                    row = transform(order)
                    log.debug("page=%d idx=%d transformed row=%s", page_no, idx, _snippet(row))
                    upload(row)
                    synced += 1
                except Exception as e:
                    # Keep going: one night per attempt, so collect every bad
                    # record instead of dying on the first. Exit code stays 1.
                    failures.append((page_no, idx, order_id, repr(e)))
                    if len(failures) <= MAX_DETAILED_FAILURES:
                        log.error(
                            "order failed page=%d idx=%d order_id=%r error=%r\n"
                            "order_keys=%s\norder_raw=%s\n%s",
                            page_no, idx, order_id, e,
                            sorted(order.keys()) if isinstance(order, dict) else type(order).__name__,
                            _snippet(order),
                            traceback.format_exc(),
                        )
            prev = cursor
            cursor = page.get("next_cursor")
            if not cursor:
                log.info("page=%d no next_cursor, done paging", page_no)
                break
            if cursor == prev:
                log.error("cursor did not advance (%r) -- stopping to avoid loop", cursor)
                break
    except Exception:
        log.exception(
            "fatal: aborting run page=%d cursor=%r synced=%d failures=%d elapsed=%.1fs",
            page_no, cursor, synced, len(failures), time.monotonic() - t0,
        )
        raise SystemExit(1)

    log.info(
        "synced %d orders pages=%d failures=%d elapsed=%.1fs",
        synced, page_no, len(failures), time.monotonic() - t0,
    )
    if failures:
        log.error("failed order ids=%s", [f[2] for f in failures[:MAX_DETAILED_FAILURES]])
        raise SystemExit(1)


def _self_check():
    """Smallest check that the diagnostic paths actually emit what we need."""
    import tempfile
    global LOG_PATH
    LOG_PATH = os.path.join(tempfile.mkdtemp(), "sync.log")

    pages = [
        {"orders": [
            {"id": "ok-1", "items": [{"price": 2, "qty": 3}],
             "shipping": {"address": {"region": "JP"}}},
            {"id": "bad-1", "items": [{"price": 1, "qty": 1}], "shipping": {}},
        ], "next_cursor": None},
    ]
    globals()["fetch_orders"] = lambda cursor: pages.pop(0)
    globals()["upload"] = lambda row: None

    try:
        main()
    except SystemExit as e:
        assert e.code == 1, e.code
    else:
        raise AssertionError("expected exit 1 when an order fails")

    with open(LOG_PATH) as f:
        out = f.read()
    for needle in ("order failed", "bad-1", "order_keys=", "order_raw=", "Traceback", "synced 1 orders"):
        assert needle in out, f"missing {needle!r} in log:\n{out}"
    print("self-check ok:", LOG_PATH)


if __name__ == "__main__":
    if "--self-check" in sys.argv:
        _self_check()
    else:
        main()
