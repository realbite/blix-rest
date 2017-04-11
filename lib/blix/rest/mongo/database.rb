require 'mongoc'

module Realbite::Rest
  
  module Mongo
    
    class Database
      
      class << self
        
        # setup the mongo database
        def configure(params={})
          @host = params[:host]
          @port = params[:port]
          @database = params[:database]  || raise( "mongo databasename required")
          @pool_size = params[:pool_size] || 1
        end
        
        # mongo host
        def host
          @host || 'localhost'
        end
        
        # mongo port number
        def port
          @port || 27017
        end
        
        # database name
        def database
          @database
        end
        
        # a database connection .. one per thread
        def connection
          #@pool ||= {}
          #@pool[Thread.current] ||= Mongoc::Client.new(host, port, :pool_size=>@pool_size)
          #Mongoc::Client.new(host, port, {})
          Thread.current[:_mongo] ||= Mongoc::Client.new(host, port, {})
        end
        
        # the full path of a collection
        def path(table)
        "#{database}.#{table}"
        end
        
        # get all the documents in the given table
        def all_docs(table)
          connection.all_docs(path(table))
        end
        
        # find a document in a table
        def find(table,query)
          connection.find(path(table),query)
        end
        
        # insert a document into a table
        def insert(table,doc)
          connection.insert(path(table),doc)
        end
        
        # ensure an index is present for the given table
        def ensureIndex(table,keys,options={})
          connection.ensureIndex(path(table),keys,options)
        end
        # drop the given table from the database
        def drop_table(table)
          connection.drop_collection(database,table)
        end
        
        # remove documents from the table
        def remove(table,cond)
          connection.remove(path(table),cond)
        end
        
        # update a document on a table
        def update(table,cond,op)
          connection.update(path(table),cond,op)
        end
        
        # clear out the whole database for testing puposes.
        def drop_test_database!
          raise "not a test database!!! database name must end in `_test`" unless @database =~ /_test$/
          connection.drop_database(@database)
        end
        
      end
    end
  end
end

class BSON::ObjectId
  def empty?
    false
  end
  
  def as_json(*a)
    to_s
  end
  
  def ==(other)
    self.to_s == other.to_s
  end
end
