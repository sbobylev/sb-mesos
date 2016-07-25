# If a host has multiple nic's and mesos is not running on eth0 or similar
default['mesos']['primary_nic'] = 'eth0'
# Host IP address
default['mesos']['host_ip'] = node['network']['interfaces']["#{node['mesos']['primary_nic']}"]['addresses'].keys[1]
# Zookeeper client port
default['zookeeper']['client_port'] = '2181'
