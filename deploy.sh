container_id=$(docker ps -qf name=mysql_container)

# Get the IP address of the container
mysql_host=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")

# Check if mysql_host is empty
if [ -z "$mysql_host" ]; then
    echo "WARNING: Booting from cache. Any new information in the database will not be reflected as it is offline. Please start the database."
    echo "if its your first time deploying the system please use start.sh as failing do to so will result in a faliure of the next stages"
fi
# Print the IP address
echo "MySQL Host: $mysql_host"

# Stop the nginx_container
docker stop nginx_container
# Remove the nginx_container
docker rm nginx_container
docker build --build-arg MYSQL_HOST=$mysql_host -f ./images/nginx/ -t panaya_nginx:1.0
docker run -p 9980:9980 -d --name nginx_container panaya_nginx:1.0
