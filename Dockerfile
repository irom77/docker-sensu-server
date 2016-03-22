FROM ubuntu:14.04
MAINTAINER Irek Romaniuk
# Install
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list \
  && apt-get update \
  && apt-get -y upgrade \
  && apt-get install -y build-essential \
  && apt-get install -y software-properties-common \
  && apt-get -y install passwd sudo git wget openssl openssh-server openssh-client \
  && apt-get -y install postfix \
  && rm -rf /var/lib/apt/lists/*  
# Create user
RUN useradd sensu \
 && echo "sensu ALL=(ALL) ALL" >> /etc/sudoers.d/sensu
#1: Install Erlang
RUN wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb \
  && dpkg -i erlang-solutions_1.0_all.deb \
  && apt-get update \
  && apt-get -y install erlang-nox=1:18.2 
#2: Install RabbitMQ  
RUN wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.0/rabbitmq-server_3.6.0-1_all.deb \
  && dpkg -i rabbitmq-server_3.6.0-1_all.deb \
  && rabbitmq-plugins enable rabbitmq_management
#3: Install Redis
RUN apt-get update \
  && apt-get -y install redis-server 
#4: Install Sensu and Uchiwa  
RUN wget -q http://repositories.sensuapp.org/apt/pubkey.gpg -O- | sudo apt-key add - \
  && echo "deb http://repositories.sensuapp.org/apt sensu main" | sudo tee /etc/apt/sources.list.d/sensu.list \
  && apt-get update \
  && apt-get install sensu \
  && apt-get install -y uchiwa
#5: Copy config files
COPY ./files/config.json ./files/uchiwa.json /etc/sensu/
COPY ./files/rabbitmq.config /etc/rabbitmq/
#6: Create certificates
RUN mkdir -p /tmp \
  && cd /tmp  \
  && wget http://sensuapp.org/docs/0.21/tools/ssl_certs.tar && tar -xvf ssl_certs.tar \
  && cd ssl_certs && ./ssl_certs.sh generate \
  && mkdir -p /etc/rabbitmq/ssl \
  && cp /tmp/ssl_certs/sensu_ca/cacert.pem /tmp/ssl_certs/server/cert.pem /tmp/ssl_certs/server/key.pem /etc/rabbitmq/ssl \
  && mkdir -p /etc/sensu/ssl \
  && cp /tmp/ssl_certs/client/cert.pem /tmp/ssl_certs/client/key.pem /etc/sensu/ssl
# sudo chown -R sensu:sensu /etc/sensu \
RUN  update-rc.d rabbitmq-server defaults \
  && update-rc.d sensu-server defaults \
  && update-rc.d sensu-api defaults  \
  && update-rc.d redis-server defaults \
  #&& update-rc.d sensu-client defaults \
  && update-rc.d uchiwa defaults 
EXPOSE 22 3000 4567 5671 15672
COPY ./files/start.sh .
CMD chmod +x ./start.sh && ./start.sh 

