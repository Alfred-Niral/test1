#!/bin/bash

NO_TO_RLF=0
cnt=0

get_enb_stats()
{
  /usr/bin/expect << timeout > drrc.log
  set timeout -1
  spawn telnet 10.102.81.75
  expect "75XXEVB login: "
  send "root\r"
  expect "~ # "
  send "cli\r"
  expect "uBTS>"
  send "rsc\r"
  expect "uBTS>"
  send "drrcccstats\r"
  expect "uBTS>"
  send "dc1c2stats 0\r"
  expect "uBTS>"
  send "exit\r"
  expect "~ # "
  send "exit\r"
  exit
timeout
echo "Closing Session"
}

phytime=`date +"%H%M%S"`
out_name=PhyLogs_${phytime}
timeout 36000s ./phy_logreceiver -a "10.102.81.13" -p 9992 -o ./$out_name/ &

while [[ 1 ]];do
    cnt=$((cnt+1))
    sleep $((5*1))
    #sleep $((5*60))
    get_enb_stats
    #ssh root@10.102.81.75 'sh enb_logger.sh';scp root@10.102.81.75:/drrc.log .
    RLF_CURR=`cat drrc.log | awk '/Number of UE released due to Radio Link Failure/{print $1}'`
    echo " ITERATION $cnt : RLF_CURR = $RLF_CURR "
    if [[ $RLF_CURR -gt $NO_TO_RLF ]];then
        sleep 1
        killall -9 phy_logreceiver;killall -9 phy_logreceiver
        sleep 1
        tar -cvzf RLF${cnt}_PhyStack_logs.tgz drrc.log PhyLogs_${phytime}/
        rm -fr PhyLogs_${phytime} drrc.log

        phytime=`date +"%H%M%S"`
        sleep 1
        out_name=PhyLogs_${phytime}
        timeout 36000s ./phy_logreceiver -a "10.102.81.13" -p 9992 -o ./$out_name/ &
        NO_TO_RLF=$RLF_CURR
    fi
done



