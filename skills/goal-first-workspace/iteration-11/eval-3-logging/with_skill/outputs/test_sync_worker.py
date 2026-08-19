import sys
import json
from unittest.mock import patch, MagicMock
import logging

# Mock test to verify logging behavior on different failure scenarios
# Capture logs to verify diagnostic richness

# Configure logging for this test run
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Import the sync_worker after logging is configured
sys.path.insert(0, '.')
import sync_worker

print("\n=== TEST 1: Malformed JSON response ===")
with patch('sync_worker.urllib.request.urlopen') as mock_urlopen:
    mock_response = MagicMock()
    mock_response.read.return_value = b'{ invalid json'
    mock_response.__enter__ = MagicMock(return_value=mock_response)
    mock_response.__exit__ = MagicMock(return_value=None)
    mock_urlopen.return_value = mock_response
    
    try:
        sync_worker.main()
    except Exception as e:
        print(f"Caught: {type(e).__name__}: {e}")

print("\n=== TEST 2: Missing required field (region) ===")
with patch('sync_worker.urllib.request.urlopen') as mock_urlopen:
    mock_response = MagicMock()
    # First call returns valid batch, second call returns empty (end of sync)
    mock_response.read.side_effect = [
        b'{"orders": [{"id": "123", "items": [{"price": 10, "qty": 2}], "shipping": {"address": {}}}], "next_cursor": null}',
        b'{"orders": [], "next_cursor": null}'
    ]
    mock_response.__enter__ = MagicMock(return_value=mock_response)
    mock_response.__exit__ = MagicMock(return_value=None)
    
    call_count = 0
    def urlopen_side_effect(*args, **kwargs):
        nonlocal call_count
        if call_count == 0 or call_count == 1:
            result = MagicMock()
            result.read.return_value = [
                b'{"orders": [{"id": "123", "items": [{"price": 10, "qty": 2}], "shipping": {"address": {}}}], "next_cursor": null}'
            ][0] if call_count == 0 else b'{"orders": [], "next_cursor": null}'
            result.__enter__ = MagicMock(return_value=result)
            result.__exit__ = MagicMock(return_value=None)
            call_count += 1
            return result
    
    mock_urlopen.side_effect = urlopen_side_effect
    
    try:
        sync_worker.main()
    except Exception as e:
        print(f"Caught: {type(e).__name__}: {e}")

print("\n=== TEST 3: Successful sync (3 orders) ===")
# Create a mock that simulates a two-batch sync (3 orders total, then empty batch)
with patch('sync_worker.urllib.request.urlopen') as mock_urlopen:
    batch1 = b'{"orders": [{"id": "1", "items": [{"price": 100, "qty": 1}], "shipping": {"address": {"region": "US"}}}, {"id": "2", "items": [{"price": 50, "qty": 2}], "shipping": {"address": {"region": "EU"}}}], "next_cursor": "abc123"}'
    batch2 = b'{"orders": [{"id": "3", "items": [{"price": 25, "qty": 1}], "shipping": {"address": {"region": "APAC"}}}], "next_cursor": null}'
    
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
        print("Sync completed successfully!")
    except Exception as e:
        print(f"Caught: {type(e).__name__}: {e}")

