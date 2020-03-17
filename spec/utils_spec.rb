require 'blix/utils'

module Blix

  describe YamlConfig do

    it "should find a config file" do

      expect{YamlConfig.new( :name=>'xxx') }.to raise_error YamlConfig::ConfigError
      expect{YamlConfig.new( :file=>'resources/test1.yml') }.to raise_error YamlConfig::ConfigError
      expect{YamlConfig.new( :production, :file=>'resources/test1.yml') }.to raise_error YamlConfig::ConfigError
      expect{YamlConfig.new( :development, :file=>'resources/test1.yml') }.not_to raise_error


      c= YamlConfig.new( :development, :file=>'resources/test1.yml')
      c["status"].should == "extra"
      c[:status].should == "extra"
    end


  end

  describe "normalize" do
    it "should remove special characters" do
      expect("asûass".to_ascii).to eq "asuass".to_ascii
    end
  end

end
