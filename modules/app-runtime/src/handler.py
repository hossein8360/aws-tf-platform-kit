"""Lambda handler for the platform event processor."""
from __future__ import annotations

import json
import logging
import os
from typing import Any

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Entry point for both SQS-triggered and EventBridge-scheduled invocations."""
    source = event.get("source", "sqs")

    if source == "heartbeat":
        logger.info("Heartbeat received from EventBridge")
        return _handle_heartbeat(event)

    return _handle_sqs_batch(event)


def _handle_heartbeat(event: dict[str, Any]) -> dict[str, Any]:
    logger.info("Heartbeat processed", extra={"event": event})
    return {"statusCode": 200, "body": "ok"}


def _handle_sqs_batch(event: dict[str, Any]) -> dict[str, Any]:
    """Process an SQS batch, reporting individual item failures."""
    batch_item_failures: list[dict[str, str]] = []

    for record in event.get("Records", []):
        message_id = record.get("messageId", "unknown")
        try:
            body = json.loads(record["body"])
            logger.info("Processing record", extra={"message_id": message_id, "body": body})
            _process(body)
        except Exception:  # noqa: BLE001
            logger.exception("Failed to process record %s", message_id)
            batch_item_failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": batch_item_failures}


def _process(body: dict[str, Any]) -> None:
    """Business logic placeholder — extend this per your domain."""
    logger.debug("Processed payload: %s", body)
