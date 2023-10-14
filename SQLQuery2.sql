------------------------------------------------------------------- STAMP REGESTRATION-------------------------------------------------------------
/* 1.How does the revenue generated from document registration vary across districts in Telangana? List down the top 5 districts that showed 
	the highest document registration revenue growth between FY 2019 and 2022.*/

with cte1 as 
(select dd.district,ddate.fiscal_year,round(sum(fs.documents_registered_rev)/10000000,2) as Total_Document_Registration_Revenue_2019_crores
from tg.dbo.fact_stamps fs
join tg.dbo.dim_districts dd on fs.dist_code=dd.dist_code
join tg.dbo.dim_date ddate on fs.month=ddate.month
where fiscal_year = '2019'
group by dd.district,ddate.fiscal_year
),
cte2 as
(select dd.district,ddate.fiscal_year,round(sum(fs.documents_registered_rev)/10000000,2) as Total_Document_Registration_Revenue_2022_crores
from tg.dbo.fact_stamps fs
join tg.dbo.dim_districts dd on fs.dist_code=dd.dist_code
join tg.dbo.dim_date ddate on fs.month=ddate.month
where fiscal_year = '2022'
group by dd.district,ddate.fiscal_year
)
 
select top 5 cte2.district,cte1.Total_Document_Registration_Revenue_2019_crores,cte2.Total_Document_Registration_Revenue_2022_crores,
	(cte2.Total_Document_Registration_Revenue_2022_crores-cte1.Total_Document_Registration_Revenue_2019_crores) as Revenue_Growth ,
	round((cte2.Total_Document_Registration_Revenue_2022_crores-cte1.Total_Document_Registration_Revenue_2019_crores)/cte1.Total_Document_Registration_Revenue_2019_crores*100,2) 
	as Revenue_growth_pct_FY19_to_FY22
from cte1 join cte2 on cte1.district = cte2.district
order by Revenue_growth_pct_FY19_to_FY22 desc;


/* 2. How does the revenue generated from document registration compare to the revenue generated from e-stamp challans across districts? List 
	down the top 5 districts where e-stamps revenue contributes significantly more to the revenue than the documents in FY 2022?*/


with cte1 as 
(select dd.district,ddate.fiscal_year,round(sum(fs.documents_registered_rev)/10000000,2) as Total_Document_Registration_Revenue_2022_crores
from tg.dbo.fact_stamps fs
join tg.dbo.dim_districts dd on fs.dist_code=dd.dist_code
join tg.dbo.dim_date ddate on fs.month=ddate.month
where fiscal_year = '2022'
group by dd.district,ddate.fiscal_year
),
cte2 as 
(select dd.district,ddate.fiscal_year,round(sum(fs.estamps_challans_rev)/10000000,2) as Total_Estamp_Challans_Revenue_2022_crores
from tg.dbo.fact_stamps fs
join tg.dbo.dim_districts dd on fs.dist_code=dd.dist_code
join tg.dbo.dim_date ddate on fs.month=ddate.month
where fiscal_year = '2022'
group by dd.district,ddate.fiscal_year
)

Select top 5 c2.district,c2.Total_Estamp_Challans_Revenue_2022_crores,c1.Total_Document_Registration_Revenue_2022_crores,
			 round((c2.Total_Estamp_Challans_Revenue_2022_crores-c1.Total_Document_Registration_Revenue_2022_crores),2) as Total_diff_EstampRev_and_DocumentRev
from cte2 c2
join cte1 c1 on c2.district=c1.district
where c2.Total_Estamp_Challans_Revenue_2022_crores>c1.Total_Document_Registration_Revenue_2022_crores
order by (c2.Total_Estamp_Challans_Revenue_2022_crores-c1.Total_Document_Registration_Revenue_2022_crores) desc;


/* 3. Is there any alteration of e-Stamp challan count and document registration count pattern since the implementation of e-Stamp 
	challan? If so, what suggestions would you propose to the government?*/


select dd.district as district,sum(documents_registered_cnt) as Total_Doc_Reg_from_dec_2020,
		round((sum(documents_registered_cnt))/(sum(documents_registered_cnt+estamps_challans_cnt))*100,2) as Doc_Count_pct_of_Total,
		sum(estamps_challans_cnt) as Total_estamp_Reg_from_dec_2020,
		round((sum(estamps_challans_cnt))/(sum(documents_registered_cnt+estamps_challans_cnt))*100,2) as estamp_Count_pct_of_Total,
		round((sum(estamps_challans_cnt)-sum(documents_registered_cnt))/(sum(documents_registered_cnt+estamps_challans_cnt))*100,2) as estamp_doc_reg_diff_pct
