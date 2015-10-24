#
# Cookbook Name:: selenium
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
# Java, virtual screen, and Firefox
#

# default-jre
package 'default-jre' do
  action :install
end

# xvfb a.k.a. virtual screen
package 'xvfb' do
  action :install
end

# firefox
package 'firefox' do
  action :install
end

# run virtual screen on server start
cron 'on_start_run_xvfb' do
	minute  '@reboot'
	hour    ''
	day     ''
	month   ''
	weekday ''
	action :create
	command "sh -c 'Xvfb :99 -ac -screen 0 1024x768x8 > /tmp/xvfb.log 2>&1 &'"
end

#
# Selenium
#

# create selenium control script
cookbook_file "selenium_init_script" do
	manage_symlink_source true
	path "/etc/init.d/selenium"
	owner 'root'
	group 'root'
	mode '0755'
	action :create
end

# download and prepare selenium server, then restart
bash 'selenium_setup' do
	code <<-EOH
	    mkdir /usr/lib/selenium
		cd /usr/lib/selenium
		wget #{node["selenium"]["url"]}
		ln -s #{node["selenium"]["file"]} selenium-server-standalone.jar
		mkdir -p /var/log/selenium
		chmod a+w /var/log/selenium
		update-rc.d selenium defaults
		reboot
    EOH
end

