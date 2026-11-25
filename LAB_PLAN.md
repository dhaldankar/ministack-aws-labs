# Beginner AWS playground plan

The playground covers **14 AWS services**. Learners first use each service, then configure it for a specific outcome, then diagnose a reproducible failure. Application labs combine the services after learners have practiced each one independently.

The planned catalog has **46 guided activities**: one orientation, 42 service exercises, and three application labs. The first 40 labs are authored and included in the catalog. The three RDS exercises and three application labs remain planned.

See [all 46 lab designs and their implementation status](NEXT_20_LABS.md).

Source folders use `NN_<id>`, with a two-digit catalog position such as `01_orientation`. The ID stays stable when an exercise moves. The browser catalog and CLI use the prefix for order and the ID for commands, URLs, and workspaces.

## Orientation

Open the Linux workspace and confirm the endpoint, Region, and caller identity. Use Terraform to plan, apply, and destroy a starter S3 bucket. Recover from a supplied endpoint typo and distinguish a connection failure from an AWS API error.

## Service playgrounds

| Service | First use | Deeper configuration | Troubleshoot and verify |
| --- | --- | --- | --- |
| IAM | Identify the caller with STS and inspect an identity policy. | Assume a supplied role and scope an action to one resource. | Fix an object permission using the denied action and ARN. Verify the intended S3 read succeeds and unrelated reads and writes are denied. |
| S3 | Create a bucket, upload an object, and retrieve it by key. | Enable versioning, overwrite the object, and retrieve an earlier version by ID. | Diagnose a delete marker and verify that a fresh read returns the restored contents. |
| DynamoDB | Create a table and retrieve a sample item by primary key. | Model orders using a customer partition key and order sort key. | Compare a failing query with the key schema, then verify the query returns only the expected customer's orders. |
| SQS | Send, receive, and delete a message using its receipt handle. | Set the visibility timeout and configure a dead-letter queue with a redrive policy. | Trace a failing message through redelivery to the dead-letter queue and verify that a healthy message completes. |
| SNS | Publish to a topic and inspect the message at an SQS subscriber. | Add a second subscriber and filter by message attributes. | Fix a filter that drops an expected delivery. Verify the intended queues receive a fresh test event. |
| EventBridge | Publish a custom event and inspect its source, detail type, and payload. | Configure an event pattern and route matching events to SQS. | Correct a pattern that misses the sample event. Verify delivery for a matching event and observe that a control event stays out of the queue. |
| CloudWatch | Create a log stream, publish a sample log event, and find it by request ID. | Publish a custom metric and configure a threshold alarm. | Fix a metric dimension mismatch and observe the alarm transition after publishing a new datapoint. |
| CloudTrail | Find the actor, action, Region, and time for a management API call in event history. | Configure a trail with a supplied S3 destination and choose management event settings. | Locate a missing change record by correcting the Region or event-history filter. Verify the actor and request. |
| Lambda | Deploy and invoke a supplied handler with sample JSON. | Configure an execution role and environment variables, then find an invocation in CloudWatch Logs. | Trace a failure to a missing environment variable. Fix it and verify the same input returns the expected response. |
| API Gateway | Call one HTTP API route backed by a supplied Lambda function. | Configure a route parameter and stage. Test valid and missing-resource requests. | Diagnose a route-level 404 by comparing the request method and path with the deployed route. Verify a corrected request. |
| VPC | Inspect CIDRs, subnets, and route table associations in a supplied network. | Configure public and private subnets, routes, and scoped security group rules. | Trace a failed request to a routing or security group fault. Fix it and prove connectivity from the intended client. |
| EC2 | Launch an instance and inspect its AMI, state, and security group. | Bootstrap a supplied web server with user data and compare instance checks with an HTTP check. | Use startup output to find a bootstrap failure. Fix the configuration and verify HTTP 200. |
| Elastic Load Balancing | Send a request through an Application Load Balancer to an EC2 target. | Configure a listener rule, target group, and health check. | Fix an incorrect health check path using the target health reason. Verify target health and a successful request. |
| RDS | Connect from a supplied client to PostgreSQL and run a query. | Place the database in private subnets and scope access to the application security group. | Diagnose an application connection timeout. Fix the scope of the database rule and verify the application can query it. |

## Application labs

| Application | Services and request path | What the learner verifies |
| --- | --- | --- |
| Order status API | API Gateway → Lambda → DynamoDB, with IAM and CloudWatch Logs. | Create and retrieve an order. Trace a failed request to a wrong table setting, fix it, and verify the stored item. |
| Order processing pipeline | EventBridge → SNS → two SQS queues. Lambda processes one queue while the other retains an independent copy. | Trace one event ID across both queues and the worker logs. Repair a missing delivery and verify a fresh event end to end. |
| Web application with a private database | VPC hosts an Application Load Balancer, EC2 app, and private RDS database. CloudWatch provides operational evidence and CloudTrail records configuration changes. | Verify that the client can use the web app and the app can reach the database. Diagnose a seeded failure and identify the change that caused it. |

## Learner workflow

- Start with a working baseline and a small set of AWS CLI or HTTP commands. Use Terraform for repeatable setup and configuration changes. Supply application code and sample data.
- Give learners a target behavior and one seeded problem. Ask for the symptom, the evidence that narrowed the cause, and a successful check after the fix.
- Include an optional experiment in each service playground, such as trying another object version, event pattern, or alarm threshold. Give each exercise its own Terraform state and a way to reset it.
- Use Bash checks that inspect real outcomes, bounded polling for asynchronous behavior, and cleanup verification. Have learners explain what each service contributes to the application.

## Build order and environments

1. **Local core.** Start with IAM, S3, DynamoDB, SQS, SNS, and EventBridge in the Linux Dev Container. Validate permissions, version recovery, redrive, filtering, and event delivery against the pinned MiniStack image before publishing each activity. [MiniStack service catalog](https://ministack.org/docs/services/)
2. **Serverless and observability.** Check Lambda execution, API Gateway routing, CloudWatch logs and alarm transitions, and CloudTrail event history and trail delivery. Use a disposable AWS sandbox for exercises whose required behavior MiniStack cannot demonstrate. [MiniStack limitations](https://ministack.org/docs/limitations) · [AWS HTTP API tutorial](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-dynamo-db.html)
3. **Networking and compute.** Run the VPC, EC2, load balancer, RDS, and traditional web application exercises in an AWS sandbox. Their checks depend on real network paths. Provide isolated credentials, a time limit, and verified teardown of billable resources. [AWS VPC infrastructure security](https://docs.aws.amazon.com/vpc/latest/userguide/infrastructure-security.html) · [AWS load balancer troubleshooting](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html)
