require 'blix/rest/mongo/database'
require 'blix/rest/resource_cache'
require 'blix/rest/mongo/relationships'
require 'blix/rest/mongo/resource'
require 'blix/rest/mongo/sub_resource'
require 'blix/rest/mongo/validations'

class Blix::Rest::ProviderController
  
  # convert a path parameter to a mongodb id
  def path_bson_id(name)
    id=path_params[name]
    raise ServiceError,"#{name} missing" unless id
    to_bson_id(id)
  end
  
  def body_bson_id(name)
    id=body_hash[name]
    raise ServiceError,"#{name} missing" unless id
    to_bson_id(id)
  end
  
  def to_bson_id(id)
    id && BSON::ObjectId.from_string(id.to_s)
  end
  
end
