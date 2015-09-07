#!/usr/bin/env ruby
# Author: djluo <dj.luo@ocworker.com>

require 'json'
require 'net/http'
require 'uri'

# config
@php_pid_file = "/var/run/php-fpm.pid"
@nginx_vhostd = "/home/nginx/conf/vhost.d/"

# regexp
@re_php_status = {
  :accepted => /^accepted conn:\s+(\d+)$/        ,
  :idle     => /^idle processes:\s+(\d+)$/       ,
  :active   => /^active processes:\s+(\d+)$/     ,
  :total    => /^total processes:\s+(\d+)$/      ,
  :max_act  => /^max active processes:\s+(\d+)$/ ,
  :max_chil => /^max children reached:\s+(\d+)$/ ,
  :slow_req => /^slow requests:\s+(\d+)$/        ,
}

# method
def discovery(nginx_vhost_dir)
  domains = []

  Dir.glob(nginx_vhost_dir + "*.conf") do |conf|
    name = get_domain_with_port(conf)
    domains << name if name
  end

  return domains
end

def get_domain_with_port(file)
  name = port = iscgi = nil

  File.open(file, "r").each_line do |line|
    name  = $1    if line =~ /^\s*server_name\s*(\S*);$/
    port  = $1    if line =~ /^\s*listen\s*(\d+);$/
    iscgi = true  if line =~ /^\s*fastcgi_pass/
  end

  if name and port and iscgi
    return name + ":" + port.to_s
  end
end

def get_http(domain,path)
    uri  = 'http://' + domain.to_s + path.to_s
    port = URI(uri).port

    res  = Net::HTTP.start('127.0.0.1', port) { |http|
      req = Net::HTTP::Get.new(uri)
      http.request(req)
    }

    return res, port
end

def ping(domain, pidfile)
  begin
    pid = File.open(pidfile,'r').read
    raise "PID not a number?" unless pid =~ /\d+/
    raise "PID not exist?"    unless File.exist?("/proc/" + pid.to_s)

    res, port = get_http(domain,'/php_ping')
    raise "response without pong?" unless res.body =~ /^pong$/

    puts "PONG: port is #{port}"
  rescue
    puts "FAIL: port is #{port}: " + $!
  end
end

def status(domain,type,regexps)
  if regexps.has_key?(:"#{type}")
    res, port = get_http(domain, '/php_status')
    num = $1 if regexps[:"#{type}"].match(res.body)
  end

  puts num || "-1"
end

def usage()
  puts "Usage: $0 discovery"
  puts "Usage: $0 ping   hostname"
  puts "Usage: $0 status hostname [accepted|idle|active|total]"
  puts "Usage: $0 status hostname [max_active|max_children_reached|slow]"
  exit
end

# main
if __FILE__ == $0

  action = ARGV[0]
  domain = ARGV[1]
  type   = ARGV[2]

  case action
  when /^discovery$/
    data    = { :data => [] }
    domains = discovery(@nginx_vhostd)
    domains.each do |domain_with_port|
      data[:data] << { "{#DOMAIN}" => domain_with_port }
    end
    puts data.to_json
  when /^ping$/
    usage() unless domain
    ping(domain, @php_pid_file)
  when /^status$/
    usage() unless domain and type
    status(domain,type, @re_php_status)
  else
    usage()
  end
end
