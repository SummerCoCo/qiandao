#!/bin/bash
#
# FILE: update.sh
#
# DESCRIPTION: Update QianDao for Python3 
#
# NOTES: This requires GNU getopt.
#        I do not issue any guarantee that this will work for you!
#
# COPYRIGHT: (c) 2021-2022 by a76yyyy
#
# LICENSE: MIT
#
# ORGANIZATION: qiandao-today (https://github.com/qiandao-today)
#
# CREATED: 2021-10-28 20:00:00
#
#=======================================================================
_file=$(readlink -f $0)
_dir=$(dirname $_file)
cd $_dir
AUTO_RELOAD=$AUTO_RELOAD

# Treat unset variables as an error
set -o nounset

__ScriptVersion="2022.12.24"
__ScriptName="update.sh"


#-----------------------------------------------------------------------
# FUNCTION: usage
# DESCRIPTION:  Display usage information.
#-----------------------------------------------------------------------
usage() {
    cat << EOT

Usage :  ${__ScriptName} [OPTION] ...
  Update QianDao for Python3 from given options.

Options:
  -h, --help                    Display help message
  -s, --script-version          Display script version
  -u, --update                  Default update method
  -v, --version=TAG_VERSION     Forced Update to the specified tag version
  -f, --force                   Forced version update
  -l, --local                   Display Local version
  -r, --remote                  Display Remote version

Exit status:
  0   if OK,
  !=0 if serious problems.

Example:
  1) Use short options:
    $ sh $__ScriptName -v=$(python -c 'import sys, json; print(json.load(open("version.json"))["version"])')

  2) Use long options:
    $ sh $__ScriptName --update

Report issues to https://github.com/qiandao-today/qiandao

EOT
}   # ----------  end of function usage  ----------

