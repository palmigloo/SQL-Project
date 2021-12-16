use e-com-analysis;

# Analyzing business patterns and seasonality 
# Question 1: Analyzing monthly/yearly trend 
select year(ws.created_at) as yr, 
       month(ws.created_at) as mon,
       count(distinct ws.website_session_id) as total_session,
       count(distinct order_id) as total_orders 
from website_sessions ws
left join orders o
on ws.website_session_id = o.website_session_id
where ws.created_at < '2013-01-02' 
group by 1,2;

select yearweek(ws.created_at) as yrwk,
       min(date(ws.created_at)) as week_start_date,
       count(distinct ws.website_session_id) as total_sessions,
       count(distinct order_id) as total_orders
from website_sessions ws
left join orders o
on ws.website_session_id = o.website_session_id
where ws.created_at < '2013-01-02'
group by 1;

# Question 2: Analyzing business patterns 
-- select hour(created_at) as hour,
--       count(case when weekday(created_at) = 0 then website_session_id end)/round(datediff('2012-11-15','2012-09-15')/7,0) as mon
-- from website_sessions
-- where created_at > '2012-09-15' and created_at < '2012-11-15'
-- group by 1
--  order by 1

create temporary table session_w_date
select date(created_at) as created_date,
       weekday(created_at) as wkday,
       hour(created_at) as hour,
       count(distinct website_session_id) as total_sessions
from website_sessions
where created_at between '2012-09-15' and '2012-11-15'
group by 1,2,3;

select hour,
       round(avg(case when wkday = 0 then total_sessions end),1) as Mon,
       round(avg(case when wkday = 1 then total_sessions end),1) as Tus,
       round(avg(case when wkday = 2 then total_sessions end),1) as Wed,
       round(avg(case when wkday = 3 then total_sessions end),1) as Thu,
       round(avg(case when wkday = 4 then total_sessions end),1) as Fri,
       round(avg(case when wkday = 5 then total_sessions end),1) as Sat,
       round(avg(case when wkday = 6 then total_sessions end),1) as Sun
from session_w_date
group by 1
order by 1



