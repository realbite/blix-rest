#========== requests with tokens

Given(/^(.*?) requests token for service "(.*?)"$/) do |user,service|
  path = "/myservices/" + service + "/token"
  send_request('POST',user,path,nil)
  @_token = valid_response.data["token"]
end

Given(/^(.*?) validates the token for service "(.*?)"$/) do |user,service|
  path = "/services/" + service + "/validate/" + @_token
  send_request('GET',user,path,nil)
end


# Given(/^guest gets "(.*?)"( .*)?$/) do |path,condition|
#   path = add_token_to_path(path,@_token) if condition == " with token"
#   send_request('GET',"guest",path,nil)
# end

# general requests

Given(/^(.*?) gets ["'](.*?)["']( with token)?$/) do |user, path, condition|
  path = add_token_to_path(path,@_token) if condition == " with token"
  send_request('GET',user,path,nil)
end

Given(/^(.*?) options ["'](.*?)["']( with token)?$/) do |user, path, condition|
  path = add_token_to_path(path,@_token) if condition == " with token"
  send_request('OPTIONS',user,path,nil)
end

Given(/^(.*?) posts ["'](.*?)["'] with (.*?)$/) do |user, path, json|
  send_request('POST',user,path,json)
end

# doc string version
Given(/^(.*?) posts ["'](.*?)["'] with$/) do |user, path, json|
  send_request('POST',user,path,json)
end

Given(/^(.*?) deletes ["'](.*?)["']$/) do |user, path|
  send_request('DELETE',user,path,nil)
end

Given(/^(.*?) puts ["'](.*?)["'] with (.*?)$/) do |user, path, json|
  send_request('PUT',user,path,json)
end

# doc string version
Given(/^(.*?) puts ["'](.*?)["'] with$/) do |user, path, json|
  send_request('PUT',user,path,json)
end

# alternative format

Given(/^I am (.*?)$/) do | string |
  @_current_user = string.split(' ')[-1]
end

Given(/^I get ["'](.*?)["']$/) do |path|
  send_request('GET',@_current_user,path,nil)
end

Given(/^I post ["'](.*?)["'] with (.*?)$/) do |path, json|
  send_request('POST',@_current_user,path,json)
end

Given(/^I delete ["'](.*?)["']$/) do | path|
  send_request('DELETE',@_current_user,path,nil)
end

Given(/^I put ["'](.*?)["'] with (.*?)$/) do |path, json|
  send_request('PUT',@_current_user,path,json)
end

# response steps ==============================

Then(/^the status should be (\d+)$/) do |code|
  expect(valid_response.status).to eq code.to_i
end

Then(/^there should be an error$/) do
  expect(valid_response.status.to_s[0,1]).not_to eq '2'
  expect(valid_response.error).not_to be_nil
end

Then(/^the error message should include ["'](.*?)["']$/) do |field|
  expect(valid_response.error && (valid_response.error =~ %r/#{field}/)).to_not be nil
end

Given(/^explain$/) do
  explain
end

Then(/^the data type should be ["'](.*?)["']$/) do |type|
  if valid_response.data.kind_of? Array
    expect(valid_response.data[0]["_type"]).to eq type
  else
    expect(valid_response.data["_type"]).to eq type
  end
end


Then(/^the data length should be (\d+)$/) do |len|
  if valid_response.data.kind_of? Array
    expect(valid_response.data.length).to eq len.to_i
  else
    1
  end
end

Then(/^the data length should equal (\d+)$/) do |len|
  if valid_response.data.kind_of? Array
    expect(valid_response.data.length).to eq len.to_i
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

  if val =~ %r{^@([^@]*)$}
     expect(v).to eq store[$1].to_s
  elsif val =~ %r{^(::)?[A-Z][A-z_a-z:]*$}
     expect(v).to eq Module.const_get(val).to_s
  elsif val =~ %r{^['"](.*)['"]$}
     expect(v).to eq $1
  end

end

Then(/^the data "(.*?)" should equal ["'](.*?)["']$/) do |field,val|
  if valid_response.data.kind_of? Array
    data = valid_response.data[0]
  else
    data = valid_response.data
  end
  expect(data[field].to_s).to eq val
end

Then(/^the data ["'](.*?)["'] should == nil$/) do |field|
  if valid_response.data.kind_of? Array
    data = valid_response.data[0]
  else
    data = valid_response.data
  end
  expect(data[field]).to be nil
end

Then(/^the data ["'](.*?)["'] should equal nil$/) do |field|
  if valid_response.data.kind_of? Array
    data = valid_response.data[0]
  else
    data =valid_response.data
  end
  expect(data[field]).to be nil
end

Then(/^the body should eq ["'](.*?)["']$/) do |val|
  val.gsub!("\\n","\n")
  expect(valid_response.body).to eq val
end



Then(/^the data should( not)? include ["'](.*?)["']$/) do |state, field|
  if valid_response.data.kind_of? Array
    data = valid_response.data[0]
  else
    data = valid_response.data
  end
  if state == " not"
     expect(data.key?(field)).to eq false
  else
     expect(data.key?(field)).to eq true
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

Given(/^save the "([^"]*)"$/) do |name|
  if valid_response.data.kind_of?(Array)
    data = valid_response.data[0]
  else
    data  = valid_response.data
  end
  if data.kind_of?(Hash) && data.key?(name)
    store[name] =  data[name]
  end
end