from tg.dbo.fact_stamps fs
join tg.dbo.dim_districts dd on fs.dist_code=dd.dist_code
where fs.month >= '2020-12-01'
group by dd.district
order by estamp_Count_pct_of_Total desc;


/* 4. Categorize districts into three segments based on their stamp registration revenue generation during the fiscal year 2021 to 2022.
		
1. **High Revenue Districts**: These are districts that have generated the highest amount of revenue.The top 20% of districts in terms of revenue generation.
2. **Medium Revenue Districts**: These are districts that have generated a moderate amount of revenue. This could be defined as the next 30% of districts in terms of revenue generation.
3. **Low Revenue Districts**: These are districts that have generated the least amount of revenue. This could be defined as the bottom 50% of districts in terms of revenue generation.
*/

with cte1 as 
(select dd.district,round(sum((fs.documents_registered_rev/10000000)+(fs.estamps_challans_rev/10000000)),2) as Total_Stamp_Registration_Revenue_FY20_21_crores
from tg.dbo.fact_stamps fs
	join tg.dbo.dim_districts dd on fs.dist_code=dd.dist_code
	join tg.dbo.dim_date ddate on fs.month=ddate.month
where fiscal_year in ('2021','2022')
group by dd.district
),
cte_rank as
(select *,RANK() OVER(ORDER BY Total_Stamp_Registration_Revenue_FY20_21_crores  DESC) as Revenue_Rank
 from cte1
)
select cte1.district,cte1.Total_Stamp_Registration_Revenue_FY20_21_crores,
    case 
        when Revenue_Rank <= (select count(*) from cte_rank) * 0.2 then 'High Revenue Districts'
        when Revenue_Rank <= (select count(*) from cte_rank) * 0.5 then 'Medium Revenue Districts'
        else 'Low Revenue Districts'
    end as Revenue_Category
from cte1 
	join cte_rank on cte1.district = cte_rank.district
order by 
    cte1.Total_Stamp_Registration_Revenue_FY20_21_crores desc;


------------------------------------------------------------------- Transportation----------------------------------------------------------------------
/* 5. Investigate whether there is any correlation between vehicle sales and specific months or seasons in different districts. Are there any months 
      or seasons that consistently show higher or lower sales rate, and if yes, what could be the driving factors? (Consider Fuel-Type category only)*/


with cte1 as (
	select dd.district,ddate.month,ddate.quarter,sum(fuel_type_petrol+fuel_type_diesel+fuel_type_electric+fuel_type_others) as total_vehicle_sales
	from tg.dbo.fact_transport ft
		join tg.dbo.dim_districts dd on ft.dist_code=dd.dist_code
		join tg.dbo.dim_date ddate on ft.month=ddate.month
	group by dd.district,ddate.month,ddate.quarter
),
cte2 as (
    select district,quarter,avg(total_vehicle_sales) as avg_quarterly_sales,
		   ROW_NUMBER() OVER(PARTITION BY district ORDER BY avg(total_vehicle_sales) DESC) as rn
    from cte1
    group by district,quarter
)
select district,quarter,round(avg_quarterly_sales,0) as Avg_Quarterly_VehicleSales_Count
from cte2
where rn=1
order by district;


/* 6. How does the distribution of vehicles vary by vehicle class (MotorCycle, MotorCar, AutoRickshaw, Agriculture) across different 
	districts? Are there any districts with a predominant preference for a specific vehicle class? Consider FY 2022 for analysis.*/


with cte as (
    select dd.district,sum(vehicleClass_MotorCycle) as MotorCycle,sum(vehicleClass_MotorCar) as MotorCar,sum(vehicleClass_AutoRickshaw) as AutoRickshaw,
           sum(vehicleClass_Agriculture) as Agriculture
    from tg.dbo.fact_transport ft
        join tg.dbo.dim_districts dd on ft.dist_code=dd.dist_code
        join tg.dbo.dim_date ddate on ft.month=ddate.month
    where ddate.fiscal_year = '2022'
    group by dd.district
)
select district,MotorCycle,MotorCar,AutoRickshaw,Agriculture,
    case 
        when MotorCycle >= greatest(MotorCar, AutoRickshaw, Agriculture) then 'MotorCycle'
        when MotorCar >= greatest(MotorCycle, AutoRickshaw, Agriculture) then 'MotorCar'
        when AutoRickshaw >= greatest(MotorCycle, MotorCar, Agriculture) then 'AutoRickshaw'
        else 'Agriculture'
    end as PredominantVehicleClass
from cte;


/* 7. List down the top 3 and bottom 3 districts that have shown the highest and lowest vehicle sales growth during FY 2022 compared to FY 
	  2021? (Consider and compare categories: Petrol, Diesel and Electric)*/

