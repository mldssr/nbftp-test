#!/bin/bash

# USAGE: gen_file FILE_DIR FILE_SIZE
# 在 FILE_DIR 下生成一个大小为 FILE_SIZE (byte) 的文件，文件名为 FILE_SIZE(9位数)，每个字节均为 \0
# gen_file ~/rsync 777
gen_file(){
        if [ $# -ne 2 ]; then
                echo "USAGE: gen_file FILE_DIR FILE_SIZE(byte)"
                exit 1
        fi

        echo Going to generate a file with size $2 B
        # 生成文件到待同步目录，文件名为指定大小
        filename=$(printf "%09d" $2)    # e.g. 000000123
        tmp_file=/tmp/$filename
        dd if=/dev/zero of=$tmp_file bs=1 count=$2
        dir=$1
        mv $tmp_file $dir
}
#gen_file $1 $2


# USAGE: gen_file_c FILE_DIR FILE_SIZE CHAR
# 在 FILE_DIR 下生成一个大小为 FILE_SIZE (byte) 的文件，文件名为 FILE_SIZE(9位数)，每个字节均为 CHAR
# gen_file_2 ~/rsync 777 A
gen_file_c(){
        if [ $# -ne 3 ]; then
                echo "USAGE: gen_file_c FILE_DIR FILE_SIZE(byte) CHAR"
                exit 1
        fi

        echo "$3" | grep -q "^[a-zA-Z]$"
        if [ $? -ne 0 ];then
                echo "arg3 must be character"
                exit 1
        fi

        filename=$(printf "%09d" $2)    # e.g. 000000123
        tmp_file=/tmp/$filename
        dir=$1
        target_size=$2
        character=$3

        # echo输出默认是带'\n'字符的，所以需要通过dd指定输入字节数
        echo "$character" | dd of=$tmp_file ibs=1 count=1
        while true
        do
                cur_size=`du -b $tmp_file | awk '{print $1}'`
                if [ $cur_size -ge $target_size ];then
                        break
                fi
                remain_size=$(($target_size-$cur_size))
                if [ $remain_size -ge $cur_size ];then
                        input_size=$cur_size
                else
                        input_size=$remain_size
                fi
                dd if=$tmp_file ibs=$input_size count=1 of=$tmp_file seek=1 obs=$cur_size || exit 1
        done

        #生成好文件后再放入指定文件夹
        mv $tmp_file $dir
}
#gen_file_c $1 $2 $3
