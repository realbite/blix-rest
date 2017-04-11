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
    
    it "should render a partial within a layout" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = TestController.new
      t.name = "joe"
      t.title = "selection page"
      #t.render_erb("layout1", :layout=>"layout1").should == "the title is hello joe to you."
      t.render_erb("partial1", :layout=>"layout1").should == "the title is the page is selection page and hello joe is the content to you."
    end
    
  end
  
end