/* Create a database and name it Hospitality */

CREATE DATABASE Hospitality;

USE Hospitality;


/* See if the tables are imported correctly */

SELECT *
FROM aggregated_bookings;


SELECT *
FROM bookings;


SELECT *
FROM [date];


SELECT *
FROM hotels;


SELECT *
FROM rooms;


/* Check for Null values in each table */

SELECT *
FROM [dbo].[aggregated_bookings]
WHERE 
	 [hotel_id] IS NULL
  OR [check_in_date] IS NULL
  OR [room_category] IS NULL
  OR [successful_bookings] IS NULL
  OR [capacity] IS NULL
  OR [occupancy_percentage] IS NULL;

SELECT *
FROM [dbo].[bookings]
WHERE 
	 [booking_id] IS NULL
  OR [hotel_id] IS NULL
  OR [booking_date] IS NULL
  OR [check_in_date] IS NULL
  OR [checkout_date] IS NULL
  OR [no_guests] IS NULL
  OR [room_category] IS NULL
  OR [booking_platform] IS NULL
  OR [ratings_given] IS NULL
  OR [booking_status] IS NULL
  OR [revenue_generated] IS NULL
  OR [revenue_realized] IS NULL;


SELECT *
FROM [dbo].[date]
WHERE 
	 [date] IS NULL
  OR [month_year] IS NULL
  OR [week_number] IS NULL
  OR [day_type] IS NULL;


SELECT *
FROM [dbo].[hotels]
WHERE 
	 [hotel_id] IS NULL
  OR [hotel_name] IS NULL
  OR [hotel_category] IS NULL
  OR [city] IS NULL;


SELECT *
FROM  [dbo].[rooms]
WHERE 
	   [room_id] IS NULL
    OR [room_class] IS NULL;


/* Check how many Null values are there(if any) */

SELECT SUM(CASE
               WHEN [ratings_given] IS NULL THEN 1
               ELSE 0
           END) AS hotel_id_nulls
FROM [dbo].[bookings];

/* Changing the week_number and day_type columns */


ALTER TABLE [dbo].[date]
DROP COLUMN [day_type],
            [week_number];   


ALTER TABLE [dbo].[date] ADD [week_number] int;


UPDATE [dbo].[date]
SET [week_number] = DATEPART(WEEK, [date]);


SELECT week_number
FROM [dbo].[date];


ALTER TABLE [dbo].[date] ADD day_type varchar(10);


UPDATE [dbo].[date]
SET day_type = CASE
                   WHEN DATEPART(dw, date) IN (6,
                                               7) THEN 'Weekend'
                   ELSE 'Weekday'
               END;


SELECT *
FROM [dbo].[date];

/* Week 32 has only 1 day. It could be harmful for the analysis. Dropping it. */

DELETE FROM [date]
WHERE week_number = 32



-- Total Revenue

SELECT SUM(revenue_realized) AS Revenue
FROM bookings;


-- ADR

SELECT SUM(revenue_realized)/COUNT(booking_id) AS ADR
FROM bookings;


-- Occupancy Rate

SELECT AVG(occupancy_percentage) AS[Occupancy Rate]
FROM aggregated_bookings;



-- RevPAR

SELECT SUM(CAST(revenue_realized AS decimal))/SUM(CAST(capacity AS decimal)) AS RevPAR
FROM aggregated_bookings ab
JOIN bookings b ON ab.hotel_id = b.hotel_id;


-- Cancellation Rate

SELECT CAST(COUNT(CASE
                      WHEN [booking_status] = 'cancelled' THEN booking_id
                  END) AS float) / count(booking_id) AS Cancellation_Rate
FROM bookings;


-- No-Show Rate

SELECT CAST(COUNT(CASE
                      WHEN [booking_status] = 'no show' THEN booking_id
                  END) AS float) / count(booking_id) AS No_Show_Rate
FROM bookings;


--Average Rating.

SELECT AVG(ratings_given) AS average_rating
FROM bookings;


/* Which hotels have the highest and lowest occupancy rates? */

SELECT 
      h.hotel_id
     ,h.hotel_name 
     ,AVG(ab.occupancy_percentage) AS [Occupancy_Rate]
FROM  
     aggregated_bookings ab
JOIN bookings b ON ab.hotel_id = b.hotel_id
JOIN hotels h ON ab.hotel_id = h.hotel_id AND b.hotel_id = h.hotel_id
GROUP BY 
      h.hotel_id
     ,h.hotel_name
