#
# Cookbook Name:: sb-mesos
# Recipe:: mesos-master
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

package 'mesos'
package 'marathon'
package 'mesosphere-zookeeper'
package 'docker-engine'
package 'haproxy'

raise 'node[\'mesos\'][\'master_hosts\'] does not have any master hosts added' if node['mesos']['master_hosts'].empty?

mesos_zk = node['mesos']['master_hosts'].keys.map{ |ip| "#{ip}:#{node['zookeeper']['client_port']}" }.join(',')
ip = node['mesos']['host_ip']
consul_master_host = node['consul']['first_master_host']

service 'zookeeper' do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
  subscribes :restart, 'template[/etc/zookeeper/conf/zoo.cfg]', :delayed
  subscribes :restart, 'template[/etc/mesos-master/cluster]', :delayed
end

service 'mesos-master' do
  supports :status => true, :restart => true
  action [ :enable, :start ]
  action :start
end

service 'consul-template' do
  action :nothing 
  supports :status => true, :start => true, :stop => true, :reload => true
  subscribes :restart, 'cookbook_file[/etc/systemd/system/consul-template.service]', :delayed
  subscribes :restart, 'cookbook_file[/etc/consul-template/templates/haproxy.ctmpl]', :delayed
  subscribes :restart, 'template[/etc/consul-template/configs/haproxy.json]', :delayed
end

docker_service 'default' do
  #host ['unix:///var/run/docker.sock', 'tcp://127.0.0.1:2376', 'tcp://0.0.0.0:4243', 'storage-opt dm.thinpooldev']
  #dns ['172.17.42.1', '10.22.0.2']
  #dns_search ['service.consul']
  action [:create, :start]
end

file '/var/lib/zookeeper/myid' do
  content node['mesos']['master_hosts']["#{node['mesos']['host_ip']}"]['zookeeper_myid']
end

template '/etc/zookeeper/conf/zoo.cfg' do
  source 'zookeeper_cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
     :master_hosts => node['mesos']['master_hosts']
  })
end

template '/etc/mesos/zk' do
  source 'mesos_master_zk.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
     :mesos_master_zk_hosts => mesos_zk
  })
end

template '/etc/mesos-master/cluster' do
  source 'mesos_master_cluster_name.erb'
  owner 'root'
  group 'root'
  mode '0644'
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
