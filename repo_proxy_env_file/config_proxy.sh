#!/usr/bin/env bash
#set -x

# include files
source /etc/os-release

# define variables
GIT_URL="https://github.com/glayneon/atto.git"
UBUNTU_REPO="/etc/apt/apt.conf.d/00proxy"
CENTOS_REPO="/etc/yum.repos.d/CentOS-Base.repo"
CENTOS_YUM_FILE="/etc/yum.conf"

# define functions
banner()  { printf -- "-----> $*\n"; }
log()     { printf -- "       $*\n"; }
warn()    { printf -- ">>>>>> $*\n"; }
fail()    { printf -- "\nERROR: $*\n" ; exit 1 ; }

# check EUID
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
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
fi

banner "OS type is ${ID}"

banner "Configuring Proxy parameters on ${ID}"
if [ $CENTOS_OK == true ]; then
	[ -e ${CENTOS_REPO} ] && mv ${CENTOS_REPO} ${CENTOS_REPO%repo}bak && banner "Backing up original file to ${CENTOS_REPO%repo}bak"
	[ -e ${CENTOS_YUM_FILE} ] && mv ${CENTOS_YUM_FILE} ${CENTOS_YUM_FILE%conf}bak && banner "Backing up original file to ${CENTOS_YUM_FILE%conf}bak"
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


elif [ "$UBUNTU_OK" == true ]; then
	[ -e ${UBUNTU_REPO} ] && mv ${UBUNTU_REPO} ${UBUNTU_REPO}bak && banner "Backking up original file to ${UBUNTU_REPO}bak"
	cat <<_EOF_ > "$UBUNTU_REPO"
Acquire::http::Proxy "http://repos.atto.io:9999";
Acquire::https::Proxy "http://repos.atto.io:9999";
Acquire::ftp::Proxy "http://repos.atto.io:9999";
_EOF_
	banner "Complete ${ID} Proxy repositories.."
	banner "Please execute 'sudo apt-get clean' to remove old repositories's metadata"

fi
