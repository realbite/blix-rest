## INSTALLATION

    gem install blix-rest


## CREATE A SIMPLE WEBSERVICE

#### put the following in config.ru


    require 'blix/rest'

    class HomeController < Blix::Rest::Controller

         get '/hello', :accept=>[:html,:json], :default=>:html do
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

## Note on JSON

the default json parser uses multi json. load the specific json library you need
before loading `blix/rest`.

when using oj then you may need to set some default options eg:

  `MultiJson.default_options = {:mode=>:custom, :use_as_json=>true}`

## NOTE ON PATHS

`get '/user/:user_id/list`

`path_params[:user_id]` contains the content of the path at location :user_id

`get '/resource/*wildpath'`

`path_params[:wildpath]` contains the remainder of the path where the * is.

if there is a more specific path then it will be used first :

`get '/resource/aaa'` will be used before `get '/resource/*'`

`get '/*'` will be used as a default path if no other paths match.

`all '/mypath'` will accept all http_methods but if a more specific handler
   is specified then it will be used first.


### Path options

    :accept     : the format or formats to accept eg: :html or [:png, :jpeg]
    :default    : default format if not derived through other means.
    :force      : force response into the given format
    :query      : derive format from request query (default: false)
    :extension  : derive format from path extension  (default: true)


use `:accept=>:*` in combination with `:force` to accept all request formats.

## APPLICATION MOUNT POINT

this is the path of the mount path of the application

this will be set to the environment variable `BLIX_REST_ROOT` if present

otherwise set it manually with:

`Blix::Rest.set_path_root( "/myapplication")`




## GENERATE AN ERROR RESPONSE

`send_error(message,status,headers)`

or for standard headers and status 406 just ..

`send_error "my error message`



## HEADERS && STATUS

add special headers to your response with eg:

`add_headers( "AAA"=>"xxx","BBB"=>"yyyy")`

change the status of a success response with eg:

`set_status(401)`


to specify __ALL__ the headers for a given format of response use eg:

    srv = Blix::Rest::Server.new
    srv.set_custom_headers(:html, 'Content-Type'=>'text/html; charset=utf-8', 'X-OTHER'=>'')

    ...
    srv.run

remember to always set at least the content type!

## BASIC AUTH

in controller..

    login,password = get_basic_auth
    auth_error( "invalid login or password" ) unless .... # validate login and password




## REQUEST FORMAT

you can provide custom responses to a request format by registering a format parser
for that format. you can also override the standard html,json or xml behavior.

Note that the format for a non standard (html/json/xml) request is only taken from
the extension part ( after the .) of the url ... eg

`http://mydomain.com/mypage.jsonp` will give a format of jsonp

you can specify the :default option in your route for a fallback format other than :json
eg `:default=>:html`


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

## CUSTOM RESPONSE WITHOUT CUSTOM PARSER

to force a response in a certain format use the :force option in your route.

to return a custom response use `:force=>:raw` . You will have to specify all the
headers and the body is returned as it is.

use the following to accept requests in a special format ..

    get '/custom', :accept=>:xyz, :force=>:raw do
       add_headers 'Content-Type'=>'text/xyz'
       "xyz"
    end


Alternatively it is possible to raise a RawResponse:

    add_headers 'Content-Type'=>'text/xyz'
    raise RawResponse, 'xyz'

or with status and headers:

    raise RawResponse.new('xyz', 123, 'Content-Type'=>'text/xyz')

## FORMATS

the format of a request is derived from

  1. the `:force` option value if present

  2. the request query `format` parameter if the `:query` option is true

  3. the url extension unless the `:extension` option is false.

  4. the accept header format

  5. the format specified in the `:default` option

  6. `:json`


## Controller

    Blix::Rest::Controller

