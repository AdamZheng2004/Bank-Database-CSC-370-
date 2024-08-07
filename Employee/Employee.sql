# Adam Zheng

# Create Table
use bank_database;
drop table if exists `Employee`;
drop table if exists `Part_Time_Employee`;
create table `Employee` (
	`employee_id` int
	,`age` int
	,`name` varchar(64)
	,`title` enum('Branch Manager', 'Assistant Branch Manager', 'Teller', 'Personal Banker', 'Loan Officer', 'Customer Service Representative', 'Financial Advisor')
	,`branch_num` int
    ,`hire_date` date
    ,primary key (`employee_id`)
    ,foreign key (`branch_num`) references `Bank`(`branch_num`)
    ,foreign key (`title`) references `Position`(`title`)
);
create table `Part_Time_Employee` (
	`employee_id` int primary key
    ,`hours_per_week` int
    ,foreign key (`employee_id`) references `Employee`(`employee_id`)
);

# Load Data Into Table (Might need to change path)
set global local_infile = 1;
load data local infile 'C:\\Users\\adamz\\OneDrive\\Documents\\UVic\\CSC 370\\Database Project\\Employee\\Employee_Data.csv'
into table Employee 
fields terminated by ',' 
optionally enclosed by '"' 
lines terminated by '\r\n'
ignore 1 lines;

# Queries
# Select entire table
select * from `Employee`;

# Hire new employees
insert into `Employee` (`employee_id`, `age`, `name`, `title`, `branch_num`, `hire_date`)
values (80, 38, 'Sam Bankman-fried', 'Teller', 1005151, current_date);
select * from `Employee`;

insert into `Employee` (`employee_id`, `age`, `name`, `title`, `branch_num`, `hire_date`)
values (81, 38, 'Sam Bank', 'Teller', 1005151, current_date);
select * from `Employee`;

# Change employee's title
update `Employee` 
set `title` = 'Financial Advisor'
where `employee_id` = 80;
select * from `Employee` where `employee_id` = 80;

# Display name, employee_id, by hire order (earliest first)
select `name`, `employee_id`, `hire_date`
from `Employee`
order by `hire_date`;

# Display name and branch location using join
select `name`, `location`
from `Employee` join `Bank` on `Employee`.`branch_num` = `Bank`.`branch_num`;

# Display possible titles, clearance_level, and how many currently hold that title
select `Employee`.`title`, `clearance_level`, count(*) as `num_employees_holding_title`
from `Employee` join `Position` on `Employee`.`title` = `Position`.`title`
group by `Position`.`title`, `clearance_level`;

# Display list of titles with atleast 4 employees holding said title
select `Employee`.`title`, count(`Employee`.`employee_id`) as `num_employees_holding_title`
from `Employee` 
group by `Employee`.`title`
having count(`Employee`.`employee_id`) > 3;

# Display list of employees with clearance_level greater than 2 that were hired before 2017-09-01 from youngest to oldest
select `Employee`.`age`,`Employee`.`name`, `Employee`.`hire_date`, `Position`.`clearance_level`
from `Employee`  join `Position` on `Employee`.`title` = `Position`.`title`
where `Position`.`clearance_level` > 2 and `Employee`.`hire_date` < '2017-09-01'
order by `Employee`.`age` asc;

# Using Transactions swap the Branch Manager
start transaction;
set SQL_SAFE_UPDATES = 0;

update `Employee` set branch_num = 1005151 where `employee_id` = 16;
update `Employee` set hire_date = current_date where `employee_id` = 16;
update `Employee` set branch_num = 2117272 where `employee_id` = 1;
update `Employee` set hire_date = current_date where `employee_id` = 1;

set SQL_SAFE_UPDATES = 1;
commit;
select * from `Employee` where `title` like 'Branch Manager';

# Using Transactions to move every even employee id to part time (with 20 hours)
start transaction;

insert into `Part_Time_Employee`(`employee_id`, `hours_per_week`)
select `Employee`.`employee_id`, 20
from `Employee`
where `Employee`.`employee_id` % 2 = 0
and `Employee`.`employee_id` not in (select `employee_id` from `Part_Time_Employee`);
	
commit;

select * from `Part_Time_Employee`;

# Create an Index on age for more optinized queries when needing to sort or filter by age
drop index `idx_age` on `Employee`;
create index `idx_age` on `Employee`(`age`);

# Add check constraint to Employee age to make sure atleast 16
alter table `Employee`
add constraint `check_age` check (`age` >= 16);

# Test that it won't allow bad insert or update (both should give error)
insert into `Employee` (`employee_id`, `age`, `name`, `title`, `branch_num`, `hire_date`)
values (100, 15, 'Not Old Enough', 'Teller', 1005151, current_date);

update `Employee` 
set `age` = 15
where `employee_id` = 1;

# Add check contraint to Part_Time_Employee hours to make sure it is less than 40 and greater than or equal to 10
alter table `Part_Time_Employee`
add constraint `check_hours` check (`hours_per_week` < 40 and `hours_per_week` >= 10);

# Test that it won't allow bad update (should give error)
update `Part_Time_Employee` 
set `hours_per_week` = 9
where `employee_id` = 2;

# Drop check constraints
alter table `Employee`
drop constraint `check_age`;

alter table `Part_Time_Employee`
drop constraint `check_hours`;
