FROM debian:buster

ARG DB_USER=admin
ARG DB_USER_PASSWORD=password
ARG WP_USER=wpuser
ARG WP_USER_PASSWORD=password
ARG WP_USER_EMAIL=jevan-de@codam.student.nl
ARG BLOWFISH_SECRET=\$2a\$07\$EJooQ7FWQIpYWJAMqd0mq.eRnrTTAkqpIwEv1InrJ8q0KMfAK0WLi

# update the package systems sources and install nginx
RUN apt-get update \
	&& apt-get install -y \
		php-fpm \
		openssl \
		nginx \
	&& sed -i '/upload_max_filesize/c upload_max_filesize = 20M' /etc/php/7.3/fpm/php.ini \
	&& sed -i '/post_max_size/c post_max_size = 21M' /etc/php/7.3/fpm/php.ini

# create a self-signed certificate for nginx to use to support
# traffic over https, port 443
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-subj '/C=NL/ST=NH/L=Amsterdam/O=42/CN=jevan-de' \
		-keyout /etc/ssl/certs/default.key \
		-out /etc/ssl/certs/default.crt

# add the modified default site config and relink it
ADD srcs/sites-enabled-default /etc/nginx/sites-available/default
RUN ln -s -f /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# add script that allows for the changing of the autoindex
# from outside of the container
ADD srcs/setautoindex.sh /setautoindex.sh
RUN chmod +x /setautoindex.sh

# install mariadb server and create a new database user
RUN apt-get install -y \
		mariadb-server \
	&& service mysql start \
	&& mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_USER_PASSWORD}';"

# all following commands will be executed from this directory
# and it will be become the starting directory when entering
# the container using a shell
WORKDIR /var/www/html

# 1. install required packages
# 2. download wordpress files
# 3. use the wp-cli tool to install and configure wordpress
RUN apt-get install -y \
		wget \
		php-mysql \
		sendmail \
	&& wget http://wordpress.org/latest.tar.gz \
	&& tar -xzf latest.tar.gz \
	&& mv wordpress/* . \
	&& rm -rf wordpress \
	&& wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp \
	&& service mysql start \
	&& wp core config \
		--allow-root \
		--dbname=wordpress \
		--dbuser=${DB_USER} \
		--dbpass=${DB_USER_PASSWORD} \
		--dbhost=localhost \
		--dbprefix=wp_ \
	&& mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO '${DB_USER}'@'localhost';" \
	&& wp db create --allow-root \
	&& wp core install \
		--allow-root \
		--url=https://localhost \
		--title=JesseW \
		--admin_user=${WP_USER} \
		--admin_password=${WP_USER_PASSWORD} \
		--admin_email=${WP_USER_EMAIL}

# 1. install required packages
# 2. download phpmyadmin files
# 3. configure phpmyadmin's config.inc.php file
# 4. setup the phpmyadmin database
RUN apt-get install -y \
		php-mbstring \
		php-zip \
		php-gd \
	&& wget https://files.phpmyadmin.net/phpMyAdmin/4.9.0.1/phpMyAdmin-4.9.0.1-all-languages.tar.gz \
	&& tar xvf phpMyAdmin-4.9.0.1-all-languages.tar.gz \
	&& mv phpMyAdmin-4.9.0.1-all-languages phpmyadmin \
	&& rm phpMyAdmin-4.9.0.1-all-languages.tar.gz \
	&& bash -c "cp phpmyadmin/config{.sample,}.inc.php" \
	&& bash -c "sed -i $'s/\$cfg\[\'blowfish_secret\'\] = \'\'/\$cfg[\'blowfish_secret\'] = \'${BLOWFISH_SECRET}\'/' phpmyadmin/config.inc.php" \
	&& service mysql start \
	&& mysql -e "CREATE DATABASE phpmyadmin;" \
	&& mysql -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO '${DB_USER}'@'localhost';" \
	&& mysql < phpmyadmin/sql/create_tables.sql

# Make sure file ownership is set up correctly
RUN chmod -R 755 /var/www \
	&& chown -R www-data:www-data /var/www

# Add the entrypoint script to the container
ADD srcs/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/bin/sh", "/entrypoint.sh" ]

# these ports should be exposed when running a container based
# on this image in order for it to be fully functional
EXPOSE 80 443