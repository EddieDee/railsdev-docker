#
# railsdev Dockerfile 
#
# https://github.com/eg5846/railsdev-docker 
#
FROM ubuntu:trusty 
MAINTAINER Andreas Egner <andreas.egner@web.de>

# Set environment variables
ENV DEBIAN_FRONTEND noninteractive

ENV ORACLE_JAVA_PACKAGE oracle-java7-installer

ENV MRIRUBY_MAJOR 2.1
ENV MRIRUBY_MINOR 2
ENV MRIRUBY_TARFILE ruby-$MRIRUBY_MAJOR.$MRIRUBY_MINOR.tar.gz
ENV MRIRUBY_TARFILE_URL http://cache.ruby-lang.org/pub/ruby/$MRIRUBY_MAJOR/$MRIRUBY_TARFILE

ENV JRUBY_VERSION 1.7.13
ENV JRUBY_TARFILE jruby-bin-$JRUBY_VERSION.tar.gz
ENV JRUBY_TARFILE_URL http://jruby.org.s3.amazonaws.com/downloads/$JRUBY_VERSION/$JRUBY_TARFILE

ENV CHRUBY_VERSION 0.3.8
ENV CHRUBY_TARFILE chruby-$CHRUBY_VERSION.tar.gz

# Modify inputrc
RUN \
  sed -i 's/^#\s*\(.*history-search-backward\)$/\1/g' /etc/inputrc && \
  sed -i 's/^#\s*\(.*history-search-forward\)$/\1/g' /etc/inputrc

# Replace sources.list for apt
ADD sources.list /etc/apt/sources.list

# Install packages
RUN apt-get update && apt-get dist-upgrade -y && apt-get clean
RUN \ 
  apt-get install -y --no-install-recommends byobu curl git git-doc iftop iperf iptraf lsof man rsync software-properties-common tree vim-nox vim-doc wget \
  coffeescript coffeescript-doc nodejs npm \
  gawk g++ gcc libc6-dev libsqlite3-dev libreadline6-dev libssl-dev libyaml-dev make patch zlib1g-dev \
  autoconf automake bison libffi-dev libgdm-dev libncurses5-dev libtool pkg-config libxml2-dev libxslt1-dev sqlite3 && \
  apt-get clean

# Install java
RUN \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y $ORACLE_JAVA_PACKAGE && \
  apt-get clean

# Install MRI ruby
RUN \
  wget -q $MRIRUBY_TARFILE_URL -O /tmp/$MRIRUBY_TARFILE && \
  tar xzf /tmp/$MRIRUBY_TARFILE -C /tmp && \
  cd /tmp/ruby-$MRIRUBY_MAJOR.$MRIRUBY_MINOR && \
  ./configure --prefix=/opt/rubies/ruby-$MRIRUBY_MAJOR.$MRIRUBY_MINOR && \
  make -j2 && make install && \
  cd / && rm -rf /tmp/ruby-$MRIRUBY_MAJOR.$MRIRUBY_MINOR /tmp/$MRIRUBY_TARFILE
  
# Install jruby
RUN \
  wget -q $JRUBY_TARFILE_URL -O /tmp/$JRUBY_TARFILE && \
  mkdir -p /opt/rubies && \
  tar -xzf /tmp/$JRUBY_TARFILE -C /opt/rubies && \
  ln -s /opt/rubies/jruby-$JRUBY_VERSION/bin/jruby /opt/rubies/jruby-$JRUBY_VERSION/bin/ruby && \
  rm -f /tmp/$JRUBY_TARFILE

# Install chruby
RUN \
  wget -q https://github.com/postmodern/chruby/archive/v$CHRUBY_VERSION.tar.gz -O /tmp/$CHRUBY_TARFILE && \
  tar -xzf /tmp/$CHRUBY_TARFILE -C /tmp && \
  cd /tmp/chruby-$CHRUBY_VERSION && \
  make install && \
  cd / && rm -rf /tmp/chruby-$CHRUBY_VERSION /tmp/$CHRUBY_TARFILE

# Install rails
RUN ["/bin/bash", "-c", "source /usr/local/share/chruby/chruby.sh && chruby ruby && gem update && gem install rails && chruby jruby && gem update && gem install rails"]

# Add user rails
RUN \
  useradd -c "Rails User" -m -p "\$6\$IWF1yZgJ$W1JAnnATqEUUfwh/a8RBAjIVtygV45EvHYLOCbe5QIoEjiaVlMNkISZ/UE22y3jtUVQFSW4XsAo1Z88OYnKfH1" -s /bin/bash rails && \
  echo "source /usr/local/share/chruby/chruby.sh" >> /home/rails/.bashrc

# Create mount point
VOLUME /projects

# Expose network ports
EXPOSE 3000 

# Finally ...
CMD su - rails && /bin/bash
