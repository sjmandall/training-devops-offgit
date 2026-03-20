# Day 2 Runbook

## Objective
Create an Apache VirtualHost for `devops.local` with separate logs, enable HTTPS using a self-signed certificate, enforce HTTP to HTTPS redirection, apply security headers, and verify the setup using `curl`.[web:18][web:19][web:67]

## Environment
- Platform: Ubuntu on WSL
- Web server: Apache2
- Local domain: `devops.local`
- Document root: `/var/www/devops.local`
- Certificate files:
  - `/etc/ssl/private/devops.local.key`
  - `/etc/ssl/certs/devops.local.crt` [web:18][web:19]

## Commands Used
```bash
sudo nano /etc/hosts
sudo mkdir -p /var/www/devops.local
sudo chown -R $USER:$USER /var/www/devops.local
sudo chmod -R 755 /var/www/devops.local
nano /var/www/devops.local/index.html
sudo a2enmod ssl
sudo a2enmod headers
sudo a2enmod rewrite
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/devops.local.key \
-out /etc/ssl/certs/devops.local.crt
sudo nano /etc/apache2/sites-available/devops.local.conf
sudo a2ensite devops.local.conf
sudo a2dissite 000-default.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
curl -I http://localhost
curl -I http://devops.local
curl -kI https://devops.local
curl http://devops.local
curl -k https://devops.local

## Host File Entries

# Ubuntu WSL
```
127.0.0.1 devops.local

```
#Windows Hosts File
```
172.31.254.41 devops.local
```

##Apache VirtualHost

```
/etc/apache2/sites-available/devops.local.conf
text
<VirtualHost *:80>
    ServerName devops.local

    ErrorLog ${APACHE_LOG_DIR}/devops.local-error.log
    CustomLog ${APACHE_LOG_DIR}/devops.local-access.log combined

    Redirect / https://devops.local/
</VirtualHost>

<VirtualHost *:443>
    ServerName devops.local
    DocumentRoot /var/www/devops.local

    ErrorLog ${APACHE_LOG_DIR}/devops.local-ssl-error.log
    CustomLog ${APACHE_LOG_DIR}/devops.local-ssl-access.log combined

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/devops.local.crt
    SSLCertificateKeyFile /etc/ssl/private/devops.local.key

    <Directory /var/www/devops.local>
        AllowOverride All
        Require all granted
    </Directory>

    Header always set Strict-Transport-Security "max-age=31536000"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
</VirtualHost>
```

##Verification URLs
 http://devops.local [web:18]

 https://devops.local [web:18]

##Website File

```
/var/www/devops.local/index.html
xml
<!DOCTYPE html>
<html>
<head>
  <title>devops.local</title>
</head>
<body>
  <h1>devops.local is working</h1>
  <p>This is my Day 2 Apache VirtualHost + TLS local setup.</p>
</body>
</html>
```
##Verification Output

#Apache Config Test

```
Syntax OK
```
#Apache Service Status
```
Active: active (running)
```

#HTTP Localhost Check
```
HTTP/1.1 200 OK
Date: Fri, 13 Mar 2026 12:09:18 GMT
Server: Apache/2.4.58 (Ubuntu)
Content-Type: text/html; charset=UTF-8
```
#HTTP Redirect Check
```
HTTP/1.1 302 Found
Date: Fri, 13 Mar 2026 12:09:18 GMT
Server: Apache/2.4.58 (Ubuntu)
Location: https://devops.local/
Content-Type: text/html; charset=iso-8859-1
```

#HTTPS Headers Check
```
HTTP/1.1 200 OK
Date: Fri, 13 Mar 2026 12:09:18 GMT
Server: Apache/2.4.58 (Ubuntu)
Strict-Transport-Security: max-age=31536000
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Last-Modified: Fri, 13 Mar 2026 10:23:57 GMT
ETag: "be-64ce5444aa7d1"
Accept-Ranges: bytes
Content-Length: 190
Vary: Accept-Encoding
Content-Type: text/html
```

#HTTP Content Check
```
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>302 Found</title>
</head><body>
<h1>Found</h1>
<p>The document has moved <a href="https://devops.local/">here</a>.</p>
<hr>
<address>Apache/2.4.58 (Ubuntu) Server at devops.local Port 80</address>
</body></html>
```

#HTTPS Content Check
```
<!DOCTYPE html>
<html>
<head>
  <title>devops.local</title>
</head>
<body>
  <h1>devops.local is working</h1>
  <p>This is my Day 2 Apache VirtualHost + TLS local setup.</p>
</body>
</html>
```

##Browser Result
Opening https://devops.local in the browser showed a privacy warning with NET::ERR_CERT_AUTHORITY_INVALID, which is expected for a self-signed certificate.[web:281][web:340]
After proceeding through the browser warning, the site opened successfully over HTTPS.[web:282][web:287]

##Acceptance Criteria Status
devops.local.conf created and enabled.[web:18][web:335]

curl -I http://devops.local showed redirect to HTTPS.[web:18][web:339]

curl -kI https://devops.local showed expected headers.[web:237][web:331]

Browser reached https://devops.local successfully with the expected self-signed certificate warning.[web:281][web:287]