ORDER BY 
     Occupancy_Rate DESC;



/* Which cities make the most and least money from hotels, and which ones have the most and least guests? */


SELECT 
      h.city AS City
     ,SUM(b.no_guests) AS [Guest Count]
     ,SUM(b.revenue_realized) AS Revenue
FROM 
     bookings b
JOIN hotels h ON h.hotel_id = b.hotel_id
GROUP BY h.city
ORDER BY 
	  3 DESC
	 ,2 DESC; 


/* What are the most popular types of rooms, booking platforms, and check-in dates for hotel guests? */

SELECT 
     r.room_class AS [Room Type]
    ,b.booking_platform AS [Booking Platform]
    ,b.check_in_date AS [Check-in Date]
	,SUM(b.no_guests) AS [Guests]
FROM 
    bookings b
join rooms r on b.room_category = r.room_id 
GROUP BY 
     r.room_class
    ,b.booking_platform 
    ,b.check_in_date
ORDER BY 
    SUM(b.no_guests) DESC;



/* How do different types of hotels (business, luxury) perform in terms of revenue and occupancy rates? */

SELECT 
      h.hotel_category AS [Hotel Type]
     ,SUM(CAST(b.revenue_realized AS BIGINT)) as Revenue  -- to remove the arithmatic overflow error
     ,AVG(ab.occupancy_percentage) AS [Occupancy_Rate]
FROM 
     hotels h
JOIN bookings b ON b.hotel_id = h.hotel_id
JOIN aggregated_bookings ab ON ab.hotel_id = h.hotel_id AND b.hotel_id = ab.hotel_id
GROUP BY 
     h.hotel_category
ORDER BY 
      2 DESC
	 ,3 DESC;


/* How does the usage of different types of rooms and their capacity affect revenue and occupancy rates? */

SELECT 
     r.room_class AS [Room Types]
     ,SUM(ab.capacity) AS Capacity
     ,SUM(CAST(b.revenue_realized AS BIGINT)) AS Revenue
     ,AVG(ab.occupancy_percentage) AS [Occupancy_Rate]
FROM 
     rooms r
JOIN bookings b ON b.room_category = r.room_id
JOIN aggregated_bookings ab ON ab.room_category = r.room_id AND b.hotel_id = ab.hotel_id
GROUP BY 
     r.room_class
ORDER BY 
     2 DESC, 3 DESC, 4 DESC;


/* Which types of rooms generate the most and least revenue for each hotel? */

SELECT 
	 h.hotel_name
	,r.room_class AS [Room Type]
	,SUM(b.revenue_realized) AS Revenue	
FROM 
	 rooms r
JOIN bookings b ON b.room_category = r.room_id
JOIN hotels h ON h.hotel_id = b.hotel_id
GROUP BY 
	 h.hotel_name
	,r.room_class
ORDER BY 3;


/* Which booking platform is most commonly used for each type of room in each city? */

SELECT 
      b.booking_platform AS [Booking Platform]
     ,r.room_class AS [Room Type]
     ,h.city AS City
     ,COUNT(*) 
FROM 
     bookings b 
JOIN rooms r ON b.room_category = r.room_id
JOIN hotels h ON b.hotel_id = h.hotel_id
GROUP BY 
      b.booking_platform
     ,r.room_class
     ,h.city
ORDER BY 
     COUNT(*) DESC;


/* How does the booking platform used affect the average daily rate (ADR) of a hotel room? */

SELECT 
     booking_platform AS [Booking Platform]
    ,SUM(revenue_realized) / COUNT(booking_id) AS ADR
FROM 
    bookings
GROUP BY booking_platform
ORDER BY ADR DESC;


/* Which months of the year have the most and least bookings for each hotel? */

SELECT 
     h.hotel_name
    ,MONTH(b.booking_date) AS [Month]
	,YEAR(b.booking_date) AS [Year]
	,COUNT(b.booking_id) AS [Total Bookings]
FROM 
     hotels h
JOIN bookings b ON h.hotel_id = b.hotel_id
GROUP BY 
	 h.hotel_name
	,MONTH(b.booking_date)
	,YEAR(b.booking_date)
ORDER BY 
	4 DESC;


/* What is the average length of stay for each type of room, and how does this affect revenue generation? */

