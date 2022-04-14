use MakerFashionDb;

# Product analysis 
# Requirement 1 : Product-level sales analysis 
select year(created_at) as yr,
       month(created_at) as mon,
       count(distinct order_id) as sales,
       sum(price_usd) as revenue,
       sum(price_usd - cogs_usd) as margin
from orders 
where created_at < '2021-01-04'
group by 1,2;

# Requirement 2: Analyszing product launch 
select case when year(ws.created_at) = '2021' then '2021' else '2021' end as yr,
       month(ws.created_at) as mon,
       count(distinct ws.website_session_id) as sessions,
       count(distinct order_id) as orders,
       count(distinct order_id)/count(distinct ws.website_session_id) as conversion_rate,
       sum(price_usd) as revenue,
       sum(price_usd)/count(distinct ws.website_session_id) as rev_per_session,
       --  avg(price_usd) as revenue_per_session_2, Note: avg() is excluding Null value
       count(distinct case when primary_product_id = 1 then order_id end) as p1_orders,
       count(distinct case when primary_product_id = 2 then order_id end) as p2_orders
from website_sessions ws
left join orders o  
on ws.website_session_id = o.website_session_id
where ws.created_at < '2021-04-05' and ws.created_at >'2021-04-01'
group by 1,2;

# Requirement 3: Product-level website pathing 
# Step 1: find the all the sessions with /products page view 
create temporary table session_w_product_pageview
select website_session_id,
       website_pageview_id,
       created_at,
	case 
       when created_at < '2021-01-06' then 'Pre_product_2' 
       when created_at >= '2021-01-06' then 'Post_product_2'
	end as time_period
from website_pageviews
where created_at < '2021-04-06' and created_at > '2021-10-06'
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
       count(distinct case when pageview_url = '/eco-cosmo' then website_session_id end) as ecocosmo,
       count(distinct case when pageview_url = '/eco-cosmo' then website_session_id end)/
       count(distinct website_session_id) as pct_to_ecocosmo,
       count(distinct case when pageview_url = '/chic-choc' then website_session_id end) as chicchoc,
       count(distinct case when pageview_url = '/chic-choc' then website_session_id end)/
       count(distinct website_session_id) as pct_to_chicchoc
from nextpage_with_url
group by 1;

# Requirement 4: Product level conversion funnel 
# Step 1: Get all the pageview url for specific sessions 
-- drop table session_w_url
create temporary table session_w_url 
select ws.website_session_id, 
       wp.website_pageview_id,
       pageview_url
from website_sessions ws
left join website_pageviews wp
on ws.website_session_id = wp.website_session_id 
where ws.created_at between '2021-01-06' and '2021-04-10';

# Step 2: Create conversion funnel for specific sessions 
drop table session_w_funnel;
create temporary table session_w_funnel 
select website_session_id, 
       max(case when pageview_url = '/eco-cosmo' then 1 else 0 end) as to_ecocosmo,
       max(case when pageview_url = '/chic-choc' then 1 else 0 end) as to_chicchoc,
       max(case when pageview_url = '/summer-bomb' then 1 else 0 end) as to_summer_bomb,
       max(case when pageview_url = '/cart' then 1 else 0 end) as to_cart,
       max(case when pageview_url = '/shipping' then 1 else 0 end) as to_shipping,
       max(case when pageview_url = '/billing-2' then 1 else 0 end )as to_billing,
       max(case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end) as to_thankyou
from session_w_url 
group by 1;

-- drop table session_w_funnel

# Step 3: Calculate the summary 
select case 
        when to_ecocosmo = 1 then 'ecocosmo' 
        when to_chicchoc = 1 then 'chicchoc' 
        end as product_seen,
        count(distinct website_session_id) as sessions, 
        count(case when to_cart = 1 then website_session_id end ) as to_cart,
        count(case when to_shipping = 1 then website_session_id end) as to_shipping,
        count(case when to_billing = 1 then website_session_id end ) as to_billing,
        count(case when to_thankyou = 1 then website_session_id end) as to_thankyou
