#!/bin/bash

# USAGE: syn_single_file FILE_SIZE(byte)
# 测试 nbftp 传输单个文件的流量消耗，生成文件到监控目录，文件名为指定大小，启动抓包
# 在 /media 下生成一个大小为 FILE_SIZE (byte) 的文件，文件名为 FILE_SIZE(9位数)，每个字节均为 \0，然后针对 nbftp 启动 tcpdump
syn_single_file(){
        if [ $# -ne 1 ]; then
                echo "USAGE: syn_single_file FILE_SIZE(byte)"
                exit 1
        fi
        echo "Going to generate a file of $1 bytes into /media and start tcpdump for nbftp"
        # 生成文件
        filename=$(printf "%09d" $1)
        tmp_file=/tmp/$filename
        dd if=/dev/zero of=$tmp_file bs=1 count=$1
        sudo mv $tmp_file /media/

        dump_path=~/trans_cmp/dumpfile/syn_single_file/nbftp_dumpfile
        sudo tcpdump -i wlp4s0 -vvv 'port 9999 and host 10.0.0.4' -w $dump_path/nbftp_$filename
}
#syn_single_file $1

# USAGE: syn_multi_file FILE_SIZE(byte) FILE_NUM
# 测试 nbftp 传输单个文件的流量消耗，生成文件到监控目录，文件名为指定大小，启动抓包
# 在 /media 下生成 FILE_NUM 个大小为 FILE_SIZE (byte) 的文件，文件名为 FILE_SIZE(9位数)，每个字节均为 \0，然后针对 nbftp 启动 tcpdump
syn_multi_file(){
        if [ $# -ne 2 ]; then
                echo "USAGE: syn_multi_file FILE_SIZE(byte) FILE_NUM"
                exit 1
        fi
        echo "Going to generate $2 files of $1 bytes into /media and start tcpdump for nbftp"

        # 生成文件
        filename=$(printf "%09d" $1)
        tmp_file=/tmp/$filename
        dd if=/dev/zero of=$tmp_file bs=1 count=$1
        counter=0
        num=$2
        while [ $counter -lt $num ]
        do
                counter=`expr $counter + 1`
                seq=$(printf "%03d" $counter)
                copy=/media/${filename}_${seq}
                sudo cp $tmp_file $copy
                echo "Have generated $copy"
        done

        rm $tmp_file

        dump_path=~/trans_cmp/dumpfile/syn_multi_file/nbftp_dumpfile_$filename
        mkdir -p $dump_path
        number=$(printf "%03d" $num)
        sudo tcpdump -i wlp4s0 -vvv 'port 9999 and host 10.0.0.4' -w $dump_path/nbftp_$number
}
#syn_multi_file $1 $2



# USAGE: file_flow FILE_SIZE INTERVAL NUM
# 在 ~/rsync 下生成一个大小为 FILE_SIZE (byte) 的文件，文件名为 FILE_SIZE(9位数)，每个字节均为 \0
# 生成文件时间间隔为 INTERVAL，总生成文件数为 NUM
# file_flow 1024 10 1
file_flow(){
        dir=/media
        size=$1
        interval=$2
        num=$3

        # 生成文件到待同步目录
        filename=flow_$(printf "%09d" $size)    # e.g. flow_000000123
        tmp_file=/tmp/$filename
        dd if=/dev/zero of=$tmp_file bs=1 count=$size

        for i in `seq 1 $num`; do
                name=${filename}_$(printf "%03d" $i)    # e.g. flow_000000123_001
                sudo cp $tmp_file $dir/$name
                echo "Have generated $dir/$name, $i/$num"
                sleep $interval
        done

        rm $tmp_file
}
file_flow $1 $2 $3



# USAGE: diff_block_size FILE_SIZE(byte) BLOCK_SIZE
# 测试 nbftp 传输单个文件，在不同 block_size 下的流量消耗，生成文件到监控目录，文件名为指定大小，启动抓包
# 在 /media 下生成一个大小为 FILE_SIZE (byte) 的文件，文件名为 FILE_SIZE(9位数)，每个字节均为 \0，然后针对 nbftp 启动 tcpdump
diff_block_size(){
        if [ $# -ne 2 ]; then
                echo "USAGE: diff_block_size FILE_SIZE(byte) BLOCK_SIZE"
                exit 1
        fi
        echo "Going to generate a file of $1 bytes into /media and start tcpdump for nbftp"
        # 生成文件
        filename=block_$(printf "%09d" $1)_$(printf "%07d" $2)    # e.g. block_000000123_0001024
        tmp_file=/tmp/$filename
        dd if=/dev/zero of=$tmp_file bs=1 count=$1
        sudo mv $tmp_file /media/

        dump_path=~/trans_cmp/dumpfile/diff_block_size
        sudo tcpdump -i wlp4s0 -vvv 'port 9999 and host 10.0.0.4' -w $dump_path/nbftp_$filename
}
#diff_block_size $1 $2
