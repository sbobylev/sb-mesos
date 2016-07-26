#
# Cookbook Name:: sb-mesos
# Recipe:: mesos-master
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

package 'mesos'
package 'marathon'
package 'mesosphere-zookeeper'

raise 'node[\'mesos\'][\'masters_hosts\'] does not have any master hosts added' if node['mesos']['masters_hosts'].empty?

service 'zookeeper' do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
  subscribes :restart, 'template[/etc/zookeeper/conf/zoo.cfg]', :delayed
end

service 'mesos-master' do
  supports :status => true, :restart => true
  action [ :enable, :start ]
  action :start
end

file '/var/lib/zookeeper/myid' do
  content node['mesos']['masters_hosts']["#{node['mesos']['host_ip']}"]['zookeeper_myid']
end

template '/etc/zookeeper/conf/zoo.cfg' do
  source 'zookeeper_cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
     :master_hosts => node['mesos']['masters_hosts']
  })
end

mesos_zk = node['mesos']['masters_hosts'].keys.map{ |ip| "#{ip}:#{node['zookeeper']['client_port']}" }.join(',')

template '/etc/mesos/zk' do
  source 'mesos_master_zk.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
     :mesos_master_zk_hosts => mesos_zk
  })
end
