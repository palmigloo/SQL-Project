use MakerFashionDb;

# Traffic source analysis

# Requirement 1: Check traffic source trending data 
select min(date(created_at)) as start_date_of_week,
       count(distinct website_session_id) as sessions
from website_sessions 
where created_at < '2021-05-10' and utm_source = 'gsearch' and utm_campaign = 'nonbrand'
group by year(created_at),
         week(created_at);
         
#Requirement 2: Check device specific conversion rate
select device_type,
       count(distinct ws.website_session_id) as sessions,
	   count(distinct o.order_id) as orders,
       count(distinct o.order_id)/count(distinct ws.website_session_id) as cvr
from website_sessions ws
left join orders o on ws.website_session_id = o.website_session_id
where ws.created_at < '2021-05-11' and utm_source = 'gsearch' and utm_campaign = 'nonbrand'
group by 1;

# Requirement 3: Check weekly sessions trending on device level 
select min(date(created_at)) as start_date_of_week,
       count(distinct case when device_type = 'desktop' then website_session_id else null end) as pc_sessions,
       count(distinct case when device_type = 'mobile' then website_session_id else null end) as mobile_sessions
from website_sessions
where created_at between '2021-04-15' and '2021-06-09' and utm_source = 'gsearch' and utm_campaign = 'nonbrand'
group by year(created_at),
         week(created_at);






