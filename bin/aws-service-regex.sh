#!/usr/bin/env bash
service=${1:?Missing service 
AMAZON
AMAZON_APPFLOW
AMAZON_CONNECT
API_GATEWAY
CHIME_MEETINGS
CHIME_VOICECONNECTOR
CLOUD9
CLOUDFRONT
CLOUDFRONT_ORIGIN_FACING
CODEBUILD
DYNAMODB
EBS
EC2
EC2_INSTANCE_CONNECT
GLOBALACCELERATOR
KINESIS_VIDEO_STREAMS
MEDIA_PACKAGE_V2
ROUTE53
ROUTE53_HEALTHCHECKS
ROUTE53_HEALTHCHECKS_PUBLISHING
ROUTE53_RESOLVER
S3
WORKSPACES_GATEWAYService name}
region=${2:-us-east-1}
echo Generating IP network range for $service in $region
curl -sSL https://ip-ranges.amazonaws.com/ip-ranges.json | \
  jq -r '.prefixes[] | select(.service=="'$service'") | select(.region =="'$region'") | .ip_prefix' | \
  sed -E 's/^([0-9]*)\.([0-9]*)\..*/\1\\\.\2|/' | \
  tr -d "\n" | \
  sed -e 's/^/^(/' -e 's/|$/)\\\./'
