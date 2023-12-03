FROM mysql:5.7

# Environment variables for MySQL configuration
ENV MYSQL_ROOT_PASSWORD=123123123123
ENV MYSQL_DATABASE=panaya
ENV MYSQL_USER=panaya
ENV MYSQL_PASSWORD=123123123123

# Copy SQL script to initialize the database

COPY images/mysql/create_tables.sql /docker-entrypoint-initdb.d/