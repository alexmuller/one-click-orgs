Given /^the subdomain is "([^"]*)"$/ do |subdomain|
  When %Q{the domain is "#{subdomain}.#{Setting[:base_domain].sub(/:\d+$/, '')}"}
end

When /^the domain is "([^"]*)"$/ do |domain|
  if Capybara.current_driver == :selenium
    Capybara.default_host = "http://#{domain}:#{Capybara.server_port}"
    Capybara.app_host = "http://#{domain}:#{Capybara.server_port}"
  else
    Capybara.default_host = "http://#{domain}:#{Capybara.server_port}"
    Capybara.app_host = "http://#{domain}"
  end
end

Then /^the domain should be "([^"]*)"$/ do |domain|
  current_domain = URI.parse(current_url).host
  current_domain.should == domain
end

Then /^the subdomain should be "([^"]*)"$/ do |subdomain|
  current_subdomain = URI.parse(current_url).host.sub(".#{Setting[:base_domain].sub(/:\d+$/, '')}", '')
  current_subdomain.should == subdomain
end

Then /^I should get a "([^"]*)" download with the name of the organisation$/ do |extension|
  @organisation ||= Organisation.last
  page.response_headers['Content-Disposition'].should =~ Regexp.new("filename=\"#{Regexp.escape(@organisation.name)}.*#{Regexp.escape(extension)}\"")
end
