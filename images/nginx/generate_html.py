import pymysql
import os
import time
import sys

def wait_for_mysql(mysql_host):
    max_retries = 10
    retries = 0
    while retries < max_retries:
        try:
            connection = pymysql.connect(host=mysql_host,  
                                 user='panaya',
                                 password='123123123123',
                                 db='panaya',
                                 port =3306,
                                 charset='utf8mb4',
                                 cursorclass=pymysql.cursors.DictCursor)
            connection.close()
            print("MySQL is ready!")
            return
        except pymysql.err.OperationalError:
            print("MySQL not ready, waiting...")
            retries += 1
            time.sleep(5)  # Wait for 5 seconds before retrying

    print("Max retries reached. Could not connect to MySQL.")
    exit(1)

def generate_html(mysql_host):
    connection = pymysql.connect(host=mysql_host,  
                                 user='panaya',
                                 password='123123123123',
                                 db='panaya',
                                 port =3306,
                                 charset='utf8mb4',
                                 cursorclass=pymysql.cursors.DictCursor)

    try:
        with connection.cursor() as cursor:
            # Use a JOIN query to retrieve data from all three tables
            sql = """
                SELECT 
                    c.Id AS Company_id,
                    c.Name AS Company,
                    a.Id AS Account_id,
                    a.Name AS Account,
                    p.Id AS Project_id,
                    p.Name AS Project,
                    p.Status
                FROM As_company c
                JOIN As_account a ON c.Id = a.Company_id
                JOIN As_project p ON a.Id = p.Account_id;
            """
            cursor.execute(sql)
            results = cursor.fetchall()

            with open('index.html', 'w') as file:
                file.write("<html><head><title>MySQL Tables</title></head><body>\n")
                file.write("<h1>MySQL Tables</h1>\n")
                file.write("<table border='1'>\n")
                file.write("<tr><th>Company ID</th><th>Company</th><th>Account ID</th><th>Account</th><th>Project ID</th><th>Project</th><th>Status</th></tr>\n")
                for row in results:
                    file.write(f"<tr><td>{row['Company_id']}</td><td>{row['Company']}</td><td>{row['Account_id']}</td><td>{row['Account']}</td><td>{row['Project_id']}</td><td>{row['Project']}</td><td>{row['Status']}</td></tr>\n")
                file.write("</table>\n")
                file.write("</body></html>\n")
    finally:
        connection.close()

if __name__ == "__main__":
    mysql_host = os.environ.get("MYSQL_HOST", "localhost")
    
    #wait_for_mysql(mysql_host)
    
    generate_html(mysql_host)