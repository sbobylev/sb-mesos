# If a host has multiple nic's and mesos is not running on eth0 or similar
default['mesos']['primary_nic'] = 'eth0'
# Host IP address
default['mesos']['host_ip'] = node['network']['interfaces']["#{node['mesos']['primary_nic']}"]['addresses'].keys[1]
#default['mesos']['masters_hosts'] = []
# The default value of Zookeeper myid is set to the last octet of the ip address of the primary NIC. 
#default['zookeeper']['myid'] = node['mesos']['host_ip'].split('.')[-1]
