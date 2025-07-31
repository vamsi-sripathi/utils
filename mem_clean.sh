#!/bin/bash

sync; echo 3 > /proc/sys/vm/drop_caches; echo 1 >/proc/sys/vm/compact_memory
# echo 2 > /proc/sys/vm/zone_reclaim_mode
