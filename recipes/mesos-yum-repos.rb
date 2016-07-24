#
# Cookbook Name:: sb-mesos
# Recipe:: mesos-yum-repos
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

cookbook_file '/etc/pki/rpm-gpg/RPM-GPG-KEY-mesosphere' do
  source 'RPM-GPG-KEY-mesosphere'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

yum_repository 'mesosphere' do
  description 'Mesosphere Packages for EL 7 - $basearch'
  baseurl 'http://repos.mesosphere.io/el/7/$basearch/'
  gpgkey 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mesosphere'
  action :create
end

yum_repository 'mesosphere-noarch' do
  description 'Mesosphere Packages for EL 7 - noarch'
  baseurl 'http://repos.mesosphere.io/el/7/noarch/'
  gpgkey 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mesosphere'
  action :create
end
