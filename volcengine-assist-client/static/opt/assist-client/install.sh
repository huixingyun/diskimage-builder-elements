#!/bin/bash
# https://www.volcengine.com/docs/6396/147514#%E5%B7%B2%E6%9C%89%E4%BA%91%E6%9C%8D%E5%8A%A1%E5%99%A8%E5%AE%9E%E4%BE%8B%E5%AE%89%E8%A3%85
#火山引擎云助手安装脚本
set -x

echo "installing assist-client"

if [[ $(uname -m) == "x86_64" ]]; then
  ARCH="amd64"
else
  echo "Unsupported Arch: $(uname -m)"
  exit 0
fi

metadata_url=http://100.96.0.96/volcstack/lastest/iam/security-credentials/ServiceRoleForVolcECS
assume_role_err_msg="Need bind ecs with assume role name"
metadata_resp=$(curl -s $metadata_url)

if [ "$metadata_resp" = "$assume_role_err_msg" ]; then
  echo '实例AssumeRole不存在，请在IAM上创建'
  exit
else
  echo "实例AssumeRole正常"
fi

# version file
VERSION_FILE="version"

# online 公网
ONLINE_TAR_URL=http://assist-client.tos-cn-beijing.volces.com
ONLINE_TAR_BACKUP_URL=http://assist-client.tos-s3-cn-beijing.volces.com

# boe
BOE_TAR_URL=http://assist-client-boe.tos-s3-cn-boe.volces.com
BOE_TAR_BACKUP_URL=http://assist-client-boe.tos-s3-cn-boe.ivolces.com

# beijing 内网
ONLINE_BJ_TAR_URL=http://assist-client-beijing.tos-cn-beijing.ivolces.com
ONLINE_BJ_TAR_BACKUP_URL=http://assist-client-beijing.tos-s3-cn-beijing.ivolces.com

# shanghai 内网
ONLINE_SH_TAR_URL=http://assist-client-shanghai.tos-cn-shanghai.ivolces.com
ONLINE_SH_TAR_BACKUP_URL=http://assist-client-shanghai.tos-s3-cn-shanghai.ivolces.com

# guangzhou 内网
ONLINE_GZ_TAR_URL=http://assist-client-guangzhou.tos-cn-guangzhou.ivolces.com
ONLINE_GZ_TAR_BACKUP_URL=http://assist-client-guangzhou.tos-s3-cn-guangzhou.ivolces.com

echo "try get region code from remote..."
REGION_CODE=$(wget -q -O - http://100.96.0.96/volcstack/latest/region_id)

if [[ -z $REGION_CODE ]]; then
  echo "set region code fail..."
  exit 0
fi

case ${REGION_CODE} in
cn-beijing)
  VERSION_FILE_PATH=${ONLINE_BJ_TAR_URL}/${VERSION_FILE}
  BACKUP_VERSION_FILE_PATH=${ONLINE_BJ_TAR_BACKUP_URL}/${VERSION_FILE}
  ;;
cn-shanghai)
  VERSION_FILE_PATH=${ONLINE_SH_TAR_URL}/${VERSION_FILE}
  BACKUP_VERSION_FILE_PATH=${ONLINE_SH_TAR_BACKUP_URL}/${VERSION_FILE}
  ;;
cn-guangzhou)
  VERSION_FILE_PATH=${ONLINE_GZ_TAR_URL}/${VERSION_FILE}
  BACKUP_VERSION_FILE_PATH=${ONLINE_GZ_TAR_BACKUP_URL}/${VERSION_FILE}
  ;;
cn-chengdu-sdv | cn-baoding-sdv | cn-guilin-boe | cn-north-4)
  VERSION_FILE_PATH=${BOE_TAR_URL}/${VERSION_FILE}
  BACKUP_VERSION_FILE_PATH=${BOE_TAR_BACKUP_URL}/${VERSION_FILE}
  ;;
*)
  echo "Unsupported Region"
  exit 0
  ;;
esac

get_version_from_remote() {
  echo "get current version..."
  VERSION=$(wget -q -T 2 -t 3 -O - $VERSION_FILE_PATH)

  if [[ $? != 0 ]]; then
    echo "get version fail, retry..."
    VERSION=$(wget -q -T 2 -t 3 -O - $BACKUP_VERSION_FILE_PATH)
  fi

  if [[ $? != 0 ]]; then
    echo "get version fail"
    exit 0
  fi
}

if [[ -z $VERSION ]]; then
  get_version_from_remote
elif [[ "$VERSION" < "v1.1.0" ]]; then
  echo "the version $VERSION is to old, please install the newer package"
  exit 0
