# AWS playground lab designs

This document details all **46 activities** across 14 AWS services. **40 are authored** and **6 are pending**. Authored labs have a walkthrough, starter files, and a checker. Their catalog build passes. End-to-end verification against MiniStack and the AWS sandbox remains open. Pending labs have designs only.

## Lab order

The two-digit prefix in each source folder matches its position in the catalog. For example, `labs/04_s3-least-privilege/` uses the stable lab ID `s3-least-privilege`. The prefix sets display order and stays out of the front matter ID, CLI commands, browser URLs, and saved workspace paths. The browser catalog and CLI use the prefix for sorting. Pending entries reserve their positions until published.

## Orientation

Orientation is the shared prerequisite. After completing it, learners can follow the prerequisite chain for any service. Each exercise has independent resources and Terraform state.

### 1. Start the AWS playground

**ID** `orientation` · **Source folder** `labs/01_orientation/` · **Authored** · **Orientation** · **15 min**

- **Starter.** A Linux workspace with AWS CLI and Terraform, a local MiniStack endpoint, and a Terraform S3 bucket template.
- **Learner task.** Inspect the endpoint, Region, and caller identity. Diagnose an intentionally mistyped endpoint, then plan and apply the bucket.
- **Check and cleanup.** The checker identifies the caller and finds the bucket. Destroy the bucket and confirm Terraform state is empty. [Runnable walkthrough](labs/01_orientation/lab.md)

## What every lab ships with

Each exercise has a walkthrough, editable starter files, a checker, and fixtures where needed. The first-use lab supplies a working baseline. A configuration lab asks the learner to change one or two settings and predict the result. A troubleshooting lab supplies a reproducible symptom and a hint about where to look. Each workspace provisions its own resources so learners can repeat or skip ahead within a service without importing Terraform state from another exercise.

Terraform owns the infrastructure and the AWS CLI exercises its behavior. The checker reads resource identifiers from Terraform outputs, verifies API results against a fresh test ID when needed, and reports what it observed. For tasks that leave no durable resource change, such as inspecting a role or acknowledging a message, the learner saves a small result record and the checker cross-checks it against a live probe. An exercise that compares before and after behavior records the initial symptom before the learner changes the configuration. Publish each local lab after its seeded failure, repair, checker, rerun, and teardown pass against the MiniStack image pinned by Compose.

## IAM and STS

Learners use emulator credentials throughout. The checker uses an isolated environment for each identity and keeps temporary session credentials in memory or process environment. It leaves the learner's default credentials untouched. Validate trust and the effective permissions of the assumed session with MiniStack IAM enforcement enabled. [MiniStack IAM operations and limits](https://ministack.org/docs/services/iam)

### 2. Identify an AWS caller

**ID** `iam-caller-identity` · **Source folder** `labs/02_iam-caller-identity/` · **Authored** · **First use** · **15 min**

- **Starter.** Terraform provisions a sample IAM role with a trust policy and a small inline permissions policy. A fixture identifies the role to inspect.
- **Learner task.** Use STS to identify the active caller, inspect the role and its inline policy, and explain which document controls who can assume the role and which controls what it can do.
- **Check and cleanup.** Confirm the caller ARN, role ARN, policy action, and resource match the inspection record. Destroy the sample role with Terraform.

### 3. Assume a role and use temporary credentials

**ID** `iam-assume-role` · **Source folder** `labs/03_iam-assume-role/` · **Authored** · **Configure** · **25 min** · **After** lab 2

- **Starter.** A local source principal, a target role with a supplied trust relationship, and two S3 objects. A partially completed permission statement has the intended object ARN as a Terraform output.
- **Learner task.** Give the role read access to one object. Assume the role in a subshell, include the session token, and compare the resulting caller ARN with the original identity.
- **Check and cleanup.** Use a fresh assumed session to read the intended object and get `AccessDenied` for the second. Verify that exiting the subshell restores the starting caller. Destroy the role, policies, and sample objects.

### 4. Grant least-privilege access to one S3 object

**ID** `s3-least-privilege` · **Source folder** `labs/04_s3-least-privilege/` · **Authored** · **Troubleshoot** · **20 min** · **After** lab 3

