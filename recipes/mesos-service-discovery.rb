#
# Cookbook Name:: sb-mesos
# Recipe:: mesos-service-discovery
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

package 'docker-engine'
package 'haproxy'
package 'unzip'

ip = node['mesos']['host_ip']
consul_master_host = node['consul']['first_master_host']

docker_service 'default' do
  #host ['unix:///var/run/docker.sock', 'tcp://127.0.0.1:2376', 'tcp://0.0.0.0:4243', 'storage-opt dm.thinpooldev']
  #dns ['172.17.42.1', '10.22.0.2']
  #dns_search ['service.consul']
  action [:create, :start]
end

docker_image 'gliderlabs/consul-server'

docker_container 'consul' do
  repo 'gliderlabs/consul-server'
  restart_policy 'always'
  privileged true
  host_name "#{ip}"
  port ["#{ip}:8300:8300", "#{ip}:8301:8301", "#{ip}:8301:8301/udp", "#{ip}:8302:8302", "#{ip}:8302:8302/udp", "#{ip}:8400:8400", "#{ip}:8500:8500", "#{ip}:53:8600/udp", "#{ip}:53:8600/tcp"]
  env ['SERVICE_NAME=consul', 'SERVICE_TAGS=consul']
  if node['consul']['first_master_host'] == "#{ip}"
    command "-server -advertise #{ip} -bootstrap"
  else
    command "-server -advertise #{ip} -join #{consul_master_host}"
  end
  notifies :redeploy, 'docker_container[registrator]', :immediately
end

docker_image 'gliderlabs/registrator' do
  # Added tag due to https://github.com/gliderlabs/registrator/issues/425
  tag 'v6'
end

docker_container 'registrator' do
  # Added tag due to https://github.com/gliderlabs/registrator/issues/425
  tag 'v6'
  repo 'gliderlabs/registrator'
  restart_policy 'always'
  network_mode 'host'
  command "consul://#{ip}:8500"
  action :run
  volumes ['/var/run/docker.sock:/tmp/docker.sock']
end

# Only run these on masters
if node['mesos']['master_hosts'].keys.include?("#{ip}")

  service 'consul-template' do
    action :nothing 
    supports :status => true, :start => true, :stop => true, :reload => true
    subscribes :restart, 'cookbook_file[/etc/systemd/system/consul-template.service]', :delayed
    subscribes :restart, 'cookbook_file[/etc/consul-template/templates/haproxy.ctmpl]', :delayed
    subscribes :restart, 'template[/etc/consul-template/configs/haproxy.json]', :delayed
  end
  
  remote_file "#{Chef::Config[:file_cache_path]}/consul-template.zip" do
    source node['consul']['template']['url']
    checksum node['consul']['template']['checksum']
    owner 'root'
    group 'root'
    mode '0755'
    not_if { ::File.exists?('/usr/local/sbin/consul-template') }
  end
  
  execute 'install consul-template' do
    creates '/usr/local/sbin/consul-template'
    command "unzip #{Chef::Config[:file_cache_path]}/consul-template.zip -d /usr/local/sbin/"
  end
  
  cookbook_file '/etc/systemd/system/consul-template.service' do
    source 'consul-template.service'
    mode '0644'
    action :create
    owner 'root'
    group 'root'
  end
  
  execute 'systemctl daemon-reload' do
    command 'systemctl daemon-reload'
    action :nothing
    subscribes :run, 'cookbook_file[/etc/systemd/system/consul-template.service]', :immediately
  end
  
  directory '/etc/consul-template/templates/' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
    recursive true
  end
  
  directory '/etc/consul-template/configs/' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end
  
  template '/etc/consul-template/configs/haproxy.json' do
    source 'mesos_haproxy_consul_conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end
  
  cookbook_file '/etc/consul-template/templates/haproxy.ctmpl' do
    source 'mesos_haproxy_template'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end
end