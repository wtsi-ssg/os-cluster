#!/bin/bash
#
# install_cloud-init.sh
#  Installs the cloud init package after building
#

echo "Installing cloud-init"
PACKER_BUILDER_TYPE=openstack
echo ${PACKER_BUILDER_TYPE}
if [ ${PACKER_BUILDER_TYPE} != 'null' ] ; then
	apt-get -y install cloud-init
else
	echo "Null builder - skipping install of cloud-init"
fi

echo "Patching cc_disk_setup.py"

cc_disk_setup=/usr/lib/python2.7/dist-packages/cloudinit/config/cc_disk_setup.py
cc_disk_setup_md5=08b45fa565f2cf3fdf31760ae93a6962

chksum=$( md5sum $cc_disk_setup | cut -f1 -d\   )

echo " >${cc_disk_setup_md5}<  >${chksum}< "

if [ ${cc_disk_setup_md5} = ${chksum} ] ; then
	echo "Applying patch"
	patch -p1 $cc_disk_setup <<-EOF
--- cc_disk_setup.py	2016-03-14 15:24:37.179403160 +0000
+++ cc_disk_setup.py.new	2016-03-14 15:24:48.411402930 +0000
@@ -108,7 +108,6 @@
 
         if origname is None:
             continue
-
         (dev, part) = util.expand_dotted_devname(origname)
 
         tformed = tformer(dev)
@@ -121,7 +120,7 @@
 
         if part and 'partition' in definition:
             definition['_partition'] = definition['partition']
-        definition['partition'] = part
+            definition['partition'] = part
 
 
 def value_splitter(values, start=None):
@@ -305,7 +304,7 @@
     # If the child count is higher 1, then there are child nodes
     # such as partition or device mapper nodes
     use_count = [x for x in enumerate_disk(device)]
-    if len(use_count.splitlines()) > 1:
+    if len(use_count) > 1:
         return True
 
     # If we see a file system, then its used
EOF
else
	echo "Version of ${cc_disk_setup} doesn't match expected - not patching"
fi

echo "Installing disk configuration for cloud.cfg"

case ${PACKER_BUILDER_TYPE} in
	null)
		CLOUD_FILE=/tmp/cloud.cfg
		DEVICE=/dev/null
	;;
	openstack)
		CLOUD_FILE=/etc/cloud/cloud.cfg
		DEVICE=/dev/vdb
	;;
	vmware-iso)
		CLOUD_FILE=/etc/cloud/cloud.cfg
		DEVICE=/dev/sdb
	;;
	virtualbox-iso)
		CLOUD_FILE=/etc/cloud/cloud.cfg
		DEVICE=/dev/sdb
	;;
	*)
		echo "Unknown builder!"
		exit 1
	;;
esac

cat >>${CLOUD_FILE} <<EOF
disk_setup:
    ${DEVICE}:
       table_type: 'mbr'
       layout: True
       overwrite: False


fs_setup:
    - label: Data1
      filesystem: 'ext4'
      device: '${DEVICE}'
      partition: '1'
      overwrite: false

mounts:
    - [ ${DEVICE}, /home, auto, "defaults" ]

EOF
