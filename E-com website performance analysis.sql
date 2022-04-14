use mavenfuzzyfactory;

# Landing page performance & testing 

# Requirement 1: Finding top website pages
select pageview_url,
       count(distinct website_session_id) as sessions 
from website_pageviews
where created_at < '2021-06-09'
group by 1
order by 2 desc;

# Requirement 2: Finding the top entry pages 
# Step 1: Find the first pageview for specific session 
create temporary table session_w_first_pv
select website_session_id,
       min(website_pageview_id) as first_pv_id 
from website_pageviews
where created_at < '2021-06-12'
group by 1;

# Step 2: Find the first pageview url 
select pageview_url,
       count(distinct swfp.website_session_id) as sessions
from session_w_first_pv swfp left join website_pageviews wp
on swfp.first_pv_id = wp.website_pageview_id
group by 1;


#Requirement 3 :  Check bounce rate for traffic landing on the /home page with 3 columns: sessions, bounced sessions, bounce rate
# step 1: finding the first website_page_id for the relevant sessions
create temporary table first_pageviews
select website_session_id, 
       min(website_pageview_id) as min_pv_id
from website_pageviews 
where created_at < '2021-06-14'
group by 1;

# step 2: identify the landing page of each session
create temporary table sessions_w_home_landing_page
select fp.website_session_id,
       wp.pageview_url as landing_url 
from first_pageviews fp 
left join website_pageviews wp on fp.min_pv_id = wp.website_pageview_id
where wp.pageview_url = '/home';

# step 3: count pageview for each session to identify 'bounce'
create temporary table bounced_sessions
select swlp.website_session_id,
       swlp.landing_url,
       count(distinct website_pageview_id) as count_page_view
from sessions_w_home_landing_page swlp
left join website_pageviews wp on swlp.website_session_id = wp.website_session_id
group by 1,2
having count(distinct website_pageview_id) = 1;

# step 4: summarize by counting total sessions and bounced sessions 
select count(distinct swhl.website_session_id) as sessions,
       count(distinct bs.website_session_id) as bounced_session_id,
       count(distinct bs.website_session_id)/count(distinct swhl.website_session_id) as bounce_rate
from sessions_w_home_landing_page swhl
left join bounced_sessions bs on swhl.website_session_id = bs.website_session_id;

# Requirement 4: Analyzing landing page tests 
# Step 1 Find the the creation time and its first pageview id 
select min(created_at),
       min(website_pageview_id)
from website_pageviews
where pageview_url = '/lander-1';
# first pageview id for /lander-1 is 23504

# step 2: finding the first website_page_id for the relevant sessions
create temporary table non_brand_session_w_first_pv
select wp.website_session_id,
       min(wp.website_pageview_id) as first_pv_id
from website_pageviews wp inner join website_sessions ws
on wp.website_session_id = ws.website_session_id and utm_source = 'gsearch' and utm_campaign = 'nonbrand' 
                                                 and ws.created_at < '2021-07-28' and wp.website_pageview_id > 23504
group by 1;


# step 3: identify the landing page of each session
create temporary table non_brand_session_lp_url
select nbswfp.website_session_id,
       wp.pageview_url as landing_pg
from non_brand_session_w_first_pv nbswfp left join website_pageviews wp
on nbswfp.first_pv_id = wp.website_pageview_id
where wp.pageview_url in ('/home','/lander-1');

# step 4: count pageview for each session to identify 'bounce'
create temporary table non_brand_bounced_session
select nbslu.*,
       count(distinct wp.website_pageview_id) as nb_pv
from non_brand_session_lp_url nbslu left join website_pageviews wp
on nbslu.website_session_id = wp.website_session_id
group by 1,2
having count(distinct wp.website_pageview_id) = 1;

# step 5: summarize by counting total sessions and bounced sessions 
select nbslu.landing_pg,
       count(distinct nbslu.website_session_id) as total_sessions,
       count(distinct nbbs.website_session_id) as bounce_sessions,
       count(distinct nbbs.website_session_id)/count(distinct nbslu.website_session_id) as bounce_rate
from non_brand_session_lp_url nbslu left join non_brand_bounced_session nbbs
on nbslu.website_session_id = nbbs.website_session_id
group by 1;