SELECT 
     r.room_class as [Room Type]
    ,AVG(DATEDIFF(day, b.check_in_date, b.checkout_date)) AS [Average Length of Stay]
    ,SUM(CAST(b.revenue_realized AS BIGINT)) AS [Total Revenue]
FROM 
     rooms r
JOIN bookings b ON b.room_category = r.room_id
GROUP BY 
     r.room_class
ORDER BY 
     2 DESC, 3 DESC;



/* Which hotels get the best and worst ratings during the given period of time? */

SELECT 
	 h.hotel_name AS [Hotel Name]
    ,AVG(b.ratings_given) AS [Average Ratings]
FROM 
     hotels h
JOIN bookings b ON h.hotel_id = b.hotel_id
GROUP BY h.hotel_name
ORDER BY 2 DESC;



/* Which booking platform has the highest percentage of cancellations? */

SELECT 
    booking_platform,
    CAST(COUNT(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE NULL END) AS FLOAT) / COUNT(booking_date) * 100 AS [Cancellation Percentage]
FROM 
    bookings
GROUP BY 
    booking_platform
ORDER BY 2 DESC;



/* Are there any connections between the rates of cancellations or no-shows and the revenue and occupancy rates of hotels? */

SELECT 
      h.hotel_name
     ,CAST(COUNT(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE NULL END) AS FLOAT) / COUNT(booking_date) * 100 AS [Cancellation Rate]
     ,CASt(COUNT(CASE WHEN booking_status = 'no show' THEN 1 ELSE NULL END) AS FLOAT) / COUNT(booking_date) * 100AS [No-Show Rate]
     ,SUM(CAST(b.revenue_realized AS BIGINT)) AS [Revenue]
     ,AVG(ab.occupancy_percentage) AS [Occupancy_Rate]
FROM 
     hotels h 
JOIN bookings b ON h.hotel_id = b.hotel_id
JOIN aggregated_bookings ab ON h.hotel_id = ab.hotel_id
GROUP BY h.hotel_name
ORDER BY  
      [Revenue] DESC
     ,[Cancellation Rate] DESC
     ,[No-Show Rate] DESC
     ,[Occupancy_Rate] DESC;


/* Is there a connection between hotel ratings and revenue generated per available room (RevPAR)? */

SELECT 
      h.hotel_name as [Hotel Name]
     ,AVG(b.ratings_given) AS [Hotel Rating]
     ,SUM(CAST(b.revenue_realized AS decimal))/SUM(CAST(ab.capacity AS decimal)) AS RevPAR
FROM 
     hotels h 
JOIN bookings b ON h.hotel_id = b.hotel_id
JOIN aggregated_bookings ab ON h.hotel_id = ab.hotel_id AND b.hotel_id = ab.hotel_id
GROUP BY h.hotel_name
ORDER BY 
      [Hotel Rating] DESC
     ,RevPAR DESC;



/* What is the cancellation rate for each booking platform for each hotel in each city? */

-- cancellation rate for each booking platform

SELECT
      b.booking_platform AS [Booking Platform]
     ,CAST(COUNT(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE NULL END) AS FLOAT) / COUNT(booking_date) * 100 AS [Cancellation Rate]
FROM
     hotels h 
Left JOIN bookings b ON h.hotel_id = b.hotel_id
GROUP BY 
      b.booking_platform
ORDER BY [Cancellation Rate] DESC;


-- cancellation rate for each hotel and city

SELECT
      h.hotel_name AS [Hotel Name]
     ,h.city AS City
     ,CAST(COUNT(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE NULL END) AS FLOAT) / COUNT(booking_date) * 100 AS [Cancellation Rate]
FROM
     hotels h 
Left JOIN bookings b ON h.hotel_id = b.hotel_id
GROUP BY 
      h.hotel_name
     ,City    
ORDER BY [Cancellation Rate] DESC;


-- cancellation rate for each booking platform for each hotel in each city

SELECT
      b.booking_platform AS [Booking Platform]
     ,h.hotel_id AS [Hotel Id]
     ,h.hotel_name AS [Hotel Name]
     ,h.city AS City
     ,CAST(COUNT(CASE WHEN booking_status = 'cancelled' THEN 1 ELSE NULL END) AS FLOAT) / COUNT(booking_date) * 100 AS [Cancellation Rate]
FROM
     hotels h 