base class for controllers. within your block handling a particular route you
have access to a number of methods


    env                : the request environment hash
    method             : the request method lowercase( 'get'/'post' ..)
    req                : the rack request
    body               : the request body as a string
    query_params       : a hash of parameters as passed in the url as parameters
    path_params        : a hash of parameters constructed from variable parts of the path
    post_params        : a hash of parameters passed in the body of the request
    params             : all the params combined
    user               : the user making this request ( or nil if
    format             : the format the response should be in :json or :html
    before             : before hook ( opts ) - remember to add 'super' as first line !!!
    after              : after hook (opts,response)- remember to add 'super' as first line !!!
    proxy              : forward the call to another service (service,path, opts={}) , :include_query=>true/false
    session            : req.session
    redirect           : (path, status=302) redirect to another url.
    request_ip         : the ip of the request
    render_erb         : (template_name [,:layout=>name])
    server_cache       : get the server cache object
    server_cache_get   : retrieve/store value in cache
    path_for           : (path) give the correct path for an internal path
    url_for            : (path) give the full url for an internal path
    h                  : escape html string to avoid XSS
    escape_javascript  : escape  a javascript string
    server_options     : options as passed to server at create time
    mode_test?         : test mode ?
    mode_production?   : production mode ?
    mode_development?  : development mode?
    send_data          : send raw data (data, options )
                            [:type=>mimetype]
                            [:filename=>name]
                            [:disposition=>inline|attachment]
                            [:status=>234]

    get_session_id(session_name, opts={}) :
    refresh_session_id(session_name, opts={}) :

to accept requests other than json then set `:accept=>[:json,:html]` as options        in the route

eg  `post '/myform' :accept=>[:html]      # this will only accept html requests.`

### Hooks

a before or after hook can be defined on a controller. Only define the hook once
for a given controller per source file. A hook included from another source file
is ok though.

    class MyController < Blix::Rest::Controller

      before do
        ...
      end

      after do
        ...
      end

    end


#### manipulate the route path or options

the `before_route` hook can be used to modify the path or options of a route.

*NOTE* ! when manipulating the path you have to modify the string object in place.

the verb can not be modified

example:

    class MyController < Blix::Rest::Controller

      before_route do |verb, path, opts|
        opts[:level] = :visitor unless opts[:level]
        path.prepend('/') unless path[0] == '/'
        path.prepend('/app') unless path[0, 4] == '/app'
      end
      ...
    end

### Sessions

the following methods are available in the controller for managing sessions.

    get_session_id(session_name, opts={})

this will set up a session and setup the relevant cookie  headers forthe browser.

    refresh_session_id(session_name, opts={})

this will generate a new session_id and setup the relevant headers

options can include:

    :secure => true    # secure cookies only
    :http = >true      # cookies for http only not javascript requests
    :samesite =>:strict  # use strict x-site policy
    :samesite =>:lax     # use lax x-site policy


## Cache


the server has a cache which can also be used for storing your own data.

within a controller access the controller with `server_cache` which returns the
cache object.

cache object methods:

    get(key)        # return value from the cache or nil
    set(key,value)  # set a value in the cache
    key?(key)       # is a key present in the cache
    delete(key)     # delete a key from the cache
    clear           # delete all keys from the cache.

there is also a `server_cache_get` method.

    server_cache_get(key){ action }

get the value from the cache. If the key is missing in the cache then perform
the action in the provided block and store the result in the cache.

the default cache is just a ruby hash in memory. Pass a custom cache to
when creating a server with the `:cache` parameter.

    class MyCache < Blix::Rest::Cache
       def get(key)
          ..
       end

       def set(key,value)
         ..
       end

       def key?(key)
        ..
       end

       def delete(key)
         ..
       end

       def clear
         ..
       end
     end

     cache = MyCache.new

     app = Blix::Rest::Server.new(:cache=>cache)

there is a redis cache already defined:

    require 'blix/rest/redis_cache'

    cache = Blix::Rest::RedisCache.new(:expire_secs=>60*60*24) # expire after 1 day
    run Blix::Rest::Server.new(:cache=>cache)


### automatically cache server responses

add  `:cache=>true` to your route options in order to cache this route.

add `:cache_reset=>true` to your route options if the cache should be cleared when
calling this route.

the cache is not used in development/testmode , only in production mode.

## Views

the location of your views defaults to `app/views` otherwise set it manually with:

globally eg:

    Blix::Rest.set_erb_root ::File.expand_path('../lib/myapp/views',  __FILE__)

or per controller eg:

    class MyController < Blix::Rest::Controller

       erb_dir  ::File.expand_path('../..',  __FILE__)

    end

then within a controller render your view with.

    render_erb( "users/index", :layout=>'layouts/main', :locals=>{:name=>"charles"})

    ( locals work from ruby 2.1 )


#### directory structure

     views
     -----
          users
          -----
               index.html.erb
          layouts
          -------
               main.html.erb


## Logging

    Blix::Rest.logger = Logger.new('/var/log/myapp.log')


## Testing a Service with cucumber


in features/support/setup.rb

   require 'blix/rest/cucumber'

   and setup your database connections etc


in features/support/hooks.rb

   reset your database



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


    Blix::AssetManager.config_dir = "myassets/config/location"   # defaults to `"config/assets"`


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

or

    <%= asset_tag('/assets/standard.js') %>


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
