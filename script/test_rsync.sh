#!/bin/bash

reset_env(){
        rm -rf ~/rsync/*
        rsync -avP --delete ~/rsync/ jermaine@10.0.0.4:~/rsync/   # Remote Shell 方式
}

# USAGE: syn_single_file FILE_SIZE(byte)
# 测试 rsync 同步单个文件的流量消耗，清空两端目录，生成文件到待同步目录，文件名为指定大小，启动抓包
# 注：需要在另一终端里启动 rsync
# 在 ~/rsync 下生成一个大小为 FILE_SIZE (byte) 的文件，文件名为 FILE_SIZE(9位数)，每个字节均为 \0，然后针对 rsync 启动 tcpdump
syn_single_file(){
        if [ $# -ne 1 ]; then
                echo "USAGE: syn_single_file FILE_SIZE(byte)"
                exit 1
        fi
        echo "Going to generate a file of $1 bytes into ~/rsync and start tcpdump for rsync"
        # 清空两端目录
        reset_env
        # 生成文件到待同步目录，文件名为指定大小
        filename=$(printf "%09d" $1)    # e.g. 000000123
        tmp_file=/tmp/$filename
        dd if=/dev/zero of=$tmp_file bs=1 count=$1
        mv $tmp_file ~/rsync/   #生成好文件后再放入待同步文件夹
        # 抓包
        dump_path=~/trans_cmp/dumpfile/syn_single_file/rsync_dumpfile
        sudo tcpdump -i wlp4s0 -vvv 'port 873 and host 10.0.0.4' -w $dump_path/rsync_$filename
}
#syn_single_file $1


# USAGE: syn_multi_file FILE_SIZE(byte) FILE_NUM
# 测试 rsync 同步多个文件的流量消耗，清空两端目录，生成文件到待同步目录，文件名为指定大小，启动抓包
# 注：需要在另一终端里启动 rsync
# 在 ~/rsync 下生成一个大小为 FILE_SIZE (byte) 的文件，文件名为 FILE_SIZE(9位数)，每个字节均为 \0，然后针对 rsync 启动 tcpdump
syn_multi_file(){
        if [ $# -ne 2 ]; then
                echo "USAGE: syn_multi_file FILE_SIZE(byte) FILE_NUM"
                exit 1
        fi
        echo "Going to generate $2 files of $1 bytes each into ~/rsync and start tcpdump for rsync"

        # 清空两端目录
        reset_env

        # 生成文件到待同步目录，文件名为指定大小
        filename=$(printf "%09d" $1)    # e.g. 000000123
        tmp_file=/tmp/$filename
        dd if=/dev/zero of=$tmp_file bs=1 count=$1
        counter=0
        num=$2
        while [ $counter -lt $num ]
        do
                counter=`expr $counter + 1`
                seq=$(printf "%03d" $counter)
                copy=~/rsync/${filename}_${seq}
                cp $tmp_file $copy
                echo "Have generated $copy"
        done
        rm $tmp_file

        # 抓包
        dump_path=~/trans_cmp/dumpfile/syn_multi_file/rsync_dumpfile_$filename
        mkdir -p $dump_path
        number=$(printf "%03d" $num)
        sudo tcpdump -i wlp4s0 -vvv 'port 873 and host 10.0.0.4' -w $dump_path/rsync_$number
}
#syn_multi_file $1 $2


# USAGE: no_load FILE_SIZE(byte) FILE_NUM
# 测试 rsync 已同步完多个文件后，再同步一次的流量消耗，清空两端目录，生成文件到待同步目录，文件名为指定大小，先同步一次，启动抓包
# 注：需要在另一终端里启动 rsync
# 在 ~/rsync 下生成一个大小为 FILE_SIZE (byte) 的文件，文件名为 FILE_SIZE(9位数)，每个字节均为 \0，先同步一次，然后针对 rsync 启动 tcpdump
no_load(){
        if [ $# -ne 2 ]; then
                echo "USAGE: no_load FILE_SIZE(byte) FILE_NUM"
                exit 1
        fi
        echo "Going to generate $2 files of $1 bytes each into ~/rsync, rsync it, then start tcpdump for rsync"

        # 清空两端目录
        reset_env

        # 生成文件到待同步目录，文件名为指定大小
        filename=$(printf "%09d" $1)    # e.g. 000000123
        tmp_file=/tmp/$filename
        dd if=/dev/zero of=$tmp_file bs=1 count=$1
        counter=0
        num=$2
        while [ $counter -lt $num ]
        do
                counter=`expr $counter + 1`
                seq=$(printf "%03d" $counter)
                copy=~/rsync/${filename}_${seq}
                cp $tmp_file $copy
                echo "Have generated $copy"
        done
        rm $tmp_file

        rsync -avP ~/rsync/ 10.0.0.4::home/rsync/
        sleep 2
        echo "Have synced. Now ready for tcpdump"

        # 抓包
        dump_path=~/trans_cmp/dumpfile/no_load/rsync_dumpfile_$filename
        mkdir -p $dump_path
        number=$(printf "%03d" $num)
        sudo tcpdump -i wlp4s0 -vvv 'port 873 and host 10.0.0.4' -w $dump_path/rsync_$number
}
#no_load $1 $2


# USAGE: file_flow FILE_SIZE INTERVAL NUM
# 在 ~/rsync 下生成一个大小为 FILE_SIZE (byte) 的文件，文件名为 FILE_SIZE(9位数)，每个字节均为 \0
# 生成文件时间间隔为 INTERVAL，总生成文件数为 NUM
# file ~/rsync 777 10 99
file_flow(){
        dir=~/rsync
        size=$1
        interval=$2
        num=$3

        # 清空两端目录
        rm -rf ~/rsync/*
        rsync -avP --delete ~/rsync/ jermaine@10.0.0.4:~/rsync/   # Remote Shell 方式

        # 生成文件到待同步目录
        filename=flow_$(printf "%09d" $size)    # e.g. flow_000000123
        tmp_file=/tmp/$filename
        dd if=/dev/zero of=$tmp_file bs=1 count=$size

        for i in `seq 1 $num`; do
                name=${filename}_$(printf "%03d" $i)    # e.g. flow_000000123_001
                cp $tmp_file $dir/$name
                echo "Have generated $dir/$name, $i/$num"
                sleep $interval
        done

        rm $tmp_file
}
file_flow $1 $2 $3
