#
# Cookbook Name:: geoip
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

# GeoIP
package 'geoip-bin' do
  action :install
end

# Packages for geoipupdate
package 'build-essential' do
  action :install
end
package 'libcurl4-openssl-dev' do
  action :install
end
package 'automake' do
  action :install
end
package 'autoconf' do
  action :install
end
package 'libtool' do
  action :install
end

# Install update tool for GeoIP
script "install_geoipupdate" do
	interpreter "bash"
	user "root"
	cwd "/usr/local/share"
	code <<-EOH
	    git clone https://github.com/maxmind/geoipupdate
		cd geoipupdate
		./bootstrap
		./configure
		make
		make install
	EOH
end

# make sure this directory exists
directory '/usr/local/share/GeoIP' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end
