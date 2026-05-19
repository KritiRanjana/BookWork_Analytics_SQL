--Create Databases 
CREATE DATABASE BookWork_Analytics 

-- Create Tables
DROP TABLE IF EXISTS Books;
CREATE TABLE Books (
    Book_ID SERIAL PRIMARY KEY,
    Title VARCHAR(100),
    Author VARCHAR(100),
    Genre VARCHAR(50),
    Published_Year INT,
    Price NUMERIC(10, 2),
    Stock INT
);

DROP TABLE IF EXISTS customers;
CREATE TABLE Customers (
    Customer_ID SERIAL PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100),
    Phone VARCHAR(15),
    City VARCHAR(50),
    Country VARCHAR(150)
);

DROP TABLE IF EXISTS orders;
CREATE TABLE Orders (
    Order_ID SERIAL PRIMARY KEY,
    Customer_ID INT REFERENCES Customers(Customer_ID),
    Book_ID INT REFERENCES Books(Book_ID),
    Order_Date DATE,
    Quantity INT,
    Total_Amount NUMERIC(10, 2)
);

SELECT * FROM Books;
SELECT * FROM Customers;
SELECT * FROM Orders;


--1. Retrieve all orders placed in the year 2023.

SELECT * FROM Orders
WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31';


--2. Fetch the total available stock of books.

SELECT SUM(stock) as Total_Stocks 
FROM Books;


--3. Display the details of the most expensive book in stock.

SELECT *
FROM books
WHERE price = (
    SELECT MAX(price)
    FROM books
);


--4. Calculate average order value

SELECT
    ROUND(AVG(Total_Amount),2) AS Average_Order_Value
FROM Orders;


--5. Retrieve orders where the total transaction amount exceeds $20

SELECT * FROM orders 
WHERE total_amount > 20 ; 


--6. Retrieve all distinct book genres available in the Books table

SELECT DISTINCT genre
FROM Books;


--7. Retrieve all books having the minimum stock quantity

SELECT * FROM books 
WHERE stock = (SELECT MIN(stock) 
FROM books
);


--8. Calculate the overall sales revenue from all orders 

SELECT SUM(total_amount) AS Total_Revenue
FROM orders;


--9. Retrieve the total number of books sold for each genre

SELECT 
    b.genre,
    SUM(o.quantity) AS total_books_sold
FROM orders o
JOIN books b
ON o.book_id = b.book_id
GROUP BY b.genre
ORDER BY total_books_sold DESC;


--10. Show the total number of books sold per author

SELECT b.author , SUM(o.quantity) AS Total_Books_Sold
FROM orders AS o 
JOIN books AS b
ON o.book_id = b.book_id
GROUP BY b.author;


--11. List customers who have placed alteast 2 orders ; 

SELECT c.customer_id , c.name , COUNT(o.order_id) AS ORDER_COUNT 
FROM orders AS o
JOIN customers AS c
ON c.customer_id = o.customer_id
GROUP BY c.customer_id , c.name
HAVING COUNT(o.Order_id) >= 2 ;


--12. Identify books with low stock availability

SELECT 
    title, stock,
    CASE
        WHEN stock < 10 THEN 'Low Stock'
        WHEN stock BETWEEN 10 AND 30 THEN 'Medium Stock'
        ELSE 'High Stock'
    END AS stock_status
FROM books;


--13. Identify the books with the highest number of orders 

SELECT o.book_id, b.title, COUNT(o.order_id) AS order_count
FROM orders AS o
JOIN books AS b
ON o.book_id = b.book_id
GROUP BY o.book_id, b.title
HAVING COUNT(o.order_id) = (
    SELECT MAX(order_total)
    FROM (
        SELECT COUNT(order_id) AS order_total
        FROM orders
        GROUP BY book_id
    ) AS max_orders
);


--14. Retrieve the top 3 most expensive books in the 'Fantasy' genre. 

SELECT * FROM books 
WHERE genre = 'Fantasy'
ORDER BY price DESC LIMIT 3 ;


--15. List the cities where customers placed orders greater than $30

SELECT DISTINCT c.city 
FROM orders AS o 
JOIN customers AS c 
ON o.customer_id = c.customer_id 
WHERE o.total_amount > 30 ;


--16. Find the customer who spent the most on orders 

SELECT c.customer_id , c.name , SUM(o.total_amount) AS Total_Spent 
FROM orders AS o
JOIN customers AS c
ON o.customer_id = c.customer_id 
GROUP BY c.customer_id , c.name 
ORDER BY total_spent DESC LIMIT 1 ;


--17. Calculate the remaining stock after fulfilling all orders.

SELECT b.book_id , b.title , b.stock ,
COALESCE(SUM(o.quantity),0) AS Order_quantity , 
b.stock - COALESCE(SUM(o.quantity),0) AS Remaining_quantity
FROM books AS b 
LEFT JOIN orders AS o 
ON b.book_id = o.book_id 
GROUP BY b.book_id , b.title , b.stock
ORDER BY b.book_id;


--18. Retrieve customers who spent more than $100

SELECT
    c.Name,
    SUM(o.Total_Amount) AS Total_Spent
FROM Orders o
JOIN Customers c
ON o.Customer_ID = c.Customer_ID
GROUP BY c.Name
HAVING SUM(o.Total_Amount) > 100;


--19. Rank books based on total quantity sold

SELECT 
    b.title,
    SUM(o.quantity) AS total_books_sold,
    DENSE_RANK() OVER(ORDER BY SUM(o.quantity) DESC) AS sales_rank
FROM orders o
JOIN books b
ON o.book_id = b.book_id
GROUP BY b.title;


--20. Rank customers based on total spending.

SELECT c.name , 
	SUM(o.total_amount) AS total_spent ,
	DENSE_RANK() OVER(ORDER BY SUM(o.total_amount) DESC) AS customer_rank
FROM orders AS o 
JOIN customers AS c 
ON o.customer_id = c.customer_id 
GROUP BY c.name;


--21. Rank books within each genre based on price

SELECT 
    title, genre, price,
	DENSE_RANK() OVER(PARTITION BY genre ORDER BY price DESC) AS price_rank
FROM books;


--22. Retrieve the top 5 best-selling books based on quantity sold

SELECT * FROM ( SELECT b.title,
        SUM(o.quantity) AS total_books_sold,
		DENSE_RANK() OVER(ORDER BY SUM(o.quantity) DESC) AS sales_rank 
FROM orders o
JOIN books b
ON o.book_id = b.book_id
GROUP BY b.title
) ranked_books
WHERE sales_rank <= 5;


--23. Categorize customers based on total spending

SELECT c.name,SUM(o.total_amount) AS total_spent,
	CASE
        WHEN SUM(o.total_amount) > 150 THEN 'Premium Customer'
		WHEN SUM(o.total_amount) BETWEEN 80 AND 150 THEN 'Regular Customer'
		ELSE 'Basic Customer'
    END AS customer_category
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id

GROUP BY c.name;


--24. Calculate cumulative revenue over time

SELECT 
    order_date,
    SUM(total_amount) AS daily_revenue,
	SUM(SUM(total_amount)) OVER(ORDER BY order_date) AS running_revenue
FROM orders
GROUP BY order_date
ORDER BY order_date;


--25. Analyze monthly sales trend

SELECT 
    DATE_TRUNC('month', order_date) AS month,
    SUM(total_amount) AS monthly_revenue,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;


SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name IN ('books', 'customers', 'orders')
ORDER BY table_name, ordinal_position;