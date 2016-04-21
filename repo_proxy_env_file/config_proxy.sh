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
	UBUNTU_OK=true
	CENTOS_OK=false
elif [ "${VERSION_ID}" == "7" ]; then
	UBUNTU_OK=false
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
	[ -e ${CENTOS_REPO} ] && mv ${CENTOS_REPO} ${CENTOS_REPO%repo}bak && banner "Backing up original file ${CENTOS_REPO} to ${CENTOS_REPO%repo}bak"
	[ -e ${CENTOS_YUM_FILE} ] && mv ${CENTOS_YUM_FILE} ${CENTOS_YUM_FILE%conf}bak && banner "Backing up original file ${CENTOS_YUM_FILE} to ${CENTOS_YUM_FILE%conf}bak"
	cat <<_EOF_ > "$CENTOS_REPO"
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the
# remarked out baseurl= line instead.
#
#

[base]
name=CentOS-\$releasever - Base
#mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=os&infra=\$infra
#baseurl=http://mirror.centos.org/centos/\$releasever/os/\$basearch/
baseurl=http://ftp.daumkakao.com/centos/\$releasever/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-\$releasever - Updates
#mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=updates&infra=\$infra
baseurl=http://ftp.daumkakao.com/centos/\$releasever/os/\$basearch/
#baseurl=http://mirror.centos.org/centos/\$releasever/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-\$releasever - Extras
#mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=extras&infra=\$infra
#baseurl=http://mirror.centos.org/centos/\$releasever/extras/\$basearch/
baseurl=http://ftp.daumkakao.com/centos/\$releasever/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-\$releasever - Plus
#mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=centosplus&infra=\$infra
baseurl=http://ftp.daumkakao.com/centos/\$releasever/os/\$basearch/
#baseurl=http://mirror.centos.org/centos/\$releasever/centosplus/\$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
_EOF_

	cat <<_EOF_ > "${CENTOS_YUM_FILE}"
[main]
cachedir=/var/cache/yum/\$basearch/\$releasever
keepcache=0
debuglevel=2
logfile=/var/log/yum.log
exactarch=1
obsoletes=1
gpgcheck=1
plugins=1
installonly_limit=5
bugtracker_url=http://bugs.centos.org/set_project.php?project_id=23&ref=http://bugs.centos.org/bug_report_page.php?category=yum
distroverpkg=centos-release
proxy=http://repos.atto.io:9999
_EOF_
	banner "Complete ${ID} Proxy repositories.."
	banner "Please execute 'sudo yum clean all' to remove old repositories's metadata"

# setting for ubuntu proxy
elif [ "$UBUNTU_OK" == true ]; then
	[ -e ${UBUNTU_REPO} ] && mv ${UBUNTU_REPO} ${UBUNTU_REPO%/*/*}00proxy.bak && banner "Backing up original file ${UBUNTU_REPO} to ${UBUNTU_REPO%/*/*}00proxy.bak"
	[ -e ${UBUNTU_SRC_FILE} ] && mv ${UBUNTU_SRC_FILE} ${UBUNTU_SRC_FILE%list}bak && banner "Backing up original file ${UBUNTU_SRC_FILE} to ${UBUNTU_SRC_FILE%list}bak"
	cat <<_EOF_ > "$UBUNTU_REPO"
Acquire::http::Proxy "http://repos.atto.io:9999";
Acquire::https::Proxy "http://repos.atto.io:9999";
Acquire::ftp::Proxy "http://repos.atto.io:9999";
_EOF_

    cat <<_EOF_ > "$UBUNTU_SRC_FILE"
#deb cdrom:[Ubuntu 14.04.4 LTS _Trusty Tahr_ - Release amd64 (20160217.1)]/ trusty main restricted

# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://ftp.daumkakao.com/ubuntu/ trusty main restricted
deb-src http://ftp.daumkakao.com/ubuntu/ trusty main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://ftp.daumkakao.com/ubuntu/ trusty-updates main restricted
deb-src http://ftp.daumkakao.com/ubuntu/ trusty-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://ftp.daumkakao.com/ubuntu/ trusty universe
deb-src http://ftp.daumkakao.com/ubuntu/ trusty universe
deb http://ftp.daumkakao.com/ubuntu/ trusty-updates universe
deb-src http://ftp.daumkakao.com/ubuntu/ trusty-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu 
## team, and may not be under a free licence. Please satisfy yourself as to 
## your rights to use the software. Also, please note that software in 
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://ftp.daumkakao.com/ubuntu/ trusty multiverse
deb-src http://ftp.daumkakao.com/ubuntu/ trusty multiverse
deb http://ftp.daumkakao.com/ubuntu/ trusty-updates multiverse
deb-src http://ftp.daumkakao.com/ubuntu/ trusty-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://ftp.daumkakao.com/ubuntu/ trusty-backports main restricted universe multiverse
deb-src http://ftp.daumkakao.com/ubuntu/ trusty-backports main restricted universe multiverse

deb http://ftp.daumkakao.com/ubuntu trusty-security main restricted
deb-src http://ftp.daumkakao.com/ubuntu trusty-security main restricted
deb http://ftp.daumkakao.com/ubuntu trusty-security universe
deb-src http://ftp.daumkakao.com/ubuntu trusty-security universe
deb http://ftp.daumkakao.com/ubuntu trusty-security multiverse
deb-src http://ftp.daumkakao.com/ubuntu trusty-security multiverse

## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.
## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
# deb http://archive.canonical.com/ubuntu trusty partner
# deb-src http://archive.canonical.com/ubuntu trusty partner

## This software is not part of Ubuntu, but is offered by third-party
## developers who want to ship their latest software.
deb http://extras.ubuntu.com/ubuntu trusty main
deb-src http://extras.ubuntu.com/ubuntu trusty main
_EOF_
	banner "Complete ${ID} Proxy repositories.."
	banner "Please execute 'sudo apt-get clean' to remove old repositories's metadata"

fi