Left JOIN bookings b ON h.hotel_id = b.hotel_id
GROUP BY 
      b.booking_platform
      ,h.hotel_id
     ,h.hotel_name
     ,City    
ORDER BY [Cancellation Rate] DESC;


/* What is the average rating for each type of room in each hotel? */

SELECT 
      h.hotel_name AS [Hotel Name]
     ,r.room_class AS [Room Type]
     ,AVG(ratings_given) AS [Average Rating]
FROM 
     hotels h 
JOIN bookings b ON h.hotel_id = b.hotel_id
JOIN rooms r    ON r.room_id = b.room_category
GROUP BY 
      h.hotel_name
     ,r.room_class
ORDER BY [Average Rating] DESC;



/* How does the average daily rate vary by room type and hotel category? */

SELECT 
      h.hotel_category AS [Hotel Category]
     ,r.room_class AS [Room Type]
     ,SUM(b.revenue_realized) / COUNT(b.booking_id) AS ADR
FROM
     rooms r 
JOIN bookings b ON r.room_id = b.room_category
JOIN hotels h ON b.hotel_id = h.hotel_id
GROUP BY 
      r.room_class
     ,h.hotel_category
ORDER BY ADR DESC;



/* What is the average number of guests per booking, and how does this vary by hotel type and room class? */

SELECT 
      h.hotel_category AS [Hotel Type]
     ,r.room_class AS [Room Class]
     ,AVG(b.no_guests) AS [Average Guests per Booking]
     
FROM bookings b 
JOIN hotels h ON b.hotel_id = h.hotel_id
JOIN rooms r  ON b.room_category = r.room_id
GROUP BY
      r.room_class
     ,h.hotel_category
ORDER BY [Average Guests per Booking] DESC;





/* How does the percentage of successful bookings vary by room type? */

SELECT 
      r.room_class AS [Room Type]
     ,CAST(COUNT(CASE WHEN b.booking_status = 'checked out' THEN 1 ELSE NULL END) AS FLOAT) / COUNT(b.booking_date) * 100 AS [Successful Booking Percentage]
FROM
     rooms r 
JOIN bookings b ON r.room_id = b.room_category
GROUP BY r.room_class
ORDER BY [Successful Booking Percentage] DESC;



/* Which city has the highest and lowest average revenue per available room (RevPAR)? */

SELECT 
      h.city AS City
     ,SUM(CAST(b.revenue_realized AS decimal))/SUM(CAST(ab.capacity AS decimal)) AS RevPAR
FROM 
     hotels h 
JOIN bookings b ON h.hotel_id = b.hotel_id
JOIN aggregated_bookings ab ON h.hotel_id = ab.hotel_id
GROUP BY h.city
ORDER BY RevPAR DESC;



/* How does the percentage of successful bookings vary by booking platform? */

SELECT 
      booking_platform AS [Booking Platform]
     ,CAST(COUNT(CASE WHEN booking_status = 'checked out' THEN 1 ELSE NULL END) AS FLOAT) / COUNT(booking_date) * 100 AS [Successful Booking Percentage]
FROM
     bookings
GROUP BY booking_platform
ORDER BY [Successful Booking Percentage] DESC;



/* Which day of the week has the highest occupancy rate for each type of room in each hotel? */


SELECT 
   hotel_name AS [Hotel Name] 
  ,room_class AS [Room Type]
  ,day_of_week AS [Day of Week] 
  ,day_type AS [Day Type] 
  ,occupancy_rate AS [Occupancy Rate] 
FROM 
  (
    -- This subquery calculates the occupancy rate for each hotel, room class, day of week, and day type,
    -- and assigns a row number to each row within each group of hotel and room class based on the occupancy rate.
    SELECT 
      hotel_name
      ,room_class 
      ,day_of_week
      ,day_type 
      ,occupancy_rate
      ,ROW_NUMBER() OVER (PARTITION BY hotel_name, room_class ORDER BY occupancy_rate DESC) AS rn 
    FROM 
      (
        -- This subquery joins the aggregated_bookings, rooms, hotels, and date tables to retrieve the hotel name, 
        -- room class, day of week, day type, and average occupancy percentage for each day of the week and day type
        -- for each hotel and room class.
        SELECT 
          h.hotel_name
          ,r.room_class
          ,DATENAME(WEEKDAY, ab.check_in_date) AS day_of_week 
          ,d.day_type 
          ,AVG(ab.occupancy_percentage) AS occupancy_rate 
        FROM 
          aggregated_bookings ab 
          JOIN rooms r ON ab.room_category = r.room_id 
          JOIN hotels h ON ab.hotel_id = h.hotel_id 
          JOIN [date] d ON d.[date] = ab.check_in_date 
        GROUP BY 
           h.hotel_name 
          ,r.room_class 
          ,DATENAME(WEEKDAY, ab.check_in_date)
          ,d.day_type
      ) AS subquery
  ) AS subquery2 -- This outer query filters the results to return only the row with the highest occupancy rate for each hotel and room class.
