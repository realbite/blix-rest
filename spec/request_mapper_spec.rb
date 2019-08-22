require 'spec_helper'

module Blix::Rest

  describe RequestMapper do

    GET  = "GET"
    POST = "POST"
    PUT  = "PUT"
    DELETE = "DELETE"

    before(:all) do
      @_save = RequestMapper.reset
    end

    after(:all) do
      RequestMapper.reset(@_save)
    end

    before(:each) do
      RequestMapper.reset
    end

    it "should register a path" do
      RequestMapper.locations["GET"].length.should == 0
      RequestMapper.add_path("GET","/welcome",{:foo=>:bar}) do
        "hello there"
      end
      RequestMapper.locations["GET"].length.should == 1
      RequestMapper.locations["POST"].length.should == 0
    end

    it "should parse a one element path" do
      blk = lambda{"hello there"}
      RequestMapper.add_path("GET","/welcome",{:foo=>:bar},&blk)

      RequestMapper.match(GET,"").should == [nil,{},nil]
      RequestMapper.match(GET,"/").should == [nil,{},nil]
      RequestMapper.match(GET,"/xxx").should == [nil,{},nil]
      RequestMapper.match(GET,"/welcome").should == [blk,{},{:foo=>:bar}]
      RequestMapper.match(GET,"/welcome")[0].call.should == "hello there"
      RequestMapper.match(POST,"/welcome").should == [nil,{},nil]
    end

    it "should parse a path with a variable" do
      blk = lambda{|params| "item:#{params[:id]}"}

      RequestMapper.add_path(GET,"/products/:id",{},&blk)
      RequestMapper.match(GET,"/products").should == [nil,{},nil]
      RequestMapper.match(GET,"/products/").should == [nil,{},nil]
      RequestMapper.match(GET,"/products/xxx").should == [blk,{"id"=>"xxx"},{}]
      RequestMapper.process(GET,"/products/xxx").should == "item:xxx"
      RequestMapper.match(GET,"/other/").should == [nil,{},nil]
      RequestMapper.match(POST,"/products/xxx").should == [nil,{},nil]
    end

    it "should parse a path with multiple variables" do
      blk = lambda{|params| "item:#{params[:prod_id]}/user:#{params[:user_id]}"}
      RequestMapper.add_path(GET,"/products/:prod_id/user/:user_id/clear",{},&blk)

      RequestMapper.process(GET,"/products/1234/user/9999/clear").should == "item:1234/user:9999"
      RequestMapper.process(GET,"/products/1234/user/9999").should == nil

    end

    it "should parse the root path" do
      blk = lambda{|params| "list:#{params.to_s}"}
      RequestMapper.add_path(GET,"/",{},&blk)
      RequestMapper.process(GET,"/").should == "list:{}"
      RequestMapper.process(GET,"/cc").should == nil
      RequestMapper.process(GET,"").should == "list:{}"
    end

    it "should parse multiple paths" do
      blk = lambda{|params| "list:#{params.to_s}"}

      RequestMapper.add_path(GET,"/products/:prod_id/user/:user_id/clear",{},&blk)
      RequestMapper.add_path(GET,"/products",{},&blk)
      RequestMapper.add_path(GET,"/products/:prod_id",{},&blk)
      RequestMapper.add_path(GET,"/products/:prod_id/user",{},&blk)
      RequestMapper.add_path(GET,"/products/:prod_id/user/:user_id",{},&blk)
      #RequestMapper.add_path(GET,"/",{},&blk)

      RequestMapper.process(GET,"/products").should == "list:{}"
      RequestMapper.process(GET,"/products/1234").should == 'list:{"prod_id"=>"1234"}'
      RequestMapper.process(GET,"/products/1234/user").should == 'list:{"prod_id"=>"1234"}'
      RequestMapper.process(GET,"/products/1234/user/9999").should == 'list:{"prod_id"=>"1234", "user_id"=>"9999"}'
      RequestMapper.process(GET,"/products/1234/user/9999/clear").should == 'list:{"prod_id"=>"1234", "user_id"=>"9999"}'


    end

    it "should raise error if different wild cards are used for same section" do
      blk = lambda{|params| ""}
      RequestMapper.add_path(GET,"/products/:prod_id/user/:user_id/clear",{},&blk)
      RequestMapper.add_path(GET,"/products/:prod_id/user/:other_id/clear",{},&blk)
      lambda{RequestMapper.table}.should raise_error RequestMapperError
      #RequestMapper.table
    end

    it "should raise error if elements added after wildpath" do
      blk = lambda{|params| ""}
      RequestMapper.add_path(GET,"/aaa/*/bbb",{},&blk)
      lambda{RequestMapper.table}.should raise_error RequestMapperError
    end

    it "should be fast" do
      blk = lambda{|params| "list:#{params.to_s}"}
      RequestMapper.add_path(GET,"/products/:prod_id/user/:user_id/clear",{},&blk)
      t = Time.now
      count = 10000
      count.times do
        RequestMapper.process(GET,"/products/1234/user/9999/clear")
      end
      d = ((Time.now-t)*1000000/count).to_i
      puts "#{d} micro seconds per lookup"
      d.should < 100
    end

    it "should detect the format" do
      blk = lambda{|params| params}
      RequestMapper.add_path(GET,"/products/:prod_id/user",{},&blk)

      RequestMapper.process(GET,"/products/1234/user").should == {"prod_id"=>"1234"}
      RequestMapper.process(GET,"/products/1234/user.json").should == {"prod_id"=>"1234", "format"=>:json}
      RequestMapper.process(GET,"/products.html/1234/user.xxx").should == {"prod_id"=>"1234", "format"=>:xxx}
      RequestMapper.process(GET,"/products.html/1234/user.jsonx").should == {"prod_id"=>"1234", "format"=>:jsonx}

      RequestMapper.add_path(GET,"/others/:other_id/*",{},&blk)
      RequestMapper.process(GET,"/others/1234/other").should == {"other_id"=>"1234", "wildpath"=>"/other"}
      RequestMapper.process(GET,"/others/1234/other.json").should == {"other_id"=>"1234", "format"=>:json, "wildpath"=>"/other"}
      RequestMapper.process(GET,"/others/1234/zzz/other.json").should == {"other_id"=>"1234", "format"=>:json, "wildpath"=>"/zzz/other"}

    end

    it "should set the path root" do
      RequestMapper.path_root.should == '/'
      RequestMapper.set_path_root(nil)
      RequestMapper.path_root.should == '/'
      RequestMapper.set_path_root('/')
      RequestMapper.path_root.should == '/'
      RequestMapper.set_path_root('a')
      RequestMapper.path_root.should == '/a/'
      RequestMapper.set_path_root('b/c/d')
      RequestMapper.path_root.should == '/b/c/d/'
      RequestMapper.set_path_root('x/y/z/')
      RequestMapper.path_root.should == '/x/y/z/'
      RequestMapper.reset
      RequestMapper.path_root.should == '/'

    end

    it "should allow a path root" do
      blk = lambda{|params| "list:#{params.to_s}"}
      RequestMapper.add_path(GET,"/",{},&blk)
      RequestMapper.process(GET,"/").should == "list:{}"
      RequestMapper.set_path_root("/")
      RequestMapper.process(GET,"/").should == "list:{}"
      RequestMapper.set_path_root("/a/b/c/")
      RequestMapper.process(GET,"/").should == nil
      RequestMapper.process(GET,"/a/b/c/").should == "list:{}"
      RequestMapper.set_path_root("abc")
      RequestMapper.path_root.should == "/abc/"
      RequestMapper.process(GET,"abc").should == "list:{}"
    end



    it "should document the paths" do
      blk = lambda{|params| "list:#{params.to_s}"}
      RequestMapper.add_path(GET,"/",{},&blk)
      RequestMapper.add_path(POST,"/",{},&blk)
      RequestMapper.add_path(GET,"/users",{},&blk)
      RequestMapper.add_path(POST,"/users",{},&blk)
      RequestMapper.add_path(GET,"/users/:user_id",{},&blk)
      RequestMapper.add_path(PUT,"/users/:user_id",{},&blk)
      RequestMapper.add_path(DELETE,"/users/:user_id",{},&blk)
      RequestMapper.add_path(GET,"/users/:user_id/comments",{},&blk)
      puts RequestMapper.routes
    end

    it "should recompile if path id redefined" do
      blk1 = lambda{|params| "foo"}
      blk2 = lambda{|params| "bar"}
      RequestMapper.add_path(GET,"/a/b/c",{},&blk1)
      RequestMapper.add_path(PUT,"/a/b/c",{},&blk1)
      RequestMapper.add_path(GET,"/d/e/f",{},&blk1)
      RequestMapper.process(GET,"/a/b/c").should == "foo"
      RequestMapper.add_path(GET,"/a/b/c",{},&blk2)
      RequestMapper.process(GET,"/a/b/c").should == "bar"
      RequestMapper.process(GET,"/d/e/f").should == "foo"
    end

    it "should allow a wild card in the path" do
      blk = lambda{|params| "list:#{params.to_s}"}
      RequestMapper.add_path(GET,"/aaa",{},&blk)
      RequestMapper.add_path(GET,"/aaa/*",{},&blk)
      RequestMapper.add_path(GET,"/bbb/ccc",{},&blk)
      RequestMapper.add_path(GET,"/aaa/aaa",{},&blk)
      RequestMapper.add_path(GET,"*",{},&blk)
      RequestMapper.process(GET,"/aaa").should == "list:{}"
      RequestMapper.process(GET,"/aaa/bbb").should == 'list:{"wildpath"=>"/bbb"}'
      RequestMapper.process(GET,"/aaa/aaa").should == "list:{}"
      RequestMapper.process(GET,"/zzz/yyyy/xxx").should == 'list:{"wildpath"=>"/zzz/yyyy/xxx"}'
      RequestMapper.process(GET,"/xxx").should == 'list:{"wildpath"=>"/xxx"}'
      RequestMapper.process(GET,"/").should == 'list:{"wildpath"=>"/"}'
    end

    it "should allow a named wild card in the path" do
      blk = lambda{|params| "list:#{params.to_s}"}
      RequestMapper.add_path(GET,"/aaa",{},&blk)
      RequestMapper.add_path(GET,"/aaa/*zzz",{},&blk)
      RequestMapper.add_path(GET,"/bbb/ccc",{},&blk)
      RequestMapper.add_path(GET,"/aaa/aaa",{},&blk)
      RequestMapper.add_path(GET,"*fullpath",{},&blk)
      RequestMapper.process(GET,"/aaa").should == "list:{}"
      RequestMapper.process(GET,"/aaa/bbb").should == 'list:{"zzz"=>"/bbb"}'
      RequestMapper.process(GET,"/aaa/aaa").should == "list:{}"
      RequestMapper.process(GET,"/zzz/yyyy/xxx").should == 'list:{"fullpath"=>"/zzz/yyyy/xxx"}'
      RequestMapper.process(GET,"/xxx").should == 'list:{"fullpath"=>"/xxx"}'
      RequestMapper.process(GET,"/").should == 'list:{"fullpath"=>"/"}'
    end

    it "should start wildcard path correctly" do
      blk = lambda{|params| params}
      RequestMapper.add_path(GET,"/foo/*",{},&blk)
      puts RequestMapper.table.inspect
      RequestMapper.process(GET,"/foo/").should == {"wildpath"=>"/"}

    end



  end


end
