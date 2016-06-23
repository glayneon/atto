#!/usr/bin/env bash
#set -x

# include files
source /etc/os-release

# define variables
GIT_URL="https://github.com/glayneon/atto.git"
UBUNTU_REPO="/etc/apt/apt.conf.d/00proxy"
UBUNTU_SRC_FILE="/etc/apt/sources.list"
CENTOS_REPO="/etc/yum.repos.d/CentOS-Base.repo"
CENTOS_YUM_FILE="/etc/yum.conf"

# define functions
banner()  { printf -- "-----> $*\n"; }
log()     { printf -- "       $*\n"; }
warn()    { printf -- ">>>>>> $*\n"; }
fail()    { printf -- "\nERROR: $*\n" ; exit 1 ; }

# check EUID
if [[ $EUID -ne 0 ]]; then
   fail "This script must be run as root" 
   exit 1
fi

# check linux distribution type
banner "Checking linux distribution type.."
if [ "${VERSION_ID}" == "14.04" ]; then
	UBUNTU4_OK=true
	CENTOS_OK=false
elif [ "${VERSION_ID}" == "16.04" ]; then
	UBUNTU6_OK=true
	CENTOS_OK=false
elif [ "${VERSION_ID}" == "7" ]; then
	UBUNTU4_OK=false
	CENTOS_OK=true
else
    fail "Only support CentOS7 & Ubuntu-14.04"
    fail "Please check this system's version"
    exit 1
fi

banner "OS type is ${ID}"
banner "Configuring Proxy parameters on ${ID}"

# Setting for CentOS proxy 
if [ $CENTOS_OK == true ]; then
sed -i 's/proxy/#proxy/g' ${CENTOS_YUM_FILE}
	banner "Complete ${ID} to remove Proxy repositories.."
	banner "Please execute 'sudo yum clean all' to remove old repositories's metadata"

# setting for ubuntu4 proxy
elif [ "${UBUNTU4_OK}" == true ]; then
    rm "${UBUNTU_REPO}"
	banner "Complete ${ID} to remove Proxy repositories.."
	banner "Please execute 'sudo apt-get clean' to remove old repositories's metadata"


# setting for ubuntu6 proxy
elif [ "${UBUNTU6_OK}" == true ]; then
    rm "${UBUNTU_REPO}"
	banner "Complete ${ID} to remove Proxy repositories.."
	banner "Please execute 'sudo apt-get clean' to remove old repositories's metadata"
fi
