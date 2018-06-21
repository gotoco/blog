#!/bin/bash

echo "hexo regenerate static pages"

hexo clean
hexo generate
hexo deploy

echo "Remove content of /var/www/hexo/*"
rm -rf /var/www/hexo/*

echo "Push static pages to the /var/www/hexo/"
cp -r ./public/* /var/www/hexo/

echo "Restart NGINX"
sudo service nginx restart
