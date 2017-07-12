## INSTALLATION

    gem install blix_rest


## CREATE A SIMPLE WEBSERVICE 

#### put the following in config.ru


    require 'blix/rest'
    
    class HomeController < Blix::Rest::Controller
    
         get '/hello', :accept=>[:html,:json] do
            if format == :json
              {"message"=>"hello world"}
            else
             "<h1>hello world</h1>"
            end
         end
    end
    
    run Blix::Rest::Server.new




#### at the command line ..

`ruby -S rackup -p3000`
    
    
#### now go to your browser and enter ..
    
`http://localhost:3000/hello`

or 

`http://localhost:3000/hello.json`

## NOTE ON PATHS

`get '/user/:user_id/list`

`path_params[:user_id]` contains the content of the path at location :user_id

`get '/resource/*'`

`path_params[:wildpath]` contains the remainder of the path where the * is.

if there is a more specific path then it will be used first :

`get '/resource/aaa'` will be used before `get '/resource/*'`

`get '/*'` will be used as a default path if no other paths match.



## GENERATE AN ERROR RESPONSE

raise a ServiceError within your controller code.

`raise Blix::Rest::ServiceError.new(message,status,headers)`

or for standard headers and status 406 just ..

`raise Blix::Rest::ServiceError, "my error message"` 

## HEADERS && STATUS

add special headers to your response with eg:
   
`add_headers( "AAA"=>"xxx","BBB"=>"yyyy")`
   
change the status of a success response with eg:

`set_status(401)` 

## REQUEST FORMAT

you can provide custom responses to a request format by registering a format parser
for that format. you can also override the standard html,json or xml behavior.

Note that the format for a non standard (html/json/xml) request is only taken from
the extension part ( after the .) of the url ... eg 

`http://mydomain.com/mypage.jsonp` will give a format of jsonp


    class MyParser < FormatParser
        
        def set_default_headers(headers)
          headers[CACHE_CONTROL]= CACHE_NO_STORE 
          headers[PRAGMA]       = NO_CACHE 
          headers[CONTENT_TYPE] = CONTENT_TYPE_JSONP
        end
        
        def format_error(message)
          message.to_s
        end
        
        def format_response(value,response)
          response.content = "<script>load(" +
            MultiJson.dump( value) +
            ")</script>"
        end
    end
    
    
    s = Blix::Rest::Server.new
    s.register_parser(:jsonp,MyParser.new)


Then in your controller accept that format..


    get "/details" :accept=>[:jsonp] do
        {"id"=>12}
    end


## Controller

    Blix::Rest::Controller  

base class for controllers. within your block handling a particular route you
have access to a number of methods

    
    env          : the request environment hash
    verb         : the request method ( 'GET'/'POST' ..)
    req          : the rack request
    body         : the request body as a string
    query_params : a hash of parameters as passed in the url as parameters
    path_params  : a hash of parameters constructed from variable parts of the path
    post_params  : a hash of parameters passed in the body of the request
    params       : all the params combined
    user         : the user making this request ( or nil if 
    format       : the format the response should be in :json or :html
    before       : before hook ( opts ) - remember to add 'super' as first line !!!
    after        : after hook (opts,response)- remember to add 'super' as first line !!!
    proxy        : forward the call to another service (service,path, opts={}) , :include_query=>true/false
    session      : req.session
    redirect     : (path, status=302) redirect to another url.
    request_ip   : the ip of the request
    render_erb   : (template_name [,:layout=>name])
    path_for     : (path) give the correct path for an internal path
    url_for      : (path) give the full url for an internal path
  
  
to accept requests other than json then set `:accept=>[:json,:html]` as options        in the route

eg  `post '/myform' :accept=>[:html]      # this will only accept html requests.`
  

## VIEWS


    Blix::Rest.set_erb_root ::File.expand_path('../lib/myapp/views',  __FILE__)


  
    render_erb( "users/index", :layout=>'layouts/main')


myapp
-----
     views
     -----
          users
          -----
               index.html.erb
          layouts
          -------
               main.html.erb


## Testing a Service with cucumber


in features/support/setup.rb

   require 'blix/rest/cucumber'


   
now you can use the following in scenarios ........

        Given user guest gets "/info"
        
        Given the following users exist:
              | name  | level |
              | anon  | guest |
              | bob   | user  |
              | mary  | provider  |
              | paul  | user  |
              | admin | admin |
              
        Given user mary posts "/worlds" with {"name":"narnia"}    [..or gets/puts/deletes]
        Then store the "id" as "world_id"  
        
        Given user bob posts "/worlds/:world_id" with  {"the_world_id"::world_id }
        
        Then the status should be 200
        Then the data type should be "r_type"
        Then the data length should be 3
        Then there should be an error
        Then the error message should include "unique"
        Then the data "name" should == "bob"
        Then the data should include "name"
        
        And explain


NOTE : if you need to set up your database with users then you can use the following hook ..

in features/support/world.rb .........

    class RestWorld
      
      # add a hook to create the user in the  database - 
      #
      def before_user_create(user,hash)
        name = hash["name"]
        u = MyUser.new
        u.set(:user_wid, name)
        u.set(:name,name)
        u.set(:is_super,true) if hash["level"] == "super"
        u.save
        store["myuser_#{name}_id"] = u.id.to_s
      end
    end

now you can also use eg  `:myuser_foo_id` within a request path/json.



## Manage Assets


    require 'blix/assets'


The asset manager stores a hash of the asset data and the current unique file suffix for each asset in its own file.
This config file is stored in a config directory. The default is 'config/assets' but another location can be specified.
 

    Blix::AssetManager.config_dir = "myassets/config/location"   # defaults to `"config/assets" 


### Compile your assets

    require 'blix/assets'
  
    ......
    ......
    ASSETS = ['admin.js', 'admin.css', 'standard.js']
    ASSETS.each do |name| 
        
       compiled_asset = environment[name].to_s
       
       Blix::AssetManager.if_modified(name,compiled_asset,:rewrite=>true) do |a|
         
         filename = File.join(ROOT,"public","assets",a.newname)
         puts "writing #{name} to #{filename}"
         File.write filename,compiled_asset
         
         File.unlink File.join(ROOT,"public","assets",a.oldname) if a.oldname
       end
       
    end


### In your erb view


eg:

    require 'blix/assets'
    
    ........
    
    <script src="<%= asset_path('assets/standard.js') %>" type="text/javascript"></script>


### or in your controller

eg: 

    require 'blix/assets'
    
    ........

    path = asset_path('assets/standard.js')



#### NOTE ON ASSETS!!

In production mode the compiled version of the assets will be used which will have a unique file name.

In production the expiry date of your assets can be set to far in the future to take advantage of cacheing.

In development or test mode the standard name will be used which then will make use of your asset pipeline ( eg sprockets )

Asset names can contain only one extension. if there are more extensions eg: 'myfile.extra.css' then only the last 
extension will be used: in this case the name will be simplified to 'myfile.css' !!!
