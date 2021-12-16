use mavenfuzzyfactory;

# Analysis for channel porfolio management 
# Question 1 : Analysing channel porfolio 
select yearweek(created_at) as yrwk,
       min(date(created_at)) as week_start_date,
	   count(distinct website_session_id) as total_session,
       count(distinct case when utm_source = 'gsearch' then website_session_id end) as gsearch_session,
	   count(distinct case when utm_source = 'bsearch' then website_session_id end) as bsearch_session
from website_sessions
where created_at > '2012-08-22' and created_at < '2012-11-29'
AND utm_campaign = 'nonbrand'
group by 1;

# Question 2: Comparing channel characteristics 
select utm_source,
       count(distinct website_session_id) as total_session,
       count(distinct case when device_type = 'mobile' then website_session_id end ) as mobile_session,
       count(distinct case when device_type = 'mobile' then website_session_id end )/count(distinct website_session_id) as pct_mobile_trafic
from website_sessions 
where created_at > '2012-08-22' and created_at < '2012-11-30'
AND utm_campaign = 'nonbrand'
group by 1;

# Question 3: Cross-channel bid optimization 

select device_type,
       utm_source,
	 count(distinct ws.website_session_id) as total_session,
     count(distinct o.order_id) as total_order,
     count(distinct o.order_id)/count(distinct ws.website_session_id) as conversion_rct 
from website_sessions ws
left join orders o 
on ws.website_session_id = o.website_session_id 
where ws.created_at > '2012-08-22' and ws.created_at < '2012-09-19'
AND utm_campaign = 'nonbrand'
group by 1,2 ;

#Question 4: Analyzing channel porfolio trends 
select yearweek(created_at) as year_week,
       min(date(created_at)) as week_start_date,
       count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id end) as g_s_pc_session,
       count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id end) as b_s_pc_session,
       count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id end)
       /count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id end) as b_g_pc_rate,
       count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id end) as g_s_mobile_session,
       count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id end) as b_s_mobile_session,
       count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id end)
       /count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id end)as b_g_mobile_rate
from website_sessions
where created_at > '2012-11-04' and created_at < '2012-12-22'
AND utm_campaign = 'nonbrand'
group by 1;

# Question 5: Analysing direct,brand-driven traffic 
create temporary table session_w_channel
select  website_session_id,
        created_at,
       case 
			when utm_source is null and http_referer in ('https://www.gsearch.com','https://www.bsearch.com') then 'organic_search'
            when utm_campaign = 'nonbrand' then 'paid_nonbrand'
            when utm_campaign = 'brand' then 'paid_brand'
            when utm_source is null and http_referer is null then 'direct_type_in'
		end as channel_group,
        utm_source,
        utm_campaign,
        http_referer
from website_sessions
where created_at < '2012-12-23';

select year(created_at) as yr,
       month(created_at) as mon,
       count(distinct case when channel_group = 'paid_nonbrand' then website_session_id end) as nonbrand,
       count(distinct case when channel_group = 'paid_brand' then website_session_id end) as brand,
       count(distinct case when channel_group = 'paid_brand' then website_session_id end)/
       count(distinct case when channel_group = 'paid_nonbrand' then website_session_id end) as brand_pct_nonbrand,
       count(distinct case when channel_group = 'direct_type_in' then website_session_id end) as direct,
       count(distinct case when channel_group = 'direct_type_in' then website_session_id end)/
       count(distinct case when channel_group = 'paid_nonbrand' then website_session_id end) as direct_pct_nonbrand,
       count(distinct case when channel_group = 'organic_search' then website_session_id end) as organic,
       count(distinct case when channel_group = 'organic_search' then website_session_id end)/
       count(distinct case when channel_group = 'paid_nonbrand' then website_session_id end) as organic_pct_nonbrand
from session_w_channel 
group by 1,2 








