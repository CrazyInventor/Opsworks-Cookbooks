#
# Cookbook Name:: webserver
# Recipe:: deploy
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

# deploy all applications
node[:opsworks][:applications].each do |application|

	Chef::Log.info("Deploy application #{application[:slug_name]}")

	# update id_rsa key	
	Chef::Log.info("Write SSH Key")

	# write the actual key to file
	template "/var/www/.ssh/id_rsa" do
		source 'ssh_key.erb'
		mode '0600'
		owner "www-data"
		group "www-data"
		variables(
			:key => node[:deploy][application[:slug_name]][:scm][:ssh_key]
		)
	end

	Chef::Log.info("Create app directory")

	# create a directory to host the application
	directory "/srv/www/#{application[:slug_name]}" do
		owner 'www-data'
		group 'www-data'
		mode '0755'
		action :create
		recursive true
	end

	Chef::Log.info("Sync git repo to app directory")

	# Sync github repo
	unless node[:deploy][application[:slug_name]][:scm][:revision].nil?
		Chef::Log.info("Syncing branch #{node[:deploy][application[:slug_name]][:scm][:revision]}")
		git "/srv/www/#{application[:slug_name]}" do
			repository repository node[:deploy][application[:slug_name]][:scm][:repository]
			user "www-data"
			group "www-data"
			reference node[:deploy][application[:slug_name]][:scm][:revision]
			action :sync
		end
	else
		Chef::Log.info("Syncing branch master")
		git "/srv/www/#{application[:slug_name]}" do
			repository repository node[:deploy][application[:slug_name]][:scm][:repository]
			user "www-data"
			group "www-data"
			reference "master"
			action :sync
		end
	end

	
	Chef::Log.info("Write environment file")

	# environment variables
	template "/srv/www/#{application[:slug_name]}/.env" do
		source 'env.erb'
		mode '0660'
		owner "www-data"
		group "www-data"
		variables(
			:env => node[:deploy][application[:slug_name]][:environment_variables]
		)
	end

	Chef::Log.info("Create Nginx site config")

	# create virtual host config for nginx
	template "/etc/nginx/sites-available/#{application[:slug_name]}" do
		source 'nginx_site.erb'
		mode '0644'
		owner "root"
		group "root"
		variables(
			:host_names => node[:deploy][application[:slug_name]][:domains],
			:document_root => node[:deploy][application[:slug_name]][:document_root],
			:slug_name => application[:slug_name]
		)
	end

	Chef::Log.info("Enable Nginx site config")

	# enable virtual host
	link "/etc/nginx/sites-enabled/#{application[:slug_name]}" do
		to "/etc/nginx/sites-available/#{application[:slug_name]}"
		link_type :symbolic
		mode '0644'
		owner "root"
		group "root"
		action :create
	end

	# SSL info available?
	unless node[:deploy][application[:slug_name]][:ssl_certificate_key].nil?

		Chef::Log.info("Deploying SSL configuration for #{application[:slug_name]}")

		Chef::Log.info("Write SSL key")

		#write ssl key
		file "/var/www/ssl/#{application[:slug_name]}.key" do
			content node[:deploy][application[:slug_name]][:ssl_certificate_key]
			owner "www-data"
			group "www-data"
			mode 00600
			action :create
		end

		Chef::Log.info("Write SSL certificate")

		#write ssl certificate
		file "/var/www/ssl/#{application[:slug_name]}.pem" do
			content node[:deploy][application[:slug_name]][:ssl_certificate]
			owner "www-data"
			group "www-data"
			mode 00600
			action :create
		end


		Chef::Log.info("Write SSL key")

		#write ssl virtual host file
		template "/etc/nginx/sites-available/#{application[:slug_name]}_ssl" do
			source 'nginx_site_ssl.erb'
			mode '0644'
			owner "root"
			group "root"
			variables(
				:host_names => node[:deploy][application[:slug_name]][:domains],
				:document_root => node[:deploy][application[:slug_name]][:document_root],
				:slug_name => application[:slug_name]
			)
		end

		Chef::Log.info("Create Nginx SSL site config")
		
		# enable virtual host
		link "/etc/nginx/sites-enabled/#{application[:slug_name]}_ssl" do
			to "/etc/nginx/sites-available/#{application[:slug_name]}_ssl"
			link_type :symbolic
			mode '0644'
			owner "root"
			group "root"
			action :create
		end
	end

	# disable default host
	file '/etc/nginx/sites-enabled/default' do
		only_if { node["nginx_use_default_site"] == false }
		action :delete
	end

	Chef::Log.info("Restart Nginx")

	# restart nginx
	service "nginx" do
		action :restart
	end

	# run post deploy commands
	unless node["post_deploy"]["commands"].empty?

		Chef::Log.info("Executing post deploy commands for application #{application[:slug_name]}")
		
		node["post_deploy"]["commands"].each do |cid,command|
		
			Chef::Log.info("Executing post deploy command #{cid}")
		
			script "post_deploy_command" do
				interpreter "bash"
				user "www-data"
				group "www-data"
				cwd "/srv/www/#{application[:slug_name]}"
				code <<-EOH
				#{command}
				EOH
			end
		end
	end
end