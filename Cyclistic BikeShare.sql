

--Cyclistic Bikeshare Data Cleaning, Manipulation & Analysis

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 1.Data Cleaning and Manipulation

-- Combining last twelve months data into new single table 

-- Creating new table with required columns only. I am skipping station Ids, longitude and latitude columns as I won't be needing them for now.

Drop table if exists combinied_data
create table combinied_data
(ride_id nvarchar(50),
rideable_type nvarchar(50),
started_at datetime2(7),
ended_at datetime2(7),
start_station_name nvarchar(max),
end_station_name nvarchar(max),
member_casual nvarchar (50)
)

-- Combining and inserting data into newly created table
Insert Into combinied_data
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from August22
UNION ALL
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from September22
UNION ALL
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from October22
UNION ALL
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from November22
UNION ALL
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from December22
UNION ALL
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from January23
UNION ALL
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from February23
UNION ALL
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from March23
UNION ALL
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from April23
UNION ALL
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from May23
UNION ALL
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from June23
UNION ALL
select ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual
from July23

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Spelling errors or multiple names

-- Checking if spelling errors or multiple names exist for 'member' and 'casual'
 select count(distinct(member_casual)), member_casual
 from combinied_data
 group by member_casual
-- no multiple names or spelling errors  found.

--Checking if spelling errors or multiple names exist for bike types (rideable_type)
 select count(distinct(rideable_type)), rideable_type
 from combinied_data
 group by rideable_type
-- no multiple names or spelling errors found.

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Null values

select *
from combinied_data
where ride_id is Null or rideable_type is Null or started_at is Null or ended_at is Null or
      start_station_name is Null or end_station_name is Null or member_casual is Null

/* 1,382,918 rows found with null values and all null values are belonging to columns start_station_name and end_station_name. 
   Right now I am keeping all the rows with null values as it is.
*/

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Duplicates

-- Checking for duplicate ride_id
select count(ride_id), ride_id
from combinied_data
group by ride_id
having count(ride_id) >1
-- No duplicate ride_id found

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Adding extra column

--Adding column trip_duration which is difference between start time and end time and indicates total time to complete the ride in minutes.

Alter Table combinied_data
Add trip_duration int;

Update combinied_data
Set trip_duration = DATEDIFF(minute, started_at,ended_at)

-- checking the update with added column
select TOP 10
ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual, trip_duration
from combinied_data
-- success :)

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 2. Analysis
/*
As per data source, if ride has trip duration less than 1 min then it is either false start or users trying to re-dock a bike to ensure it was secure.
Therefore for analysis I am going to skip rides having trip duration less than 1 min
*/

-- Number of rides

-- Total rides
select  count(distinct(ride_id)) as total_rides
from combinied_data
where trip_duration >= 1

-- Total member rides
select  count(distinct(ride_id)) as member_rides
from combinied_data
where trip_duration >= 1 and member_casual = 'member'

-- Total Casual rides
select  count(distinct(ride_id)) as casual_rides
from combinied_data
where trip_duration >= 1 and member_casual = 'casual'

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Bike Preferences

-- Using CTE to calculate bike preferences as percent of total members and casuals

-- Member
With Member_biktype (rideable_type, member_count)
as 
(select rideable_type, count(ride_id) as member_count
from combinied_data
where trip_duration >= 1 and member_casual = 'member'
group by rideable_type
)
select rideable_type,
       concat(member_count * 100 / sum(member_count) over(),'%') as member_percent 
	   -- Using 'concat' to concatenate result of the calculation and % sign (if result is 84, then output will be 84%)
from Member_biktype
group by rideable_type, member_count;

-- Casual
With Casual_biketype (rideable_type, casual_count) 
as
(select rideable_type, count(ride_id) as casual_count
from combinied_data
where trip_duration >= 1 and member_casual = 'casual'
group by rideable_type)

select rideable_type,
       concat(casual_count *100 / sum(casual_count) over(), '%') as casual_percent
from Casual_biketype
group by rideable_type, casual_count;

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Rides Per Month

-- Creating and joining two ctes

With member_month as -- creating first cte
(
select  datename(month, started_at) as month, -- Using 'Datename' to extract month and year
        datename(year,started_at) as year, 
		count(ride_id) as member_rides
from combinied_data
where trip_duration >= 1 and member_casual = 'member'
group by datename(month, started_at),
        datename(year,started_at) 
),
casual_month as -- creating second cte
(
select  datename(month, started_at) as month,
        datename(year,started_at) as year,
		count(ride_id) as casual_rides
from combinied_data
where trip_duration >= 1 and member_casual = 'casual'
group by datename(month, started_at),
        datename(year,started_at) 
)
select concat(member_month.month, '/', member_month.year) as month_year, -- using 'concat' to concatenate month & year as month/year (e.g. July/2023)
       member_month.member_rides, casual_month.casual_rides
