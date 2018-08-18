#!/bin/bash

###########################################################
#  description: inotify+rsync best practice               #
#  author     : 骏马金龙                                  #
#  blog       : http://www.cnblogs.com/f-ck-need-u/       #
###########################################################

# 要求对方启动 rsyncd 服务，己方通过 rsync daemon 的方式把文件 push 到远端
watch_dir=/home/lxx/rsync
push_to=10.0.0.4

# First to do is initial sync
rm -rf ~/rsync/*
rsync -avP --delete --exclude="*.swp" --exclude="*.swx" $watch_dir/ $push_to::home/rsync # 同步不包含目录本身

log_dir=~/trans_cmp/script/inotify_log
log_file=$log_dir/inotifywait.log
full_log=$log_dir/inotify_full.log
away_log=$log_dir/inotify_away.log

killall inotifywait
#inotifywait -mrq -e delete,close_write,moved_to,moved_from,isdir \
inotifywait -mrq -e close_write,moved_to \
        --timefmt '%Y-%m-%d %H:%M:%S' --format '%w%f:%e:%T' $watch_dir \
        --exclude=".*.swp" >> $log_file &

interval=3 #测试 syn_single_file, syn_multi_file 和 no_load 时需要设置大一点，file_flow 也要大一点
while true;do
        while [ -s "$log_file" ];do     # 使用 whlile 而非 if 是为了及时处理传输过程中发生文件变化
                echo "file changes in $watch_dir, rsync begins in $interval seconds..."
                sleep $interval     # 一定要先等几秒再清空 $log_file，以便 test_rsync.sh 完成清空目录及生成文件的工作，否则这里的 rsync 会触发两次
                grep -i -E "delete|moved_from" $log_file >> $away_log
                cat $log_file
                cat $log_file >> $full_log
                cat /dev/null > $log_file

                rsync -avP --exclude="*.swp" --exclude="*.swx" $watch_dir/ $push_to::home/rsync
                if [ $? -ne 0 ];then
                        echo "$watch_dir sync to $push_to failed at `date +"%F %T"`,please check it by manual"
#                        echo "$watch_dir sync to $push_to failed at `date +"%F %T"`,please check it by manual" |\
#                                mail -s "inotify+Rsync error has occurred" root@localhost
                else
                        echo "========================= rsync success! ========================="
                fi
        done
        echo "No change"
        sleep 2
done
