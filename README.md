# [42] ft_server

Project where we containerise a nginx webserver together with a mysql database server.
Under nginx both wordpress and PhpMyAdmin are installed.

Traffic is encrypted using a self-signed certificate. A simple /setautoindex.sh script
can be used to turn nginx's autoindex on and off.

Usage: /setautoindex.sh [off/on]

