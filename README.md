# 用于zabbix的php模板

- 使用ruby脚本编写
- 支持Ping和status绘图
- 支持自动探测单台设备上跑了几个php pool资源池,并自动监控上

# 依赖:

- Nginx使用vhost dir设置,将每个域名的配置单独放到一个配置文件中
- PHP的ping和status路径使用分别使用 /php_ping 和 /php_status
- Ruby 1.8.7 和 rpm包: ruby-json (Non-Gem support package for json)

# 使用方法:

1) 修改php_status.rb内的2个配置项
<pre>
# config
@php_pid_file = "/var/run/php-fpm.pid"
@nginx_vhostd = "/home/nginx/conf/vhost.d/"
</pre>

2) 放置php_status.rb和php.conf至相应路径.

3) 导入zbx_php_templates.xml
