import os
import time
import json
import boto3
from botocore.config import Config


def lambda_handler(event, context):
    print(event)
    print("----------------- \n -----------------")
    print(context)
    print("----------------- \n -----------------")

    req_context = event["requestContext"]
    route = req_context["routeKey"]
    connection_id = req_context["connectionId"]
    api_client = create_api_client(req_context)

    if route == "$connect":
        print("$connected")

    if route == "$disconnect":
        print("$disconnected")

    if route == "$default":
        send_to_client(
            api_client,
            connection_id,
            "statusMsg",
            {
                "from": "SYSTEM",
                "message": "Unknown Action",
                "ts": round(time.time() * 1000),
            },
            False,
        )

    if route == "ping":
        send_to_client(
            api_client,
            connection_id,
            "pong",
            {
                "client_ts": json.loads(event["body"])["data"]["client_ts"],
                "server_ts": round(time.time() * 1000),
            },
        )

    return {
        "statusCode": 200 if route != "$default" else 500,
        "body": route,
        "headers": {"Sec-WebSocket-Protocol": "auth"},
    }


def create_api_client(req_context: dict):
    domain_name = req_context.get("domainName", "")
    stage_name = req_context.get("stage", "")
    return boto3.client(
        "apigatewaymanagementapi",
        endpoint_url=f"https://{domain_name}/{stage_name}",
        region_name=os.getenv("AWS_REGION", "us-west-2"),
        config=Config(connect_timeout=3, read_timeout=3, retries={"max_attempts": 2}),
    )


def send_to_client(
        api_client: boto3.client,
        connection_id: str,
        action: str,
        message,
        status: bool = True,
):
    try:
        data = json.dumps({"status": status, "action": action, "data": message})
        api_client.post_to_connection(
            Data=data,
            ConnectionId=connection_id,
        )
        return data
    except Exception as e:
        print(e)
        return False
