FROM ubuntu:14.04
MAINTAINER Irek Romaniuk
# Install
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
  apt-get update \
  apt-get -y upgrade \
  apt-get install -y build-essential \
  apt-get install -y software-properties-common \
  && yum -y install passwd sudo git wget openssl openssh openssh-server openssh-clients \
  && yum -y install mail postfix \
  rm -rf /var/lib/apt/lists/*
# Create user
RUN useradd sensu \
 && echo "sensu" | passwd sendu --stdin \
 && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
 && sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config \
 && echo "sensu ALL=(ALL) ALL" >> /etc/sudoers.d/sensu
#1: Install Erlang
RUN wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb \
  && dpkg -i erlang-solutions_1.0_all.deb \
  && apt-get update \
  && apt-get -y install erlang-nox=1:18.2 
#2: Install RabbitMQ  
RUN wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.0/rabbitmq-server_3.6.0-1_all.deb \
  && dpkg -i rabbitmq-server_3.6.0-1_all.deb \
#3: Running and configure RabbitMQ  
ADD ./files/rabbitmq.config /etc/rabbitmq/
RUN update-rc.d rabbitmq-server defaults \
  && /etc/init.d/rabbitmq-server start \
  && rabbitmqctl add_vhost /sensu \
  && rabbitmqctl add_user sensu secret \
  && rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"
#4: Install and run Redis
RUN apt-get update \
  && apt-get -y install redis-server \
  && update-rc.d redis-server defaults \
  && /etc/init.d/redis-server start
RUN wget -q http://repositories.sensuapp.org/apt/pubkey.gpg -O- | sudo apt-key add - \
&& echo "deb http://repositories.sensuapp.org/apt sensu main" | sudo tee /etc/apt/sources.list.d/sensu.list
ADD ./files/sensu.repo /etc/yum.repos.d/
RUN apt-get update \
  && apt-get install sensu
ADD ./files/config.json /etc/sensu/
RUN mkdir /tmp \
  && cd /tmp  \
  && wget http://sensuapp.org/docs/0.21/tools/ssl_certs.tar && tar -xvf ssl_certs.tar \
  && cd ssl_certs && ./ssl_certs.sh generate \
  && mkdir -p /etc/rabbitmq/ssl \
  && cp /tmp/ssl_certs/sensu_ca/cacert.pem /tmp/ssl_certs/server/cert.pem /tmp/ssl_certs/server/key.pem /etc/rabbitmq/ssl \
  && mkdir -p /etc/sensu/ssl \
  && cp /tmp/ssl_certs/client/cert.pem /tmp/ssl_certs/client/key.pem /etc/sensu/ssl
ADD ./files/uchiwa.json /etc/sensu/  
RUN sudo chown -R sensu:sensu /etc/sensu \
  && apt-get install -y uchiwa
  && update-rc.d sensu-server defaults \
  && update-rc.d sensu-api defaults 
RUN /etc/init.d/sshd start && /etc/init.d/sshd stop \
&& /etc/init.d/sensu-server start && /etc/init.d/sensu-api start
EXPOSE 22 3000 4567 5671 15672
#CMD [""]

