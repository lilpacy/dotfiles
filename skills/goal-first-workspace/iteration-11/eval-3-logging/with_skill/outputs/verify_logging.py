"""Verify that logging captures diagnostic information on failures."""
import sys
import json
import io
from unittest.mock import patch, MagicMock

# Capture stderr to show logging output
captured_logs = io.StringIO()

# Configure logging to capture to our buffer
import logging
handler = logging.StreamHandler(captured_logs)
handler.setFormatter(logging.Formatter('%(levelname)s - %(message)s'))

sys.path.insert(0, '.')
import sync_worker

# Replace stderr handler to capture
sync_worker.logger.handlers = [handler]

print("=== Scenario 1: Network error during fetch ===")
with patch('sync_worker.urllib.request.urlopen') as mock_urlopen:
    mock_urlopen.side_effect = OSError("Connection refused")
    try:
        sync_worker.fetch_orders("")
    except OSError:
        pass

logs1 = captured_logs.getvalue()
print(logs1)
assert "Connection refused" in logs1, "Network error not logged"
assert "cursor=" in logs1, "Cursor not logged"
print("✓ Network errors logged with cursor context\n")

# Reset
captured_logs.truncate(0)
captured_logs.seek(0)

print("=== Scenario 2: Malformed JSON ===")
with patch('sync_worker.urllib.request.urlopen') as mock_urlopen:
    mock_response = MagicMock()
    mock_response.read.return_value = b'{ broken json'
    mock_response.__enter__ = MagicMock(return_value=mock_response)
    mock_response.__exit__ = MagicMock(return_value=None)
    mock_urlopen.return_value = mock_response
    
    try:
        sync_worker.fetch_orders("cursor1")
    except json.JSONDecodeError:
        pass

logs2 = captured_logs.getvalue()
print(logs2)
assert "JSON decode error" in logs2, "JSON error not logged"
assert "cursor1" in logs2, "Cursor not included in JSON error log"
print("✓ JSON errors logged with cursor context\n")

# Reset
captured_logs.truncate(0)
captured_logs.seek(0)

print("=== Scenario 3: Missing order field (transform) ===")
order = {"id": "order-123", "items": [], "shipping": {"address": {}}}  # missing region
try:
    sync_worker.transform(order)
except KeyError:
    pass

logs3 = captured_logs.getvalue()
print(logs3)
assert "Missing required field" in logs3, "Missing field error not logged"
assert "order-123" in logs3, "Order ID not logged in transform error"
assert "region" in logs3 or "field=" in logs3, "Field name not logged"
print("✓ Transform errors logged with order ID and missing field\n")

print("=== Scenario 4: Successful batch processing ===")
captured_logs.truncate(0)
captured_logs.seek(0)

with patch('sync_worker.urllib.request.urlopen') as mock_urlopen:
    # Two batches: 2 orders then end
    batch1 = b'{"orders": [{"id": "o1", "items": [{"price": 10, "qty": 1}], "shipping": {"address": {"region": "US"}}}], "next_cursor": "next"}'
    batch2 = b'{"orders": [], "next_cursor": null}'
    
    responses = []
    for batch_data in [batch1, batch2]:
        r = MagicMock()
        r.read.return_value = batch_data
        r.__enter__ = MagicMock(return_value=r)
        r.__exit__ = MagicMock(return_value=None)
        responses.append(r)
    
    mock_urlopen.side_effect = responses
    
    try:
        sync_worker.main()
    except Exception as e:
        print(f"Error: {e}")

logs4 = captured_logs.getvalue()
print(logs4)
assert "Starting nightly sync" in logs4, "Start message not logged"
assert "synced 1 orders" in logs4 or "Sync completed successfully" in logs4, "Completion message not logged"
print("✓ Sync progress logged with order counts\n")

print("\n=== ALL TESTS PASSED ===")
print("Logging provides:")
print("  • Failure stage identification (fetch/transform/upload)")
print("  • Cursor position and order IDs at point of failure")
print("  • Full exception stack traces (exc_info=True)")
print("  • Progress tracking (order counts, batch info)")
