#
# Cookbook Name:: sb-mesos
# Recipe:: mesos-master
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

package 'mesos'
package 'marathon'
package 'mesosphere-zookeeper'

raise 'node[\'mesos\'][\'master_hosts\'] does not have any master hosts added' if node['mesos']['master_hosts'].empty?

mesos_zk = node['mesos']['master_hosts'].keys.map{ |ip| "#{ip}:#{node['zookeeper']['client_port']}" }.join(',')
ip = node['mesos']['host_ip']
consul_master_host = node['consul']['first_master_host']

service 'zookeeper' do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
  subscribes :restart, 'template[/etc/zookeeper/conf/zoo.cfg]', :delayed
  subscribes :restart, 'template[/etc/mesos-master/cluster]', :delayed
  subscribes :restart, 'template[/etc/mesos-master/hostname]', :delayed
  subscribes :restart, 'template[/etc/mesos-master/ip]', :delayed
  subscribes :restart, 'template[/etc/mesos-master/quorum]', :delayed
  subscribes :restart, 'template[/etc/mesos-master/work_dir]', :delayed
end

service 'mesos-master' do
  supports :status => true, :restart => true
  action [ :enable, :start ]
  action :start
  subscribes :restart, 'template[/etc/zookeeper/conf/zoo.cfg]', :delayed
  subscribes :restart, 'template[/etc/mesos-master/cluster]', :delayed
  subscribes :restart, 'template[/etc/mesos-master/hostname]', :delayed
  subscribes :restart, 'template[/etc/mesos-master/ip]', :delayed
  subscribes :restart, 'template[/etc/mesos-master/quorum]', :delayed
  subscribes :restart, 'template[/etc/mesos-master/work_dir]', :delayed
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

template '/etc/mesos-master/hostname' do
  source 'mesos_master_hostname.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/mesos-master/ip' do
  source 'mesos_master_ip.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/mesos-master/quorum' do
  source 'mesos_master_quorum.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/mesos-master/work_dir' do
  source 'mesos_master_work_dir.erb'
  owner 'root'
  group 'root'
  mode '0644'
end