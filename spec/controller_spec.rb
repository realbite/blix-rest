require 'spec_helper'
require 'test_controllers'

CONTENT_TYPE      = 'Content-Type'
CONTENT_TYPE_JSON = 'application/json'
CONTENT_TYPE_HTML = 'text/html'
CONTENT_TYPE_XML  = 'application/xml'
ACCEPT = "HTTP_ACCEPT"


    
module Blix::Rest
  
  class TestController < Controller
    
    attr_accessor :name, :title
    
    def initialize
      
    end
    
    def logmessage(msg)
      logger.info msg
    end
    
  end
  
  describe Controller do
    
    it "should set the erb_base" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      File.exist?( File.join(Controller.erb_root,"test1.html.erb")).should == true
    end
   
    it "should render the template" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = TestController.new
      t.name = "joe"
      t.render_erb("test1").should == "hello joe"
    end
    
    it "should render a layout" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = TestController.new
      t.name = "joe"
      #t.render_erb("layout1", :layout=>"layout1").should == "the title is hello joe to you."
      t.render_erb("test1", :layout=>"layout1").should == "the title is hello joe to you."
    end
    
    it "should render a partial" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = TestController.new
      t.name = "joe"
      t.title = "selection page"
      #t.render_erb("layout1", :layout=>"layout1").should == "the title is hello joe to you."
      t.render_erb("partial1").should == "the page is selection page and hello joe is the content"
    end
    
    it "should render with locals" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = TestController.new
      #t.render_erb("layout1", :layout=>"layout1").should == "the title is hello joe to you."
      t.render_erb("partial2", :locals=>{:name=>"joe",:title => "selection page"}).should == "the page is selection page and hello joe is the content"
    end
    
    it "should render a partial within a layout" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = TestController.new
      t.name = "joe"
      t.title = "selection page"
      #t.render_erb("layout1", :layout=>"layout1").should == "the title is hello joe to you."
      t.render_erb("partial1", :layout=>"layout1").should == "the title is the page is selection page and hello joe is the content to you."
    end
    
    it "should log messages" do
      file = Tempfile.new("LOGGER")
      logger = Logger.new(file)
      Blix::Rest.logger = logger
      
      t = TestController.new
      t.logmessage("one")
      t.logmessage("two")
      t.logmessage("three")
      logger.close
      file.close
      file.open
      str = file.read
      expect(str).to include "one"
      expect(str).to include "two"
      expect(str).to include "three"
      
      puts file.path
      puts str
      file.close
      file.unlink
    end
    
    it "should calculate the full_path" do
      t = TestController.new
      expect(t.full_path('/') ).to eq '/'
      expect(t.full_path('') ).to eq '/'
      expect(t.full_path('xxx') ).to eq '/xxx'
      expect(t.full_path('/foo') ).to eq '/foo'
      
      RequestMapper.set_path_root('assets')
      t = TestController.new
      expect(t.full_path('/') ).to eq '/assets/'
      expect(t.full_path('') ).to eq '/assets/'
      expect(t.full_path('xxx') ).to eq '/assets/xxx'
      expect(t.full_path('/foo') ).to eq '/assets/foo'
      
      RequestMapper.set_path_root('/assets/')
      t = TestController.new
      expect(t.full_path('/') ).to eq '/assets/'
      expect(t.full_path('') ).to eq '/assets/'
      expect(t.full_path('xxx') ).to eq '/assets/xxx'
      expect(t.full_path('/foo') ).to eq '/assets/foo'
    end
    
  end
  
end