def handler(event, context):
    order_id = event.get("order_id")
    if not isinstance(order_id, str) or not order_id:
        return {"error": "order_id is required"}
    return {"processed": order_id}
