#/bin/sh

service nginx start
service mysql start
service php7.3-fpm start
service sendmail start

# sendmail requires a FQDN in /etc/hosts
echo "$(hostname -i)	$(hostname) $(hostname).localhost" >> /etc/hosts

# access logs can be followed from outside of container
# using docker -f logs <container_name>
tail -f /var/log/nginx/access.log