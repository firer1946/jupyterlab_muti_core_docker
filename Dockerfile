FROM ubuntu
# 国内源
COPY ./conf/apt_source/sources.list /etc/apt/
RUN cat /etc/apt/sources.list
RUN apt-get update
# proxychains
RUN apt-get install proxychains curl -y
RUN sed -i 's/socks4[[:space:]]*127.0.0.1[[:space:]]*9050/socks5 192.168.175.1 1080/g' /etc/proxychains.conf
RUN proxychains curl google.com

# Install coq e python
RUN apt-get update && apt-get install -y coq coqide python3-dev python3
RUN apt-get update && apt-get install -y python3-pip wget

# conda
WORKDIR /server
COPY ./software/Anaconda3-2019.03-Linux-x86_64.sh /server
RUN bash /server/Anaconda3-2019.03-Linux-x86_64.sh -b
RUN echo "PATH=$PATH:/root/anaconda3/bin" >> /etc/profile &&\
echo "export PATH" >> /etc/profile &&\
. /etc/profile
RUN . /etc/profile && conda install jupyterlab -y

# c++
RUN . /etc/profile && conda install xeus-cling -c conda-forge -y

# Install scala
RUN apt-get update && apt-get install -y wget
RUN proxychains wget https://downloads.lightbend.com/scala/2.11.0/scala-2.11.0.tgz && tar -xvzf scala-2.11.0.tgz && rm scala-2.11.0.tgz
ENV SCALA_HOME=/scala-2.11.0
ENV export PATH=$PATH:$SCALA_HOME/bin:$PATH

# Install java
RUN apt-get update && apt-get install -y openjdk-11-jdk

# Configure Scala
ADD almond .
RUN chmod +x ./almond
RUN ./almond --install

# install c
RUN . /etc/profile && pip install jupyter-c-kernel
RUN . /etc/profile && install_c_kernel

# go
RUN apt-get install software-properties-common -y &&\
	apt-get install golang-go git -y
RUN apt-get install curl wget tar -y
# libsodium
COPY ./software/libsodium-1.0.3.tar.gz /server
RUN export ALL_PROXY=socks5://192.168.175.1:1080&&\
	cd /server/ &&\
	tar -xvzf libsodium-1.0.3.tar.gz &&\
	cd libsodium-1.0.3 && ./configure &&\
	make && make install
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
RUN ldconfig
# zeromq
RUN apt-get install libzmq3-dev -y
RUN export ALL_PROXY=socks5://192.168.175.1:1080 && go get -v -u github.com/gopherdata/gophernotes
ENV GOPATH=/root/go PATH=$PATH:$GOPATH:$GOPATH/bin
RUN . /etc/profile &&\
	mkdir -p ~/.local/share/jupyter/kernels/gophernotes && \
	cp $GOPATH/src/github.com/gopherdata/gophernotes/kernel/* ~/.local/share/jupyter/kernels/gophernotes &&\
	ln -s $GOPATH/bin/gophernotes /usr/bin/gophernotes

# configure java
ADD ijava-1.3.0 ./ijava-1.3.0
RUN ls
RUN . /etc/profile && cd ijava-1.3.0 && proxychains python install.py --sys-prefix

# Install Ruby
RUN apt-get update && apt-get install -y libtool libffi-dev ruby ruby-dev make
RUN apt-get update && apt-get install -y libzmq3-dev libczmq-dev
# Install Nodejs
RUN apt-get update && apt-get install -y nodejs npm


# Install Ruby
RUN apt-get update && apt-get install -y libtool libffi-dev ruby ruby-dev make
RUN apt-get update && apt-get install -y libzmq3-dev libczmq-dev
# Install Nodejs
RUN apt-get update && apt-get install -y nodejs npm
# Configure Ruby
RUN proxychains gem install cztop
RUN proxychains gem install iruby --pre
RUN . /etc/profile && proxychains iruby register --force
# Configure javascript(this step npm install maybe error,just reboot)
RUN mkdir -p /root/.npm &&\
	npm install --registry https://registry.npm.taobao.org -g ijavascript --unsafe-perm
RUN . /etc/profile && proxychains ijsinstall

# php
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get install ntpdate tzdata -y &&\
	cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
	apt install php -y

RUN curl -sS https://getcomposer.org/installer | php &&\
	mv composer.phar /usr/local/bin/composer
# php-zmq
RUN export ALL_PROXY=socks5://192.168.175.1:1080 && git clone https://github.com/zeromq/php-zmq.git
# phpize安装
RUN apt-get install php-dev -y
RUN	cd php-zmq && phpize && ./configure && \
	make && make install
# install
COPY ./software/jupyter-php-installer.phar /server/
RUN echo "extension=zmq.so">/etc/php/7.2/mods-available/zmq.ini
RUN echo "extension=zmq.so">/etc/php/7.2/cli/conf.d/zmq.ini
#RUN mkdir -p /var/www/.composer && chown -R www-data /var/www/.composer
#USER www-data
RUN mkdir -p /var/www/.composer/ &&\
	composer config -g repo.packagist composer https://packagist.phpcomposer.com
RUN php jupyter-php-installer.phar install -v

#rust
RUN apt-get install cargo cmake -y
RUN proxychains cargo install evcxr_jupyter
ENV export PATH=$PATH:/root/.cargo/bin
RUN ln -s /root/.cargo/bin/evcxr_jupyter /usr/bin/evcxr_jupyter
RUN evcxr_jupyter --install

#sos
#RUN mkdir /root/.pip
#COPY ./conf/pip/pip.conf /root/.pip
#ADD requirements.txt /server/requirements.txt
#RUN . /etc/profile &&\
#	pip3 install -r requirements.txt &&\
## Configure jupyter plugin for install extension
#	jupyter contrib nbextension install --user &&\
#	jupyter nbextensions_configurator enable --user &&\
## Configure coq (proof assistant)
#	python3 -m coq_jupyter.install &&\
## Configure sos (for multi lenguage into a notebook)
#	python3 -m sos_notebook.install

# remove package
RUN ls |grep -v notebook | xargs rm -rf


# cmd
CMD . /etc/profile && jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --NotebookApp.token=''