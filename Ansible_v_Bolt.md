# Ansible and Puppet Bolt comparison

Both Ansible and Puppet Bolt offer similar functionality: remote sys admin tasks over SSH using CLI tools.  This doc is aiming to provide and unbiased comparison of the two on CentOS 7.  It is also the understanding of one person trying to explore the differences.  Best effort type stuff.

Almost all information has been gleaned from the Ansible and Bolt user documentation. <br />
* [Welcome to Bolt](https://puppet.com/docs/bolt/1.x/bolt.html)
* [Ansible User Guide](https://docs.ansible.com/ansible/latest/user_guide/)

## Overview of Features
| Feature | Ansible | Bolt |
| ------- | ------- | ---- |
| **Release Year** | 2012 | 2017 |
| **Authentication** | SSH | SSH |
| **Remote Agent / Daemon Required** | No | No |
| **Package source** | Native CentOS 'extras' channel | Puppet Repo (non-native) |
| **Command execution** | CLI | CLI |
| **Target options** | Ansible 'hosts' inventory file | Option to pass host on command line, inside a Plan, a YAML inventory file |
| **Task management** | "Ansible Playbooks" | "Tasks and Plans" |
| **Command Mechanism** | An extensive collection of local modules that deal with the under-the-covers stuff | A few generic commands to execute everything such as 'command', 'file', 'script', 'plan', 'task', and 'apply'.  There are also some Puppet-provided modules such as 'package' and 'service'.  At this time, Bolt Relies on admin to develop scripting |
| **Collection of Native Modules** | 100's | 10's |
| **Task wrappers** | Ansible-provided modules ( shell, yum, etc.) | Bolt commands |
| **Parallel Tasks** | Yes | Yes |
| **Ease of Bundling Tasks** | Not too bad.  Knowing YAML well is they key.  Everything is done in YAML | A bit of overhead and scripting mindset is required.  Seems a bit cumbersome, but much easier to read |
| **Custom Modules / Tasks** | Although largely unrequired because of the vast collection of Ansible modules available, writing a custom one is a bit tedious and is limited to Python, Powershell, and/or small binaries.  Strict guidelines are in place for development. | Quite flexible.  As this is the primary means of implementing useful tasks with Bolt, any language is supported provided that language is supported on the remote system. |

**Which one then?** <br />
There's no clear "winner".  If the collection of commands you expect to run are common like 'yum' and 'package' or even less common ones listed in [Ansible Modules Index](https://docs.ansible.com/ansible/2.5/modules/modules_by_category.html), Ansible will work nicely.  If you're looking for maybe more customizable task creation with various languages other than Python, Bolt would be a great option.  That's my take.

## Commands in-depth
### Setup
Both Ansible and Bolt to function as **agentless** admin tools over **SSH**.  This means, there is no daemon running on your remote systems waiting for commands.  There IS however, a control/origin/master server that is a centralized point for issuing commands remotely.  To function, you must first establish **SSH keys** for <code>root</code> or a privileged user.  Any remote servers' <code>~/.ssh/authorized_keys</code> file must have the **public key** from the SSH keypair on the control server.  There are plenty of tutorials online for how to get this done using <code>ssh-keygen</code>.  If you'd like, there is also a reference at the bottom of this page.

### Installation
#### Ansible
`sudo yum install ansible`

#### Bolt

```shell
sudo rpm -Uvh https://yum.puppet.com/puppet6/puppet6-release-el-6.noarch.rpm
sudo yum install puppet-bolt
```

### Running a simple command
In this test, it appears Ansible does not support passing an FQDN on the command line.  The first step in executing the command is by updating the hosts inventory file then running a command with that as a reference.

#### Ansible
1. Update the Ansible hosts inventory:
```shell
[root@control .ssh]# cat /etc/ansible/hosts
[remote]
    www.remote.com
```
2. Run the remote command referencing the tagged hosts section:
```shell
[root@control .ssh]# ansible remote -m shell -a '/bin/uname'
www.remote.com | SUCCESS | rc=0 >>
Linux
```

#### Bolt
1. You have the option to pass an FQDN right on the command line.
```shell
[root@control .ssh]# bolt command run /bin/uname --nodes www.remote.com --user root
Started on www.remote.com...
Finished on www.remote.com:
  STDOUT:
    Linux
Successful on 1 node: www.remote.com
Ran on 1 node in 0.44 seconds
```

### Task Parallelism
For this test, I simply ran a sleep command to see if the cumulative time would be greater than the sleep time ran accross each node. <br />
Note the execution time accross the 4 nodes was between not much more than 5 seconds, where each slept for 5 seconds.<br />
#### Ansible
```shell
[root@control ~]# cat /etc/ansible/hosts
[remote]
    www.remote.com
    www.remote2.com
    www.remote3.com
    www.remote4.com
[root@control ~]# date; ansible remote -m shell -a '/bin/sleep 5; echo $?'; date
Thu Nov  1 10:56:08 CDT 2018
www.remote4.com | SUCCESS | rc=0 >>
0

www.remote.com | SUCCESS | rc=0 >>
0

www.remote2.com | SUCCESS | rc=0 >>
0

www.remote3.com | SUCCESS | rc=0 >>
0

Thu Nov  1 10:56:14 CDT 2018
[root@control ~]#
```

#### Bolt
```shell
[root@control ~]# cat bolt.hosts
www.remote.com
www.remote2.com
www.remote3.com
www.remote4.com
[root@control ~]# bolt command run '/bin/sleep 5; echo $?' --nodes @bolt.hosts --user root --no-host-key-check
Started on www.remote.com...
Started on www.remote2.com...
Started on www.remote4.com...
Started on www.remote3.com...
Finished on www.remote4.com:
  STDOUT:
    0
Finished on www.remote.com:
  STDOUT:
    0
Finished on www.remote2.com:
  STDOUT:
    0
Finished on www.remote3.com:
  STDOUT:
    0
Successful on 4 nodes: www.remote.com,www.remote2.com,www.remote3.com,www.remote4.com
Ran on 4 nodes in 5.68 seconds
[root@control ~]#
```

### Running Collection of Tasks
#### Ansible Playbook

This situation is just a simple play against two collections of servers *remote_1* and *remote_2*.
1. A quick look at the hosts list.
```shell
[root@control ~]# cat /etc/ansible/hosts
[remote_1]
    www.remote.com
    www.remote2.com
[remote_2]
    www.remote3.com
    www.remote4.com
[root@control ~]#
```
2. Our `playbook.yaml` is pretty simple.  We use *register* to get reference *stdout* later on in debug.
```yaml
---
- hosts: remote_1
  remote_user: root
  tasks:
  - name: ensure openssl is up-to-date
    yum:
      name: openssl
      state: latest
  - name: echo openssl version
    shell: /bin/openssl version
    register: openssl_ver
  - debug: msg="{{ openssl_ver.stdout }}"
- hosts: remote_2
  remote_user: root
  tasks:
  - name: get the uname
    command: /bin/uname
    register: uname
  - debug: msg="{{ uname.stdout }}"
```
3. Running the playbook
```shell
[root@control ~]# ansible-playbook playbook.yml

PLAY [remote_1] ********************************************************************************************

TASK [Gathering Facts] *************************************************************************************
ok: [www.remote.com]
ok: [www.remote2.com]

TASK [ensure openssl is up-to-date] ************************************************************************
ok: [www.remote2.com]
ok: [www.remote.com]

TASK [echo openssl version] ********************************************************************************
changed: [www.remote.com]
changed: [www.remote2.com]

TASK [debug] ***********************************************************************************************
ok: [www.remote.com] => {
    "msg": "OpenSSL 1.0.2k-fips  26 Jan 2017"
}
ok: [www.remote2.com] => {
    "msg": "OpenSSL 1.0.2k-fips  26 Jan 2017"
}

PLAY [remote_2] ********************************************************************************************

TASK [Gathering Facts] *************************************************************************************
ok: [www.remote4.com]
ok: [www.remote3.com]

TASK [get the uname] ***************************************************************************************
changed: [www.remote4.com]
changed: [www.remote3.com]

TASK [debug] ***********************************************************************************************
ok: [www.remote3.com] => {
    "msg": "Linux"
}
ok: [www.remote4.com] => {
    "msg": "Linux"
}

PLAY RECAP *************************************************************************************************
www.remote.com             : ok=4    changed=1    unreachable=0    failed=0
www.remote2.com            : ok=4    changed=1    unreachable=0    failed=0
www.remote3.com            : ok=3    changed=1    unreachable=0    failed=0
www.remote4.com            : ok=3    changed=1    unreachable=0    failed=0
```
#### Bolt
Bolt requires you learn the Puppet language to write plans.  It's doable if you're a decent scripter.  In order to parse the returned data from query-like tasks, it's important to have a grasp on iterating and understanding returned data structures.

1. First you have to create a module to house your plans.  My example is `boltmodule` with my plan named `example`.  It's helpful in this step to be familiar with Puppet organization. Note the contents of ```boltmodule/plans/example.pp``` below; there are many more keystrokes to accomplish the same tasks as the Ansible example above.  There's a trade-off here: more charactes, but greater flexibility (i.e. looping and logic checks).
```puppet
plan boltmodule::example(){
  $remotes_1 = ['www.remote.com', 'www.remote2.com']
  $p = run_task('package', $remotes_1, action => 'upgrade', name => 'openssl')
  $p.each |$result| {
    $node = $result.target.name
    if $result.ok {
      $res = $result.value
      notice("${node} returned:\n  ${res}")
    } else {
      notice("${node} errored with a message: ${result.error.message}")
    }
  }
  $remotes_2 = ['www.remote3.com', 'www.remote4.com']
  $f = run_command('/bin/uname', $remotes_2)
  $f.each |$result| {
    $node = $result.target.name
    if $result.ok {
      $res = $result.value
      notice("${node} returned:\n  ${res}")
    } else {
      notice("${node} errored with a message: ${result.error.message}")
    }
  }
}
```
2. Run the plan:
```shell
[root@control ~]# bolt plan run boltmodule::example --modulepath ./ --user=root --no-host-key-check
Starting: plan boltmodule::example
Starting: task package on www.remote.com, www.remote2.com
Finished: task package with 0 failures in 3.14 sec
www.remote.com returned:
  {old_version => 1:1.0.2k-12.el7, version => 1:1.0.2k-12.el7}
www.remote2.com returned:
  {old_version => 1:1.0.2k-12.el7, version => 1:1.0.2k-12.el7}
Starting: command '/bin/uname' on www.remote3.com, www.remote4.com
Finished: command '/bin/uname' with 0 failures in 0.52 sec
www.remote3.com returned:
  {stdout => Linux
, stderr => , exit_code => 0}
www.remote4.com returned:
  {stdout => Linux
, stderr => , exit_code => 0}
Finished: plan boltmodule::example in 3.68 sec
```
### Custom Modules/Tasks
Between the two of them, Bolt is much easier and more flexible for setting up custom tasks right out of the gate.  It allows you to write them in any language that will run on a target host (bash, python, perl, etc.).  You do need to have the tasks within a module though, another Puppet-style convention.  Ansible requires more formal development and has to be written in Python or a compiled binary file.  On the other hand, many tasks are already coded in Ansible modules readily available from the community.  

#### Bolt
Here's a quick example for getting the uname:
```shell
[root@control ~]# cat boltmodule/tasks/mytask.sh
#!/bin/bash

/bin/uname
[root@control ~]# bolt task run boltmodule::mytask --modulepath ./ --user=root --no-host-key-check --nodes='www.remote.com'
Started on www.remote.com...
Finished on www.remote.com:
  Linux
  {
  }
Successful on 1 node: www.remote.com
Ran on 1 node in 0.76 seconds
[root@control ~]
```

#### Ansible
A custom module wasn't built for this excersize.  For more information, check out [Ansible Module Development Walkthrough](https://docs.ansible.com/ansible/2.5/dev_guide/developing_modules_general.html#new-module-development)


### Setting up ssh keys

1. Create the keys with <code>ssh-keygen</code> on the **control** server:
```shell
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
```
NOTE: A password is not required.
2.  Get the contents of the ONLY the **public** key.  **IMPORTANT: NEVER SHARE THE PRIVATE KEY!!!**
```shell
[root@control .ssh]# cat remote_commands.pub
ssh-rsa ABC123(REDACTED A few hudred bites)XYZ root@control
```
3. Paste the contents of the **PUBLIC** key into the <code>authorized_keys</code> file on the **remote** server.
```shell
[root@remote ~]# mkdir ~/.ssh && chmod 700 ~/.ssh # if it doesn't exist
[root@remote ~]# cd ~/.ssh
[root@remote .ssh]# vim authorized_keys
[root@remote .ssh]# cat authorized_keys
ssh-rsa ABC123(REDACTED A few hudred bites)XYZ root@control
```
4. Test the connection from the **control** server to the **remote** server with a simple command.
```shell
[root@control .ssh]# ssh www.remote.com '/bin/uname'
Linux
```
