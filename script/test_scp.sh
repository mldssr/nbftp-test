#!/bin/bash

# 不加参数时输出提示信息
if [ $# -eq 0 ]; then
        echo USAGE:
        echo ./test_scp.sh FILE_SIZE
        echo 测试 rsync 同步单个文件的流量消耗
        echo 清空两端目录，生成文件到待同步目录，文件名为指定大小，启动抓包
        echo 注：需要在另一终端里启动 scp
        exit
fi
# 用tcpdump解析指定文件，计算所有IP包的长度之和
#sudo tcpdump -vvv -r $1 | awk -F '[ ()]' 'NR%2==1 {sum+=$20} END {print "Packets:", NR/2, "\nTotal traffic in byte:", sum}'

# Example
#sudo tcpdump -i wlp4s0 -vvv 'port 9999 and host 10.0.0.4' -w dump_nbftp_no_load_interval10_2min
#sudo tcpdump -i wlp4s0 -vvv 'port 9999 and host 10.0.0.4' -r dump_nbftp_no_load_interval10_2min | awk -F '[ ()]' 'NR%2==1 {sum+=$20} END {print "Packets:", NR/2, "\nTotal traffic in byte:", sum}'

reset_env(){
        rm -rf ~/scp/*
        rsync -avP --delete ~/scp/ jermaine@10.0.0.4:~/scp/
}

# 用法: test_a_file FILE_SIZE
# 参数为要测试文件的大小，单位B
test_a_file(){
        echo Going to test a file with size $1 B
        dump_path=~/trans_cmp/dumpfile/diff_single_size/scp_dumpfile
        # 清空两端目录
        reset_env
        # 生成文件到待同步目录，文件名为指定大小
        filename=$(printf "%09d" $1)    # e.g. 000000123
        tmp_file=/tmp/$filename
        dd if=/dev/zero of=$tmp_file bs=1 count=$1
        mv $tmp_file ~/scp/   #生成好文件后再放入待同步文件夹
        # 抓包
        sudo tcpdump -i wlp4s0 -vvv 'port 22 and host 10.0.0.4' -w $dump_path/scp_$filename
}

test_a_file $1

