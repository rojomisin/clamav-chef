# Encoding: UTF-8

# Compiler is needed to install Cucumber for the acceptance tests
include_recipe 'apt' if node['platform_family'] == 'debian'
include_recipe 'build-essential'

# Ensure rsyslog is installed and running, regardless of whether the build
# environment is a Vagrant box or a Docker container with no init system.
package 'rsyslog'
file '/etc/rsyslog.conf' do
  content <<-EOH.gsub(/^ {4}/, '')
    $ModLoad imuxsock
    $WorkDirectory /var/lib/rsyslog
    $ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
    $OmitLocalLogging off
    *.info;mail.none;authpriv.none;cron.none /var/log/messages
    authpriv.* /var/log/secure
    mail.* -/var/log/maillog
    cron.* /var/log/cron
    *.emerg :omusrmsg:*
    uucp,news.crit /var/log/spooler
    local7.* /var/log/boot.log
  EOH
  only_if do
    node['platform_family'] == 'rhel' && \
      node['platform_version'].to_i >= 7 && \
      File.open('/proc/1/cmdline').read.start_with?('/usr/sbin/sshd')
  end
end
execute 'rsyslogd' do
  ignore_failure true
end

directory '/etc/cron.d'

# Speed up Travis builds by dropping in some shared .cvd files instead of
# downloading them from the DB server on each test platform.
if ::File.exist?(::File.expand_path('../../files/main.cvd', __FILE__))
  directory node['clamav']['database_directory'] do
    recursive true
  end

  %w(main.cvd daily.cvd bytecode.cvd).each do |f|
    cookbook_file ::File.join(node['clamav']['database_directory'], f)
  end
end

include_recipe 'clamav'
