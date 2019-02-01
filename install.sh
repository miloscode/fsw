yum update -y

yum install -y wget ntp

clear
echo "*****************************************************************"
echo "Opening Licence - PRESS Enter to scroll down the license        *"
echo "*****************************************************************"

for i in {1..10}
do
    sleep 0.5
    echo -ne ".";
done

#if [ -f GNU-license.txt ]; then
#	more GNU-license.txt
#else
#	wget --no-check-certificate -q -O GNU-license.txt https://www.gnu.org/licenses/gpl-3.0-standalone.html
#	more GNU-license.txt
#fi

echo "***"
echo "*** I agree to be bound by the terms of the license - [YES/NO]"
echo "*** "
read ACCEPT
while [ "$ACCEPT" != "yes" ] && [ "$ACCEPT" != "Yes" ] && [ "$ACCEPT" != "YES" ] && [ "$ACCEPT" != "no" ] && [ "$ACCEPT" != "No" ] && [ "$ACCEPT" != "NO" ]; do
    echo "I agree to be bound by the terms of the license - [YES/NO]"
    read ACCEPT
done
if [ "$ACCEPT" != "yes" ] && [ "$ACCEPT" != "Yes" ] && [ "$ACCEPT" != "YES" ]; then
    echo "License rejected!"
    exit 0
else

    ## Set time
    ntpdate pool.ntp.org
    systemctl restart ntpd
    chkconfig ntpd on

    ## Install FreeSWITCH prerequisities
    yum groupinstall "Development tools" -y
    yum -y install epel-release
    rpm -Uvh http://files.freeswitch.org/freeswitch-release-1-6.noarch.rpm
    yum update -y
    yum install -y wget git autoconf automake expat-devel yasm nasm gnutls-devel libtiff-devel libX11-devel unixODBC-devel python-devel zlib-devel alsa-lib-devel libogg-devel libvorbis-devel uuid-devel @development-tools gdbm-devel db4-devel libjpeg libjpeg-devel compat-libtermcap ncurses ncurses-devel ntp screen sendmail sendmail-cf gcc-c++ @development-tools bison bzip2 curl curl-devel dmidecode git make mysql-connector-odbc openssl-devel unixODBC zlib pcre-devel speex-devel sqlite-devel ldns-devel libedit-devel bc e2fsprogs-devel libcurl-devel libxml2-devel libyuv-devel opus-devel libvpx-devel libvpx2* libdb4* libidn-devel unbound-devel libuuid-devel lua-devel libsndfile-devel

    ## Install FreeSWITCH
    cd /usr/local/src
    git clone -b v1.6.19 https://freeswitch.org/stash/scm/fs/freeswitch.git
    cd freeswitch
    ./bootstrap.sh -j

    ## Uncomment modules in `modules.conf`
    sed -i "s#\#xml_int/mod_xml_curl#xml_int/mod_xml_curl#g" /usr/local/src/freeswitch/modules.conf
    sed -i "s#\#applications/mod_callcenter#applications/mod_callcenter#g" /usr/local/src/freeswitch/modules.conf
    sed -i "s#\#event_handlers/mod_event_zmq#event_handlers/mod_event_zmq#g" /usr/local/src/freeswitch/modules.conf
    sed -i "s#\#languages/mod_v8#languages/mod_v8#g" /usr/local/src/freeswitch/modules.conf

    ./configure -C
    make all install cd-sounds-install cd-moh-install
    make && make install

    ln -s /usr/local/freeswitch/bin/freeswitch /usr/local/bin/freeswitch
    ln -s /usr/local/freeswitch/bin/fs_cli /usr/local/bin/fs_cli

    wget https://raw.githubusercontent.com/miloscode/fs/master/init/fs.centos.init
    mv fs.centos.init /etc/init.d/freeswitch
    cd /etc/init.d/
    chmod 755 /etc/init.d/freeswitch
    chmod +x /etc/init.d/freeswitch
    chkconfig --add freeswitch
    chkconfig --level 345 freeswitch on
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/sysconfig/selinux
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
    setenforce 0
    systemctl start freeswitch

fi
