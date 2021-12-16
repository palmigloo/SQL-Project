Use mavenfuzzyfactory;

# Product analysis 
# Question 1 : Product-level sales analysis 
select year(created_at) as yr,
       month(created_at) as mon,
       count(distinct order_id) as sales,
       sum(price_usd) as revenue,
       sum(price_usd - cogs_usd) as margin
from orders 
where created_at < '2013-01-04'
group by 1,2;

# Question 2: Analyszing product launch 
select year(ws.created_at) as yr,
       month(ws.created_at) as mon,
       count(distinct ws.website_session_id) as sessions,
       count(distinct order_id) as orders,
       count(distinct order_id)/count(distinct ws.website_session_id) as conversion_rate,
       sum(price_usd) as revenue,
       sum(price_usd)/count(distinct ws.website_session_id) as revenue_per_session,
       --  avg(price_usd) as revenue_per_session_2, Note: avg() is excluding Null value
       count(distinct case when primary_product_id = 1 then order_id end) as product_one_orders,
       count(distinct case when primary_product_id = 2 then order_id end) as product_two_orders
from website_sessions ws
left join orders o 
on ws.website_session_id = o.website_session_id
where ws.created_at < '2013-04-05' and ws.created_at >'2012-04-01'
group by 1,2;

# Question 3: Product-level website pathing 
# Step 1: find the all the sessions with /products page view 
create temporary table session_w_product_pageview
select website_session_id,
       website_pageview_id,
       created_at,
	case 
       when created_at < '2013-01-06' then 'Pre_product_2' 
       when created_at >= '2013-01-06' then 'Post_product_2'
	end as time_period
from website_pageviews
where created_at < '2013-04-06' and created_at > '2012-10-06'
      and pageview_url = '/products';
      
# Step 2: Find the next pageview id after product pageview 
create temporary table session_w_next_pageview 
select swpp.time_period,
	   swpp.website_session_id,
       min(wp.website_pageview_id) as next_pageview_id
from session_w_product_pageview swpp
left join website_pageviews wp
on swpp.website_session_id = wp.website_session_id 
and wp.website_pageview_id > swpp.website_pageview_id
group by 1,2;

# Step 3: Find the pageview_url of next pageview 
create temporary table nextpage_with_url
select time_period,
       swnp.website_session_id,
       next_pageview_id,
       pageview_url
from session_w_next_pageview swnp 
left join website_pageviews wp
on swnp.next_pageview_id = wp.website_pageview_id;

# Step 4: Aggregate data  
select time_period, 
       count(distinct website_session_id) as sessions, 
       count(distinct case when pageview_url is not null then website_session_id end) as w_next_pg,
       count(distinct case when pageview_url is not null then website_session_id end)/
       count(distinct website_session_id) as pct_w_next_pg,
       count(distinct case when pageview_url = '/the-original-mr-fuzzy' then website_session_id end) as mrfuzzy,
       count(distinct case when pageview_url = '/the-original-mr-fuzzy' then website_session_id end)/
       count(distinct website_session_id) as pct_to_mrfuzzy,
       count(distinct case when pageview_url = '/the-forever-love-bear' then website_session_id end) as lovebear,
       count(distinct case when pageview_url = '/the-forever-love-bear' then website_session_id end)/
       count(distinct website_session_id) as pct_to_lovebear
from nextpage_with_url
group by 1;

# Question 4: Product level conversion funnel 

# Step 1: Get all the pageview url for specific sessions 
-- drop table session_w_url
create temporary table session_w_url 
select ws.website_session_id, 
       wp.website_pageview_id,
       pageview_url
from website_sessions ws
left join website_pageviews wp
on ws.website_session_id = wp.website_session_id 
where ws.created_at between '2013-01-06' and '2013-04-10';

# Step 2: Create conversion funnel for specific sessions 
drop table session_w_funnel;
create temporary table session_w_funnel 
select website_session_id, 
       max(case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end) as to_mrfuzzy,
       max(case when pageview_url = '/the-forever-love-bear' then 1 else 0 end) as to_lovebear,
       max(case when pageview_url = '/the-birthday-sugar-panda' then 1 else 0 end) as to_panda,
       max(case when pageview_url = '/cart' then 1 else 0 end) as to_cart,
       max(case when pageview_url = '/shipping' then 1 else 0 end) as to_shipping,
       max(case when pageview_url = '/billing-2' then 1 else 0 end )as to_billing,
       max(case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end) as to_thankyou
from session_w_url 
group by 1;

-- drop table session_w_funnel

# Step 3: Calculate the summary 
select case 
        when to_mrfuzzy = 1 then 'mrfuzzy' 
        when to_lovebear = 1 then 'lovebear' 
        end as product_seen,
        count(distinct website_session_id) as sessions, 
        count(case when to_cart = 1 then website_session_id end ) as to_cart,
        count(case when to_shipping = 1 then website_session_id end) as to_shipping,
        count(case when to_billing = 1 then website_session_id end ) as to_billing,
        count(case when to_thankyou = 1 then website_session_id end) as to_thankyou