WITH cte1 AS (
    SELECT 
        dd.district,
        ddate.fiscal_year,
        SUM(fuel_type_petrol) AS Petrol,
        SUM(fuel_type_diesel) AS Diesel,
        SUM(fuel_type_electric) AS Electric
    FROM 
        tg.dbo.fact_transport ft
        JOIN tg.dbo.dim_districts dd ON ft.dist_code = dd.dist_code
        JOIN tg.dbo.dim_date ddate ON ft.month = ddate.month
    WHERE 
        ddate.fiscal_year IN ('2021', '2022')
    GROUP BY 
        dd.district,
        ddate.fiscal_year
),
cte2 AS (
    SELECT 
        district,
        round((Petrol_2022 - Petrol_2021) / NULLIF(Petrol_2021, 0)*100,0) AS Petrol_Growth,
        round((Diesel_2022 - Diesel_2021) / NULLIF(Diesel_2021, 0)*100,0) AS Diesel_Growth,
        round((Electric_2022 - Electric_2021) / NULLIF(Electric_2021, 0)*100,0) AS Electric_Growth
    FROM (
        SELECT 
            district,
            MAX(CASE WHEN fiscal_year = '2021' THEN Petrol END) AS Petrol_2021,
            MAX(CASE WHEN fiscal_year = '2022' THEN Petrol END) AS Petrol_2022,
            MAX(CASE WHEN fiscal_year = '2021' THEN Diesel END) AS Diesel_2021,
            MAX(CASE WHEN fiscal_year = '2022' THEN Diesel END) AS Diesel_2022,
            MAX(CASE WHEN fiscal_year = '2021' THEN Electric END) AS Electric_2021,
            MAX(CASE WHEN fiscal_year = '2022' THEN Electric END) AS Electric_2022
        FROM 
            cte1
        GROUP BY 
            district
    ) t
),
cte3 AS (
    SELECT 
        district, 
        Petrol_Growth, 
        Diesel_Growth, 
        Electric_Growth,
        RANK() OVER (ORDER BY (Petrol_Growth + Diesel_Growth + Electric_Growth) DESC) AS rn_desc,
        RANK() OVER (ORDER BY (Petrol_Growth + Diesel_Growth + Electric_Growth)) AS rn_asc
    FROM 
        cte2
)
SELECT 
    district as Top_3_and_Bottom_3_Districts_with_Vehicle_Sales_Growth , 
    Petrol_Growth as Petrol_Growth_FY21_to_FY22, 
    Diesel_Growth as Diesel_Growth_FY21_to_FY22, 
    Electric_Growth as Electric_Growth_FY21_to_FY22
FROM 
    cte3
WHERE 
    rn_desc <= 3
    OR rn_asc <= 3
ORDER BY 
    rn_desc, rn_asc;


	------------------------------------------------------------------- TS iPASS----------------------------------------------------------------------
/* 8. List down the top 5 sectors that have witnessed the most significant investments in FY 2022. */


select top 
		5 fi.sector,sum(fi.[investment in cr]) as Total_Investment_in_2022_cr
from 
		tg.dbo.fact_ts_ipass fi
			join tg.dbo.dim_date ddate on fi.month=ddate.month
where 
		ddate.fiscal_year ='2022'
group by 
		fi.sector
order by 
		Total_Investment_in_2022_cr desc;


/* 9. List down the top 3 districts that have attracted the most significant sector investments during FY 2019 to 2022? What factors could have 
	  led to the substantial investments in these particular districts?*/select top 3
		 dd.district,fi.sector,round(sum(fi.[investment in cr]),2) as Total_Investment_from_FY19_to_FY22_cr
from 
		tg.dbo.fact_ts_ipass fi
			join tg.dbo.dim_date ddate on fi.month=ddate.month
			join tg.dbo.dim_districts dd  on fi.dist_code=dd.dist_code
group by 
		dd.district,fi.sector
order by 
		Total_Investment_from_FY19_to_FY22_cr desc;

/* 10. Is there any relationship between district investments, vehicles sales and stamps revenue within the same district between FY 2021
	   and 2022?*/


