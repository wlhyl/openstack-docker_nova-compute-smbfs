#!/bin/bash

if [ -z "$RABBIT_HOST" ];then
  echo "error: RABBIT_HOST not set"
  exit 1
fi

if [ -z "$RABBIT_USERID" ];then
  echo "error: RABBIT_USERID not set"
  exit 1
fi

if [ -z "$RABBIT_PASSWORD" ];then
  echo "error: RABBIT_PASSWORD not set"
  exit 1
fi

if [ -z "$KEYSTONE_INTERNAL_ENDPOINT" ];then
  echo "error: KEYSTONE_INTERNAL_ENDPOINT not set"
  exit 1
fi

if [ -z "$KEYSTONE_ADMIN_ENDPOINT" ];then
  echo "error: KEYSTONE_ADMIN_ENDPOINT not set"
  exit 1
fi

if [ -z "$NOVA_PASS" ];then
  echo "error: NOVA_PASS not set. user nova password."
  exit 1
fi

if [ -z "$MY_IP" ];then
  echo "error: MY_IP not set. my_ip use management interface IP address."
  exit 1
fi

if [ -z "$NOVNCPROXY_BASE_URL" ];then
  echo "error: NOVNCPROXY_BASE_URL not set."
  exit 1
fi

# GLANCE_HOST = pillar['glance']['internal_endpoint']
if [ -z "$GLANCE_HOST" ];then
  echo "error: GLANCE_HOST not set."
  exit 1
fi

# NEUTRON_INTERNAL_ENDPOINT = pillar['neutron']['internal_endpoint']
if [ -z "$NEUTRON_INTERNAL_ENDPOINT" ];then
  echo "error: NEUTRON_INTERNAL_ENDPOINT not set."
  exit 1
fi

if [ -z "$NEUTRON_PASS" ];then
  echo "error: NEUTRON_PASS not set."
  exit 1
fi

if [ -z "$REGION_NAME" ];then
  echo "error: REGION_NAME not set."
  exit 1
fi

if [ -z "$SMB_PASS" ];then
  echo "error: SMB_PASS not set."
  exit 1
fi

CRUDINI='/usr/bin/crudini'

    $CRUDINI --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
    $CRUDINI --set /etc/nova/nova.conf DEFAULT state_path /var/lib/nova

    $CRUDINI --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit

    $CRUDINI --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
    $CRUDINI --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
    $CRUDINI --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWORD

    $CRUDINI --set /etc/nova/nova.conf DEFAULT auth_strategy keystone

    $CRUDINI --del /etc/nova/nova.conf keystone_authtoken

    $CRUDINI --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$KEYSTONE_INTERNAL_ENDPOINT:5000
    $CRUDINI --set /etc/nova/nova.conf keystone_authtoken auth_url http://$KEYSTONE_ADMIN_ENDPOINT:35357
    $CRUDINI --set /etc/nova/nova.conf keystone_authtoken auth_plugin password
    $CRUDINI --set /etc/nova/nova.conf keystone_authtoken project_domain_id default
    $CRUDINI --set /etc/nova/nova.conf keystone_authtoken user_domain_id default
    $CRUDINI --set /etc/nova/nova.conf keystone_authtoken project_name service
    $CRUDINI --set /etc/nova/nova.conf keystone_authtoken username nova
    $CRUDINI --set /etc/nova/nova.conf keystone_authtoken password $NOVA_PASS

    $CRUDINI --set /etc/nova/nova.conf DEFAULT my_ip $MY_IP

    $CRUDINI --set /etc/nova/nova.conf spice enabled false
    $CRUDINI --set /etc/nova/nova.conf DEFAULT vnc_enabled True
    $CRUDINI --set /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
    $CRUDINI --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address $MY_IP
    $CRUDINI --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://${NOVNCPROXY_BASE_URL}:6080/vnc_auto.html
    
    $CRUDINI --set /etc/nova/nova.conf DEFAULT force_config_drive True
    
    $CRUDINI --set /etc/nova/nova.conf glance host $GLANCE_HOST

    $CRUDINI --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

    # 设置compute_drive 为libvirt
    $CRUDINI --set /etc/nova/nova.conf DEFAULT compute_driver libvirt.LibvirtDriver
    $CRUDINI --del /etc/nova/nova.conf libvirt
    $CRUDINI --set /etc/nova/nova.conf libvirt virt_type kvm
    # 禁用密码注入
    $CRUDINI --set /etc/nova/nova.conf libvirt inject_password False
    $CRUDINI --set /etc/nova/nova.conf libvirt inject_key False
    $CRUDINI --set /etc/nova/nova.conf libvirt inject_partition -2
    $CRUDINI --set /etc/nova/nova.conf libvirt disk_cachemodes \"file=writeback\"
    $CRUDINI --set /etc/nova/nova.conf libvirt smbfs_mount_options -o username=root,password=${SMB_PASS}
    
    # 设置vcpu pin
    PHY_CPU_CORE=$((`nproc`-1))
    $CRUDINI --set /etc/nova/nova.conf DEFAULT vcpu_pin_set \"0-${PHY_CPU_CORE},^0,^1,^2,^3\"

    # 配置网络
    $CRUDINI --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
    $CRUDINI --set /etc/nova/nova.conf DEFAULT security_group_api neutron
    $CRUDINI --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
    $CRUDINI --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
    
    $CRUDINI --del /etc/nova/nova.conf neutron
    $CRUDINI --set /etc/nova/nova.conf neutron url http://${NEUTRON_INTERNAL_ENDPOINT}:9696
    $CRUDINI --set /etc/nova/nova.conf neutron auth_url http://$KEYSTONE_ADMIN_ENDPOINT:35357
    $CRUDINI --set /etc/nova/nova.conf neutron auth_region  $REGION_NAME
    $CRUDINI --set /etc/nova/nova.conf neutron auth_plugin password
    $CRUDINI --set /etc/nova/nova.conf neutron project_domain_id default
    $CRUDINI --set /etc/nova/nova.conf neutron user_domain_id default
    $CRUDINI --set /etc/nova/nova.conf neutron project_name service
    $CRUDINI --set /etc/nova/nova.conf neutron username neutron
    $CRUDINI --set /etc/nova/nova.conf neutron password $NEUTRON_PASS
    
    $CRUDINI --set /etc/nova/nova.conf DEFAULT reserved_host_memory_mb 4096

/usr/bin/supervisord -n