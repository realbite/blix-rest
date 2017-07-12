$:.unshift 'lib'

require 'blix/assets'

CONFIG_DIR = "/tmp/blix_assets"

RSpec.configure do |config|

  config.before(:each) do
    Blix::AssetManager.cache.clear
    Blix::AssetManager.config_dir = nil
    
    Dir.mkdir(CONFIG_DIR) rescue nil
    Dir.new(CONFIG_DIR).each{|file| File.unlink(File.join(CONFIG_DIR,file)) if File.file?(File.join(CONFIG_DIR,file))}
    expect(Dir.entries(CONFIG_DIR).length).to eq 2
  end
  
  config.after(:each) do
    
  end
  

end


module Blix
  describe AssetManager do
    
    it "should have defaults" do
      a = AssetManager
      expect(a.config_dir).to eq "config/assets"
    end
    
    it "should make file stamp" do
      s = AssetManager.get_filestamp
      expect(s.length).to be > 6
    end
    
  
    it "should get/set a config file" do
      a = AssetManager
      AssetManager.config_dir = CONFIG_DIR
      expect(a.config_dir).to eq CONFIG_DIR
  
      
      expect(a.get_config("foo.js")).to eq nil
      expect(a.set_config("foo.js","111","sss")).to be true
      expect(a.get_config("foo.js")).to eq( {:hash=>"111",:stamp=>"sss"} )
      
      expect(a.get_asset_name("foo.js")).to eq "foo-sss.js"
      
      File.unlink(File.join(CONFIG_DIR,"foo.js"))
      
      expect(a.get_asset_name("foo.js")).to eq "foo-sss.js"   # from cache !!
      
      AssetManager.cache.clear
      
      expect{a.get_asset_name("foo.js")}.to raise_error RuntimeError
      
    end
    
    it "should update an asset " do
      
      a = AssetManager
      AssetManager.config_dir = CONFIG_DIR
      expect(a.config_dir).to eq CONFIG_DIR
      
      done = false
      name1 = nil
      a.if_modified("bar.js" ,"var a=1") do |c|
        expect(c.oldname).to eq nil
        expect(c.newname).to match /^bar\-(\w*)\.js$/
        name1 = c.newname
        done = true
      end
      expect(done).to eq true
      
      done = false
      a.if_modified("bar.js" ,"var a=1") do |c|
        done = true
      end
      expect(done).to eq false
      
      done = false
      name2 = nil
      a.if_modified("bar.js" ,"var a=2") do |c|
        expect(c.oldname).to eq name1
        expect(c.newname).to match /^bar\-(\w*)\.js$/
        expect(c.newname).not_to eq name1
        done = true
      end
      expect(done).to eq true

    end
    
  end
end