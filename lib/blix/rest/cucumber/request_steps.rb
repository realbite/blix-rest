Given(/^user (.*?) gets ["'](.*?)["']$/) do |user, path|
  send_request('GET',user,path,nil)
end

Given(/^user (.*?) posts ["'](.*?)["'] with (.*?)$/) do |user, path, json|
  send_request('POST',user,path,json)
end

Given(/^user (.*?) deletes ["'](.*?)["']$/) do |user, path|
  send_request('DELETE',user,path,nil)
end

Given(/^user (.*?) puts ["'](.*?)["'] with (.*?)$/) do |user, path, json|
  send_request('PUT',user,path,json)
end

Then(/^the status should be (\d+)$/) do |code|
  valid_response.status.should == code.to_i
end

Then(/^there should be an error$/) do
  valid_response.status.to_s[0,1].should_not == '2'
  valid_response.error.should_not == nil
end

Then(/^the error message should include ["'](.*?)["']$/) do |field|
  (valid_response.error && (valid_response.error =~ %r/#{field}/)).should_not == nil
end

Given(/^explain$/) do
  puts "request ==> #{@_verb} #{@_request}"
  puts "body ==> #{@_body}" if @_body
  puts "response ==> #{@_response.inspect}"
end

Then(/^the data type should be ["'](.*?)["']$/) do |type|
  if valid_response.data.kind_of? Array
    valid_response.data[0]["_type"].should == type
  else
    valid_response.data["_type"].should == type
  end
end


Then(/^the data length should be (\d+)$/) do |len|
  if valid_response.data.kind_of? Array
    valid_response.data.length.should == len.to_i
  else
    1
  end
end

Then(/^the data "(.*?)" should == (.*?)$/) do |field,val|
  if valid_data.kind_of? Array
    data = valid_data[0]
  else
    data = valid_data
  end
  v = data[field].to_s
  
  if val =~ %r{^:([^:]*)$}
     v.should == store[$1].to_s
  elsif val =~ %r{^(::)?[A-Z][A-z_a-z:]*$}
     v.should == Module.const_get(val).to_s
  elsif val =~ %r{^['"](.*)['"]$}
     v.should == $1
  end
  
end

Then(/^the data "(.*?)" should equal ["'](.*?)["']$/) do |field,val|
  if valid_response.data.kind_of? Array
    data = valid_response.data[0]
  else
    data = valid_response.data
  end
  data[field].to_s.should == val
end

Then(/^the data ["'](.*?)["'] should == nil$/) do |field|
  if valid_response.data.kind_of? Array
    data = valid_response.data[0]
  else
    data = valid_response.data
  end
  data[field].should == nil
end

Then(/^the data ["'](.*?)["'] should equal nil$/) do |field|
  if valid_response.data.kind_of? Array
    data = valid_response.data[0]
  else
    data =valid_response.data
  end
  data[field].should == nil
end



Then(/^the data should( not)? include ["'](.*?)["']$/) do |state, field|
  if valid_response.data.kind_of? Array
    data = valid_response.data[0]
  else
    data = valid_response.data
  end
  if state == " not"
     data.key?(field).should == false
  else
     data.key?(field).should == true
  end
end



Then(/^store the ["'](.*?)["'] as ["'](.*?)["']$/) do |name,key|
  if valid_response.data.kind_of?(Array)
    data = valid_response.data[0]
  else
    data  = valid_response.data
  end
  if data.kind_of?(Hash) && data.key?(name)
    store[key] =  data[name]
  end
end
