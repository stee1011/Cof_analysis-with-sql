-- Payment variation from the depatment analysis which will help us know the Departments with the highrst variations for further analysis of corruption or is a talent diversity

with cof_analysis as (
	select jobtitle, coalesce(stddev(rate),0) as variation_degree_in_payments, coalesce(avg(rate), 0) as mean, (coalesce(stddev(rate),0) / coalesce(avg(rate), 0)) as cof, employee_name
	from (
	select eh.jobtitle, e2.rate, eh.loginid as employee_name
	from department d 
	left join employeedepartmenthistory e on d.departmentid = e.departmentid
	left join employee eh on eh.businessentityid = e.businessentityid 
	left join employeepayhistory e2 on e2.businessentityid = e.businessentityid
	) as data_employee
	
	group by jobtitle, employee_name
	order by variation_degree_in_payments desc
	
),

cdf_like_data as (

	select 

	percentile_cont(0.25) within group (order by cof) as Q1,
	percentile_cont(0.5) within group (order by cof) as Q2,
	percentile_cont(0.75) within group (order by cof) as Q3

	from cof_analysis
	where cof > 0 

),

suspicious_dep as (
select * from cof_analysis cf, cdf_like_data cdf where cf.cof > cdf.Q3 -- which is the Q3 that is 75th percentile
),

final_data_2 as (

select * from (select * from suspicious_dep se left join employee e on se.jobtitle = e.jobtitle) order by vacationhours desc), -- Further analysis since no way those with more vacation Hours earn high 
	
final_data as (
select  se.jobtitle,se.employee_name , df.cof ,
row_number() over(partition by se.jobtitle order by df.cof desc) as variation_rank
from cof_analysis se, suspicious_dep df
  --- For top 3 Suspicious employees!

)

select * from final_data where variation_rank <= 3   --- For top 3 Suspicious employees!;


-- BYE! Happy Forensics
