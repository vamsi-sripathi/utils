#!/bin/bash
set -o errexit

mkdir -p /mnt/hugetlbfs
chown root:root /mnt/hugetlbfs
mount -t hugetlbfs none /mnt/hugetlbfs

# Allow at least 2GB memory allocatable via 2mb pages
hugeadm --pool-pages-min 2MB:2G

hugeadm --set-recommended-shmmax

chmod 777 /mnt/hugetlbfs

LD_PRELOAD=/usr/lib64/libhugetlbfs.so HUGETLB_VERBOSE=99 HUGETLB_MORECORE=yes ls

hugeadm --pool-list