WITH cte_investments AS (
    SELECT
        dd.district,
        ddate.fiscal_year,
        round(SUM([investment in cr]),2) AS Total_Investments
    FROM
       tg.dbo.fact_ts_ipass inv
    JOIN
        tg.dbo.dim_districts dd ON inv.dist_code = dd.dist_code
    JOIN
         tg.dbo.dim_date AS ddate ON inv.month = ddate.month
    WHERE
        ddate.fiscal_year IN ('2021', '2022')
    GROUP BY
        dd.district, ddate.fiscal_year
),
cte_vehicle_sales AS (
    SELECT
        dd.district,
        ddate.fiscal_year,
        sum(fuel_type_petrol+fuel_type_diesel+fuel_type_electric+fuel_type_others) AS Total_Vehicle_Sales
    FROM
        tg.dbo.fact_transport AS vs
    JOIN
         tg.dbo.dim_districts AS dd ON vs.dist_code = dd.dist_code
    JOIN
        tg.dbo.dim_date AS ddate ON vs.month = ddate.month
    WHERE
        ddate.fiscal_year IN ('2021', '2022')
    GROUP BY
        dd.district, ddate.fiscal_year
),
cte_stamps_revenue AS (
    SELECT
        dd.district,
        ddate.fiscal_year,
        round(sum(sr.documents_registered_rev+sr.estamps_challans_rev)/10000000,2) AS Total_Stamps_Revenue_in_cr
    FROM
        tg.dbo.fact_stamps  sr
    JOIN
        tg.dbo.dim_districts  dd ON sr.dist_code = dd.dist_code
    JOIN
        tg.dbo.dim_date  ddate ON sr.month = ddate.month
    WHERE
        ddate.fiscal_year IN ('2021', '2022')
    GROUP BY
        dd.district, ddate.fiscal_year
)
SELECT
    i.district,
    sum(i.Total_Investments) as Total_Investments ,
    sum(vs.Total_Vehicle_Sales) as Total_Vehicle_Sales,
    sum(sr.Total_Stamps_Revenue_in_cr) as Total_Stamps_Revenue_in_cr
FROM
    cte_investments AS i
JOIN
    cte_vehicle_sales AS vs ON i.district = vs.district AND i.fiscal_year = vs.fiscal_year
JOIN
    cte_stamps_revenue AS sr ON i.district = sr.district AND i.fiscal_year = sr.fiscal_year
GROUP BY
	i.district
ORDER BY
    i.district;


/* 11. Are there any particular sectors that have shown substantial investment in multiple districts between FY 2021 and 2022?*/


WITH cte_sector_investments AS (
    SELECT
        inv.sector,
        dd.district,
        ddate.fiscal_year,
        round(SUM(inv.[investment in cr]),2) AS Total_Investment
    FROM
        tg.dbo.fact_ts_ipass AS inv
    JOIN
        tg.dbo.dim_districts AS dd ON inv.dist_code = dd.dist_code
    JOIN
        tg.dbo.dim_date AS ddate ON inv.month = ddate.month
    
    WHERE
        ddate.fiscal_year IN ('2021', '2022')
    GROUP BY
        inv.sector, dd.district, ddate.fiscal_year
)

SELECT
    sector,
    district,
    SUM(Total_Investment) AS Total_Sector_Investment
FROM
    cte_sector_investments
GROUP BY
    sector, district
HAVING
    SUM(Total_Investment) > 0
ORDER BY
    sector, Total_Sector_Investment DESC;


/* 12. Can we identify any seasonal patterns or cyclicality in the investment trends for specific sectors? Do certain sectors 
	   experience higher investments during particular months?*/


WITH cte_monthly_sector_investments AS (
    SELECT
        month,
        sector,
        SUM([investment in cr]) AS total_investment_in_cr
    FROM
        tg.dbo.fact_ts_ipass
    GROUP BY
        month,
        sector
),

cte_sector_avg_monthly_investments AS (
    SELECT
        sector,
        DATEPART(MONTH, month) AS investment_month,
        AVG(total_investment_in_cr) AS avg_monthly_investment
    FROM
        cte_monthly_sector_investments
    GROUP BY
        sector,
        DATEPART(MONTH, month)
)

SELECT
    sector,
    investment_month,
    avg_monthly_investment
FROM
    cte_sector_avg_monthly_investments
ORDER BY
    sector,
    investment_month;


----------------------------------------Secondary Research: (Need additional research and get additional data) -----------------------------------------
/* 1. What are the top 5 districts to buy commercial properties in Telangana? Justify your answer. */


WITH cte_commercial_sector_investments AS (
    SELECT
        f.dist_code,
        SUM(f.[investment in cr]) AS total_investment
    FROM
        tg.dbo.fact_ts_ipass AS f
    WHERE
        f.sector IN ('Industrial Parks and IT Buildings','Real Estate,Industrial Parks and IT Buildings')
    GROUP BY
        f.dist_code
)
SELECT top 5
    d.district,
    COALESCE(SUM(c.total_investment), 0) AS total_commercial_investment
FROM
    tg.dbo.dim_districts AS d
LEFT JOIN
    cte_commercial_sector_investments AS c ON d.dist_code = c.dist_code
GROUP BY
    d.district
ORDER BY
    total_commercial_investment DESC;









