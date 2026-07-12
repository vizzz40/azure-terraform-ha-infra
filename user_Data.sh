#!/bin/bash

apt-get update
apt-get install -y apache2 php curl unzip


rm /var/www/html/index.html
echo "<?php echo 'hello world! '; ?>" > /var/www/html/index.php


systemctl restart apache2