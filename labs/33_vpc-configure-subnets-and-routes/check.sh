#!/usr/bin/env bash
set -euo pipefail
source "${LAB_SOURCE_DIR:?}/../../scripts/sandbox.sh"
export AWS_PAGER="" AWS_DEFAULT_OUTPUT=json

public=$(terraform output -json public_subnets | jq -r '.[0]')
private=$(terraform output -json private_subnets | jq -r '.[0]')
pub_rt=$(terraform output -raw public_route_table)
priv_rt=$(terraform output -raw private_route_table)
gateway=$(terraform output -raw gateway)
aws ec2 describe-route-tables --route-table-ids "$pub_rt" "$priv_rt" |
  jq -e --arg pub "$public" --arg priv "$private" --arg public_rt "$pub_rt" --arg private_rt "$priv_rt" --arg igw "$gateway" '
    (.RouteTables | map(select(.RouteTableId == $public_rt))[0]) as $a |
    (.RouteTables | map(select(.RouteTableId == $private_rt))[0]) as $b |
    any($a.Associations[]; .SubnetId == $pub) and
    any($a.Routes[]; .DestinationCidrBlock == "0.0.0.0/0" and .GatewayId == $igw and .State == "active") and
    any($b.Associations[]; .SubnetId == $priv) and
    all($b.Routes[]; .DestinationCidrBlock != "0.0.0.0/0")' >/dev/null
aws ec2 describe-subnets --subnet-ids "$public" "$private" |
  jq -e '[.Subnets[].CidrBlock] | sort == ["10.42.0.0/24","10.42.10.0/24"]' >/dev/null
echo "Verified subnet CIDRs, route table associations, and the public internet route."
aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$(terraform output -raw app_sg)" |
  jq -e --arg client "$(terraform output -raw client_sg)" '
    [.SecurityGroupRules[] | select(.IsEgress | not)] |
    length == 1 and .[0].IpProtocol == "tcp" and .[0].FromPort == 8080 and .[0].ToPort == 8080 and .[0].ReferencedGroupInfo.GroupId == $client' >/dev/null
echo "Only the client security group is allowed to connect to the app on TCP 8080."