WHERE 
  rn = 1 -- This outer query orders the results by occupancy rate in descending order.
ORDER BY 
  occupancy_rate DESC;



/* Getting the data for Visualization*/
-- Creating a New Table

CREATE TABLE HotelData (
   hotel_id INT,
   hotel_name VARCHAR(255),
   hotel_category VARCHAR(255),
   city VARCHAR(255),
   room_id VARCHAR(255),
   room_category VARCHAR(255),
   booking_id VARCHAR(255),
   booking_platform VARCHAR(255),
   booking_status VARCHAR(255),
   check_in_date DATE,
   checkout_date DATE,
   stay_duration INT,
   no_guests INT,
   ratings_given INT,
   successful_bookings INT,
   capacity INT,
   revenue_realized DECIMAL(10, 2),
   date DATE,
   week_number INT,
   day_type VARCHAR(255),
   month_year NVARCHAR(255)
);


-- Inserting the data we need for visualization

INSERT INTO HotelData
SELECT 
   a.hotel_id, 
   h.hotel_name,
   h.hotel_category, 
   h.city, 
   a.room_category AS room_id,
   r.room_class As room_category,
   b.booking_id,
   b.booking_platform,
   b.booking_status,
   b.check_in_date,
   b.checkout_date,
   DATEDIFF(DAY,b.check_in_date, b.checkout_date)+1 AS stay_duration,
   b.no_guests,
   b.ratings_given,
   a.successful_bookings, 
   a.capacity, 
   b.revenue_realized, 
   d.date,
   d.week_number,
   d.day_type,
   d.month_year
FROM 
   Aggregated_Bookings a
   JOIN Hotels h ON a.hotel_id = h.hotel_id
   JOIN Bookings b ON a.hotel_id = b.hotel_id AND a.room_category = b.room_category AND a.check_in_date = b.check_in_date
   JOIN Date d ON b.booking_date = d.date
   JOIN rooms r ON a.room_category = r.room_id;



-- Remove duplicate rows

DELETE FROM HotelData 
WHERE booking_id IN (
    SELECT booking_id
    FROM HotelData 
    GROUP BY booking_id
    HAVING COUNT(*) > 1
)
AND hotel_id NOT IN (
    SELECT MIN(hotel_id)
    FROM HotelData 
    GROUP BY booking_id
    HAVING COUNT(*) > 1
);


/* Clean the data */
-- Remove null values

DELETE FROM HotelData
WHERE hotel_id IS NULL 
OR hotel_name IS NULL 
OR hotel_category IS NULL 
OR city IS NULL 
OR room_id IS NULL 
OR room_category IS NULL 
OR booking_id IS NULL 
OR booking_platform IS NULL 
OR booking_status IS NULL 
OR check_in_date IS NULL 
OR checkout_date IS NULL 
OR stay_duration IS NULL
OR no_guests IS NULL 
OR successful_bookings IS NULL 
OR capacity IS NULL 
OR revenue_realized IS NULL 
OR date IS NULL
OR week_number IS NULL
OR day_type IS NULL
OR month_year IS NULL;


-- Check if the checkout date is smaller than check in date

SELECT * FROM HotelData
WHERE checkout_date < check_in_date;

-- Check if the number of guests is lesser than 0

SELECT * FROM HotelData
WHERE no_guests < 0;


-- Check if the capacity is lesser than 0

SELECT * FROM HotelData
WHERE capacity < 0;

-- Check if the successful_bookings is lesser than 0

SELECT * FROM HotelData
WHERE successful_bookings < 0;

-- Check if the revenue_realized is lesser than 0

SELECT * FROM HotelData
WHERE revenue_realized < 0;


/* Query to import the data into POWER BI */

SELECT * FROM HotelData;


