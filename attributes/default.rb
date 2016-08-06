# If a host has multiple nic's and mesos is not running on eth0 or similar
default['mesos']['primary_nic'] = 'eth0'
# Host IP address
default['mesos']['host_ip'] = node['network']['interfaces']["#{node['mesos']['primary_nic']}"]['addresses'].keys[1]
# Zookeeper client port
default['zookeeper']['client_port'] = '2181'
# Mesos cluster name
default['mesos']['master']['cluster_name'] = 'Mesos Sandbox'
# Consul template 
default['consul']['template']['url'] = 'https://releases.hashicorp.com/consul-template/0.14.0/consul-template_0.14.0_linux_amd64.zip'
default['consul']['template']['checksum'] = '7c70ea5f230a70c809333e75fdcff2f6f1e838f29cfb872e1420a63cdf7f3a78'

