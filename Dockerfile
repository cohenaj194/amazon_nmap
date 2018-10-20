FROM centos:7

# install software
RUN yum install -y -q https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum update -y
RUN yum install -y ansible \
                   ruby \
                   nmap \
                   python \
                   python-dev \
                   python-pip \ 
                   openssh-clients 
RUN gem install bundler
RUN pip install boto

# copy over nmap scripts
RUN mkdir /nmap-scan/ 
RUN mkdir /nmap-scan/output/
ADD nmap-scan/* /nmap-scan/
RUN cd /nmap-scan/ && bundle install
RUN mkdir /aws-setup/
ADD aws-setup/* /aws-setup/


RUN mkdir /root/.ssh/
RUN touch /root/.ssh/known_hosts