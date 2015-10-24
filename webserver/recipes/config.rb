#
# Cookbook Name:: webserver
# Recipe:: config
#
# Copyright (C) 2015 David Schneider
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

Chef::Log.info("Configure composer")

# composer configuration
unless node["github"]["oauth_token"].empty?
	# Github Oauth token
	template "/var/www/.composer/config.json" do
		source 'composer_config_json.erb'
		mode '0644'
		owner "www-data"
		group "www-data"
		variables(
			:oauth_token => node["github"]["oauth_token"]
		)
	end
end

Chef::Log.info("Configure SSH")

# Update known_hosts, or deploys will be interrupted
unless node["known_hosts"].nil?
	Chef::Log.info("Adding known hosts")

	# write the actual key to file
	template "/var/www/.ssh/known_hosts" do
		source 'known_hosts.erb'
		mode '0644'
		owner "www-data"
		group "www-data"
		variables(
			:hosts => node["known_hosts"]
		)
	end
end