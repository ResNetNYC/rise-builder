# RISE: NYC Neighborhood Network Setup Guide

## Server – Cluster Sync

Josh King – 26-Mar-2020.0

# Introduction

This how-to walks you through the process of setting up two RISE servers
as a two-node failover cluster. This means that we will have two RISE
servers connected to each other in such a way that if one of them fails,
the other one will take over automatically. It’s expected that you’ve
already gone through the Debian Linux Installation section of the RISE:
NYC Neighborhood Network Setup Guide. 

This guide assumes the following:

  - You have a Cincoze DA-1000 server connected to a monitor and
    keyboard that has already been configured according to the first
    part of the guide. This will be the **secondary** server. Please
    note down the hostname of this server that you selected in part one
    of the guide.
  - You have a second Cincoze DA-1000 server that has already been
    configured according to the first part of the guide. This will be
    the **primary** server. Please note down the hostname of this server
    that you selected in part one of the guide as well.
  - Both servers have a connection to the internet via one of their
    ethernet ports. For the purposes of this guide, when looking at the
    ethernet ports on the side of the Cincoze DA-1000, the port
    connected to the internet is assumed to be the rightmost port. This
    can be overridden by the setup script below.
  - The servers are connected to each other via another ethernet cable
    connecting to another one of their ethernet ports. For the purposes
    of this guide, the port connecting the two servers is assumed to be
    the leftmost port. This can also be overridden by the setup script
    below.
  - You have a full-qualified domain name (FQDN) on the local domain in
    mind to be the canonical location of the server cluster, and you
    also have an unused IP address on the local network in mind for that
    domain to be pointed to. This is separate from the IP address that
    each server receives individually, and represents the cluster as a
    whole. With that FQDN and unused IP in mind, the local network DNS
    should be configured to point both the FQDN and a subdomain wildcard
    at the IP address. For example, if your selected unused IP is
    192.0.2.5 and your domain name is server.example.com, you should
    configure your local DNS server to resolve server.example.com and
    \*.server.example.com to 192.0.2.5. Doing so is outside the scope of
    this guide.

## Setup Cluster

Setting up a cluster is complicated and has many separate parts.
Consequently, we are going to install some RISE automation software that
will finish the configuration:

1.  First, we need to install some dependencies so that we can download
    the automation software and run it. Login to the secondary server
    using the username and password you established in the first part of
    the guide and install the *salt-minion,* *python-pygit2, python-pip*
    and *git* packages by running the following command:  
    `sudo apt-get install salt-minion python-pygit2 python-pip git`
2.  We also need a slightly newer version of one dependency than is
    available in the Debian repository. Using the pip tool we just
    installed, run the following command:  
    `sudo pip install docker`
3.  Now, we are going to download the automation tool into our home
    directory:
    ```
    cd \~  
    git clone https://github.com/jheretic/rise-builder.git
    ```
4.  You should now have a directory called `rise-builder` in your home
    directory. It contains information that will inform a tool called
    `salt` (which we installed in step 1) how to configure this server
    to our needs. Enter the directory and and run `salt` with the
    following commands:
    ```
    cd rise-builder
    RISE\_HOSTNAME="\<hostname\>" RISE\_DOMAIN="\<domain\>"
    RISE\_DISK="\<partition 1\>" RISE\_BACKUP\_DISK="\<partition 2\>"
    RISE\_ROLE="secondary" RISE\_ADMIN\_PASSWORD="\<admin password\>"
    RISE\_SANDSTORM\_PASSWORD="\<sandstorm password\>"
    RISE\_PUBLIC\_IP="\<IP address\>" salt-call state.highstate
    ```
    That’s a lot, so let’s talk about each of those options we’re
    providing to *salt *via environment variables:  
    **RISE\_HOSTNAME** is the main hostname that you want your server
    cluster to be available at on your local network. It is not
    necessarily the same as the individual hostname you assigned to this
    server.  
    **RISE\_DOMAIN** is the local DNS domain of your network.  
    **RISE\_DISK** is the name of the disk partition you previously
    created to house the apps that will be running on this server (e.g.,
    /*dev/sdb1*).  
    **RISE\_BACKUP\_DISK** is the name of the disk partition you
    previously created to house backups of the apps running on this
    server (e.g. /*dev/sdb2*).  
    **RISE\_ROLE** is the role this server performs in the failover
    cluster. It is either *primary* or *secondary.  
    ***RISE\_ADMIN\_PASSWORD** is the initial administrative password
    for logging into web applications on this server. It should be a
    strong password and kept in a safe place.  
    **RISE\_SANDSTORM\_PASSWORD** is the password that the app platform,
    Sandstorm, will need in order to authenticate. It can be any strong
    password, you’ll just need it for later in the setup process.  
    **RISE\_PUBLIC\_IP** is the address on the local network that you
    want the server to be available at. It should resolve to hostname
    specified above, and should be different from the IP address this
    server received from the network.  
    This command may take several minutes to complete.
5.  After the previous command has completed successfully, logout and
    switch to the primary server (you may have to switch the keyboard
    and mouse over to it, if you only have one). Complete steps 1-3
    above for the primary server, but when you get to step 4 instead run
    the following commands:  
    ```
    cd rise-builder  
    RISE\_HOSTNAME="\<hostname\>" RISE\_DOMAIN="\<domain\>"
    RISE\_DISK="\<partition 1\>" RISE\_BACKUP\_DISK="\<partition 2\>"
    RISE\_ROLE="primary" RISE\_ADMIN\_PASSWORD="\<admin password\>"
    RISE\_SANDSTORM\_PASSWORD="\<sandstorm password\>"
    RISE\_PUBLIC\_IP="\<IP address\>" salt-call state.highstate
    ```
    This command may take several minutes to complete. When it’s
    completed, you should now have a functional failover cluster\!

## Configure Sandstorm

You should now have the application platform Sandstorm running on port
80 on the server, but it will take a small amount of configuration to
set it up:

1.  We will need an admin token in order to set up Sandstorm. SSH into
    the primary server, and verify that Sandstorm is running by using
    the sandstorm command-line tool:  
    `sandstorm status`
    If it reports that Sandstorm is running, generate an admin-token:  
    `sandstorm admin-token`  
    A unique URL will be printed on the screen. Visit that URL in your
    browser to proceed with setup.
2.  Follow the on-screen instructions to install Sandstorm. When you
    reach the section on Login Providers, click ‘Configure’ next to
    ‘LDAP’ so that we can setup Sandstorm against our local
    authentication server.
3.  In the LDAP configuration popup, enter the following values in the
    corresponding boxes:  
    LDAP Server URL: `ldap://ldap:389`
    Bind user DN: `cn=sandstorm,dc=rise-nyc,dc=com`
    Bind user password: `\<RISE\_SANDSTORM\_PASSWORD\>` you specified
    above
    Base DN: `ou=Users,dc=rise-nyc,dc=com`
    All other options can be left to their default values. Click
    ‘Enable’.
4.  When you reach the email settings, skip them for now.
5.  Sandstorm should now be setup and running on the server\! You can
    login as an admin by using the **RISE\_ADMIN\_PASSWORD** you specified
    above.

## Behind the scenes

TODO
