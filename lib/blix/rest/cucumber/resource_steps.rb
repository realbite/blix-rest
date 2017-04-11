Given(/^the following users exist:$/) do |table|
  table.hashes.each do |h|
       
    name = h["name"] || h["login"]
    
    next if name=="guest"
    
    u = {}
    
    def u.set(k,v)
      self[k.to_s] = v
    end
    
    def u.get(k)
      self[k.to_s]
    end
    
    u.set(:pw,h["secret"] || h["password"] || name+"@12345678")
    u.set(:name,name )
    u.set(:login,name)
    u.set(:email,name+"@example.com")
    u.set(:name,name)
    u.set(:email_is_verified,false) 
    u.set(:is_admin,true)    if h["level"] == "admin"
    u.set(:is_provider,true) if h["level"] == "provider"
    before_user_create(u,h)
    users[name] = u
  end
end