fi

ASSIST_CLIENT_HOME="/usr/local/assist-client"
TAR_FILE=assist-client_linux_${ARCH}_${VERSION}.tar.gz

DEST_TAR_FILE=${ASSIST_CLIENT_HOME}/${TAR_FILE}
DEST_BIN_FILE=${ASSIST_CLIENT_HOME}/assist-client
DEST_CLIENT_CONF=${ASSIST_CLIENT_HOME}/assist_client_conf.json
DEST_SERVICE_FILE=/lib/systemd/system/assist-client.service

case ${REGION_CODE} in
cn-beijing)
  DOWNLOAD_PATH=${ONLINE_BJ_TAR_URL}/${TAR_FILE}
  BACKUP_PATH=${ONLINE_BJ_TAR_BACKUP_URL}/${TAR_FILE}
  ;;
cn-shanghai)
  DOWNLOAD_PATH=${ONLINE_SH_TAR_URL}/${TAR_FILE}
  BACKUP_PATH=${ONLINE_SH_TAR_BACKUP_URL}/${TAR_FILE}
  ;;
cn-guangzhou)
  DOWNLOAD_PATH=${ONLINE_GZ_TAR_URL}/${TAR_FILE}
  BACKUP_PATH=${ONLINE_GZ_TAR_BACKUP_URL}/${TAR_FILE}
  ;;
cn-guilin-boe | cn-chengdu-sdv | cn-baoding-sdv)
  DOWNLOAD_PATH=${BOE_TAR_URL}/${TAR_FILE}
  BACKUP_PATH=${BOE_TAR_BACKUP_URL}/${TAR_FILE}
  ;;
*)
  echo "Unsupported Region"
  exit 0
  ;;
esac

case $(uname -s) in
Linux)
  ASSIST_CLIENT_OS="linux"
  ;;
*)
  echo "Unsupported OS: $(uname -s)"
  exit 0
  ;;
esac

#如果已经安装了旧版，先卸载旧版
ASSIST_CLIENT_STATUS=$(systemctl status assist-client.service | grep running)

if [[ -n ${ASSIST_CLIENT_STATUS} ]]; then
  systemctl stop assist-client.service
fi

if [[ -d ${ASSIST_CLIENT_HOME} ]]; then
  rm -rf ${ASSIST_CLIENT_HOME}
  rm -f ${DEST_SERVICE_FILE}
  rm -f /etc/systemd/system/multi-user.target.wants/assist-client.service
fi

download() {
  if [[ -n "${REGION_CODE}" ]]; then
    TOS_URL=${DOWNLOAD_PATH}
  else
    echo "unsupported region ${REGION_CODE}"
  fi

  echo "Download and Installing..."

  wget -q "${TOS_URL}" -O "${DEST_TAR_FILE}" -t 3 --connect-timeout=2

  if [[ $? != 0 ]]; then
    echo "download fail, retry..."
    TOS_URL=${BACKUP_PATH}
    wget -q ${TOS_URL} -O ${DEST_TAR_FILE} -t 3 --connect-timeout=2
  fi
}

mkdir -p ${ASSIST_CLIENT_HOME}

if [[ "${ASSIST_CLIENT_OS}" == "linux" ]]; then
  chown -R root:root ${ASSIST_CLIENT_HOME}
fi

download

if [[ ! -f "${DEST_TAR_FILE}" ]]; then
  echo "download failed: {$DEST_TAR_FILE}"
  exit 0
fi

#解压
tar xf "${DEST_TAR_FILE}" -C ${ASSIST_CLIENT_HOME}
rm -f "${DEST_TAR_FILE}"

# 是否启用自动更新, 默认为 true
if [[ -n ${DISABLE_AUTO_UPDATE} ]]; then
  sed -i 's/\"AutoUpdate\": true/\"AutoUpdate\": false/g' ${DEST_CLIENT_CONF}
fi

#拷贝service文件
mv -f ${ASSIST_CLIENT_HOME}/assist-client.service ${DEST_SERVICE_FILE}

#设置assist-client开机自启动
ln -s ${DEST_SERVICE_FILE} /etc/systemd/system/multi-user.target.wants/assist-client.service

#安装状态检测
ASSIST_CLIENT_VERSION=$(${DEST_BIN_FILE} version)

if [[ -n "${ASSIST_CLIENT_VERSION}" ]]; then
  echo assist-client installed
else
  echo assist-client install failed
  exit 0
fi

systemctl daemon-reload
systemctl start assist-client.service --no-block
