/*
Lab 2 report <Fabian Bergström fabbe820 Alexander Nordin Davidsson aleno645>
*/

/* All non code should be within SQL-comments like this */ 


/*
Drop all user created tables that have been created when solving the lab
*/

DROP TABLE IF EXISTS custom_table CASCADE;

/* Have the source scripts in the file so it is easy to recreate!*/

SOURCE company_schema.sql;
SOURCE company_data.sql;



/*
Question 1: Print a message that says "hello world"
*/

SELECT 'hello world!' AS 'message';

/* Show the output for every question.
+--------------+
| message      |
+--------------+
| hello world! |
+--------------+
1 row in set (0.00 sec)
supplier, sum(quantity) AS sum FROM jbsale_supply
*/ 
/*

1. List all employees, i.e., all tuples in the jbemployee relation.

*/



SELECT * FROM jbemployee;



/*

2. List the name of all departments in alphabetical order. Note: by “name” 
we mean the name attribute in the jbdept relation.

*/



SELECT name FROM jbdept ORDER BY name ASC;



/*

3. What parts are not in store? Note that such parts have the value 0 (zero)
for the qoh attribute (qoh = quantity on hand). *

*/



SELECT name FROM jbparts WHERE QOH = 0;



/*

4. List all employees who have a salary between 9000 (included) and 
10000 (included)? *

*/



SELECT name FROM jbemployee WHERE SALARY >= 9000 AND SALARY <= 10000;



/*

5. List all employees together with the age they had when they started 
working? Hint: use the startyear attribute and calculate the age in the 
SELECT clause. *

*/



SELECT name, (STARTYEAR - BIRTHYEAR) FROM jbemployee;



/*

6. List all employees who have a last name ending with “son”. *

*/



SELECT name FROM jbemployee WHERE name LIKE "%son,%";



/*

7. Which items (note items, not parts) have been delivered by a supplier 
called Fisher-Price? Formulate this query by using a subquery in the 
WHERE clause.

*/



SELECT name FROM jbitem WHERE supplier IN (SELECT id FROM jbsupplier WHERE name = "Fisher-Price");



/*

8. Formulate the same query as above, but without a subquery. *

SELECT name from jbitem WHERE SUPPLIER = 89;

*/



SELECT jbitem.name 
FROM jbitem, jbsupplier 
WHERE jbitem.SUPPLIER = jbsupplier.ID AND jbsupplier.NAME = "Fisher-Price";



/*

9. List all cities that have suppliers located in them. Formulate this query 
using a subquery in the WHERE clause.

*/



SELECT name FROM jbcity 
WHERE id IN (SELECT city FROM jbsupplier);



/*

10.  What is the name akoppla jbcity, jbsupplier, jbsupply, jbpartsnd the color of the parts that are heavier than a card 
reader? Formulate this query using a subquery in the WHERE clause. 
(The query must not contain the weight of the card reader as a constant;
instead, the weight has to be retrieved within the query.)

*/



SELECT name, color 
FROM jbparts 
WHERE weight > ALL (SELECT weight FROM jbparts WHERE name = "card reader");



/*



11.  Formulate the same query as above, but without a subquery. Again, the 
query must not contain the weight of the card reader as a constant.

*/



SELECT A.name, A.color 
FROM jbparts A, jbparts B 
WHERE A.weight > B.weight AND B.name = "card reader";



/*

12. What is the average weight of all black parts?

*/



SELECT AVG(weight) 
FROM jbparts WHERE color = "black";



/*

13. For every supplier in Massachusetts (“Mass”), retrieve the name and the
total weight of all parts that the supplier has delivered? Do not forget to 
take the quantity of delivered parts into account. Note that one row 
should be returned for each supplier.

*/



SELECT jbsupplier.name, SUM(jbparts.weight * jbsupply.quan) AS "Total Weight"
FROM jbsupply JOIN jbparts ON jbsupply.part = jbparts.id
JOIN jbsupplier ON jbsupplier.id = jbsupply.supplier
WHERE jbsupplier.city IN (SELECT id FROM jbcity WHERE state = "Mass")
GROUP BY jbsupplier.name;



/*

14. Create a new relation with the same attributes as the jbitems relation by 
using the CREATE TABLE command where you define every attribute 
explicitly (i.e., not as a copy of another table). Then, populate this new 
relation with all items that cost less than the average price for all items. 
Remember to define the primary key and foreign keys in your table!

*/



DROP TABLE IF EXISTS new_jbitem CASCADE;



CREATE TABLE new_jbitem (
    ID integer,
    NAME varchar(20),
    DEPT integer,
    PRICE integer,
    QOH integer,
    SUPPLIER integer,



    constraint pk_new_jbitem 
        primary key (ID),
    constraint fk_newitem_dept 
        FOREIGN KEY (DEPT) references jbdept(ID),
    constraint fk_newitem_supplier 
        FOREIGN KEY (SUPPLIER) references jbsupplier(ID)

);



INSERT INTO new_jbitem (SELECT * FROM jbitem WHERE price < (SELECT AVG(price) FROM jbitem));



/*

15. Create a view that contains the items that cost less than the average 
price for items.

*/