from member_month join casual_month -- joining above two cte.
          on member_month.month = casual_month.month and member_month.year = casual_month.year
order by 
case concat(member_month.month, '/', member_month.year) -- using 'case statement' to order month_year chronologically in the output.
when 'August/2022' then 1
when 'September/2022' then 2
when 'October/2022' then 3
when 'November/2022' then 4
when 'December/2022' then 5
when 'January/2023' then 6
when 'February/2023' then 7
when 'March/2023' then 8
when 'April/2023' then 9
when 'May/2023' then 10
when 'June/2023' then 11
when 'July/2023' then 12
end


------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Rides per day of week 

-- Creating and joining two ctes

With member_weekday -- creating first cte
as
(
select Datename(weekday, started_at) as weekday, -- Using 'datename' to extract weekday from given datetime.
       count(ride_id) as member_rides
from combinied_data
where trip_duration >= 1 and member_casual = 'member'
group by datename(weekday, started_at)
),
casuals_weekday -- creating second cte
as
(
select datename(weekday,started_at) as weekday, 
       count(ride_id) as casual_rides
from combinied_data
where trip_duration >= 1 and member_casual = 'casual'
group by datename(weekday,started_at)
)
select member_weekday.weekday, member_weekday.member_rides, casuals_weekday.casual_rides
from member_weekday join casuals_weekday -- joining two ctes
                    on member_weekday.weekday = casuals_weekday.weekday
order by
case member_weekday.weekday -- 'case statement' to order names of weekday chronologically
when 'Monday' then 1
when 'Tuesday' then 2
when 'Wednesday' then 3
when 'Thursday' then 4
when 'Friday' then 5
when 'Saturday' then 6
when 'Sunday' then 7
end

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Hourly Demand

-- Creating and joining two ctes


With member_hour -- first cte
as
(
select datename(hour,started_at) as hour, count(ride_id) as member_rides
from combinied_data
where trip_duration >= 1 and member_casual = 'member'
group by datename(hour, started_at)
),
casual_hour as -- second cte
(
select Datename(hour, started_at) as hour, count(ride_id) as casual_rides
from combinied_data
where trip_duration >= 1 and member_casual = 'casual'
group by datename(hour, started_at)
)
select member_hour.hour, -- using case to return hour in 'hh:mm am/pm' format (e.g. if hour is 1 then 1:00 am)
       Case
	   when member_hour.hour = 0 then '12.00 am' 
	   when member_hour.hour = 1 then '1.00 am'
	   when member_hour.hour = 2 then '2.00 am'
	   when member_hour.hour = 3 then '3.00 am'
	   when member_hour.hour = 4 then '4.00 am'
	   when member_hour.hour = 5 then '5.00 am'
	   when member_hour.hour = 6 then '6.00 am'
	   when member_hour.hour = 7 then '7.00 am'
	   when member_hour.hour = 8 then '8.00 am'
	   when member_hour.hour = 9 then '9.00 am'
	   when member_hour.hour = 10 then '10.00 am'
	   when member_hour.hour = 11 then '11.00 am' 
	   when member_hour.hour = 12 then '12.00 pm'
	   when member_hour.hour = 13 then '1.00 pm'
	   when member_hour.hour = 14 then '2.00 pm'
	   when member_hour.hour = 15 then '3.00 pm'
	   when member_hour.hour = 16 then '4.00 pm'
	   when member_hour.hour = 17 then '5.00 pm'
	   when member_hour.hour = 18 then '6.00 pm'
	   when member_hour.hour = 19 then '7.00 pm'
	   when member_hour.hour = 20 then '8.00 pm'
	   when member_hour.hour = 21 then '9.00 pm'
	   when member_hour.hour = 22 then '10.00 pm'
	   when member_hour.hour = 23 then '11.00 pm'
	   end as time,
       concat(member_hour.member_rides * 100 / sum(member_hour.member_rides) over(), '%') as percent_member_rides,
	   -- concatenating percent output with '%' sign 
       concat(casual_hour.casual_rides * 100 / sum(casual_hour.casual_rides) over(), '%') as percent_casual_rides
from member_hour join casual_hour 
                 on member_hour.hour = casual_hour.hour
