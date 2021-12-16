Use mavenfuzzyfactory;
# Context : CEO pitch to the investor to show the growth of the company  
# Analyze : 1. Traffic , 2. Website performance 3. 

# Question 1: Show the website's volumn growth by showing the overall session and orders by quarter 
select year(ws.created_at) as yr,
       quarter(ws.created_at) as quar,
       count(distinct ws.website_session_id) as total_sessions,
       count(distinct order_id) as total_orders,
       count(distinct order_id)/count(distinct ws.website_session_id) as crt
from website_sessions ws
left join orders o 
on ws.website_session_id = o.website_session_id
where ws.created_at < '2015-01-01'
group by 1,2;

# Question 2: Show efficiency improvement , quarterly figures 
select year(ws.created_at) as yr,
       quarter(ws.created_at) as quar,
       sum(price_usd)/count(distinct order_id) as rev_per_order,
       sum(price_usd)/count(distinct ws.website_session_id) as rev_per_session,
       count(distinct order_id)/count(distinct ws.website_session_id) as session_to_order_crt
from website_sessions ws
left join orders o 
on ws.website_session_id = o.website_session_id
where ws.created_at < '2015-01-01'
group by 1,2;

# Question 3: Growth in specific channels 
select year(ws.created_at) as yr,
       quarter(ws.created_at) as quar,
       count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then order_id end) as gsearch_nonbrand_orders,
       count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then order_id end) as bsearch_nonbrand_orders,
       count(distinct case when utm_campaign = 'nonbrand' then order_id end) as brand_search_orders,
       count(distinct case when utm_source is null and http_referer is not null then order_id end) as organic_search_orders,
       count(distinct case when utm_source is null and http_referer is null then order_id end) as direct_typein_orders
from website_sessions ws
left join orders o 
on ws.website_session_id = o.website_session_id
where ws.created_at < '2015-01-01'
group by 1,2;

#Question 4: Show overall session_to_order rate for specific channel by quarter 
select year(ws.created_at) as yr,
       quarter(ws.created_at) as quar,
       count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then order_id end)/
       count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then ws.website_session_id end) as gsearch_nonbrand_crt,
       count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then order_id end)/
       count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then ws.website_session_id end) as bsearch_nonbrand_crt,
       count(distinct case when utm_campaign = 'nonbrand' then order_id end)/
       count(distinct case when utm_campaign = 'nonbrand' then ws.website_session_id end) as brand_search_crt,
       count(distinct case when utm_source is null and http_referer is not null then order_id end)/
       count(distinct case when utm_source is null and http_referer is not null then ws.website_session_id end) as organic_search_crt,
       count(distinct case when utm_source is null and http_referer is null then order_id end)/
       count(distinct case when utm_source is null and http_referer is null then ws.website_session_id end) as direct_typein_orders
from website_sessions ws
left join orders o 
on ws.website_session_id = o.website_session_id
where ws.created_at < '2015-01-01'
group by 1,2;

# 2012 quarter4 to 2013 quarter 1 , there was an improvement of all channels. 

# Question 5: Monthly trending for revenue,margin and total by product 
select year(created_at) as yr,
       month(created_at) as mon,
       sum(case when product_id = 1 then price_usd end) as p1_rev,
       sum(case when product_id = 1 then price_usd - cogs_usd end ) as p1_margin,
       sum(case when product_id = 2 then price_usd end) as p2_rev,
       sum(case when product_id = 2 then price_usd - cogs_usd end ) as p2_margin,
       sum(case when product_id = 3 then price_usd end) as p3_rev,
       sum(case when product_id = 3 then price_usd - cogs_usd end ) as p3_margin,
       sum(case when product_id = 4 then price_usd end) as p4_rev,
       sum(case when product_id = 4 then price_usd - cogs_usd end ) as p4_margin,
       sum(price_usd) as total_rev,
       sum(price_usd - cogs_usd) as total_margin
from order_items
where created_at < '2015-03-20'
group by 1,2;

# Observations: There is a quite noticable improvement at the end of year because of the holiday in the US 

# Question 6: Pull monthly session for /products page, ctr to next page and session to order rate 
# Step 1: Get all the specific sessions for /products pages 
create temporary table session_for_products
select website_session_id,
       website_pageview_id,
       created_at
from website_pageviews 
where created_at < '2015-03-20' and pageview_url = '/products';

# Step2: Find the next page after /products 
create temporary table session_w_nextpage 
select sfp.website_session_id,
       sfp.created_at,
       min(wp.website_pageview_id) as next_page_id 
from session_for_products sfp
left join website_pageviews wp
on sfp.website_session_id = wp.website_session_id and sfp.website_pageview_id < wp.website_pageview_id  
and wp.created_at < '2015-03-20'
group by 1,2;

# Step 3: Calculate the summary 
select year(swn.created_at) as yr,
       month(swn.created_at) as mon,
       count(distinct swn.website_session_id) as total_product_sessions,
       count(distinct swn.next_page_id)/count(distinct swn.website_session_id) as product_crt,
       count(distinct order_id)/count(distinct swn.website_session_id) as session_to_order_rate
from session_w_nextpage swn 
left join orders o 
on swn.website_session_id = o.website_session_id 
group by 1,2;

# Question 7: Show how each product cross sell with each other 
create temporary table primary_products 
select order_id,
	   primary_product_id,
       created_at 
from orders 
where created_at > '2014-12-05';

create temporary table order_w_xsell_products
select pp.*,
       oi.product_id
from primary_products pp
left join order_items oi 
on pp.order_id = oi.order_id and oi.is_primary_item = 0;

select primary_product_id,
       count(distinct order_id) as total_orders,
       count(case when product_id = 1 then order_id end) as xsell_p1,
       count(case when product_id = 2 then order_id end) as xsell_p2,
       count(case when product_id = 3 then order_id end) as xsell_p3,
       count(case when product_id = 4 then order_id end) as xsell_p4,
       count(case when product_id = 1 then order_id end)/count(distinct order_id) as xsell_p1_rate,
       count(case when product_id = 2 then order_id end)/count(distinct order_id) as xsell_p2_rate,
       count(case when product_id = 3 then order_id end)/count(distinct order_id) as xsell_p3_rate,
       count(case when product_id = 4 then order_id end)/count(distinct order_id) as xsell_p4_rate
from order_w_xsell_products
group by 1


# Question 8 : 



