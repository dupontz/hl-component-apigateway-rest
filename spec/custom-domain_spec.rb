require 'yaml'

describe 'compiled component' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/custom-domain.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/custom-domain/apigateway-rest.compiled.yaml") }

  context 'Resource RestApi' do
    let(:properties) { template["Resources"]["RestApi"]["Properties"] }

    it 'has property Name and Description' do
      expect(properties["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}"})
      expect(properties["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName} - Rest Api"})
    end

    it 'has property FailOnWarnings' do
      expect(properties["FailOnWarnings"]).to eq(true)
    end

    it 'has property Tags' do
      expect(properties["Tags"]).to eq([
        {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, 
        {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
    end

  end

  context 'Resource Custom Domain' do
    let(:properties) { template["Resources"]["CustomDomain"]["Properties"] }

    it 'has properties' do
        expect(properties).to eq({
            "CertificateArn" => {"Fn::If"=>["HasEdgeCertificateArn", {"Ref"=>"EdgeCertificateArn"}, {"Ref"=>"AWS::NoValue"}]},
            "DomainName" => {"Fn::Sub"=>"api.${EnvironmentName}.${DnsDomain}"},
            "RegionalCertificateArn" => {"Fn::If"=>["HasRegionalCertificateArn", {"Ref"=>"RegionalCertificateArn"}, {"Ref"=>"AWS::NoValue"}]},
            "SecurityPolicy" => "TLS_1_2",
            "Tags" => [{"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}],
        })
    end
  end

  context 'Resource Base Path Mapping' do
    let(:properties) { template["Resources"]["BasePathMapping"]["Properties"] }

    it 'has properties' do
        expect(properties).to eq({
            "BasePath" => "api",
            "DomainName" => {"Ref"=>"CustomDomain"},
            "RestApiId" => {"Ref"=>"RestApi"},
            "Stage" => {"Ref"=>"RestApiStage"},
        })
    end
  end
end