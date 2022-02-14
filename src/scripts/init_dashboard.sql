ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'nebula';
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS `dashboard` CHARACTER SET utf8 COLLATE utf8_general_ci;