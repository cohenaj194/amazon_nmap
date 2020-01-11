# frozen_string_literal: true

Vagrant.configure(2) do |config|
  config.vm.box = 'concourse/lite'
  config.vm.network 'forwarded_port', guest: 8080, host: 8080
  config.vm.provision :shell, inline: 'apt-get update'
  config.vm.provision :shell, inline: 'apt-get install -y -q ntp'
  config.vm.provision :shell, inline: 'wget --quiet https://github.com/concourse/concourse/releases/download/v3.4.0/concourse_linux_amd64 -O /usr/local/bin/concourse.next && chmod +x /usr/local/bin/concourse.next ; service concourse-web stop ; service concourse-worker stop ; mv /usr/local/bin/concourse.next /usr/local/bin/concourse'
  config.vm.provision :shell, inline: 'service concourse-web restart'
  config.vm.provision :shell, inline: 'service concourse-worker restart'
  config.vm.provision :shell, inline: "grep -q -F '# Set aggressive ntpd time correction' /etc/ntp.conf || echo -e '\n# Set aggressive ntpd time correction' >> /etc/ntp.conf"
  config.vm.provision :shell, inline: "grep -q -F 'tinker panic 0' /etc/ntp.conf || echo 'tinker panic 0' >> /etc/ntp.conf"
end