from session_w_funnel
where to_mrfuzzy != 0 or to_lovebear != 0
group by 1;

select case 
        when to_mrfuzzy = 1 then 'mrfuzzy' 
        when to_lovebear = 1 then 'lovebear' 
        end as product_seen,
        count(case when to_cart = 1 then website_session_id end )/count(distinct website_session_id) as product_click_rt,
        count(case when to_shipping = 1 then website_session_id end)/count(case when to_cart = 1 then website_session_id end ) as cart_click_rt,
        count(case when to_billing = 1 then website_session_id end )/count(case when to_shipping = 1 then website_session_id end) as shipping_click_rt,
        count(case when to_thankyou = 1 then website_session_id end)/count(case when to_billing = 1 then website_session_id end ) as billing_click_rt
from session_w_funnel
where to_mrfuzzy != 0 or to_lovebear != 0
group by 1 ;

 -- select distinct pageview_url from session_w_url

# Question 5: Cross-selling analysis 

# Step 1: Get all the sessions with /cart pageview 
drop table session_with_cart;
create temporary table session_with_cart
select case 
          when created_at >= '2013-09-25' then 'Post-cross-sell'
          when created_at < '2013-09-25' then 'Pre-cross-sell'
          end as time_period,
          website_session_id as cart_session_id,
          website_pageview_id as cart_pageview_id
from website_pageviews
where created_at between '2013-08-25' and '2013-10-25' 
	and pageview_url = '/cart';

# Step 2: Find all the sessions with next pageview after /cart 
drop table session_see_after_cart;
create temporary table session_see_after_cart
select time_period,
       cart_session_id,
       min(wp.website_pageview_id) as next_page
from session_with_cart swc 
left join website_pageviews wp 
on swc.cart_session_id = wp.website_session_id 
and swc.cart_pageview_id < wp.website_pageview_id 
group by 1,2;


# Step 3: Find all the sessions placed an order 
drop table session_w_order;
create temporary table session_w_order 
select time_period,
       ssac.cart_session_id,
       next_page,
       order_id,
       items_purchased,
       price_usd
from session_see_after_cart ssac
left join orders o 
on ssac.cart_session_id = o.website_session_id;

# Step 4: Calculate all the summary data 
select time_period,
       count(distinct cart_session_id) as cart_session,
       count(distinct next_page) as clickthrough,
       count(distinct next_page)/count(distinct cart_session_id) as cart_ctr,
       count(distinct order_id) as order_placed,
       sum(items_purchased) as products_purchased,
       sum(items_purchased)/count(distinct order_id) as product_per_order,
       sum(price_usd)/count(distinct order_id) as aov,
       sum(price_usd)/count(distinct cart_session_id) as rev_per_cart_session
from session_w_order
group by 1 ;


# Question 6:  Product porfolio expansion 
# Step 1: Find all the specific sessions with order info 
create temporary table session_w_order_info
select case 
         when ws.created_at < '2013-12-12' then 'A pre launch'
         when ws.created_at >= '2013-12-12' then 'B post launch' 
		end as time_period, 
        ws.website_session_id,
        order_id,
        items_purchased,
        price_usd
from website_sessions ws
left join orders o
on ws.website_session_id = o.website_session_id
where ws.created_at between '2013-11-12' and '2014-01-12';

# Step 2: Calculate the summary 
select time_period,
       count(distinct order_id)/count(distinct website_session_id) as conversion_rct,
       sum(price_usd)/count(distinct order_id) as aov,
       sum(items_purchased)/count(distinct order_id) as product_per_order,
       sum(price_usd)/count(distinct website_session_id) as revenue_per_session
from session_w_order_info 
group by 1;

# Question 7 : Analyzing product refund rate.  

select year(ot.created_at) as yr,
       month(ot.created_at) as mon,
       count(distinct case when product_id = 1 then ot.order_item_id end ) as product_1_order,
       count(distinct case when product_id = 1 then otr.order_item_id end)/count(distinct case when product_id = 1 then ot.order_item_id end ) as p1_refund_rct,
       count(distinct case when product_id = 2 then ot.order_item_id end ) as product_2_order,
       count(distinct case when product_id = 2 then otr.order_item_id end )/count(distinct case when product_id = 2 then ot.order_item_id end ) as p2_refund_rct,
       count(distinct case when product_id = 3 then ot.order_item_id end ) as product_3_order,
       count(distinct case when product_id = 3 then otr.order_item_id end)/count(distinct case when product_id = 3 then ot.order_item_id end ) as p3_refund_rct,
       count(distinct case when product_id = 4 then ot.order_item_id end ) as product_4_order,
       count(distinct case when product_id = 4 then otr.order_item_id end )/count(distinct case when product_id = 4 then ot.order_item_id end ) as p4_refund_rct
from order_items ot
left join order_item_refunds otr 
on ot.order_item_id = otr.order_item_id 
where ot.created_at < '2014-10-15'
group by 1,2 











