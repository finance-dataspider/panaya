docker build -f ./images/mysql/Dockerfile . -t panaya_mysql:1.0 
docker run -d -p 3306:3306 --name mysql_container panaya_mysql:1.0
container_id=$(docker ps -qf name=mysql_container)

# Get the IP address of the container
mysql_host=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")

# Print the IP address
echo "MySQL Host: $mysql_host"
docker build --build-arg MYSQL_HOST=$mysql_host -f ./images/nginx/Dockerfile . -t panaya_nginx:1.0 
docker run -p 9980:9980 -d --name nginx_container panaya_nginx:1.0