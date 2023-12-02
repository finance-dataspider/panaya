-- create_tables.sql

USE panaya;

-- Create As_company table
CREATE TABLE As_company (
    Id INT PRIMARY KEY,
    Name VARCHAR(255)
);

-- Create As_account table
CREATE TABLE As_account (
    Id INT PRIMARY KEY,
    Name VARCHAR(255),
    Company_id INT,
    FOREIGN KEY (Company_id) REFERENCES As_company(Id)
);

-- Create As_project table
CREATE TABLE As_project (
    Id INT PRIMARY KEY,
    Name VARCHAR(255),
    Account_id INT,
    Status INT,
    FOREIGN KEY (Account_id) REFERENCES As_account(Id)
);

-- Insert data into As_company
INSERT INTO As_company (Id, Name) VALUES (1, 'Company1'), (2, 'Company2');

-- Insert data into As_account
INSERT INTO As_account (Id, Name, Company_id) VALUES (1, 'Account1', 1), (2, 'Account2', 2);

-- Insert data into As_project
INSERT INTO As_project (Id, Name, Account_id, Status) VALUES (1, 'Project1', 1, 1), (2, 'Project2', 2, 0);
