CfhighlanderTemplate do

  Name 'apigateway-rest'
  Description "#{component_name} - #{component_version} - (#{template_name}@#{template_version})"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    ComponentParam 'DnsDomain', description: 'the root DNS Name'
    ComponentParam 'EdgeCertificateArn', description: 'the EDGE Cert Arn'
    ComponentParam 'RegionalCertificateArn', description: 'the REGIONAL Cert Arn'
    ComponentParam 'NetworkLoadBalander', '', description: 'The NLB to use for a vpc private link'
  end

end