# Requirement 5: Check paid search nonbrand landing on /home and /lander-1 weekly trend since June 1st, as well as overall paid search bounce 
#                 rate trend weekly

# Step1: Find the first pageview for each session and count the pageview for each session
create temporary table non_brand_session_w_pv_nb
select ws.website_session_id,
       min(wp.website_pageview_id) as first_pv_id,
       count(distinct wp.website_pageview_id) as nb_pv
from website_sessions ws left join website_pageviews wp
on ws.website_session_id = wp.website_session_id 
where ws.created_at between '2021-06-01' and '2021-08-31'
and utm_source = 'gsearch' and utm_campaign = 'nonbrand'
group by 1;

# Step 2: Create a table to get landing page url and creation time
create temporary table non_brand_session_lp_url_2
select nbswpn.*, 
       wp.pageview_url as landing_pg,
       wp.created_at as lp_view_time
from non_brand_session_w_pv_nb nbswpn left join website_pageviews wp
on nbswpn.first_pv_id = wp.website_pageview_id;

# Step 3:Summarize for the final result
select min(date(lp_view_time)) as start_date_of_week,
       count(distinct case when nb_pv = 1 then website_session_id else null end)/count(distinct website_session_id) as bounce_rate,
       count(distinct case when landing_pg = '/home' then website_session_id else null end) as home_sessions,
       count(distinct case when landing_pg = '/lander-1' then website_session_id else null end) as lander_sessions
from non_brand_session_lp_url_2
group by yearweek(lp_view_time);


# Requirement 6: Analyze conversion funnel 

# Step 1: Find all the relevant sessions and tag funnel steps
drop table session_with_funnel_tag;
create temporary table session_with_funnel_tag
select website_session_id,
       max(products_page) as products,
       max(eco_cosmo_page) as eco_cosmo,
       max(cart_page) as cart,
       max(shipping_page) as shipping,
       max(billing_page) as billing,
       max(thankyou_page) as thankyou
from ( 
select ws.website_session_id,
       wp.pageview_url,
       case when pageview_url = '/products' then 1 else 0 end as products_page,
       case when pageview_url = '/eco-cosmo' then 1 else 0 end as eco_cosmo_page,
       case when pageview_url = '/cart' then 1 else 0 end as cart_page,
       case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
       case when pageview_url = '/billing' then 1 else 0 end as billing_page,
       case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions ws left join website_pageviews wp
on ws.website_session_id = wp.website_session_id
where utm_source = 'gsearch' and utm_campaign = 'nonbrand' and ws.created_at between '2021-08-05' and '2021-09-05'
) as tag_funnuel
group by 1;

#Step 2: Calculate the total user for each step in the funnel and calculate the click through rate for each step 
select count(distinct website_session_id) as total_sessions, 
       sum(products) as to_products,
       sum(eco_cosmo) as to_eco_cosmo,
       sum(cart) as to_cart,
       sum(shipping) as to_shipping,
       sum(billing) as to_billing,
       sum(thankyou) as to_thankyou
from session_with_funnel_tag;

select sum(products)/count(distinct website_session_id) as lander_ctr,
	   sum(eco_cosmo)/sum(products) as product_ctr,
       sum(cart)/sum(eco_cosmo) as ecocosmo_ctr,
       sum(shipping)/sum(cart) as cart_ctr,
       sum(billing)/sum(shipping) as shipping_ctr,
       sum(thankyou)/sum(billing) as billing_ctr
from session_with_funnel_tag;


# Requirement 7: Analyzing conversion funnel test for billing pages
# Step 1: Find the new billing page first pageview id 
select min(website_pageview_id)
from website_pageviews
where pageview_url = '/billing-2';
# First pageview id for /billing-2 is 53550

# Step 2: Calculate the final result
select wp.pageview_url,
	   count(distinct wp.website_session_id) as sessions,
       count(distinct o.order_id) as orders,
       count(distinct o.order_id)/count(distinct wp.website_session_id) as billing_to_order_rt
from website_pageviews wp left join orders o
on wp.website_session_id = o.website_session_id
where wp.pageview_url in ('/billing','/billing-2') and wp.website_pageview_id > 53550 and wp.created_at < '2021-11-10'
group by 1






