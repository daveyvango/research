# Ansible and Puppet Bolt comparison

Both Ansible and Puppet Bolt offer similar functionality: remote sys admin tasks over SSH using CLI tools.  This doc is aiming to provide and unbiased comparison of the two on CentOS 7

## Overview of Features
| Feature | Ansible | Bolt |
| ------- | ------- | ---- |
| Authentication | SSH | SSH |
| Package source | Native CentOS 'extras' channel | Puppet Repo (non-native) |


## Commands in-depth

Ansible
<code>sudo yum install ansible</code>

Bolt
<pre>
sudo rpm -Uvh https://yum.puppet.com/puppet6/puppet6-release-el-6.noarch.rpm
sudo yum install puppet-bolt
</pre>
