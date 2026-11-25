import json

ORDERS = {"123": {"id": "123", "item": "widget", "qty": 5}}


def handler(event, context):
    order_id = (event.get("pathParameters") or {}).get("id")
    order = ORDERS.get(order_id)
    return {
        "statusCode": 200 if order else 404,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(order or {"error": "not found", "id": order_id}),
    }
