CREATE database music_store;

use music_store;

SELECT * FROM album2;

SELECT * FROM artist;

SELECT * FROM customer;

SELECT * FROM employee;

SELECT * FROM genre;

SELECT * FROM invoice_line;

SELECT * FROM media_type;

SELECT * FROM playlist;

SELECT * FROM playlist_track;

SELECT * FROM track;

-- 1. Who is the senior most employee based on job title?
-- According to the hire_date 
SELECT min(hire_date) as joinning_date ,title, first_name,last_name 
FROM employee 
GROUP BY title
ORDER BY joinning_date DESC
LIMIT 1;

-- According to date of birth
SELECT min(birthdate)  AS date_of_birth ,title, first_name,last_name
FROM employee
GROUP BY title
ORDER BY date_of_birth DESC;

-- According to level present in the employee table
SELECT title, first_name,last_name
FROM employee
ORDER BY levels DESC
LIMIT 1;

-- 2. Which countries have the most Invoices?
SELECT COUNT(billing_country) AS no_of_invoice ,billing_country FROM invoice
GROUP BY billing_country
ORDER BY no_of_invoice DESC
LIMIT 1;

-- 3. What are top 3 values of total invoice?
-- Simple using the distinct and order by
SELECT distinct(total)
FROM invoice
ORDER BY total DESC
LIMIT 3;

-- By using rank and row_number
WITH cte AS 
(SELECT total,DENSE_RANK() OVER(ORDER BY total DESC) AS rn
FROM invoice)
,cte1 AS
(SELECT * , ROW_NUMBER() OVER(PARTITION BY rn ORDER BY rn DESC) AS new_rn FROM cte)
SELECT total FROM cte1 WHERE rn <= 3 AND new_rn = 1;

-- 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
-- Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals 

SELECT billing_city, round(SUM(total),2) as invoice_totals from invoice
group by billing_city 
order by invoice_totals DESC
limit 1;

-- 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
-- Write a query that returns the person who has spent the most money 
SELECT cust.customer_id, first_name, last_name, round(SUM(total),2) AS total_spending
FROM customer cust
JOIN invoice inv ON cust.customer_id = inv.customer_id
GROUP BY (cust.customer_id)
ORDER BY total_spending DESC
LIMIT 1;

-- Phase:2
-- 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
--    Return your list ordered alphabetically by email starting with A :

SELECT DISTINCT email,first_name,last_name,g.name AS Genre_name
FROM customer c
INNER JOIN invoice i ON c.customer_id = i.customer_id
INNER JOIN  invoice_line e ON i.invoice_id = e.invoice_id
INNER JOIN track t ON e.track_id = t.track_id
INNER JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock' AND email LIKE 'a%'
ORDER BY email ;

-- 2. Let's invite the artists who have written the most rock music in our dataset.
--  Write a query that returns the Artist name and total track count of the top 10 rock bands 

SELECT  artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album2 ON album2.album_id = track.album_id
JOIN artist ON artist.artist_id = album2.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;

-- 3. Return all the track names that have a song length longer than the average song length.
--  Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.
SELECT name,milliseconds AS song_length 
FROM track WHERE milliseconds > (SELECT AVG(milliseconds) AS etc FROM track)
ORDER BY milliseconds DESC;

-- By using cte
WITH cte as(
SELECT AVG(milliseconds) AS etc FROM track)
SELECT t.name, t.milliseconds AS song_length FROM track t,cte
WHERE t.milliseconds > etc
ORDER BY song_length DESC; 





-- Phase 3
-- 1. Find how much amount spent by each customer on artists? 
-- Write a query to return customer name, artist name and total spent 
SELECT c.customer_id, c.first_name, c.last_name,r.name ,sum(il.unit_price*il.quantity) as amount
FROM customer c INNER JOIN invoice i ON c.customer_id = i.customer_id
INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
INNER JOIN track t ON il.track_id = t.track_id
INNER JOIN album2 a ON t.album_id = a.album_id
INNER JOIN artist r ON a.artist_id = r.artist_id
GROUP BY c.first_name,r.name,c.last_name
ORDER BY amount DESC;

#By using cte:-
WITH cte  AS (
	SELECT a.artist_id AS artist_id, a.name AS artist_name, round(SUM(il.unit_price*il.quantity),2) AS total_sales
	FROM invoice_line il
	JOIN track t ON t.track_id = il.track_id
	JOIN album2 l ON l.album_id = t.album_id
	JOIN artist a ON a.artist_id = l.artist_id
	GROUP BY a.artist_id
	ORDER BY total_sales DESC
	
)
SELECT c.first_name, c.last_name, cte.artist_name, round(SUM(il.unit_price*il.quantity),2) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album2 l ON l.album_id = t.album_id
JOIN cte  ON cte.artist_id = l.artist_id
GROUP BY c.first_name, c.last_name, cte.artist_name
ORDER BY amount_spent DESC;

-- 2. We want to find out the most popular music Genre for each country. 
-- We determine the most popular genre as the genre with the highest amount of purchases.
-- Write a query that returns each country along with the top Genre. 
-- For countries where the maximum number of purchases is shared return all Genres

WITH cte AS
(SELECT count(il.quantity) AS purches, c.country,g.name AS genre_name,g.genre_id 
FROM invoice_line il
INNER JOIN invoice i ON il.invoice_id = i.invoice_id 
INNER JOIN customer c ON c.customer_id = i.customer_id 
INNER JOIN track t ON t.track_id = il.track_id 
INNER JOIN genre g ON g.genre_id  = t.genre_id
GROUP BY c.country,g.name,g.genre_id
ORDER BY purches DESC,country ASC)
,cte1 AS
(SELECT *,DENSE_RANK() OVER(PARTITION BY country ORDER BY purches DESC) AS rn FROM cte)
SELECT * FROM cte1 WHERE rn = 1;

-- 3. Write a query that determines the customer that has spent the most on music for each country.
--  Write a query that returns the country along with the top customer and how much they spent.
--  For countries where the top amount spent is shared, provide all customers who spent this amount.
WITH cte AS 
(SELECT c.customer_id,c.first_name,c.last_name,billing_country ,sum(total) AS total
FROM invoice i INNER JOIN customer c ON c.customer_id = i.customer_id
GROUP BY c.customer_id,c.first_name,c.last_name,billing_country
ORDER BY billing_country)
,cte1 AS
(SELECT * , DENSE_RANK() OVER(PARTITION BY billing_country ORDER BY total DESC) AS rn FROM cte)
SELECT * FROM cte1 WHERE rn = 1;






