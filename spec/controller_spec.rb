require 'spec_helper'
require 'test_controllers'

CONTENT_TYPE      = 'Content-Type'
CONTENT_TYPE_JSON = 'application/json'
CONTENT_TYPE_HTML = 'text/html'
CONTENT_TYPE_XML  = 'application/xml'
ACCEPT = "HTTP_ACCEPT"



module Blix::Rest

  class BaseController < Controller

    attr_accessor :name, :title, :out

    def initialize
      @out =String.new
    end

    def logmessage(msg)
      logger.info msg
    end

    def echo(str)
      @out << str
      @out
    end

  end

  class NewController < BaseController

  end



  describe Controller do

    it "should set the erb_base" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      File.exist?( File.join(Controller.erb_root,"test1.html.erb")).should == true
    end

    it "should render the template" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = BaseController.new
      t.name = "joe"
      t.render_erb("test1").should == "hello joe"
    end

    it "should render a layout" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = BaseController.new
      t.name = "joe"
      #t.render_erb("layout1", :layout=>"layout1").should == "the title is hello joe to you."
      t.render_erb("test1", :layout=>"layout1").should == "the title is hello joe to you."
    end

    it "should render a partial" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = BaseController.new
      t.name = "joe"
      t.title = "selection page"
      #t.render_erb("layout1", :layout=>"layout1").should == "the title is hello joe to you."
      t.render_erb("partial1").should == "the page is selection page and hello joe is the content"
    end

    it "should render with locals" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = BaseController.new
      #t.render_erb("layout1", :layout=>"layout1").should == "the title is hello joe to you."
      t.render_erb("partial2", :locals=>{:name=>"joe",:title => "selection page"}).should == "the page is selection page and hello joe is the content"
    end

    it "should render a partial within a layout" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = BaseController.new
      t.name = "joe"
      t.title = "selection page"
      t.render_erb("partial1", :layout=>"layout1").should == "the title is the page is selection page and hello joe is the content to you."
    end

    it "should render a partial with locals within a layout" do
      Controller.set_erb_root File.expand_path File.join( File.dirname(__FILE__),'../resources')
      t = BaseController.new
      t.render_erb("partial2", :layout=>"layout1", :locals=>{:name=>"joe",:title => "selection page"}).should == "the title is the page is selection page and hello joe is the content to you."
    end

    it "should log messages" do
      file = Tempfile.new("LOGGER")
      logger = Logger.new(file)
      Blix::Rest.logger = logger

      t = BaseController.new
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
      t = BaseController.new
      expect(t.full_path('/') ).to eq '/'
      expect(t.full_path('') ).to eq '/'
      expect(t.full_path('xxx') ).to eq '/xxx'
      expect(t.full_path('/foo') ).to eq '/foo'

      RequestMapper.set_path_root('assets')
      t = BaseController.new
      expect(t.full_path('/') ).to eq '/assets/'
      expect(t.full_path('') ).to eq '/assets/'
      expect(t.full_path('xxx') ).to eq '/assets/xxx'
      expect(t.full_path('/foo') ).to eq '/assets/foo'

      RequestMapper.set_path_root('/assets/')
      t = BaseController.new
      expect(t.full_path('/') ).to eq '/assets/'
      expect(t.full_path('') ).to eq '/assets/'
      expect(t.full_path('xxx') ).to eq '/assets/xxx'
      expect(t.full_path('/foo') ).to eq '/assets/foo'
    end

    it "should allow erb path to be set" do
      expect(BaseController.__erb_path).to be_nil
      BaseController.erb_dir "xxx/yyy"
      expect(BaseController.__erb_path).to eq "xxx/yyy"
    end

    it "should  perform before/after hooks" do

      BaseController.before{ echo("hello") }
      t = BaseController.new
      t.__before
      expect(t.out).to eq "hello"

      BaseController.after{ echo(" there")}
      t.__after
      expect(t.out).to eq "hello there"



      NewController.before do
        echo(" again")
      end
      n = NewController.new
      n.__before

      expect(n.out).to eq "hello again"

      NewController.include SpecialStuff
      n = NewController.new
      n.__before
      expect(n.out).to eq "hello againspecial"
    end

    it "should modify path/options in route hook" do
      #RequestMapper.reset
      BaseController.before_route{|r| r.path.prepend("/foo"); r.options[:foo]='bar'; r.verb.replace('PUT') }
      BaseController.route('GET','/admin',{:accept=>:html}){}
      l = RequestMapper.locations["GET"][-1]
      expect(l[0]).to eq 'GET'
      expect(l[1]).to eq 'foo/admin'
      expect(l[2]).to eq( {:accept=>:html, :foo=>'bar'})

      NewController.before_route{|r| r.path.prepend("/new"); r.options[:xxx]='yyy' }
      NewController.route('GET','/orders',{:accept=>:json}){}
      l = RequestMapper.locations["GET"][-1]
      expect(l[0]).to eq 'GET'
      expect(l[1]).to eq 'new/foo/orders'
      expect(l[2]).to eq( {:accept=>:json, :foo=>'bar', :xxx=>'yyy'})


      NewController.before_route{|r| r.path_prefix("/other"); r.default_option(:yyy,'zzz') }
      NewController.route('GET','/orders',{:accept=>:json}){}
      l = RequestMapper.locations["GET"][-1]
      expect(l[0]).to eq 'GET'
      expect(l[1]).to eq 'other/foo/orders'
      expect(l[2]).to eq( {:accept=>:json, :foo=>'bar', :yyy=>'zzz'})

      BaseController.before_route(){1}
      NewController.before_route(){1}
    end

  end

end
