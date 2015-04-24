FROM    centos:centos6

RUN	yum install -y wget which tar unzip nc openssh-server openssh-clients

RUN	wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz"
RUN	tar xvf jdk-8u45-linux-x64.tar.gz
ENV	JAVA_HOME $HOME/jdk1.8.0_45

RUN	wget http://repo.spring.io/libs-snapshot-local/org/springframework/xd/spring-xd/1.2.0.BUILD-SNAPSHOT/spring-xd-1.2.0.BUILD-20150423.001857-1-dist.zip
RUN 	unzip spring-xd-1.2.0.BUILD-20150423.001857-1-dist.zip

ENV 	XD_HOME $HOME/spring-xd-1.2.0.BUILD-SNAPSHOT

ENV	PATH $PATH:$XD_HOME/xd/bin:$XD_HOME/shell/bin:$JAVA_HOME/bin

RUN	echo PATH=$PATH

RUN	chkconfig sshd on
RUN	service sshd start

# Bundle source
COPY 	. .

RUN	rpm -ivh pivotal-gemfire-8.1.0-50625.el7.noarch.rpm

RUN	echo `which java`

EXPOSE	22	
EXPOSE  8080    
EXPOSE	10334  	
EXPOSE	40404	
EXPOSE	1099	
EXPOSE	7575


EXPOSE	9393


