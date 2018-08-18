#!/bin/bash

###########################################################
#  description: inotify+rsync best practice               #
#  author     : 骏马金龙                                  #
#  blog       : http://www.cnblogs.com/f-ck-need-u/       #
###########################################################

# 要求对方启动 rsyncd 服务，己方通过 rsync daemon 的方式把文件 push 到远端
watch_dir=/home/lxx/scp
push_to=jermaine@10.0.0.4

# First to do is initial sync
rm -rf ~/scp/*
rsync -avP --delete --exclude="*.swp" --exclude="*.swx" $watch_dir/ $push_to::home/scp # 同步不包含目录本身

log_dir=~/trans_cmp/script
log_file=$log_dir/inotifywait.log
full_log=$log_dir/inotify_full.log
away_log=$log_dir/inotify_away.log

killall inotifywait
inotifywait -mrq -e delete,close_write,moved_to,moved_from,isdir \
        --timefmt '%Y-%m-%d %H:%M:%S' --format '%w%f:%e:%T' $watch_dir \
        --exclude=".*.swp" >> $log_file &

while true;do
        if [ -s "$log_file" ];then
                echo file changes in $watch_dir, scp begins in 5 seconds...
                sleep 5
                cat $log_file >> $full_log
                grep -i -E "delete|moved_from" $log_file >> $away_log
                ls $watch_dir | xargs -I {} echo "scp $watch_dir/{} $push_to:/home/jermaine/scp"
                ls $watch_dir | xargs -I {} scp $watch_dir/{} $push_to:/home/jermaine/scp
                if [ $? -ne 0 ];then
                        echo "$watch_dir sync to $push_to failed at `date +"%F %T"`,please check it by manual"
                else
                        echo "==================== scp success! ===================="
                fi
                cat /dev/null > $log_file
        else
                sleep 1
        fi
done