order by 
 case member_hour.hour -- 'case' to order hours chronologically
 when 0 then 1
 when 1 then 2
 when 2 then 3
 when 3 then 4
 when 4 then 5
 when 5 then 6
 when 6 then 7
 when 7 then 8
 when 8 then 9
 when 9 then 10 
 when 10 then 11
 when 11 then 12
 when 12 then 13
 when 13 then 14
 when 14 then 15
 when 15 then 16
 when 16 then 17
 when 17 then 18
 when 18 then 19
 when 19 then 20 
 when 20 then 21
 when 21 then 22
 when 22 then 23
 when 23 then 24
 end

 -----------------------------------------------------------------------------------------------------------------------------------------------------------
 -- Trip duration 

 -- Average trip duration of last 12 months
select  member_casual, avg(trip_duration) as avg_trip_duration
from combinied_data
where trip_duration >= 1
group by member_casual;

-- Monthly average trip duration by creating and joining two ctes

With mmd as -- first cte
(
select  datename(month, started_at) as month,
        datename(year,started_at) as year,
		avg(trip_duration) as member_duration
from combinied_data
where trip_duration >= 1 and member_casual = 'member'
group by datename(month, started_at),
        datename(year,started_at) 
),
cmd as -- second cte
(
select  datename(month, started_at) as month,
        datename(year,started_at) as year,
		avg(trip_duration) as casual_duration
from combinied_data
where trip_duration >= 1 and member_casual = 'casual'
group by datename(month, started_at),
        datename(year,started_at) 
)
select concat(mmd.month, '/', mmd.year) as month_year,
       mmd.member_duration, cmd.casual_duration
from mmd join cmd -- joining two ctes
          on mmd.month = cmd.month and mmd.year = cmd.year
order by 
case concat(mmd.month, '/', mmd.year) -- 'case statement' to order months chronologically 
when 'August/2022' then 1
when 'September/2022' then 2
when 'October/2022' then 3
when 'November/2022' then 4
when 'December/2022' then 5
when 'January/2023' then 6
when 'February/2023' then 7
when 'March/2023' then 8
when 'April/2023' then 9
when 'May/2023' then 10
when 'June/2023' then 11
when 'July/2023' then 12
end

--Daily average trip duration

With mwd -- first cte
as
(
select Datename(weekday, started_at) as weekday , 
       avg(trip_duration) as member_duration
from combinied_data
where trip_duration >= 1 and member_casual = 'member'
group by datename(weekday, started_at)
),
cwd -- second cte
as
(
select datename(weekday,started_at) as weekday, 
       avg(trip_duration) as casual_duration
from combinied_data
where trip_duration >= 1 and member_casual = 'casual'
group by datename(weekday,started_at)
)
select mwd.weekday, mwd.member_duration, cwd.casual_duration
from mwd join cwd -- joining two ctes
                    on mwd.weekday = cwd.weekday
order by
case mwd.weekday -- 'case statement' to order weekdays chronologically
when 'Monday' then 1
when 'Tuesday' then 2
when 'Wednesday' then 3
when 'Thursday' then 4
when 'Friday' then 5
when 'Saturday' then 6
when 'Sunday' then 7
end

-- Hourly average trip duration

With mhd -- first cte
as
(
select datename(hour,started_at) as hour, 
       avg(trip_duration) as member_duration
from combinied_data
where trip_duration >= 1 and member_casual = 'member'
group by datename(hour, started_at)
),
chd as -- second cte
(
select Datename(hour, started_at) as hour, 
       avg(trip_duration) as casual_duration
from combinied_data
where trip_duration >= 1 and member_casual = 'casual'
group by datename(hour, started_at)
)
select mhd.hour, 
       Case -- case to return hour in 'hh:mm am/pm' format (e.g. if hour is 1 then output is 1:00 am)
	   when mhd.hour = 0 then '12.00 am' 
	   when mhd.hour = 1 then '1.00 am'
	   when mhd.hour = 2 then '2.00 am'
	   when mhd.hour = 3 then '3.00 am'
	   when mhd.hour = 4 then '4.00 am'
	   when mhd.hour = 5 then '5.00 am'
	   when mhd.hour = 6 then '6.00 am'
	   when mhd.hour = 7 then '7.00 am'
	   when mhd.hour = 8 then '8.00 am'
	   when mhd.hour = 9 then '9.00 am'
	   when mhd.hour = 10 then '10.00 am'
	   when mhd.hour = 11 then '11.00 am' 
	   when mhd.hour = 12 then '12.00 pm'
	   when mhd.hour = 13 then '1.00 pm'
	   when mhd.hour = 14 then '2.00 pm'
	   when mhd.hour = 15 then '3.00 pm'
	   when mhd.hour = 16 then '4.00 pm'
	   when mhd.hour = 17 then '5.00 pm'
	   when mhd.hour = 18 then '6.00 pm'
	   when mhd.hour = 19 then '7.00 pm'
	   when mhd.hour = 20 then '8.00 pm'
	   when mhd.hour = 21 then '9.00 pm'
	   when mhd.hour = 22 then '10.00 pm'
	   when mhd.hour = 23 then '11.00 pm'
	   end as time,
       mhd.member_duration, chd.casual_duration
