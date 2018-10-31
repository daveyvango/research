# Ansible and Puppet Bolt comparison

Both Ansible and Puppet Bolt offer similar functionality: remote sys admin tasks over SSH using CLI tools.  This doc is aiming to provide and unbiased comparison of the two on CentOS 7

## Overview of Features
| Feature | Ansible | Bolt |
| ------- | ------- | ---- |
| Authentication | SSH | SSH |
| Remote Agent / Daemon Required | No | No |
| Package source | Native CentOS 'extras' channel | Puppet Repo (non-native) |


## Commands in-depth
### Setup
Both Ansible and Bolt to function as **agentless** admin tools over SSH.  This means, there is no daemon running on your remote systems waiting for commands.  There IS however, a control/origin/master server that is a centralized point for issuing commands remotely.  To function, you must first establish **SSH keys** for <code>root</code> or a privileged user.  Any remote servers' <code>~/.ssh/authorized_keys</code> file must have the **public key** from the SSH keypair on the control server.  There are plenty of tutorials online for how to get this done using <code>ssh-keygen</code>.  Just a brief setup though here:
1. Create the keys with <code>ssh-keygen</code> on the **control** server:
<pre>
[root@control ~]# mkdir ~/.ssh && chmod 700 ~/.ssh # if it doesn't exist
[root@control ~]# cd ~/.ssh
[root@control .ssh]# ssh-keygen -t rsa -b 2048 -f remote_commands
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in remote_commands.
Your public key has been saved in remote_commands.pub.
The key fingerprint is:
SHA256:(REDACTED) root@control
The key's randomart image is:
+---[RSA 2048]----+
|        ...ABC   |
|  (REDACTED)     |
|            ...  |
+----[SHA256]-----+
[root@control .ssh]# ls -la remote_commands*
-rw-------. 1 root root 1679 Oct 31 10:19 remote_commands
-rw-r--r--. 1 root root  394 Oct 31 10:19 remote_commands.pub
</pre>
NOTE: A password is not required.
2.  Get the contents of the ONLY the **public** key.  **IMPORTANT: NEVER SHARE THE PRIVATE KEY!!!**
<pre>
[root@control .ssh]# cat remote_commands.pub
ssh-rsa ABC123(REDACTED A few hudred bites)XYZ root@control
</pre>
3. Paste the contents of the **PUBLIC** key into the <code>authorized_keys</code> file on the **remote** server.
<pre>
[root@remote ~]# mkdir ~/.ssh && chmod 700 ~/.ssh # if it doesn't exist
[root@remote ~]# cd ~/.ssh
[root@remote .ssh]# vim authorized_keys
[root@remote .ssh]# cat authorized_keys
ssh-rsa ABC123(REDACTED A few hudred bites)XYZ root@control
</pre>
4. Test the connection from the **control** server to the **remote** server with a simple command.
<pre>
[root@control .ssh]# ssh www.remote.com '/bin/uname'
Linux
</pre>

### Installation
Ansible
<code>sudo yum install ansible</code>

Bolt
<pre>
sudo rpm -Uvh https://yum.puppet.com/puppet6/puppet6-release-el-6.noarch.rpm
sudo yum install puppet-bolt
</pre>
