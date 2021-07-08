#!/bin/bash -u
##############################################################
###############		        SETUP		      ################
##############################################################
# Set language to make sure same separator (, and .) config is being used
export LC_ALL=C.UTF-8

# setup variables and arguments
while getopts ":f:a:t:h" opt; do
  case $opt in
    a)
    SAMPLES=$OPTARG
    ;;
    f)
    FILE_NAME=$OPTARG
    ;;
    t)
    TIME=$OPTARG
    ;;
    h)
    echo "Usage:"
    echo "This script is used to monitor the internal behaviour of a Raspberry Pi."
    echo ""
    echo "The following arguments can be given: -a | -f | -t"
    echo ""
    echo "Options:"
    echo "-a        To set the amount of samples to be taken. Default is 10 samples."
    echo "-f        To name the output file. Default is 'data'."
    echo "-t        To set the time between samples (in seconds). Default is 10 seconds."
    exit 0
  esac
done
# check if arguments are given, if not set default values
# Amount of samples to be taken
if [ -z "$SAMPLES" ]
then
    SAMPLES=10
fi
# Name of the target file
if [ -z "$FILE_NAME" ]
then
    FILE_NAME='data'
fi
# Time between samples
if [ -z "$TIME" ]
then
    TIME=10
fi
# List of events to monitor using perf
EVENTS="alarmtimer:alarmtimer_fired,alarmtimer:alarmtimer_start,block:block_bio_backmerge,block:block_bio_remap,block:block_dirty_buffer,block:block_getrq,block:block_touch_buffer,block:block_unplug,cachefiles:cachefiles_create,cachefiles:cachefiles_lookup,cachefiles:cachefiles_mark_active,clk:clk_set_rate,cpu-migrations,cs,dma_fence:dma_fence_init,fib:fib_table_lookup,filemap:mm_filemap_add_to_page_cache,gpio:gpio_value,ipi:ipi_raise,irq:irq_handler_entry,irq:softirq_entry,jbd2:jbd2_handle_start,jbd2:jbd2_start_commit,kmem:kfree,kmem:kmalloc,kmem:kmem_cache_alloc,kmem:kmem_cache_free,kmem:mm_page_alloc,kmem:mm_page_alloc_zone_locked,kmem:mm_page_free,kmem:mm_page_pcpu_drain,mmc:mmc_request_start,net:net_dev_queue,net:net_dev_xmit,net:netif_rx,page-faults,pagemap:mm_lru_insertion,preemptirq:irq_enable,qdisc:qdisc_dequeue,random:get_random_bytes,random:mix_pool_bytes_nolock,random:urandom_read,raw_syscalls:sys_enter,raw_syscalls:sys_exit,rpm:rpm_resume,rpm:rpm_suspend,sched:sched_process_exec,sched:sched_process_free,sched:sched_process_wait,sched:sched_switch,sched:sched_wakeup,signal:signal_deliver,signal:signal_generate,skb:consume_skb,skb:kfree_skb,skb:skb_copy_datagram_iovec,sock:inet_sock_set_state,task:task_newtask,tcp:tcp_destroy_sock,tcp:tcp_probe,timer:hrtimer_start,timer:timer_start,udp:udp_fail_queue_rcv_skb,workqueue:workqueue_activate_work,writeback:global_dirty_state,writeback:sb_clear_inode_writeback,writeback:wbc_writepage,writeback:writeback_dirty_inode,writeback:writeback_dirty_inode_enqueue,writeback:writeback_dirty_page,writeback:writeback_mark_inode_dirty,writeback:writeback_pages_written,writeback:writeback_single_inode,writeback:writeback_write_inode,writeback:writeback_written"
# check if file exists, if not then create it
if [ ! -f "$FILE_NAME.csv" ]
then
    # Create the file
    touch "$FILE_NAME.csv"
fi
FINAL_OUTPUT="$FILE_NAME.csv"
TEMP_OUTPUT=temp
##############################################################
#############		  OUTPUT FORMATTING  		##############
##############################################################
# Perf execution to get the order of the events (perf might not ouput them in the specified order)
perf stat -e "$EVENTS" --o "$TEMP_OUTPUT" -a sleep 1
placeholder=$(cat $TEMP_OUTPUT | cut -b 25- | cut -d " " -f 1 | tail -n +6 | head -n -3 | tr "\n" "," | sed 's/.$//')
# header line in file
echo "time,cpu_usage_pct,ram_usage_pct,network_in,network_out,${placeholder}" >> $FINAL_OUTPUT
##############################################################
#############		   MONITORING LOOP			##############
##############################################################
x=1
while [ $x -le $SAMPLES ]
do
    ##############################################################
	#############		   DATA COLLECTION			##############
	##############################################################
    # Perf data collection
    perf stat -e "$EVENTS" --o "$TEMP_OUTPUT" -a sleep "$TIME"
    # Data extraction
    timestamp=$(echo `date +'%T'`)
    cpu=$(echo `top -b -n1 | grep "Cpu(s)" | awk '{print $2 + $4}'`)
    mem=$(echo `free | grep Mem | awk '{print $3/$2}'`)
    network=$(echo `ifstat -i eth0 -q 1 1 | sed -n '3 p' | awk 'OFS="," {print $1,$2}'`)
    hpc=$(cat "$TEMP_OUTPUT" | cut -c -20 | tr -s " " | tail -n +6 | head -n -3 | tr "\n" "," | sed 's/ //g'| sed 's/.$//')
    ##############################################################
	#############			   OUTPUT				##############
	##############################################################
    echo "$timestamp,$cpu,$mem,$network,$hpc" >> $FINAL_OUTPUT
    #up counter and wait
    x=$(( $x + 1 ))
done
exit 0