update() {
    localversion=$(python -c 'import sys, json; print(json.load(open("version.json"))["version"])')
    remoteversion=$(git ls-remote --tags origin | grep -o 'refs/tags/[0-9]*' | sort -r | head -n 1 | grep -o '[^\/]*$')
    if [ $(echo $localversion $remoteversion | awk '$1>=$2 {print 0} $1<$2 {print 1}') == 1 ];then
        echo -e "Info: ????????????: $localversion \nInfo: ?????????: $remoteversion \nInfo: ???????????????, ?????????..."
        wget https://gitee.com/a76yyyy/qiandao/raw/$remoteversion/requirements.txt -O /usr/src/app/requirements.txt && \
        [[ -z "$(cat /etc/issue | grep -E "Alpine|alpine")" ]] && { \
            pip install -r requirements.txt && \
            echo "???????????? DdddOCR API, ??????????????? ddddocr Python?????? (????????????, ????????????????????????????????????qiandao); " && \
            echo "pip3 install ddddocr" && \
            echo "???????????? PyCurl ??????, ??????????????? pycurl Python?????? (????????????, ????????????????????????????????????qiandao); " && \
            echo "pip3 install pycurl" ;\
        } || { \
            if [ $(echo $localversion | awk '$1>20211228 {print 0} $1<=20211228 {print 1}') == 1 ];then
                echo "https://mirrors.ustc.edu.cn/alpine/edge/main" > /etc/apk/repositories 
                echo "https://mirrors.ustc.edu.cn/alpine/edge/community" >> /etc/apk/repositories 
                apk del .python-rundeps  
                echo "Info: ????????????DDDDOCR API, ??????????????????????????? (32????????????????????????API). "
            fi
            apk add --update --no-cache openssh-client python3 py3-six py3-markupsafe py3-pycryptodome py3-tornado py3-wrapt py3-packaging py3-greenlet py3-urllib3 py3-cryptography py3-aiosignal py3-async-timeout py3-attrs py3-frozenlist py3-multidict py3-charset-normalizer py3-aiohttp py3-typing-extensions py3-yarl && \
            if [ $(printenv QIANDAO_LITE) ] && [ "$QIANDAO_LITE" = "True" ];then
                echo "Info: Qiandao-Lite will not install ddddocr related components. "
            else
                [[ $(getconf LONG_BIT) = "32" ]] && \
                    echo "Info: 32-bit systems do not support ddddocr, so there is no need to install numpy and opencv-python. " || \
                    apk add --update --no-cache py3-opencv py3-pillow 
            fi && \
            apk add --no-cache --virtual .build_deps cmake make perl autoconf g++ automake \
                linux-headers libtool util-linux py3-pip py3-setuptools py3-wheel python3-dev py3-numpy-dev 
            if [ -n $(ls /usr/bin | grep -w "python3$") ];then
                ls /usr/bin | grep -w "python3$"
                ln -sf /usr/bin/python3 /usr/bin/python 
                ln -sf /usr/bin/python3 /usr/local/bin/python
                sed -i '/ddddocr/d' requirements.txt 
                sed -i '/packaging/d' requirements.txt 
                sed -i '/wrapt/d' requirements.txt 
                sed -i '/pycryptodome/d' requirements.txt 
                sed -i '/tornado/d' requirements.txt 
                sed -i '/MarkupSafe/d' requirements.txt 
                sed -i '/pillow/d' requirements.txt 
                sed -i '/opencv/d' requirements.txt 
                sed -i '/numpy/d' requirements.txt 
                sed -i '/greenlet/d' requirements.txt
                sed -i '/urllib3/d' requirements.txt
                sed -i '/cryptography/d' requirements.txt
                sed -i '/aiosignal/d' requirements.txt
                sed -i '/async-timeout/d' requirements.txt
                sed -i '/attrs/d' requirements.txt
                sed -i '/frozenlist/d' requirements.txt
                sed -i '/multidict/d' requirements.txt
                sed -i '/charset-normalizer/d' requirements.txt
                sed -i '/aiohttp/d' requirements.txt
                sed -i '/typing-extensions/d' requirements.txt
                sed -i '/yarl/d' requirements.txt
            fi
            pip install --no-cache-dir -r requirements.txt 
            pip install --no-cache-dir --compile --upgrade pycurl 
            apk del .build_deps 
            rm -rf /var/cache/apk/* 
            rm -rf /usr/share/man/*
        } && \
        git fetch --all && \
        git reset --hard origin/master && \
        git checkout master && \
        git pull
    else
        echo "Info: ????????????: $localversion , ????????????!"
    fi
    if [ $(printenv AUTO_RELOAD) ] && [ "$AUTO_RELOAD" == "False" ];then
        echo "Info: ?????????????????????, ?????????????????????AUTO_RELOAD????????????????????????"
    fi
}

force_update() {
    localversion=$(python -c 'import sys, json; print(json.load(open("version.json"))["version"])')
    remoteversion=$(git ls-remote --tags origin | grep -o 'refs/tags/[0-9]*' | sort -r | head -n 1 | grep -o '[^\/]*$')
    echo -e "Info: ?????????????????????, ?????????..."
    wget https://gitee.com/a76yyyy/qiandao/raw/master/requirements.txt -O /usr/src/app/requirements.txt && \
    [[ -z "$(cat /etc/issue | grep -E "Alpine|alpine")" ]] && { \
        pip install -r requirements.txt && \
        echo "???????????? DdddOCR API, ??????????????? ddddocr Python?????? (????????????, ????????????????????????????????????qiandao); " && \
        echo "pip3 install ddddocr" && \
        echo "???????????? PyCurl ??????, ??????????????? pycurl Python?????? (????????????, ????????????????????????????????????qiandao); " && \
        echo "pip3 install pycurl" ;\
    } || { \
        if [ $(echo $localversion | awk '$1>20211228 {print 0} $1<=20211228 {print 1}') == 1 ];then
            echo "https://mirrors.ustc.edu.cn/alpine/edge/main" > /etc/apk/repositories 
            echo "https://mirrors.ustc.edu.cn/alpine/edge/community" >> /etc/apk/repositories 
            apk del .python-rundeps  
            echo "Info: ????????????DDDDOCR API, ??????????????????????????? (32????????????????????????API). "
        fi
        apk add --update --no-cache openssh-client python3 py3-six py3-markupsafe py3-pycryptodome py3-tornado py3-wrapt py3-packaging py3-greenlet py3-urllib3 py3-cryptography py3-aiosignal py3-async-timeout py3-attrs py3-frozenlist py3-multidict py3-charset-normalizer py3-aiohttp py3-typing-extensions py3-yarl && \
        if [ $(printenv QIANDAO_LITE) ] && [ "$QIANDAO_LITE" = "True" ];then
            echo "Info: Qiandao-Lite will not install ddddocr related components. "
        else
            [[ $(getconf LONG_BIT) = "32" ]] && \
                echo "Info: 32-bit systems do not support ddddocr, so there is no need to install numpy and opencv-python. " || \
                apk add --update --no-cache py3-opencv py3-pillow 
        fi && \
        apk add --no-cache --virtual .build_deps cmake make perl autoconf g++ automake \
            linux-headers libtool util-linux py3-pip py3-setuptools py3-wheel python3-dev py3-numpy-dev 
        if [ -n $(ls /usr/bin | grep -w "python3$") ];then
            ls /usr/bin | grep -w "python3$"
            ln -sf /usr/bin/python3 /usr/bin/python 
            ln -sf /usr/bin/python3 /usr/local/bin/python
            sed -i '/ddddocr/d' requirements.txt 
            sed -i '/packaging/d' requirements.txt 
            sed -i '/wrapt/d' requirements.txt 
            sed -i '/pycryptodome/d' requirements.txt 
            sed -i '/tornado/d' requirements.txt 
            sed -i '/MarkupSafe/d' requirements.txt 
            sed -i '/pillow/d' requirements.txt 
            sed -i '/opencv/d' requirements.txt 
            sed -i '/numpy/d' requirements.txt 
            sed -i '/greenlet/d' requirements.txt
            sed -i '/urllib3/d' requirements.txt
            sed -i '/cryptography/d' requirements.txt
            sed -i '/aiosignal/d' requirements.txt
            sed -i '/async-timeout/d' requirements.txt
            sed -i '/attrs/d' requirements.txt
            sed -i '/frozenlist/d' requirements.txt
            sed -i '/multidict/d' requirements.txt
            sed -i '/charset-normalizer/d' requirements.txt
            sed -i '/aiohttp/d' requirements.txt
            sed -i '/typing-extensions/d' requirements.txt
            sed -i '/yarl/d' requirements.txt
        fi
        pip install --no-cache-dir -r requirements.txt 
        pip install --no-cache-dir --compile --upgrade pycurl 
        apk del .build_deps 
        rm -rf /var/cache/apk/* 
        rm -rf /usr/share/man/*
    } && \
    git fetch --all && \
    git reset --hard origin/master && \
    git checkout master && \
    git pull
    if [ $(printenv AUTO_RELOAD) ] && [ "$AUTO_RELOAD" == "False" ];then
        echo "Info: ?????????????????????, ?????????????????????AUTO_RELOAD????????????????????????"
    fi
}

update_version() {
    echo -e "Info: ???????????????????????????Tag??????: $1, ?????????..."
    wget https://gitee.com/a76yyyy/qiandao/raw/$1/requirements.txt -O /usr/src/app/requirements.txt && \
    [[ -z "$(cat /etc/issue | grep -E "Alpine|alpine")" ]] && { \
        pip install -r requirements.txt && \
        echo "???????????? DdddOCR API, ??????????????? ddddocr Python?????? (????????????, ????????????????????????????????????qiandao); " && \
        echo "pip3 install ddddocr" && \
        echo "???????????? PyCurl ??????, ??????????????? pycurl Python?????? (????????????, ????????????????????????????????????qiandao); " && \
        echo "pip3 install pycurl" ;\
    } || { \
        if [ $(echo $localversion | awk '$1>20211228 {print 0} $1<=20211228 {print 1}') == 1 ];then
            echo "https://mirrors.ustc.edu.cn/alpine/edge/main" > /etc/apk/repositories 
            echo "https://mirrors.ustc.edu.cn/alpine/edge/community" >> /etc/apk/repositories 
            apk del .python-rundeps  
            echo "Info: ????????????DDDDOCR API, ??????????????????????????? (32????????????????????????API). "
        fi
        apk add --update --no-cache openssh-client python3 py3-six py3-markupsafe py3-pycryptodome py3-tornado py3-wrapt py3-packaging py3-greenlet py3-urllib3 py3-cryptography py3-aiosignal py3-async-timeout py3-attrs py3-frozenlist py3-multidict py3-charset-normalizer py3-aiohttp py3-typing-extensions py3-yarl && \
        if [ $(printenv QIANDAO_LITE) ] && [ "$QIANDAO_LITE" = "True" ];then
            echo "Info: Qiandao-Lite will not install ddddocr related components. "
        else
            [[ $(getconf LONG_BIT) = "32" ]] && \
                echo "Info: 32-bit systems do not support ddddocr, so there is no need to install numpy and opencv-python. " || \
                apk add --update --no-cache py3-opencv py3-pillow 
        fi && \
        apk add --no-cache --virtual .build_deps cmake make perl autoconf g++ automake \
            linux-headers libtool util-linux py3-pip py3-setuptools py3-wheel python3-dev py3-numpy-dev 
        if [ -n $(ls /usr/bin | grep -w "python3$") ];then
            ls /usr/bin | grep -w "python3$"
            ln -sf /usr/bin/python3 /usr/bin/python 
            ln -sf /usr/bin/python3 /usr/local/bin/python
            sed -i '/ddddocr/d' requirements.txt 
            sed -i '/packaging/d' requirements.txt 
            sed -i '/wrapt/d' requirements.txt 
            sed -i '/pycryptodome/d' requirements.txt 
            sed -i '/tornado/d' requirements.txt 
            sed -i '/MarkupSafe/d' requirements.txt 
            sed -i '/pillow/d' requirements.txt 
            sed -i '/opencv/d' requirements.txt 
            sed -i '/numpy/d' requirements.txt 
            sed -i '/greenlet/d' requirements.txt
            sed -i '/urllib3/d' requirements.txt
            sed -i '/cryptography/d' requirements.txt
            sed -i '/aiosignal/d' requirements.txt
            sed -i '/async-timeout/d' requirements.txt
            sed -i '/attrs/d' requirements.txt
            sed -i '/frozenlist/d' requirements.txt
            sed -i '/multidict/d' requirements.txt
            sed -i '/charset-normalizer/d' requirements.txt
            sed -i '/aiohttp/d' requirements.txt
            sed -i '/typing-extensions/d' requirements.txt
            sed -i '/yarl/d' requirements.txt
        fi
        pip install --no-cache-dir -r requirements.txt 
        pip install --no-cache-dir --compile --upgrade pycurl 
        apk del .build_deps 
        rm -rf /var/cache/apk/* 
        rm -rf /usr/share/man/*
    } && \
    git fetch --all && \
    git checkout -f $1
    if [ $(printenv AUTO_RELOAD) ] && [ "$AUTO_RELOAD" == "False" ];then
        echo "Info: ?????????????????????, ?????????????????????AUTO_RELOAD????????????????????????"
    fi
}


if [ $# == 0 ]; then update; exit 0; fi

# parse options:
RET=`getopt -o hsuv:flr \
    --long help,script-version,update,version:,force,local,remote \
    -n ' * ERROR' -- "$@"`

if [ $? != 0 ] ; then echo "Error: $__ScriptName exited with doing nothing." >&2 ; exit 1 ; fi

# Note the quotes around $RET: they are essential!
eval set -- "$RET"

# set option values
while true; do
    case "$1" in
        -h | --help ) usage; exit 1 ;;
        -s | --script-version ) echo "$(basename $0) -- version $__ScriptVersion"; exit 1 ;;

        -u | --update ) update; exit 0 ;;

        -v | --version ) echo "$2" | grep [^0-9] >/dev/null && echo "'$2' is not correct type of tag" || update_version $2; exit 0 ;;

        -f | --force ) force_update; exit 0 ;;

        -l | --local ) echo "????????????: $(python -c 'import sys, json; print(json.load(open("version.json"))["version"])')"; shift ;;

        -r | --remote ) echo "????????????: $(git ls-remote --tags origin | grep -o 'refs/tags/[0-9]*' | sort -r | head -n 1 | grep -o '[^\/]*$')"; shift ;;

        -- ) shift; break ;;
        * ) echo "Error: internal error!" ; exit 1 ;;
     esac
done

# # remaining argument
# for arg do
#     # method
# done
