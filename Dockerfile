FROM ubuntu:14.04

MAINTAINER Irek Romaniuk

# Basic packages
RUN RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  && yum -y install passwd sudo git wget openssl openssh openssh-server openssh-clients \
  && yum -y install mail postfix \
  rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd sensu \
 && echo "sensu" | passwd sendu --stdin \
 && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
 && sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config \
 && echo "sensu ALL=(ALL) ALL" >> /etc/sudoers.d/hiroakis

#1: Install Erlang
RUN wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb \
  && dpkg -i erlang-solutions_1.0_all.deb \
  && apt-get update \
  && apt-get -y install erlang-nox=1:18.2 
#2: Install RabbitMQ  
RUN wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.0/rabbitmq-server_3.6.0-1_all.deb \
  && dpkg -i rabbitmq-server_3.6.0-1_all.deb \
#3: Running and configure RabbitMQ  
RUN update-rc.d rabbitmq-server defaults \
  && /etc/init.d/rabbitmq-server start \
  && rabbitmqctl add_vhost /sensu \
  && sudo rabbitmqctl add_user sensu secret \
  && sudo rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"
#4: Install and run Redis
RUN apt-get update \
  && apt-get -y install redis-server \
  && update-rc.d redis-server defaults \
  && /etc/init.d/redis-server start


ADD ./files/rabbitmq.config /etc/rabbitmq/
RUN rabbitmq-plugins enable rabbitmq_management

export SE_USER=USER
export SE_PASS=PASSWORD

# Sensu server
ADD ./files/sensu-enterprise.repo /etc/yum.repos.d/
ADD ./files/sensu-enterprise-dashboard.repo /etc/yum.repos.d/
RUN yum install -y sensu \
  && apt-get update \
  && apt-get install sensu-enterprise
ADD ./files/config.json /etc/sensu/
RUN mkdir -p /etc/sensu/ssl \
  && cp /joemiller.me-intro-to-sensu/client_cert.pem /etc/sensu/ssl/cert.pem \
  && cp /joemiller.me-intro-to-sensu/client_key.pem /etc/sensu/ssl/key.pem

sudo chown -R sensu:sensu /etc/sensu
apt-get install sensu-enterprise-dashboard

RUN /etc/init.d/sshd start && /etc/init.d/sshd stop  && /etc/init.d/sensu-enterprise start && /etc/init.d/sensu-enterprise-dashboard start

EXPOSE 22 3000 4567 5671 15672

CMD ["/usr/bin/supervisord"]