- **Starter.** A Terraform bucket, two objects, and a learner IAM user with no object permissions.
- **Learner task.** Observe the denied baseline request. Grant one read action on the intended object ARN, then retry with the learner identity.
- **Check and cleanup.** The allowed read returns the expected contents. The other object read and a write still return AccessDenied. The checker removes its temporary access key. Destroy the lab resources. [Runnable walkthrough](labs/04_s3-least-privilege/lab.md)

## Amazon S3

Use a unique bucket per exercise. Versioned-bucket teardown removes the lab's object versions and delete markers before the bucket is destroyed. [AWS S3 versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html) · [MiniStack S3 coverage](https://ministack.org/docs/services/s3)

### 5. Upload and retrieve an object

**ID** `s3-first-object` · **Source folder** `labs/05_s3-first-object/` · **Authored** · **First use** · **15 min**

- **Starter.** An empty bucket and two small text fixtures with the same filename.
- **Learner task.** Upload both fixtures under different prefixes. List the objects under one prefix and retrieve the intended object by its full key.
- **Check and cleanup.** Read both keys and compare their contents with the fixtures. Confirm the prefix listing returns the expected key. Remove the uploaded objects and destroy the bucket.

### 6. Keep and retrieve earlier versions

**ID** `s3-object-versioning` · **Source folder** `labs/06_s3-object-versioning/` · **Authored** · **Configure** · **20 min** · **After** lab 5

- **Starter.** A bucket, an unfinished Terraform versioning configuration, and two different contents for the same key.
- **Learner task.** Enable versioning before either upload. Upload both revisions, find their version IDs, and retrieve the first version by ID.
- **Check and cleanup.** Verify versioning is enabled, the current read returns the second revision, and the earlier version returns the first. Remove the lab's object versions and destroy the bucket.

### 7. Recover an object hidden by a delete marker

**ID** `s3-recover-delete-marker` · **Source folder** `labs/07_s3-recover-delete-marker/` · **Authored** · **Troubleshoot** · **20 min** · **After** lab 6

- **Starter.** A versioned bucket with a known object and a current delete marker created by the failure setup.
- **Learner task.** Compare a failing normal read with the version listing. Identify the latest delete marker and remove that marker by its version ID.
- **Check and cleanup.** A normal read returns the original content and the original data version is still present. Remove the lab's remaining versions and destroy the bucket.

## Amazon DynamoDB

Use a small order dataset with distinct customers and predictable sort keys. The checker compares exact returned keys. [AWS DynamoDB key condition expressions](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.KeyConditionExpressions.html)

### 8. Store and retrieve an item by key

**ID** `dynamodb-first-item` · **Source folder** `labs/08_dynamodb-first-item/` · **Authored** · **First use** · **15 min**

- **Starter.** A table with a string partition key called `order_id` and a sample item document.
- **Learner task.** Inspect the key schema, write the item, and retrieve it by its key. Repeat the read with a different key and inspect the response.
- **Check and cleanup.** A consistent read finds the exact order and status. The control key returns no item. Destroy the table.

### 9. Query orders for one customer

**ID** `dynamodb-query-customer-orders` · **Source folder** `labs/09_dynamodb-query-customer-orders/` · **Authored** · **Configure** · **25 min** · **After** lab 8

- **Starter.** An incomplete Terraform table schema, order fixtures for two customers, and a query input template.
- **Learner task.** Configure `customer_id` as the partition key and `order_id` as the sort key. Load the fixtures and query one customer with an optional order ID range.
- **Check and cleanup.** Verify the composite key schema and compare the query's returned order IDs with the expected sorted list. Confirm a different customer has its own results. Destroy the table.

### 10. Repair a DynamoDB query

**ID** `dynamodb-fix-key-condition` · **Source folder** `labs/10_dynamodb-fix-key-condition/` · **Authored** · **Troubleshoot** · **20 min** · **After** lab 9

- **Starter.** A populated table and an editable query request that uses a non-key field as its key condition.
- **Learner task.** Reproduce the validation error, inspect the table schema, and correct the key condition and its attribute values.
- **Check and cleanup.** Replay the learner's request and compare the exact results. Probe a second partition value to verify the query changes partitions correctly. Destroy the table.

