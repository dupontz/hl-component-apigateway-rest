# Rest Api Gateway CfHighlander component

## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |
| EnvironmentName | Tagging | dev | true | String
| EnvironmentType | Tagging | development | true | String | ['development','production']
| DomainName | The fully qualified domain name (FQDN), such as www.example.com, with which you want to secure an ACM certificate | | false | string
| EdgeCertificateArn | The ACM cert ARN created in us-east-1 | | false | String
| RegionalCertificateArn | The regional ACM cert ARN | | false | String
| NetworkLoadBalander | The ARN of a NLB for creating a VPC Link for this API Gateway | | false | String

## Outputs/Exports

| Name | Value | Exported |
| ---- | ----- | -------- |
| RestApiId | RestApiId | true
| RestApiStage | RestApiStage | true

## Config Examples

TODO
 