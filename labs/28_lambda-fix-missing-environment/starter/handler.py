import os

import boto3

dynamodb = boto3.client("dynamodb", endpoint_url=os.environ.get("AWS_ENDPOINT_URL"))


def handler(event, context):
    order_id = event["order_id"]
    probe = event.get("probe", "manual")
    try:
        table = os.environ["TABLE_NAME"]
    except KeyError:
        print(f"probe={probe} missing TABLE_NAME", flush=True)
        raise

    response = dynamodb.get_item(
        TableName=table, Key={"order_id": {"S": order_id}}, ConsistentRead=True
    )
    item = response.get("Item")
    print(f"probe={probe} order={order_id} found={item is not None}", flush=True)
    if item is None:
        return {"error": "order not found"}
    return {"order_id": item["order_id"]["S"], "status": item["status"]["S"]}
