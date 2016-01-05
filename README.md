# 环境变量
- KEYSTONE_INTERNAL_ENDPOINT: keystone internal endpoint
- KEYSTONE_ADMIN_ENDPOINT: keystone admin endpoint
- RABBIT_HOST: rabbitmq IP
- RABBIT_USERID: rabbitmq user
- RABBIT_PASSWORD: rabbitmq user 的 password
- NOVA_PASS: openstack nova密码
- MY_IP: my_ip
- NOVNCPROXY_BASE_URL: nova-novncproxy ip
- GLANCE_ENDPOINT: glance endpoint
- NEUTRON_INTERNAL_ENDPOINT: neutron internal endpoint
- NEUTRON_PASS: openstack neutron 密码

# volumes:
- /etc/nova/: /etc/nova

# 启动nova-compute
```bash
docker run -d --name nova-compute --privileged \
    -v /etc/nova/:/etc/nova \
    -e RABBIT_HOST=10.64.0.52 \
    -e RABBIT_USERID=openstack \
    -e RABBIT_PASSWORD=openstack \
    -e KEYSTONE_ENDPOINT=10.64.0.52 \
    -e NOVA_PASS=nova \
    -e NOVNCPROXY_BASE_URL=10.64.0.52 \
    -e MY_IP=10.64.0.52 \
    -e GLANCE_ENDPOINT=10.64.0.52 \
    10.64.0.50:5000/lzh/nova-api:kilo
```

# 直接从ceph引导vm
编辑ceph.conf
```bash
#ceph daemon /var/run/ceph/ceph-client.cinder.19195.32310016.asok help
[client]
    rbd cache = true
    rbd cache writethrough until flush = true
    admin socket = /var/run/ceph/guests/$cluster-$type.$id.$pid.$cctid.asok
    log file = /var/log/qemu/qemu-guest-$pid.log
    rbd concurrent management ops = 20

mkdir -p /var/run/ceph/guests/ /var/log/qemu/
chown libvirt-qemu:libvirt-qemu /var/run/ceph/guests /var/log/qemu/
```
编辑/etc/nova/nova-compute.conf
```bash
images_type = rbd
images_rbd_pool = vms
images_rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = cinder
rbd_secret_uuid = 457eb676-33da-42ec-9a8c-9293d545c337
disk_cachemodes="network=writeback"
```