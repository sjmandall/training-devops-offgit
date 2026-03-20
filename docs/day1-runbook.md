# Day 1 Runbook

## Objective
Install a LAMP stack on Ubuntu WSL, deploy a small website with Home, About, and Contact pages, create a PHP diagnostic endpoint, create a dedicated Linux user `webadmin`, and ensure the site directory `/var/www/website` is owned by `webadmin`.[web:2][web:45]

## Commands Used
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql
sudo service apache2 start
sudo service mysql start
sudo adduser webadmin
sudo mkdir -p /var/www/website
sudo chown -R webadmin:webadmin /var/www/website
sudo chmod -R 755 /var/www/website
sudo nano /var/www/website/index.php
sudo nano /var/www/website/about.php
sudo nano /var/www/website/contact.php
sudo nano /var/www/website/info.php
sudo nano /etc/apache2/sites-available/website.conf
sudo a2ensite website.conf
sudo a2dissite 000-default.conf
sudo apache2ctl configtest
sudo service apache2 reload
apache2 -v
php -v
mysql --version
sudo service mysql status
sudo service apache2 status
ls -ld /var/www/website

## Acceptance criteria
1. Site reachable at `http://localhost`. [file:183]
2. PHP works using `info.php` or equivalent. [file:183]
3. `day1-runbook.md` includes exact commands. [file:183]
4. Evidence includes `apache2 -v`, `php -v`, and DB status output. [file:183]
5. Site directory is owned by `webadmin`. [file:183]

## User and environment
- User created: `webadmin`. [file:183]
- Database used: `MySQL`. 
- Site URL: `http://localhost`. [file:183]

## Commands used
### Install packages
```bash
sudo apt update
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql
```

### Start and enable services
```bash
sudo systemctl enable apache2
sudo systemctl start apache2
sudo systemctl enable mariadb
sudo systemctl start mariadb
```

### Enable Apache modules
```bash
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod ssl
sudo systemctl reload apache2
```

### Create site directory
```bash
sudo mkdir -p /var/www/website/public
sudo chown -R webadmin:webadmin /var/www/website
sudo find /var/www/website -type d -exec chmod 755 {} \;
sudo find /var/www/website -type f -exec chmod 644 {} \;
```

### Create website files
```bash
sudo -u webadmin nano /var/www/website/public/index.html
sudo -u webadmin nano /var/www/website/public/about.html
sudo -u webadmin nano /var/www/website/public/contact.html
sudo -u webadmin nano /var/www/website/public/info.php
```

### Apache virtual host
```bash
sudo tee /etc/apache2/sites-available/website.conf > /dev/null <<'EOF'
<VirtualHost *:80>
    ServerName localhost
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/website/public

    <Directory /var/www/day1site/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/website_error.log
    CustomLog ${APACHE_LOG_DIR}/website_access.log combined
</VirtualHost>
EOF
```
```

## Enable site
```bash
sudo a2dissite 000-default.conf
sudo a2ensite website.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

## Validation commands
```bash
apache2 -v
php -v
sudo systemctl status apache2 --no-pager
sudo systemctl status mariadb --no-pager
apache2ctl -M | grep rewrite
sudo apache2ctl configtest
ls -ld /var/www/day1site
ls -ld /var/www/day1site/public
ls -l /var/www/day1site/public
curl -I http://localhost
curl -I http://localhost/info.php
```

## Validation outputs

### Apache version
```bash
Server version: Apache/2.4.66 (Debian)
Server built:   2026-03-01T13:26:45

### PHP version
```bash
PHP 8.4.16 (cli) (built: Mar  2 2026 16:15:02) (NTS)
Copyright (c) The PHP Group
Built by Debian
Zend Engine v4.4.16, Copyright (c) Zend Technologies
    with Zend OPcache v8.4.16, Copyright (c), by Zend Technologies

