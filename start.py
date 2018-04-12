import os, boto3

print("Starting nginx")
os.system("nginx")

print("Starting php-fpm in production mode")
os.system("php-fpm")
