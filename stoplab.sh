#!/bin/bash
#
# This is scheduled in CRON. It will run every 20 minutes
# and check for inactivity. It compares the RX and TX packets
# from 20 minutes ago to detect if they significantly increased.
# If they haven’t, it will force the system to sleep.
#

dir="/etc/labasservice/shutdown_if_inactive"
if [ ! -e "$dir" ]; then
  mkdir -p "$dir"
fi

log="$dir/log"
# Get Interface
interface=$(ip -br l | awk '$1 !~ "lo|vir|wl|veth|cni|flan" { print $1}')

# Extract the RX/TX packages
rx=`/sbin/ifconfig $interface | grep -m 1 RX | awk '{print $3}'`
tx=`/sbin/ifconfig $interface | grep -m 1 TX | awk '{print $3}'`

#Write Date to log
date >> $log
echo "Current Values" >> $log
echo "rx: "$rx >> $log
echo "tx: "$tx >> $log

# Check if RX/TX Files Exist
if [ -f $dir/rx ] || [ -f $dir/tx ]; then
  p_rx=`cat $dir/rx` ## store previous rx value in p_rx
  p_tx=`cat $dir/tx` ## store previous tx value in p_tx

  echo "Previous Values" >> $log
  echo "p_rx: "$p_rx >> $log
  echo "t_rx: "$p_tx >> $log

  echo $rx > $dir/rx ## Write packets to RX file
  echo $tx > $dir/tx ## Write packets to TX file

  # Calculate threshold limit
  t_rx=`expr $p_rx + 10000`
  t_tx=`expr $p_tx + 10000`

  echo "Threshold Values" >> $log
  echo "t_rx: "$t_rx >> $log
  echo "t_tx: "$t_tx >> $log

  if [ $rx -le $t_rx ] || [ $tx -le $t_tx ]; then ## If network packets have not changed that much
  echo "Shutting down" >> $log
  echo " " >> $log
  rm $dir/rx
  rm $dir/tx
  echo "No Network Activity so stopping the instance" >> $log
  bash /etc/labasservice/shutdown_if_inactive/stoplab.sh
  fi
#Check if RX/TX Files Doesn’t Exist
else
  echo $rx > $dir/rx ## Write packets to file
  echo $tx > $dir/tx
  echo "Network Activity avaliable" >> $log
fi