## Amazon SQS

Use standard queues, unique correlation values, and bounded receives. A checker identifies each message by its payload. It uses receive counts and receipt handles to explain delivery attempts and avoids treating a single empty receive as proof. [AWS SQS visibility timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html) · [MiniStack SQS coverage](https://ministack.org/docs/services/sqs)

### 11. Send, receive, and delete a message

**ID** `sqs-first-message` · **Source folder** `labs/11_sqs-first-message/` · **Authored** · **First use** · **15 min**

- **Starter.** An empty work queue and a sample job body.
- **Learner task.** Send the job, receive it, and delete it using the receipt handle. Explain the difference between the message ID and the receipt handle.
- **Check and cleanup.** Exercise a fresh probe and verify its body. After deletion and a bounded polling period that spans the visibility timeout, confirm the probe has not reappeared. Destroy the queue.

### 12. Configure visibility and a dead-letter queue

**ID** `sqs-visibility-and-redrive` · **Source folder** `labs/12_sqs-visibility-and-redrive/` · **Authored** · **Configure** · **25 min** · **After** lab 11

- **Starter.** A work queue and dead-letter queue, with placeholders for the source queue's visibility timeout and redrive policy.
- **Learner task.** Set a short lab timeout and configure the dead-letter queue ARN and maximum receive count. Receive a probe without deleting it, then look for it again after the timeout.
- **Check and cleanup.** Verify the queue's configured redrive target and count. Observe a redelivered probe with the same body and a higher receive count. Delete the probe and destroy both queues.

### 13. Trace a poison message

**ID** `sqs-triage-poison-message` · **Source folder** `labs/13_sqs-triage-poison-message/` · **Authored** · **Troubleshoot** · **25 min** · **After** lab 12

- **Starter.** A supplied consumer, one healthy job, and one job with a missing field. The source queue initially has no redrive policy.
- **Learner task.** Use the consumer's error and repeat receipts to identify the failing job. Configure redrive, then repeat with fresh job IDs and inspect both queues.
- **Check and cleanup.** The healthy job is acknowledged by the consumer. The checker finds the failed job's correlation ID in the dead-letter queue within a bounded window. Delete remaining fixtures and destroy the queues.

## Amazon SNS

Use SQS subscribers so successful delivery can be inspected directly. Supply scoped queue policies in the starter so the introductory exercises focus on subscriptions and filters. On AWS, filter changes can take up to 15 minutes to take effect. Verify local behavior separately before setting a learner-facing time limit. [AWS SNS subscription filter policies](https://docs.aws.amazon.com/sns/latest/dg/sns-subscription-filter-policies.html)

### 14. Publish to a topic

**ID** `sns-first-publication` · **Source folder** `labs/14_sns-first-publication/` · **Authored** · **First use** · **15 min**

- **Starter.** One topic, one subscribed queue, and a sample order notification.
- **Learner task.** Inspect the subscription, publish the notification, and read the SNS notification envelope from SQS. Locate the original message and topic ARN.
- **Check and cleanup.** Publish a fresh notification and verify that its message and topic match the queue receipt. Acknowledge the message and destroy the subscription, topic, and queue.

### 15. Fan out with subscription filters

**ID** `sns-filter-subscriptions` · **Source folder** `labs/15_sns-filter-subscriptions/` · **Authored** · **Configure** · **25 min** · **After** lab 14

- **Starter.** Two queues subscribed to one topic. The audit queue has no filter. A billing subscription has a starter filter file. Fixtures represent paid and cancelled orders.
- **Learner task.** Configure the billing subscription to accept only `status=paid` message attributes. Publish both orders and compare which queues receive them.
- **Check and cleanup.** The audit queue receives both new correlation IDs. Billing receives the paid ID and does not receive the cancelled ID during bounded polling. Acknowledge test messages and destroy the stack.

### 16. Diagnose a missing subscriber delivery

**ID** `sns-triage-missing-delivery` · **Source folder** `labs/16_sns-triage-missing-delivery/` · **Authored** · **Troubleshoot** · **20 min** · **After** lab 15

- **Starter.** A working audit subscription and a billing subscription whose filter looks for `state` while the publisher sets the `status` message attribute.
- **Learner task.** Confirm the audit copy proves publication succeeded. Compare the billing subscription's filter scope and attribute name with the published message. Repair the filter.
- **Check and cleanup.** A fresh paid order reaches both queues and a cancelled order reaches only audit. Acknowledge test messages and destroy the stack.

## Amazon EventBridge

Use a custom event bus and a dedicated SQS target per exercise. Validate actual delivery and pattern testing on the pinned image. A successful `PutEvents` response shows acceptance by the bus, while the target receipt provides delivery evidence. [AWS EventBridge event patterns](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html) · [MiniStack EventBridge coverage](https://ministack.org/docs/services/eventbridge)

### 17. Publish and inspect a custom event

**ID** `eventbridge-first-event` · **Source folder** `labs/17_eventbridge-first-event/` · **Authored** · **First use** · **15 min**

- **Starter.** A custom bus, a supplied rule and queue target, and a sample order event.
- **Learner task.** Publish the event, inspect the result for failed entries, then read the event envelope at the target. Identify its source, detail type, and business payload.
- **Check and cleanup.** Confirm the target receives a fresh event ID with the expected fields. Delete the test message and destroy the rule, target, queue, and bus.

### 18. Route events with a pattern

**ID** `eventbridge-route-order-events` · **Source folder** `labs/18_eventbridge-route-order-events/` · **Authored** · **Configure** · **25 min** · **After** lab 17

- **Starter.** A bus, a dedicated queue and scoped access policy, a partially written rule, and created and cancelled order fixtures.
- **Learner task.** Configure the pattern to accept order creation from the intended source. Attach the queue as the target and publish both fixtures.
- **Check and cleanup.** Observe delivery of the matching correlation ID and use bounded polling to check that the cancelled event was excluded. Delete received messages and destroy the stack.

### 19. Repair a rule that misses events

**ID** `eventbridge-fix-event-pattern` · **Source folder** `labs/19_eventbridge-fix-event-pattern/` · **Authored** · **Troubleshoot** · **20 min** · **After** lab 18

- **Starter.** A rule with a detail-type typo, a valid sample event envelope, and a negative fixture from a different source.
- **Learner task.** Confirm publication succeeded even though the target is empty. Compare both JSON documents, fix the typo, and use pattern testing before sending a fresh event.
- **Check and cleanup.** The repaired pattern matches the expected fixture and rejects the control. A fresh valid event arrives at the target. Delete test messages and destroy the stack.

## Amazon CloudWatch

Use a lab-specific log group and custom metric namespace. Publish custom metric datapoints directly, since MiniStack documents that SQS queue metrics are unavailable. Validate the exact alarm evaluation behavior before publishing lab 20. [MiniStack CloudWatch coverage](https://ministack.org/docs/services/cloudwatch) · [MiniStack limitations](https://ministack.org/docs/limitations)

### 20. Find a log entry by request ID

**ID** `cloudwatch-first-log-event` · **Source folder** `labs/20_cloudwatch-first-log-event/` · **Authored** · **First use** · **15 min**

- **Starter.** A log group, a stream starter, and JSON entries for two requests with different outcomes.
- **Learner task.** Create the stream, publish the entries, and filter the group for the requested ID. Use the matched entry to identify the request outcome.
- **Check and cleanup.** Find the exact request ID and status while excluding the other request. Delete the stream or destroy the lab-owned log group.

### 21. Publish a custom metric and configure an alarm

**ID** `cloudwatch-custom-metric-alarm` · **Source folder** `labs/21_cloudwatch-custom-metric-alarm/` · **Authored** · **Configure** · **25 min** · **After** lab 20

- **Starter.** A metric publisher for a synthetic error count and an alarm template with placeholders for its metric identity, statistic, and threshold.
- **Learner task.** Configure the alarm against one custom metric and dimension set. Publish datapoints below and above the chosen threshold and inspect the stored values.
- **Check and cleanup.** Read back the datapoints and check that the alarm uses the expected namespace, metric name, dimensions, statistic, and threshold. Destroy the alarm. Use a unique namespace on repeat runs so old data does not affect the exercise.

### 22. Repair an alarm with missing data

**ID** `cloudwatch-fix-alarm-dimensions` · **Source folder** `labs/22_cloudwatch-fix-alarm-dimensions/` · **Authored** · **Troubleshoot** · **25 min** · **After** lab 21

- **Starter.** A publisher emits `ErrorCount` with `Service=orders`. The alarm selects `Service=checkout` and starts with no matching datapoints.
- **Learner task.** Compare the metric actually emitted with the alarm's full metric identity. Correct the dimension and publish a fresh above-threshold datapoint.
- **Check and cleanup.** Verify the dimension now matches and poll for the expected alarm state. If the pinned evaluator cannot show a reliable transition, use a disposable AWS sandbox for the state-based check. Destroy the alarm.

## AWS CloudTrail

Use a disposable AWS sandbox for live audit delivery unless the pinned image demonstrates the same event lookup and S3 delivery. Event history shows management events for the selected Region. [AWS CloudTrail event history](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events-console.html)

### 23. Find who made an AWS change

**ID** `cloudtrail-first-management-event` · **Source folder** `labs/23_cloudtrail-first-management-event/` · **Authored** · **First use** · **20 min** · **After** Orientation

- **Starter.** A sandbox Region and a uniquely named lab resource whose tag can be changed.
- **Learner task.** Make a tagged management API call, look up the event, and identify the actor, operation, Region, and request parameters.
- **Check and cleanup.** Find the exact resource and operation within the lab time window. Restore the tag or destroy the resource.

### 24. Deliver management events to S3

**ID** `cloudtrail-management-trail` · **Source folder** `labs/24_cloudtrail-management-trail/` · **Authored** · **Configure** · **30 min** · **After** lab 23

- **Starter.** An S3 destination with a scoped bucket policy and a trail template with event selectors left open.
- **Learner task.** Enable logging and configure write management events. Make a tagged change and inspect the log object delivered to S3.
- **Check and cleanup.** Verify trail logging and event selectors, then find the matching event inside a delivered log object. Stop and delete the trail, empty the lab bucket, and destroy it.

### 25. Find an event missing from a lookup

**ID** `cloudtrail-fix-event-lookup` · **Source folder** `labs/25_cloudtrail-fix-event-lookup/` · **Authored** · **Troubleshoot** · **20 min** · **After** lab 23

- **Starter.** A known management change, a recorded time window, and a lookup set to the wrong Region.
- **Learner task.** Compare the resource Region and lookup scope, correct the request, and retrieve the event.
- **Check and cleanup.** Return the expected event ID and actor from the corrected lookup. Destroy the lab resource.

## AWS Lambda

Validate local function execution and log delivery before publishing. Supply handler code, keep its execution role scoped, and use a sandbox if the required local behavior fails. [AWS Lambda with API Gateway](https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway-tutorial.html)

### 26. Deploy and invoke a function

**ID** `lambda-first-invocation` · **Source folder** `labs/26_lambda-first-invocation/` · **Authored** · **First use** · **20 min** · **After** Orientation

- **Starter.** A small handler, a deployable Terraform starter, and valid and invalid JSON fixtures.
- **Learner task.** Deploy the code, invoke it directly, and compare the response payload for the two fixtures.
- **Check and cleanup.** Check the valid request produces the expected value and the invalid request returns the documented application error. Destroy the function and role.

### 27. Configure a function environment and role

**ID** `lambda-configure-role-and-logs` · **Source folder** `labs/27_lambda-configure-role-and-logs/` · **Authored** · **Configure** · **25 min** · **After** labs 18 and 26

- **Starter.** A supplied handler that reads a table name from an environment variable and looks up one fixture item.
- **Learner task.** Set the table name, grant the role read access to the lab table, and find the invocation log by request ID.
- **Check and cleanup.** Verify the expected item and matching request ID. Check the role policy scopes read access to the lab table. Destroy the function, role, table, and log group.

### 28. Diagnose a function configuration error

**ID** `lambda-fix-missing-environment` · **Source folder** `labs/28_lambda-fix-missing-environment/` · **Authored** · **Troubleshoot** · **25 min** · **After** lab 27

- **Starter.** A deployed function missing a required environment variable and an input that reaches the affected code path.
- **Learner task.** Invoke the function, match the failed response to its log entry, and add the missing setting.
- **Check and cleanup.** Replay the same input successfully and find a fresh success log. Destroy the function and its dependencies.

## Amazon API Gateway

Use an HTTP API with a supplied Lambda integration. Validate route matching and real handler responses on the pinned image. [AWS HTTP API tutorials](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-http-tutorials.html)

### 29. Make your first HTTP API request

**ID** `apigateway-first-route` · **Source folder** `labs/29_apigateway-first-route/` · **Authored** · **First use** · **20 min** · **After** lab 26

- **Starter.** A single GET route and a Lambda handler that returns a JSON health response.
- **Learner task.** Inspect the API endpoint, stage, and integration. Invoke the route with curl and read the status and body.
- **Check and cleanup.** Verify HTTP 200 and the expected JSON fields, then destroy the API and function.

### 30. Configure a parameterized HTTP route

**ID** `apigateway-configure-route-and-stage` · **Source folder** `labs/30_apigateway-configure-route-and-stage/` · **Authored** · **Configure** · **25 min** · **After** lab 29

- **Starter.** A starter stage and an order handler that reads an ID from the route path.
- **Learner task.** Configure a GET route with an order ID parameter. Deploy to the lab stage and request an existing and missing order.
- **Check and cleanup.** Verify the existing ID returns the expected record and a missing ID returns the handler's application 404. Destroy the API and its integration resources.

### 31. Diagnose an HTTP API route mismatch

**ID** `apigateway-fix-route-404` · **Source folder** `labs/31_apigateway-fix-route-404/` · **Authored** · **Troubleshoot** · **20 min** · **After** lab 30

- **Starter.** A deployed route with the wrong HTTP method and a known-good handler fixture.
- **Learner task.** Compare the requested method and path with the stage's route configuration. Redeploy the corrected route if the stage requires it.
- **Check and cleanup.** Verify the corrected request returns the expected body. Separately test an unknown path and confirm it still returns a route 404. Destroy the API.

## Amazon VPC

Use a disposable AWS sandbox for real network paths. Provide a managed access path and test clients rather than requiring learners to expose SSH. [AWS VPC infrastructure security](https://docs.aws.amazon.com/vpc/latest/userguide/infrastructure-security.html)

### 32. Read a VPC network layout

**ID** `vpc-first-network` · **Source folder** `labs/32_vpc-first-network/` · **Authored** · **First use** · **20 min** · **After** Orientation

- **Starter.** A pre-provisioned VPC with two subnets and named route tables.
- **Learner task.** Find the VPC CIDR, subnet CIDRs, Availability Zones, and the effective route table for each subnet. Sketch the path from each subnet to its possible destinations.
- **Check and cleanup.** Match subnet and route table IDs and identify which subnet has a route to the internet gateway. Tear down the disposable environment.

### 33. Build public and private subnets

**ID** `vpc-configure-subnets-and-routes` · **Source folder** `labs/33_vpc-configure-subnets-and-routes/` · **Authored** · **Configure** · **35 min** · **After** lab 32

- **Starter.** A VPC CIDR and a Terraform starter for two subnets, an internet gateway, and route tables.
- **Learner task.** Choose non-overlapping CIDRs, associate route tables, and add a default route through the internet gateway for the public subnet. Scope the app security group to the supplied test client.
- **Check and cleanup.** Verify effective routes and run allowed and excluded connectivity probes from the supplied clients. Destroy the test resources and network.

### 34. Restore a blocked VPC request

**ID** `vpc-triage-blocked-connection` · **Source folder** `labs/34_vpc-triage-blocked-connection/` · **Authored** · **Troubleshoot** · **30 min** · **After** lab 33

- **Starter.** A reachable host with a healthy app and a security group missing the rule for the intended client and port.
- **Learner task.** Reproduce the timeout, confirm the app is healthy from the managed access path, inspect routing and rules, and restore the scoped rule.
- **Check and cleanup.** The intended client gets HTTP 200 and the control client still fails. Remove the lab network and compute resources.

## Amazon EC2

Use a disposable AWS sandbox with a supplied AMI and managed access. The learner checks both EC2 status and the application response. [AWS EC2 application status checks](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/application-status-checks.html)

### 35. Launch and inspect an EC2 instance

**ID** `ec2-first-instance` · **Source folder** `labs/35_ec2-first-instance/` · **Authored** · **First use** · **25 min** · **After** lab 32

- **Starter.** A supplied AMI, subnet, scoped security group, and starter instance configuration.
- **Learner task.** Launch an instance and identify its image, instance type, private address, state, and security group. Confirm the instance reaches the expected status through AWS CLI.
- **Check and cleanup.** Verify the expected configuration and successful managed access. Terminate the instance and verify termination.

### 36. Bootstrap a web server with user data

**ID** `ec2-bootstrap-web-server` · **Source folder** `labs/36_ec2-bootstrap-web-server/` · **Authored** · **Configure** · **30 min** · **After** lab 35

- **Starter.** A supplied web server and a user data template with its service configuration incomplete.
- **Learner task.** Complete the bootstrap, launch the instance, and check startup output through the managed access path. Compare EC2 status with the HTTP health endpoint.
- **Check and cleanup.** Verify the expected response from the test client after bootstrap. Terminate the instance and destroy associated lab resources.

### 37. Repair a failed EC2 bootstrap

**ID** `ec2-fix-user-data` · **Source folder** `labs/37_ec2-fix-user-data/` · **Authored** · **Troubleshoot** · **30 min** · **After** lab 36

- **Starter.** An instance whose user data references an incorrect service name, alongside a healthy instance status.
- **Learner task.** Use startup logs to find the failed command. Correct the Terraform user data and replace the instance so bootstrap runs from a clean start.
- **Check and cleanup.** The replacement passes the HTTP probe and startup logs show the service started. Terminate the replacement and verify cleanup.

## Elastic Load Balancing

Use an Application Load Balancer and real targets inside a disposable AWS sandbox. [AWS Application Load Balancer troubleshooting](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html)

### 38. Send a request through a load balancer

**ID** `elb-first-load-balanced-request` · **Source folder** `labs/38_elb-first-load-balanced-request/` · **Authored** · **First use** · **25 min** · **After** lab 35

- **Starter.** A supplied listener, target group, and EC2 application target.
- **Learner task.** Inspect the listener's forwarding action and target health, then send an HTTP request using the load balancer endpoint.
- **Check and cleanup.** Verify the expected response and healthy target. Destroy the load balancer and target resources.

### 39. Route requests by path

**ID** `elb-configure-path-routing` · **Source folder** `labs/39_elb-configure-path-routing/` · **Authored** · **Configure** · **35 min** · **After** lab 38

- **Starter.** Two supplied applications exposing distinguishable responses, plus listener and health-check templates.
- **Learner task.** Configure target groups and route /orders and /status to the intended backends. Set a health-check path for each group.
- **Check and cleanup.** Verify each path returns the intended backend response and the default route handles an unmatched path. Destroy the listener, groups, and targets.

### 40. Fix an unhealthy load balancer target

**ID** `elb-fix-target-health` · **Source folder** `labs/40_elb-fix-target-health/` · **Authored** · **Troubleshoot** · **25 min** · **After** lab 39

- **Starter.** A healthy application with an ALB health check configured for a missing path.
- **Learner task.** Read the target health reason, compare the configured path with the app response, and correct the health check.
- **Check and cleanup.** Wait for the target to become healthy and verify the response through the load balancer. Destroy the stack.

## Amazon RDS

Use a disposable AWS sandbox, temporary database credentials, and a supplied PostgreSQL client inside the VPC. Verify deletion of lab-owned database resources.

### 41. Connect to a managed PostgreSQL database

**ID** `rds-first-database-query` · **Planned folder** `labs/41_rds-first-database-query/` · **Pending** · **First use** · **30 min** · **After** lab 32

- **Starter.** A supplied private RDS instance, sample schema, and temporary credentials passed to the client outside tracked files.
- **Learner task.** Find the endpoint and port, connect from the allowed client, and query the sample records.
- **Check and cleanup.** Verify the returned row and that the instance is configured for private access. Remove the lab instance and verify deletion.

### 42. Scope database access to the app

**ID** `rds-configure-private-access` · **Planned folder** `labs/42_rds-configure-private-access/` · **Pending** · **Configure** · **35 min** · **After** lab 41

- **Starter.** Private subnets in two Availability Zones, two client identities represented by distinct security groups, and a database subnet group starter.
- **Learner task.** Configure the database subnet group and allow PostgreSQL ingress from the app security group. Leave the control client outside the rule.
- **Check and cleanup.** The app client runs a query and the control client cannot connect. Destroy the database and supporting lab resources.

### 43. Restore a timed-out database connection

**ID** `rds-triage-connection-timeout` · **Planned folder** `labs/43_rds-triage-connection-timeout/` · **Pending** · **Troubleshoot** · **30 min** · **After** lab 42

- **Starter.** A healthy database and a test app whose security group is missing from the database ingress rule.
- **Learner task.** Confirm endpoint resolution, database availability, and the network rule. Repair the rule and retry the application query.
- **Check and cleanup.** The app query succeeds and the unrelated client remains blocked. Destroy the database, clients, and lab network.

## Application labs

The applications reuse skills from the service exercises. Supply application code and let the learner own the service configuration.

### 44. Build and debug an order status API

**ID** `app-order-status-api` · **Planned folder** `labs/44_app-order-status-api/` · **Pending** · **Application** · **45 min** · **After** labs 9, 27, and 31

- **Starter.** A small orders handler, a DynamoDB table starter, API Gateway routes, and a seeded wrong table setting.
- **Learner task.** Connect create and read routes to Lambda, scope table access, and trace a failed request from HTTP to a function log before repairing the table setting.
- **Check and cleanup.** Create and retrieve the same order over HTTP, verify its DynamoDB item, and match its request ID to a log entry. Destroy the app stack.

### 45. Trace an event-driven order pipeline

**ID** `app-order-event-pipeline` · **Planned folder** `labs/45_app-order-event-pipeline/` · **Pending** · **Application** · **50 min** · **After** labs 13, 16, 19, and 27

- **Starter.** An EventBridge bus, SNS topic, work and audit SQS queues, and a supplied Lambda worker. Seed a rule that drops the intended event.
- **Learner task.** Connect the fan-out pipeline, repair the rule, and follow a new correlation ID through the audit queue and worker logs.
- **Check and cleanup.** Confirm the audit copy is preserved, the worker processes the expected job, and a control event is excluded. Drain lab messages and destroy the pipeline.

### 46. Restore a web app with a private database

**ID** `app-private-database-web` · **Planned folder** `labs/46_app-private-database-web/` · **Pending** · **Application** · **60 min** · **After** labs 24, 37, 40, and 43

- **Starter.** A disposable VPC, ALB, EC2 application, and private RDS starter. Seed a database connectivity fault and provide recent CloudTrail events.
- **Learner task.** Trace a request from the load balancer to EC2 and the database, use application logs to locate the failing hop, and correlate it with the recorded configuration change.
- **Check and cleanup.** The load balancer returns the expected database-backed response, the unrelated client still cannot connect, and the learner identifies the cause and verifies full teardown.

## How these exercises connect

- **Access to data.** IAM role sessions and S3 object permissions establish how a principal gets scoped access. DynamoDB then introduces application data and key-based reads.
- **Order events.** SQS teaches consumption and failed jobs. SNS adds fan-out and filtering. EventBridge adds routing by event content. These are prerequisites for the planned order processing pipeline.
- **Operational evidence.** CloudWatch gives learners a request ID to follow in logs and a metric to compare with an alarm. The later Lambda and API Gateway exercises reuse both habits.

## Optional playground experiments

Once the guided check passes, have learners predict what a small change will do, try it, and restore their last working configuration.

| Service | Try this |
| --- | --- |
| IAM | Compare the same read made by the starting caller and the assumed role. |
| S3 | Upload a third revision and predict which content each version ID will return. |
| DynamoDB | Reverse the sort order of a query under the same partition key. |
| SQS | Extend the visibility timeout for one receipt and compare when the message reappears. |
| SNS | Allow a second status on the filtered subscription and compare deliveries across both queues. |
| EventBridge | Add another allowed detail type and send a matched and unmatched event. |
| CloudWatch | Change the alarm threshold, publish the same value again, and compare the outcome. |