from session_w_funnel
where to_ecocosmo != 0 or to_chicchoc != 0
group by 1;

select case 
        when to_ecocosmo = 1 then 'ecocosmo' 
        when to_chicchoc = 1 then 'chicchoc' 
        end as product_seen,
        count(case when to_cart = 1 then website_session_id end )/count(distinct website_session_id) as product_click_rt,
        count(case when to_shipping = 1 then website_session_id end)/count(case when to_cart = 1 then website_session_id end ) as cart_click_rt,
        count(case when to_billing = 1 then website_session_id end )/count(case when to_shipping = 1 then website_session_id end) as shipping_click_rt,
        count(case when to_thankyou = 1 then website_session_id end)/count(case when to_billing = 1 then website_session_id end ) as billing_click_rt
from session_w_funnel
where to_ecocosmo != 0 or to_chicchoc != 0
group by 1 ;


# Requirement 5: Cross-selling analysis 

# Step 1: Get all the sessions with /cart pageview 
create temporary table cart_session
select website_session_id, 
	   website_pageview_id,
       case when created_at < '2021-09-25' then 'A. Pres test'
            when created_at >= '2021-09-25' then 'B. Post test'
            else 'Wrong logic'
       end as time_period
from website_pageviews
where created_at between '2021-08-25' and '2021-10-25' and pageview_url = '/cart';

# Step 2: Find all the sessions with next pageview after /cart 
create temporary table cart_session_w_next_pg
select time_period,
       cs.website_session_id,
       min(wp.website_pageview_id) as pv_id_after_cart
from cart_session cs left join website_pageviews wp
on cs.website_session_id = wp.website_session_id and wp.website_pageview_id > cs.website_pageview_id
group by 1,2
having pv_id_after_cart is not null;

# Step 3: Find all the sessions placed an order 
create temporary table cart_session_w_order
select cs.website_session_id,
       time_period,
       order_id,
       items_purchased,
       price_usd
from cart_session cs inner join orders o
on cs.website_session_id = o.website_session_id;

# Step 4: Calculate all the summary data 
select time_period,
       count(distinct website_session_id) as total_sessions,
       sum(click_to_nxpg) as cart_ctr,
       sum(placed_order) as orders,
       sum(items_purchased) as product_purchased,
       sum(items_purchased)/sum(placed_order) as products_per_order,
       sum(price_usd) as revenue,
       sum(price_usd)/sum(placed_order) as aov,
       sum(price_usd)/count(distinct website_session_id) as revenue_per_cart_session
from (
select cs.time_period,
       cs.website_session_id,
	   case when cswnp.website_session_id is not null then 1 else 0 end as click_to_nxpg,
       case when cswo.website_session_id is not null then 1 else 0 end as placed_order,
       cswo.items_purchased,
       cswo.price_usd
from cart_session cs left join cart_session_w_order cswo
on cs.website_session_id = cswo.website_session_id
left join cart_session_w_next_pg cswnp
on cs.website_session_id = cswnp.website_session_id) as all_data
group by 1;

# Requirement 6:  Product porfolio expansion 
# Step 1: Find all the specific sessions with order info 
create temporary table session_w_order_info
select case 
         when ws.created_at < '2021-12-12' then 'A pre launch'
         when ws.created_at >= '2021-12-12' then 'B post launch' 
		end as time_period, 
        ws.website_session_id,
        order_id,
        items_purchased,
        price_usd
from website_sessions ws
left join orders o
on ws.website_session_id = o.website_session_id
where ws.created_at between '2021-11-12' and '2014-01-12';

# Step 2: Calculate the summary 
select time_period,
       count(distinct order_id)/count(distinct website_session_id) as conversion_rct,
       sum(price_usd)/count(distinct order_id) as aov,
       sum(items_purchased)/count(distinct order_id) as product_per_order,
       sum(price_usd)/count(distinct website_session_id) as revenue_per_session
from session_w_order_info 
group by 1;

# Requirement 7 : Analyzing product refund rate.  
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
where ot.created_at < '2021-10-15'
group by 1,2 











