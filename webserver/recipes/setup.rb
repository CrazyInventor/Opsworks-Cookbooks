#
# Cookbook Name:: webserver
# Recipe:: setup
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

#
# Install Nginx, PHP5, Git, Composer, Memcached
#

# Nginx
package 'nginx' do
  action :install
end

# PHP
package 'php5-cli' do
  action :install
end

package 'php5-fpm' do
  action :install
end

package 'php5-mcrypt' do
  action :install
end

package 'php5-mysql' do
  action :install
end

package 'php5-memcached' do
  action :install
end

package 'php5-curl' do
  action :install
end

package 'php5-geoip' do
  action :install
end

# Memcached
package 'memcached' do
  action :install
end

# Git
package 'git' do
  action :install
end

# composer installation
script "composer_install" do
	interpreter "bash"
	user "root"
	cwd "/tmp"
	code <<-EOH
		curl -sS https://getcomposer.org/installer | php
		mv composer.phar /usr/local/bin/composer
	EOH
end

#
# Configure everything
#

# configure nginx php upstream
cookbook_file "nginx-phpfpm.conf" do
	manage_symlink_source true
	path "/etc/nginx/conf.d/10-phpfpm.conf"
	action :create
end

# restart nginx
service "nginx" do
  action :restart
end

# restart PHP5-FPM
service 'php5-fpm' do
  provider Chef::Provider::Service::Upstart
  supports :restart => true
  action [ :enable, :start ]
end

#
# Prepare deploy user
#

# create deploy user
user 'www-data' do
	supports :manage_home => true
	gid 'www-data'
	home '/var/www'
	shell '/bin/bash'
    action :create
end

# create user's ssl directory
directory '/var/www/ssl' do
	owner 'www-data'
	group 'www-data'
	mode '0755'
	action :create
	recursive true
end

# create user's ssh directory
directory '/var/www/.ssh' do
	owner 'www-data'
	group 'www-data'
	mode '0755'
	action :create
	recursive true
end

# create known_hosts file
cookbook_file "ssh_known_hosts" do
	path "/var/www/.ssh/known_hosts"
    owner 'www-data'
    group 'www-data'
    mode 00644
	action :create
end

# create user's composer directory
directory '/var/www/.composer' do
	owner 'www-data'
	group 'www-data'
	mode '0755'
	action :create
	recursive true
end

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
