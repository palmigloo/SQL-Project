use mavenfuzzyfactory;
# User analysis 
# Analyzing repeat behaviours 

# Question 1 : Identifying repeat visitors 

# Step 1: Find all the non repeat session 
drop table user_w_nonrepeat_session;
create temporary table user_w_nonrepeat_session
select user_id,
       website_session_id
from website_sessions
where created_at >= '2014-01-01' and created_at < '2014-11-01' 
      and is_repeat_session = 0 ;

# Step 2: Find all the repeat session 
drop table user_w_repeat_session;
create temporary table user_w_repeat_session
select uwns.user_id,
       uwns.website_session_id as new_session_id,
       ws.website_session_id as repeat_session_id
from user_w_nonrepeat_session uwns 
left join website_sessions ws
on uwns.user_id = ws.user_id 
   and created_at >= '2014-01-01' and created_at < '2014-11-01' 
   and is_repeat_session = 1  
   and uwns.website_session_id < ws.website_session_id ;
   
# Step 3: Calculate repeat and nonrepeat sessions for each user 
drop table user_w_nonrepeat_repeat_session;
create temporary table user_w_nonrepeat_repeat_session
select user_id,
       count(distinct new_session_id) as new_sessions,
       count(distinct repeat_session_id) as repeat_sessions
from user_w_repeat_session
group by 1
order by 3 desc;

# Step 4 : Calculate the result 
select repeat_sessions,
       count(distinct user_id) as users
from user_w_nonrepeat_repeat_session
group by 1;

# Question 2: Analyzing time to repeat 
# Step 1: Get all the non-repeat session 
drop table user_w_nonrepeat_session;
create temporary table user_w_nonrepeat_session
select user_id,
       website_session_id,
       created_at
from website_sessions
where created_at >= '2014-01-01' and created_at < '2014-11-03' 
      and is_repeat_session = 0 ;

# Step 2: Find out the second session_id 
drop table user_w_repeat_session;
create temporary table user_w_repeat_session
select uwns.user_id,
       uwns.website_session_id as new_session_id,
       uwns.created_at as new_session_created_at,
       ws.website_session_id,
       ws.created_at 
from user_w_nonrepeat_session uwns 
inner join website_sessions ws 
on uwns.user_id = ws.user_id 
   and ws.created_at >= '2014-01-01' and ws.created_at < '2014-11-01' 
   and is_repeat_session = 1  
   and uwns.website_session_id < ws.website_session_id ;

# Step 3: Find out the diff between 1st and 2nd session for each user 
create temporary table diff_sessions
select user_id, 
       datediff(second_session_created_at,new_session_created_at) as days_bewteen_sessions
from (
select user_id,
       new_session_id,
       new_session_created_at,
       min(website_session_id) as second_session_id,
       min(created_at) as second_session_created_at
from user_w_repeat_session
group by 1,2,3) sub ;

# Step 4: Calculate the aggregate avg(), max(), min()
select avg(days_bewteen_sessions) as avg_days,
       min(days_bewteen_sessions) as min_days,
       max(days_bewteen_sessions) as max_days
from diff_sessions;

# Question 3: Analyzing repeat channel behavior 
select case
         when utm_source is null and http_referer in ('https://www.gsearch.com','https://www.bsearch.com') then 'organic-search'
		 when utm_campaign = 'nonbrand' then 'paid_nonbrand'
         when utm_campaign = 'brand' then 'paid_brand'
         when utm_source is null and http_referer is null then 'direct_type_in'
         when utm_source = 'socialbook' then 'paid_social'
		end as channel_group,
        count(case when is_repeat_session = 0 then website_session_id end ) as new_sesions,
        count(case when is_repeat_session = 1 then website_session_id end ) as repeat_sessions
from website_sessions
where created_at >= '2014-01-01' and created_at < '2014-11-05'
group by 1;

# Question 4: Analyzing new and repeat conversion rate 
select is_repeat_session,
       count(distinct ws.website_session_id) as sessions,
       count(distinct order_id)/count(distinct ws.website_session_id) as crt,
       sum(price_usd)/count(distinct ws.website_session_id) as rev_per_session
from website_sessions ws
left join orders o
on ws.website_session_id = o.website_session_id 
where ws.created_at >= '2014-01-01' and ws.created_at < '2014-11-08'
group by 1














