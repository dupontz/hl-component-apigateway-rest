require 'yaml'

describe 'compiled component' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/api-body.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/api-body/apigateway-rest.compiled.yaml") }

  context 'Resource RestApi' do
    let(:properties) { template["Resources"]["RestApi"]["Properties"] }

    it 'has property Name and Description' do
      expect(properties["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}"})
      expect(properties["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName} - Rest Api"})
    end

    it 'has property FailOnWarnings' do
      expect(properties["FailOnWarnings"]).to eq(true)
    end

    it 'has property Body' do
      expect(properties["Body"]["Fn::Sub"]).to include("title: API Gateway OpenAPI Example")
    end

    it 'has property Tags' do
      expect(properties["Tags"]).to eq([
        {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, 
        {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
    end

  end
end