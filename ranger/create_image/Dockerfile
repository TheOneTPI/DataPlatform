######################################################################
# Ranger Base image...
######################################################################
FROM ubuntu:22.04 AS ranger-base

# Install tzdata, Python, Java, python-requests
RUN apt-get update -y && \
    apt-get install curl -y && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install bc iputils-ping openjdk-17-jdk \
    pdsh python3 python3-pip ssh tzdata vim xmlstarlet && \
    apt-get clean && \
    pip3 install apache-ranger && \
    pip3 install requests

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV RANGER_DIST=/home/ranger/dist
ENV RANGER_SCRIPTS=/home/ranger/scripts
ENV RANGER_HOME=/opt/ranger
ENV PATH=/usr/java/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN update-java-alternatives --set /usr/lib/jvm/java-1.17.0-openjdk-amd64 && \
    groupadd ranger && \
    useradd -g ranger -ms /bin/bash ranger && \
    useradd -g ranger -ms /bin/bash rangeradmin && \
    useradd -g ranger -ms /bin/bash rangerusersync && \
    useradd -g ranger -ms /bin/bash rangertagsync && \
    useradd -g ranger -ms /bin/bash rangerkms && \
    groupadd hadoop && \
    useradd -g hadoop -ms /bin/bash hdfs && \
    useradd -g hadoop -ms /bin/bash yarn && \
    useradd -g hadoop -ms /bin/bash hive && \
    useradd -g hadoop -ms /bin/bash hbase && \
    useradd -g hadoop -ms /bin/bash kafka && \
    groupadd knox && \
    useradd -g knox -ms /bin/bash knox && \
    mkdir -p /home/ranger/dist && \
    mkdir -p /home/ranger/scripts && \
    chown -R ranger:ranger /home/ranger && \
    mkdir -p /opt/ranger && \
    chown -R ranger:ranger /opt/ranger

ENTRYPOINT [ "/bin/bash" ]

######################################################################
# Ranger-Admin image...
######################################################################
FROM ranger-base AS ranger

ARG RANGER_VERSION=2.5.0

COPY ./scripts/ranger.sh                                         ${RANGER_SCRIPTS}/
COPY ./scripts/ranger-admin-install.properties                   ${RANGER_SCRIPTS}/ranger-admin-install.properties
COPY ./scripts/ranger-usersync-install.properties                ${RANGER_SCRIPTS}/ranger-usersync-install.properties
COPY ./scripts/create-ranger-services.py                         ${RANGER_SCRIPTS}/


RUN echo ${RANGER_VERSION} >> /home/ranger/dist/version
ADD https://github.com/TheOneTPI/DataPlatform/releases/download/ranger-${RANGER_VERSION}/ranger-${RANGER_VERSION}-admin.tar.gz /home/ranger/dist/ranger-${RANGER_VERSION}-admin.tar.gz
ADD https://github.com/TheOneTPI/DataPlatform/releases/download/ranger-${RANGER_VERSION}/ranger-${RANGER_VERSION}-usersync.tar.gz /home/ranger/dist/ranger-${RANGER_VERSION}-usersync.tar.gz

RUN tar xvfz /home/ranger/dist/ranger-${RANGER_VERSION}-admin.tar.gz --directory=${RANGER_HOME} && \
    ln -s ${RANGER_HOME}/ranger-${RANGER_VERSION}-admin ${RANGER_HOME}/admin && \
    rm -f /home/ranger/dist/ranger-${RANGER_VERSION}-admin.tar.gz && \
    mkdir -p ${RANGER_HOME}/admin/install_prop && \
    cp -f ${RANGER_SCRIPTS}/ranger-admin-install.properties ${RANGER_HOME}/admin/install_prop/install.properties && \
    rm -f ${RANGER_HOME}/admin/install.properties && \
    ln -s ${RANGER_HOME}/admin/install_prop/install.properties ${RANGER_HOME}/admin/install.properties && \
    mkdir -p /var/run/ranger && \
    mkdir -p /var/log/ranger && \
    mkdir -p /usr/share/java/

ADD https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.16.jre7/postgresql-42.2.16.jre7.jar /usr/share/java/postgresql.jar
ADD https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.20/mysql-connector-java-8.0.20.jar /usr/share/java/mysql-connector.jar
ADD https://repo1.maven.org/maven2/com/googlecode/log4jdbc/log4jdbc/1.2/log4jdbc-1.2.jar ${RANGER_HOME}/admin/ews/webapp/WEB-INF/lib/log4jdbc-1.2.jar

RUN tar xvfz /home/ranger/dist/ranger-${RANGER_VERSION}-usersync.tar.gz --directory=${RANGER_HOME} && \
    ln -s ${RANGER_HOME}/ranger-${RANGER_VERSION}-usersync ${RANGER_HOME}/usersync && \
    rm -f /home/ranger/dist/ranger-${RANGER_VERSION}-usersync.tar.gz && \
    mkdir -p ${RANGER_HOME}/usersync/install_prop && \
    cp -f ${RANGER_SCRIPTS}/ranger-usersync-install.properties ${RANGER_HOME}/usersync/install_prop/install.properties && \
    rm -f ${RANGER_HOME}/usersync/install.properties && \
    ln -s ${RANGER_HOME}/usersync/install_prop/install.properties ${RANGER_HOME}/usersync/install.properties && \
    mkdir -p /var/log/ranger/usersync && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    mkdir -p /etc/ranger && \
    touch /etc/init.d/ranger-usersync && \
    ln -s /etc/init.d/ranger-usersync /etc/rc2.d/S99ranger-usersync && \
    ln -s /etc/init.d/ranger-usersync /etc/rc2.d/K00ranger-usersync && \
    ln -s /etc/init.d/ranger-usersync /etc/rc3.d/S99ranger-usersync && \
    ln -s /etc/init.d/ranger-usersync /etc/rc3.d/K00ranger-usersync && \
    ln -s ${RANGER_HOME}/usersync/ranger-usersync-services.sh /usr/bin/ranger-usersync && \
    chown -R ranger:ranger ${RANGER_HOME}/admin/ && \
    chown -R ranger:ranger ${RANGER_HOME}/usersync/ && \
    chown -R ranger:ranger ${RANGER_SCRIPTS}/ && \
    chown -R ranger:ranger /var/run/ranger/ && \
    chown -R ranger:ranger /var/log/ranger/ && \
    chown -R ranger:ranger /etc/ranger && \
    chown -R ranger:ranger /etc/init.d/ranger-usersync && \
    chmod 744 ${RANGER_SCRIPTS}/ranger.sh ${RANGER_SCRIPTS}/create-ranger-services.py

USER ranger

ENTRYPOINT [ "/home/ranger/scripts/ranger.sh" ]