DROP VIEW IF EXISTS item_view CASCADE;

CREATE VIEW item_view AS 
SELECT * 
FROM jbitem 
WHERE jbitem.price < ( SELECT AVG(sub.price) FROM jbitem AS sub);


/*

16.  What is the difference between a table and a view? One is static and the
other is dynamic. Which is which and what do we mean by static 
respectively dynamic?



A view is derived from a table, always up to date. 
A view is dynamic as it is always up to date to the corresponding table.
A table is static as you have to manually change data.

*/



/*

17. Create a view that calculates the total cost of each debit, by considering 
price and quantity of each bought item. (To be used for charging 
customer accounts). The view should contain the sale identifier (debit) 
and the total cost. In the query that defines the view, capture the join 
condition in the WHERE clause (i.e., do not capture the join in the 
FROM clause by using keywords inner join, right join or left join).

*/



DROP VIEW IF EXISTS debit_cost CASCADE;



CREATE VIEW debit_cost AS 
SELECT jbdebit.id, (jbitem.price * jbsale.quantity) AS "Total Cost"
FROM jbdebit, jbsale, jbitem
WHERE jbdebit.id = jbsale.debit
AND jbsale.item = jbitem.id
GROUP BY jbdebit.id;







/*

18. Do the same as in the previous point, but now capture the join conditions
in the FROM clause by using only left, right or inner joins. Hence, the 
WHERE clause must not contain any join condition in this case. Motivate
why you use type of join you do (left, right or inner), and why this is the 
correct one (in contrast to the other types of joins).



Motivation: 
We use inner join as we are only interested in joint pairs of jbdebit.id, jbsale.debit and jbitem.id.
We could use left join aswell as every jbdebit.id has a matching jbsale.debit and 
every (jbdebit.id & jbsale.debit) has a matching item in jbitem.
Right join isn't appropriate: every jbdebit.id has a matching jbsale.debit but 
every item in jbitem hasn't been bought by an employee. 
Every jbitem.id doesn't have a matching (jbdebit.id & jbsale.debit).



*/



DROP VIEW IF EXISTS debit_cost2 CASCADE;



CREATE VIEW debit_cost2 AS 


SELECT jbdebit.id, (jbitem.price * jbsale.quantity) AS "Total Cost"
FROM jbdebit INNER JOIN jbsale ON jbdebit.id = jbsale.debit
INNER JOIN jbitem ON jbsale.item = jbitem.id
GROUP BY jbdebit.id;



/*

19. Oh no! An earthquake!

a) Remove all suppliers in Los Angeles from the jbsupplier table. This 
will not work right away. Instead, you will receive an error with error 
code 23000 which you will have to solve by deleting some other related tuples. 
However, do not delete more tuples from other tables 
than necessary, and do not change the structure of the tables (i.e., 
do not remove foreign keys). Also, you are only allowed to use "Los 
Angeles" as a constant in your queries, not "199" or "900".



b) Explain what you did and why.

First we deleted the items in jbsale which were supplied by a supplier located in 
Los Angeles as it had a foreign key to the jbitem.id.
Then we deleted the actual item in jbitem which has a foreign key to jbsupplier.id, 
did the same with our table made in question 14.
Lastly we deleted the supplier located in Los Angeles from jbsupplier.
We did it in this order since foreign keys has to point to an existing value.

*/


DELETE FROM jbsale WHERE jbsale.item in (

    SELECT jbitem.id
    FROM jbsupplier, jbitem, jbcity
    WHERE jbcity.name = "Los Angeles"
    AND jbsupplier.city = jbcity.id
    AND jbitem.supplier = jbsupplier.id

);



DELETE FROM jbitem WHERE jbitem.id in (

    SELECT jbitem.id
    FROM jbsupplier, jbitem, jbcity
    WHERE jbcity.name = "Los Angeles"
    AND jbsupplier.city = jbcity.id
    AND jbitem.supplier = jbsupplier.id

);



DELETE FROM new_jbitem WHERE new_jbitem.id in (

    SELECT new_jbitem.id

    FROM jbsupplier, new_jbitem, jbcity
    WHERE jbcity.name = "Los Angeles"
    AND jbsupplier.city = jbcity.id
    AND new_jbitem.supplier = jbsupplier.id

);



DELETE FROM jbsupplier WHERE jbsupplier.city in (

    SELECT jbsupplier.city
    FROM jbsupplier, jbcity
    WHERE jbcity.name = "Los Angeles"
    AND jbsupplier.city = jbcity.id

);



/*20. An employee has tried to find out which suppliers have delivered items
that have been sold. To this end, the employee has created a view and
a query that lists the number of items sold from a supplier.
*/
DROP VIEW IF EXISTS jbsale_supply CASCADE;

CREATE VIEW jbsale_supply(supplier, item, quantity) AS
SELECT jbsupplier.name, jbitem.name, jbsale.quantity
FROM jbsupplier INNER JOIN jbitem ON jbsupplier.id = jbitem.supplier
LEFT JOIN jbsale ON jbitem.id = jbsale.item;



SELECT supplier, sum(quantity) AS sum 
FROM jbsale_supply
GROUP BY supplier;