from mhd join chd
                 on mhd.hour = chd.hour
order by 
 case mhd.hour 
 when 0 then 1
 when 1 then 2
 when 2 then 3
 when 3 then 4
 when 4 then 5
 when 5 then 6
 when 6 then 7
 when 7 then 8
 when 8 then 9
 when 9 then 10 
 when 10 then 11
 when 11 then 12
 when 12 then 13
 when 13 then 14
 when 14 then 15
 when 15 then 16
 when 16 then 17
 when 17 then 18
 when 18 then 19
 when 19 then 20 
 when 20 then 21
 when 21 then 22
 when 22 then 23
 when 23 then 24
 end

 -----------------------------------------------------------------------------------------------------------------------------------------------------------

 -- Stations

 /* To analyse stations I am combining last 12 months data in a new table with columns containing latitude and longitude information.
    I did not include 'lat' and 'lng' columns in the first table because it was taking longer times to execute queries with all the columns.
 */

 Drop table if exists stations
 create table stations
(ride_id nvarchar(50),
started_at datetime2(7),
ended_at datetime2(7),
start_station_name nvarchar(max),
end_station_name nvarchar(max),
member_casual nvarchar (50),
start_lat nvarchar(50),
start_lng nvarchar(50),
end_lat nvarchar(50),
end_lng nvarchar(50)
)

Insert Into stations
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from August22
UNION ALL
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from September22
UNION ALL
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from October22
UNION ALL
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from November22
UNION ALL
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from December22
UNION ALL
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from January23
UNION ALL
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from February23
UNION ALL
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from March23
UNION ALL
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from April23
UNION ALL
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from May23
UNION ALL
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from June23
UNION ALL
select ride_id, started_at, ended_at, start_station_name, end_station_name, member_casual, start_lat, start_lng, end_lat, end_lng
from July23

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Null values for latitude and longitude

/* I am carring out cleaning steps for null values on latitude and longitude columns only as I have already done 
   that on rest of the columns in first table.
*/

select *
from stations
where start_lat is Null or start_lng is Null or end_lat is Null or end_lng is Null

/* 6,102 rows with null values found and all the null values belong to end_station_name, end_lat and end_lng. 
   For now I am keeping rows with null values as it is.
*/
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Checking for duplicate ride_id
select count(ride_id), ride_id
from stations
group by ride_id
having count(ride_id) >1
-- No duplicate ride_id found

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Top 10 start stations of member
 select top 10
       start_station_name as top_start_stations_member,
       count(start_station_name) as counts,
	   cast(start_lat as float) as latitude, cast(start_lng as float) as longitude
from stations
where member_casual = 'member' and end_station_name is not null and
      DATEDIFF(minute, started_at, ended_at) >= 1
group by start_station_name, cast(start_lat as float), cast(start_lng as float)	  
order by counts desc


 -- Top 10 end stations of member
 select top 10
       end_station_name as top_end_stations_member,
       count(end_station_name) as counts,
	   cast(end_lat as float) as latitude, cast(end_lng as float) as longitude
from stations
where member_casual = 'member' and end_station_name is not null and end_lat is not null and end_lng is not null and
      DATEDIFF(minute, started_at, ended_at) >= 1
group by end_station_name, cast(end_lat as float), cast(end_lng as float)	  
order by counts desc


-- top 10 start stations of casuals
 select top 10
       start_station_name as top_start_stations_casual,
       count(start_station_name) as counts,
	   cast(start_lat as float) as latitude, cast(start_lng as float) as longitude
from stations
where member_casual = 'casual' and end_station_name is not null and 
      DATEDIFF(minute, started_at, ended_at) >= 1
group by start_station_name, cast(start_lat as float), cast(start_lng as float)	  
order by counts desc


-- Top 10 end stations of casuals
 select top 10
       end_station_name as top_end_stations_casual,
       count(end_station_name) as counts,
	   cast(end_lat as float) as latitude, cast(end_lng as float) as longitude
from stations
where member_casual = 'casual' and end_station_name is not null and end_lat is not null and end_lng is not null and
      DATEDIFF(minute, started_at, ended_at) >= 1
group by end_station_name, cast(end_lat as float), cast(end_lng as float)	  
order by counts desc

------------------------------------------------------------------------------------------------------------------------------------------------------------

