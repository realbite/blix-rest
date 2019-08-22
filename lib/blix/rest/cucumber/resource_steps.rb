class UserHash < Hash
  def set(k,v)
    self[k.to_s] = v
  end

  def get(k)
    self[k.to_s]
  end
end

Given(/^the following users exist:$/) do |table|
  table.hashes.each do |h|

    name = h["name"] || h["login"]

    next if name=="guest"

    u = UserHash.new.merge!(h)



    u.set(:pw,h["secret"] || h["password"] || name+"@12345678")

    before_user_create(u,h)
    users[name] = u
    after_user_create(u,h)
  end
end
