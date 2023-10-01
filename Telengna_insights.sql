/**** Code basic challenge 7 ****/

/**** Analysis Growth and present Insght to the Telngna Govt. ****/

SELECT * FROM dim_date;
SELECT * FROM dim_dist;
SELECT * FROM fact_stamps;
SELECT * FROM fact_transport;
SELECT * FROM fact_ts_ipass;

                     /*************          Stamp Registration         **************/
/**** How does the revenue generated from the document registration very across the districts in Telangana?
List down the top 5 districts that showed the highest document registration revenue growth between FY 2019 
and 2022.****/

select stamp.dist_code,d.Fiscal_year,
	   round(sum(stamp.Document_no),2) as Total_document,
       round(sum(stamp.Document_rev),2) as Total_rev,
       dist.district,
       round((sum(stamp.Document_rev) - lag(sum(stamp.Document_rev)) over(partition by dist_code,district order by Fiscal_year))
       /lag(sum(stamp.Document_rev)) over(partition by dist_code,district order by Fiscal_year)*100,2) as revenue_growth
from fact_stamps as stamp
join dim_dist as dist 
using (dist_code)
join dim_date as d
on d.Month = stamp.Month
where Fiscal_year between '2019' and '2022'
group by dist_code,district,fiscal_year
HAVING
    SUM(stamp.Document_no) <> 0 OR SUM(stamp.Document_rev) <> 0
order by revenue_growth desc
limit 5;


select stamp.dist_code,
       dist.district,
       dim_date.Fiscal_year,
       round((sum(stamp.Document_rev) - lag(sum(stamp.Document_rev)) over(partition by dist_code,district order by Fiscal_year))
       /lag(sum(stamp.Document_rev)) over(partition by dist_code,district order by Fiscal_year)*100,2) as revenue_growth 
from fact_stamps as stamp
join dim_dist as dist
using (dist_code)
join dim_date 
on dim_date.Month = stamp.Month
where dist_code = '17_2'
group by dist_code,district,Fiscal_year;

/****  How does the revenue generated from document registration compare to the revenue generated 
from e-stamp challans across districts? List down the top 5 districts where e-stamps revenue contributes 
significantly more to the revenue than the documents in FY 2022?****/
  
with compare as(
select 
      stamp.dist_code,
      dist.district,
      date.fiscal_year,
      avg(stamp.Document_rev) as doc_rev,
      avg(stamp.estamps_challans_rev) as estamps_rev
from fact_stamps as stamp
join dim_dist as dist
using(dist_code)
join dim_date date
on date.Month = stamp.Month
group by dist_code,district,Fiscal_year
Having 
doc_rev <> 0 and estamps_rev <> 0
)
select *,
       round(((avg(estamps_rev) - avg(doc_rev)) / avg(estamps_rev))*100,2) as pres_diff
       from compare
       where fiscal_year = '2022'
       group by fiscal_year,dist_code,district
       order by pres_diff desc
       limit 5;
       
/**** Is there any alteration of e-Stamp challan count and document registration count pattern 
since the implementation of e-Stamp challan? If so, what suggestions would you propose to the 
government?****/

select dist_code,
       month,
       sum(document_no) as Total_doc,
       sum(estamps_challans_cnt) as estamps_cnt
from fact_stamps
group by dist_code,Month;

select distinct(fiscal_year),
       dist_code,
       district,
       sum(document_no) as Total_doc,
       sum(estamps_challans_cnt) as estamps_cnt
from fact_stamps as stamp
join dim_dist using (dist_code)
join dim_date as date
on date.Month = stamp.Month
group by dist_code,district,Fiscal_year;

/**** Categorize districts into three segments based on their stamp registration revenue generation 
during the fiscal year 2021 to 2022****/

select fact.dist_code,
       dist.district,
       d.fiscal_year,
       sum(fact.estamps_challans_rev) as stamp_rev,  
       case
              when sum(fact.estamps_challans_rev) >= 3000000000 THEN 'HIGH REVENUE'
              when sum(fact.estamps_challans_rev) between 1000000000 and 3000000000 THEN 'MEDIUM REVENUE'
              else 'LOW REVENUE'
		end as stamp_rev_sengments
from fact_stamps as fact
join dim_dist as dist 
using(dist_code)
join dim_date as d 
on d.Month = fact.Month
where Fiscal_year between '2021' and '2022'
group by dist_code,district,Fiscal_year
order by stamp_rev ;



                   /********                   Transportation                ********/