```

## Apache status
```bash
 apache2.service - The Apache HTTP Server
     Loaded: loaded (/usr/lib/systemd/system/apache2.service; enabled; preset: disabled)
     Active: active (running) since Thu 2026-03-12 02:35:10 EDT; 43min ago
 Invocation: ba9cb5ff49a84a3e9d74c8665a48d699
       Docs: https://httpd.apache.org/docs/2.4/
    Process: 16841 ExecReload=/usr/sbin/apachectl graceful (code=exited, status=0/SUCCESS)
   Main PID: 16580 (apache2)
     Status: "Total requests: 16; Idle/Busy workers 100/0;Requests/sec: 0.00622; Bytes served/sec:  13 B/sec"
      Tasks: 8 (limit: 9366)
     Memory: 22.4M (peak: 37.1M)
        CPU: 4.250s
     CGroup: /system.slice/apache2.service
             ├─16580 /usr/sbin/apache2 -k start -DFOREGROUND
             ├─16846 /usr/sbin/apache2 -k start -DFOREGROUND
             ├─16847 /usr/sbin/apache2 -k start -DFOREGROUND
             ├─16848 /usr/sbin/apache2 -k start -DFOREGROUND
             ├─16849 /usr/sbin/apache2 -k start -DFOREGROUND
             ├─16850 /usr/sbin/apache2 -k start -DFOREGROUND
             ├─17853 /usr/sbin/apache2 -k start -DFOREGROUND
             └─17861 /usr/sbin/apache2 -k start -DFOREGROUND

Mar 12 02:35:07 kali systemd[1]: Starting apache2.service - The Apache HTTP Server...
Mar 12 02:35:08 kali apachectl[16580]: AH00558: apache2: Could not reliably determine the server's fully qu… mess>
Mar 12 02:35:10 kali systemd[1]: Started apache2.service - The Apache HTTP Server.
Mar 12 02:36:30 kali systemd[1]: Reloading apache2.service - The Apache HTTP Server...
Mar 12 02:36:31 kali apachectl[16643]: AH00558: apache2: Could not reliably determine the server's fully qu… mess>
Mar 12 02:36:31 kali systemd[1]: Reloaded apache2.service - The Apache HTTP Server.
Mar 12 02:38:27 kali systemd[1]: Reloading apache2.service - The Apache HTTP Server...
Mar 12 02:38:27 kali systemd[1]: Reloaded apache2.service - The Apache HTTP Server.
Mar 12 02:47:56 kali systemd[1]: Reloading apache2.service - The Apache HTTP Server...
Mar 12 02:47:56 kali systemd[1]: Reloaded apache2.service - The Apache HTTP Server.
Hint: Some lines were ellipsized, use -l to show in full.

```

## Mysql status
```
sjmandal2415@SJMANDAL:/mnt/c/Users/sjman$ sudo systemctl status mysql
● mysql.service - MySQL Community Server
     Loaded: loaded (/usr/lib/systemd/system/mysql.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-03-13 07:24:44 UTC; 2h 37min ago
   Main PID: 1974 (mysqld)
     Status: "Server is operational"
      Tasks: 38 (limit: 4300)
     Memory: 351.3M (peak: 378.8M)
        CPU: 1min 23.785s
     CGroup: /system.slice/mysql.service
             └─1974 /usr/sbin/mysqld

Mar 13 07:24:43 SJMANDAL systemd[1]: Starting mysql.service - MySQL Community Server...
Mar 13 07:24:44 SJMANDAL systemd[1]: Started mysql.service - MySQL Community Server.
    ```

### Apache rewrite module
```bash
rewrite_module (shared)
```

### Apache config test
```bash
Syntax OK

```

### Ownership check
```bash
drwxr-xr-x 3 webadmin webadmin 4096 Mar 12 02:39 /var/www/day1site
drwxr-xr-x 2 webadmin webadmin 4096 Mar 12 02:46 /var/www/day1site/public
total 16
-rw-rw-r-- 1 webadmin webadmin 380 Mar 12 02:46 about.html
-rw-rw-r-- 1 webadmin webadmin 344 Mar 12 02:46 contact.html
-rw-rw-r-- 1 webadmin webadmin 406 Mar 12 02:45 index.html
-rw-rw-r-- 1 webadmin webadmin  17 Mar 12 02:46 info.php

```

### Localhost check
```bash
HTTP/1.1 200 OK
Date: Thu, 12 Mar 2026 07:22:18 GMT
Server: Apache/2.4.66 (Debian)
Last-Modified: Thu, 12 Mar 2026 06:45:52 GMT
ETag: "196-64cce1a89bc48"
Accept-Ranges: bytes
Content-Length: 406
Vary: Accept-Encoding
Content-Type: text/html

```

### PHP endpoint check
```bash
HTTP/1.1 200 OK
Date: Thu, 12 Mar 2026 07:22:59 GMT
Server: Apache/2.4.66 (Debian)
Content-Type: text/html; charset=UTF-8

```
## Result
Day 1 LAMP foundation setup completed with Apache, PHP, and MariaDB; `webadmin` created; Apache rewrite module en>

