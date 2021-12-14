CloudFormation do

  tags = external_parameters.fetch(:tags, {})
  default_tags = []
  default_tags.push({ Key: 'Environment', Value: Ref(:EnvironmentName) })
  default_tags.push({ Key: 'EnvironmentType', Value: Ref(:EnvironmentType) })
  default_tags.push(*tags.map {|k,v| {Key: FnSub(k), Value: FnSub(v)}})

  custom_dns = external_parameters.fetch(:custom_dns, 'false')

  Condition(:VpcPrivateLink, FnNot(FnEquals(Ref(:NetworkLoadBalander),'')))
  Condition(:HasEdgeCertificateArn, FnNot(FnEquals(Ref(:EdgeCertificateArn),'')))
  Condition(:HasRegionalCertificateArn, FnNot(FnEquals(Ref(:RegionalCertificateArn),'')))
  Condition(:HasDomainName, FnEquals(custom_dns,'true'))

  ApiGateway_VpcLink(:VpcLink) {
    Condition(:VpcPrivateLink)
    Name FnSub("${EnvironmentName}")
    Description FnSub("${EnvironmentName} api gateway vpc link")
    TargetArns [Ref(:NetworkLoadBalander)]
  }

  security_policy = external_parameters.fetch(:security_policy, 'TLS_1_2')
  custom_dns_prefix = external_parameters.fetch(:custom_dns_prefix, 'api')
  endpoint_configuration = external_parameters.fetch(:endpoint_configuration, {})

  ApiGateway_DomainName(:CustomDomain) {
    Condition(:HasDomainName)
    CertificateArn FnIf('HasEdgeCertificateArn', Ref(:EdgeCertificateArn), Ref('AWS::NoValue'))
    DomainName FnSub("#{custom_dns_prefix}.${EnvironmentName}.${DnsDomain}")
    EndpointConfiguration {
      Types endpoint_configuration['types']
    } unless endpoint_configuration.empty?
    RegionalCertificateArn FnIf('HasRegionalCertificateArn', Ref(:RegionalCertificateArn), Ref('AWS::NoValue'))
    SecurityPolicy security_policy
    Tags default_tags
  }
  
  Route53_RecordSet(:RegionalDNSRecord) {
    Condition(:HasRegionalCertificateArn)
    HostedZoneName FnSub("${EnvironmentName}.${DnsDomain}.")
    Name FnSub("#{custom_dns_prefix}.${EnvironmentName}.${DnsDomain}.")
    Type 'CNAME'
    TTL '60'
    ResourceRecords [ FnGetAtt('CustomDomain','RegionalDomainName') ]
  }

  Route53_RecordSet(:EdgeDNSRecord) {
    Condition(:HasEdgeCertificateArn)
    HostedZoneName FnSub("${EnvironmentName}.${DnsDomain}.")
    Name FnSub("#{custom_dns_prefix}.${EnvironmentName}.${DnsDomain}.")
    Type 'CNAME'
    TTL '60'
    ResourceRecords [ FnGetAtt('CustomDomain','DistributionDomainName') ]
  }

  api_name = external_parameters.fetch(:api_name, '${EnvironmentName}')
  api_description = external_parameters.fetch(:api_description, '${EnvironmentName} - Rest Api')
  api_key_source_type = external_parameters.fetch(:api_key_source_type, nil)
  binary_media_types = external_parameters.fetch(:binary_media_types, nil)
  body_s3_location = external_parameters.fetch(:body_s3_location, nil)
  fail_on_warnings = external_parameters.fetch(:fail_on_warnings, true)
  minimum_compression_size = external_parameters.fetch(:minimum_compression_size, nil)
  header_parameters = external_parameters.fetch(:header_parameters, nil)
  endpoint_configuration = external_parameters.fetch(:endpoint_configuration, {})

  api_path_prefix = external_parameters.fetch(:api_path_prefix, nil)

  api_body_file = external_parameters.fetch(:api_body_file, '')
  if File.exists?(api_body_file)
    api_body = File.read(api_body_file)
  else
    api_body = nil
  end

  stage_name = external_parameters.fetch(:stage_name, 'default')
  stage_variables = external_parameters.fetch(:stage_variables, nil)

  # if !api_body.nil? && !body_s3_location.nil?
  #   raise "Set either api_body or body_s3_location"
  # end

  ApiGateway_RestApi(:RestApi) {
    Name FnSub("#{api_name}")
    Description FnSub("#{api_description}")
    ApiKeySourceType FnSub(api_key_source_type) unless api_key_source_type.nil?
    BinaryMediaTypes binary_media_types unless binary_media_types.nil?
    Body api_body unless api_body.nil?
    BodyS3Location({
      Bucket: FnSub(body_s3_location['bucket']),
      Key: FnSub(body_s3_location['key'])
    }) unless body_s3_location.nil?
    EndpointConfiguration {
      Types endpoint_configuration['types']
    } unless endpoint_configuration.empty?
    FailOnWarnings fail_on_warnings
    MinimumCompressionSize minimum_compression_size unless minimum_compression_size.nil?
    Parameters header_parameters unless header_parameters.nil?
    Tags default_tags
  }

  Output(:RestApiId) {
    Value(Ref(:RestApi))
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-RestApiId")
  }

  ApiGateway_Deployment(:RestApiDeployment) {
    Description FnSub("#{api_description}")
    RestApiId Ref(:RestApi)
  }

  ApiGateway_Stage(:RestApiStage) {
    RestApiId Ref(:RestApi)
    StageName FnSub("#{stage_name}")
    DeploymentId Ref(:RestApiDeployment)
    Variables stage_variables unless stage_variables.nil?
    Tags default_tags
  }

  Output(:RestApiStage) {
    Value(Ref(:RestApiStage))
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-RestApiStage")
  }

  ApiGateway_BasePathMapping(:BasePathMapping) {
    Condition(:HasDomainName)
    BasePath api_path_prefix unless api_path_prefix.nil?
    DomainName Ref(:CustomDomain)
    RestApiId Ref(:RestApi)
    Stage Ref(:RestApiStage)
  }

  api_key = external_parameters.fetch(:api_key, {})
  if !api_key.empty?
    ApiGateway_ApiKey(:ApiKey) {
      Name FnSub('${EnvironmentName}')
      Description FnSub('${EnvironmentName} API Key')
      Enabled true
      Value api_key['key_value']
      StageKeys [{
        RestApiId: Ref(:RestApi),
        StageName: Ref(:RestApiStage)
      }]
      Tags default_tags
    }

    throttle_settings = api_key['throttle_settings'].transform_keys {|k| k.split('_').collect(&:capitalize).join }
    quota = api_key['quota']
    quota = quota.transform_keys {|k| k.split('_').collect(&:capitalize).join } unless quota.nil?
    ApiGateway_UsagePlan(:UsagePlan) {
      UsagePlanName FnSub("${EnvironmentName}")
      Throttle throttle_settings unless throttle_settings.nil?
      Quota quota unless quota.nil?
      ApiStages [{
        ApiId: Ref(:RestApi),
        Stage: Ref(:RestApiStage)
      }]
      Tags default_tags
    }

    ApiGateway_UsagePlanKey(:UsagePlanKey) {
      KeyId Ref(:ApiKey)
      KeyType 'API_KEY'
      UsagePlanId Ref(:UsagePlan)
    }
  end

end