/**** Investigate whether there is any correlation between vehicle sales and specific months or seasons
 in different districts. Are there any months or seasons that consistently show higher or lower sales rate, 
 and if yes, what could be the driving factors? (Consider Fuel-Type category only) ****/
 
SELECT X.DIST_CODE, DISTRICT, MONTH_CHAR, SUM_OF_SALES_BY_FUEL_SEGMENTS,
    TOP_SALES_MONTH,LOW_SALES_MONTH
FROM (
    WITH CTE AS (
        SELECT
            TRANSPORT.DIST_CODE,
            DIST.DISTRICT,
            DATE_FORMAT(MONTH, '%M') AS MONTH_CHAR,
            SUM(FUEL_TYPE_PETROL + FUEL_TYPE_OTHERS + FUEL_TYPE_ELECTRIC + FUEL_TYPE_DIESEL) AS SUM_OF_SALES_BY_FUEL_SEGMENTS
        FROM
            FACT_TRANSPORT as TRANSPORT
        JOIN
            dim_dist as DIST ON TRANSPORT.DIST_CODE = DIST.DIST_CODE
        WHERE
            MONTH BETWEEN '2019-04-01' AND '2023-03-31'
        GROUP BY
            DIST_CODE, MONTH_CHAR, DISTRICT
        ORDER BY
            DIST_CODE
    )
    SELECT
        DIST_CODE,
        DISTRICT,
        MONTH_CHAR,
        SUM_OF_SALES_BY_FUEL_SEGMENTS,
        FIRST_VALUE(MONTH_CHAR) OVER (PARTITION BY DIST_CODE ORDER BY SUM_OF_SALES_BY_FUEL_SEGMENTS DESC) AS TOP_SALES_MONTH,
        LAST_VALUE(MONTH_CHAR) OVER (PARTITION BY DIST_CODE ORDER BY SUM_OF_SALES_BY_FUEL_SEGMENTS DESC
                                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LOW_SALES_MONTH,
        RANK() OVER (PARTITION BY DIST_CODE ORDER BY SUM_OF_SALES_BY_FUEL_SEGMENTS DESC) AS RANK_BY_TOTAL_SALES_OF_FUEL_SEGMENTS
    FROM
        CTE
) X
WHERE X.RANK_BY_TOTAL_SALES_OF_FUEL_SEGMENTS IN (1, 12);

/**** How does the distribution of vehicles vary by vehicle class (MotorCycle, MotorCar, AutoRickshaw,
 Agriculture) across different districts? Are there any districts with a predominant preference for a 
specific vehicle class? Consider FY 2022 for analysis ****/

select Fiscal_year,dist_code,district,
	   sum(vehicleClass_Motorcycles) as Motorcycles,
       sum(vehicleClass_Motorcars) as Motorcars,
       sum(vehicleClass_Auto_rickshaws) as Auto_rickshawas,
       sum(vehicleClass_Agriculture) as Agriculture,
       sum(vehicleClass_Others) as Others
from fact_transport as fact
join dim_dist dist
using(dist_code)
join dim_date as date
on date.Month = fact.Month
where Fiscal_year = 2022
group by dist_code,district,Fiscal_year;

/**** List down the top 3 and bottom 3 districts that have shown the highest and lowest 
vehicle sales growth during FY 2022 compared to FY 2021? 
(Consider and compare categories: Petrol, Diesel and Electric) ****/

select dist_code, district,
       sum(fuel_type_petrol) as petrol_21,
       sum(fuel_type_diesel) as diesel_21,
       sum(fuel_type_electric) as electric_21
from fact_transport as fact 
join dim_dist as dist
using(dist_code)
join dim_date as date
on date.Month = fact.Month
where Fiscal_year = 2021
group by dist_code,district;

select dist_code, district,
       sum(fuel_type_petrol) as petrol_21,
       sum(fuel_type_diesel) as diesel_21,
       sum(fuel_type_electric) as electric_21
from fact_transport as fact 
join dim_dist as dist
using(dist_code)
join dim_date as date
on date.Month = fact.Month
where Fiscal_year = 2022
group by dist_code,district;

select district,
       fy.petrol_21,
       fy2.petrol_22,
       (fy2.petrol_22 - fy.petrol_21) as petrol_21_22,
       fy.diesel_21,
       fy2.diesel_22,
       (fy2.diesel_22 - fy.diesel_21) as diesel_21_22,
       fy.electric_21,
       fy2.electric_22,
       (fy2.electric_22 - fy.electric_21) as electric_21_22
from fy_21 as fy
join fy_22 as fy2
using(district);

SELECT
    district,
    petrol_21_22 AS petrol_difference,
    diesel_21_22 AS diesel_difference,
    electric_21_22 AS electric_difference
FROM
    compre_21_22
ORDER BY
    petrol_21_22 DESC, diesel_21_22 DESC, electric_21_22 DESC
LIMIT 3;

SELECT
    district,
    petrol_21_22 AS petrol_difference,
    diesel_21_22 AS diesel_difference,
    electric_21_22 AS electric_difference
FROM
    compre_21_22
ORDER BY
    petrol_21_22 ASC, diesel_21_22 ASC, electric_21_22 ASC
LIMIT 3;




				/*****                                Ts-Ipass                              *****/ 
           /*****  Telangana State Industrial Project Approval and Self Certification System     *****/
 
 /**** List down the top 5 sectors that have witnessed the most significant investments in FY 2022. *****/
 select 
		Sector,
        round(sum(investment_in_cr),2) as Investment
from fact_ts_ipass as ipass
join dim_date as date
on date.Month = ipass.Month
where Fiscal_year = 2022
group by Sector,Fiscal_year
order by Investment desc
limit 5;

/**** List down the top 3 districts that have attracted the most significant 
sector investments during FY 2019 to 2022? What factors could have 
led to the substantial investments in these particular districts? ****/

select dist.district,sector,
        round(sum(investment_in_cr),2) as Total_Investment
from fact_ts_ipass as ipass
join dim_dist as dist
using (dist_code)
join dim_date as d
on d.Month = ipass.Month
where Fiscal_year between "2019" and "2022"
group by sector,district
order by Total_Investment desc
limit 3;

/**** Is there any relationship between district investments, vehicles sales and stamps revenue 
within the same district between FY 2021 and FY 2022 ****/

with cte as (
select Sector,dist_code,
	   round(sum(investment_in_cr),2) as total_inv,
	   sum(number_of_employes) as employe,
       sum(fuel_type_diesel + fuel_type_electric + fuel_type_others + fuel_type_petrol) as fuel_type,
       sum(vehicleClass_Agriculture + vehicleClass_Auto_rickshaws + vehicleClass_Motorcars + vehicleClass_Motorcycles + vehicleClass_Others) as vechele_class,
       sum(seatCapacity_1_to_3+seatCapacity_4_to_6+seatCapacity_above_6) as seat_capacity,
       sum(Brand_new_vehicles+Pre_owned_vehicles+category_Non_Transport+category_Transport) as others_category
from fact_ts_ipass
join fact_transport
using (dist_code)
group by sector,dist_code
),
cte2 as 
        (select 
                dist_code,
                district,
                sum(Document_rev) as Total_rev,
                sum(estamps_challans_rev) as estamp_rev
        from fact_stamps
        join dim_dist
        using(dist_code)
        group by district,dist_code
)
select
    cte.dist_code,
    cte2.district,
    cte.Sector,
    cte.total_inv,
    cte.employe,
    cte.fuel_type,
    cte.vechele_class,
    cte.seat_capacity,
    cte.others_category,
    cte2.total_rev,
    cte2.estamp_rev
FROM
    cte
JOIN
    cte2
USING (dist_code);

/**** Are there any particular sectors that have shown substantial investment in multiple districts 
between FY 2021 and 2022? ****/

with sector as (
select district,sector,Month,
	   round(sum(investment_in_cr),2) as Total_Investment
from fact_ts_ipass as Ipass
join dim_dist as dist
using(dist_code)
group by sector,district,Month
)
select district,
	   sector,
       Total_Investment,
       rank() over(partition by sector order by Total_Investment desc) as rank_wise_total_investment
from sector
join dim_date as d
on d.Month = sector.Month
where Fiscal_year between "2021" and "2022"
order by Total_investment desc;

/**** Can we identify any seasonal patterns or cyclicality in the investment trends for specific sectors? 
Do certain sectors experience higher investments during particular months? ****/

with cte as (
SELECT SECTOR,
	   date_format(MONTH,'%M') AS MONTH_CHAR,
		round(SUM(investment_in_cr),2) AS TOTAL_INVESTMENTS_IN_CR
FROM fact_ts_ipass
GROUP BY SECTOR,MONTH_CHAR
ORDER BY SECTOR
)
SELECT SECTOR,MONTH_CHAR,TOTAL_INVESTMENTS_IN_CR,
	RANK() OVER (PARTITION BY SECTOR ORDER BY TOTAL_INVESTMENTS_IN_CR DESC) AS RANK_BY_TOTAL_INVESTMENTS_IN_CR
FROM CTE;
