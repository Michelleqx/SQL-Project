USE mavenfuzzyfactory;

## Section: Analyzing Website Performance
/*
Website content analysis is about understanding which pages are seen the most
by your users, to identify where to focus on improving your business.

Common Use Cases: 1) Finding the most_viewed pages that customers view on your site
				  2) Identifying the most common entry pages to your website -- the first thing a user sees
				  3) For most-viewed pages and most common entry pages, understanding how thoses pages 
                     perform for your business objectives

SQL CREATE TEMPORARY TABLE: allows you to create a dataset stored as a table which 
  						    you can query
*/

-- Finding top website pages
-- Pulling the most viewed website pages, ranked by session volume
SELECT 
	pageview_url,
    COUNT(DISTINCT website_pageview_id) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY sessions DESC;
-- Conclusion: The homepage, the products page, and the Mr. Fuzzy page get the bulk of our traffic.
-- 			   Dig into whether this list is also representative of our top entry pages

-- Finding top entry pages
-- Pull all entry pages and rank them on entry
-- STEP 1: find the first pageview for each session
CREATE TEMPORARY TABLE first_entry
SELECT 
	website_session_id,
	MIN(website_pageview_id) AS first_entry_page
FROM website_pageviews 
WHERE created_at < '2012-06-12'
GROUP BY website_session_id;
-- STEP 2: find the url the customer saw on that first pageview
SELECT 
	wp.pageview_url AS landing_page,
	COUNT(DISTINCT fe.website_session_id) AS sessions_hitting_this_landing_page
FROM first_entry fe
LEFT JOIN website_pageviews wp
	ON fe.first_entry_page = wp.website_pageview_id
GROUP BY landing_page;
-- Conclusion: Our traffic all comes in through the homepage. We need to analyze 
-- 			   landing page performance, for the homepage specifically.

/*
Analyzing Bounce Rates & Landing Page Tests
Landing page analysis and testing is about understanding the performance of your
key landing pages and then testing to improve your results

Common Use Cases: 1) Identifying your top opportunities for landing pages - high volume 
					 pages with higher than expected bounce rates or low conversion rates
 			      2) Setting up A/B experiments on your live traffic to see if you can
				     improve your bounce rates and conversion rates
				  3) Analyzing test results and making recommendations on which version of 
					 landing pages you should use going forward

BUSINESS CONTEXT: we want to see landing page performance for a certain time period

-- STEP 1: find the first website_pageview_id for relevant sessions
-- STEP 2: identify the landing page of each session
-- STEP 3: counting pageviews for each session, to identify "bounces"
-- STEP 4: summarizing total sessions and bounced session, by LP
*/

-- Calculate Bounce Rates
SELECT 
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview
FROM website_pageviews wp
JOIN website_sessions  ws
	ON wp.website_session_id = ws.website_session_id
WHERE wp.created_at < '2012-06-14'
GROUP BY wp.website_session_id;

CREATE TEMPORARY TABLE first_landing
SELECT 
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview
FROM website_pageviews wp
JOIN website_sessions  ws
	ON wp.website_session_id = ws.website_session_id
WHERE wp.created_at < '2012-06-14'
GROUP BY wp.website_session_id;

CREATE TEMPORARY TABLE sessions_w_landing_page
SELECT 
	fl.website_session_id,
    wp.pageview_url AS landing_page
FROM first_landing fl
LEFT JOIN website_pageviews wp
	ON fl.min_pageview = wp.website_pageview_id;

SELECT 
	sp.website_session_id,
    sp.landing_page,
    COUNT(wp.website_pageview_id) AS count_sessions
FROM sessions_w_landing_page sp
LEFT JOIN website_pageviews wp
	ON sp.website_session_id = wp.website_session_id
WHERE sp.landing_page = '/home'
GROUP BY sp.website_session_id,
		 sp.landing_page
HAVING COUNT(wp.website_pageview_id) = 1;

CREATE TEMPORARY TABLE bounced_sessions
SELECT 
	sp.website_session_id,
    sp.landing_page,
    COUNT(wp.website_pageview_id) AS count_sessions
FROM sessions_w_landing_page sp
LEFT JOIN website_pageviews wp
	ON sp.website_session_id = wp.website_session_id
WHERE sp.landing_page = '/home'
GROUP BY sp.website_session_id,
		 sp.landing_page
HAVING COUNT(wp.website_pageview_id) = 1;

SELECT 
	sp.landing_page,
    COUNT(DISTINCT sp.website_session_id) AS sessions,
    COUNT(DISTINCT bs.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bs.website_session_id) / COUNT(DISTINCT sp.website_session_id) AS bounce_rate
FROM sessions_w_landing_page sp
LEFT JOIN bounced_sessions bs
	ON sp.website_session_id = bs.website_session_id
WHERE sp.landing_page = '/home'
GROUP BY sp.landing_page;
-- Conclusion: The bounce rate is 0.5918, almost 60%. A custom landing page will be set up and AB test 
-- 			   will be conducted to see if the new page does better. 

-- Analyzing Landing Page Tests
-- Pull bounce rates for the two groups
-- STEP 0: find out when the new page / lander launched
SELECT 
	MIN(created_at) AS first_created_at,
    website_pageview_id AS first_pageview_id
FROM website_pageviews
WHERE pageview_url = '/lander-1'
GROUP BY website_pageview_id
ORDER BY created_at ASC;

-- STEP 1: finding the first website_pageview_id for relevant sessions
SELECT 
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS ab_min_pageview
FROM website_pageviews wp
JOIN website_sessions ws
	ON wp.website_session_id = ws.website_session_id
WHERE wp.created_at BETWEEN '2012-06-19' AND '2012-07-28'
	AND wp.website_pageview_id > 23504
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY wp.website_session_id;

CREATE TEMPORARY TABLE ab_first_entry
SELECT 
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS ab_min_pageview
FROM website_pageviews wp
JOIN website_sessions ws
	ON wp.website_session_id = ws.website_session_id
WHERE wp.created_at BETWEEN '2012-06-19' AND '2012-07-28'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY wp.website_session_id;

-- STEP 2: indentifying the landing page of each session
SELECT 
	afb.website_session_id,
    wp.pageview_url AS landing_page
FROM ab_first_entry afb
LEFT JOIN website_pageviews wp
	ON afb.ab_min_pageview = wp.website_pageview_id;

CREATE TEMPORARY TABLE nonbrand_sessions_with_landing_page
SELECT 
	afb.website_session_id,
    wp.pageview_url AS landing_page
FROM ab_first_entry afb
LEFT JOIN website_pageviews wp
	ON afb.ab_min_pageview = wp.website_pageview_id;

-- STEP 3: counting pageviews for each session, to identify "bounces"
SELECT 
	sp.website_session_id,
    sp.landing_page,
    COUNT(wp.website_pageview_id) AS count_sessions
FROM nonbrand_sessions_with_landing_page sp
LEFT JOIN website_pageviews wp
	ON sp.website_session_id = wp.website_session_id
GROUP BY sp.website_session_id,
		 sp.landing_page
HAVING COUNT(wp.website_pageview_id) = 1;

CREATE TEMPORARY TABLE nonbrand_bounced_sessions
SELECT 
	sp.website_session_id,
    sp.landing_page,
    COUNT(wp.website_pageview_id) AS count_sessions
FROM nonbrand_sessions_with_landing_page sp
LEFT JOIN website_pageviews wp
	ON sp.website_session_id = wp.website_session_id
GROUP BY sp.website_session_id,
		 sp.landing_page
HAVING COUNT(wp.website_pageview_id) = 1;

-- STEP 4: summarizing total sessions and bounced sessions, by landing page
SELECT 
	sp.landing_page,
    sp.website_session_id,
    bs.website_session_id
	-- COUNT(DISTINCT sp.website_session_id) AS total_sessions,
    -- COUNT(DISTINCT bs.website_session_id) AS bounced_sessions
    -- COUNT(DISTINCT bs.website_session_id)/COUNT(DISTINCT sp.website_session_id) AS bounce_rate
FROM nonbrand_sessions_with_landing_page sp
LEFT JOIN nonbrand_bounced_sessions bs
	ON sp.website_session_id = bs.website_session_id
ORDER BY sp.website_session_id;

SELECT 
	sp.landing_page,
	COUNT(DISTINCT sp.website_session_id) AS total_sessions,
    COUNT(DISTINCT bs.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bs.website_session_id)/COUNT(DISTINCT sp.website_session_id) AS bounce_rate
FROM nonbrand_sessions_with_landing_page sp
LEFT JOIN nonbrand_bounced_sessions bs
	ON sp.website_session_id = bs.website_session_id
GROUP BY sp.landing_page;
-- Conclusion: The customer landing page has a lower bounce rate, which is 0.53218. Confirm that traffic 
--             is all running to the new custom lander after campaign updates.

-- Landing Page Trend Analysis
-- Pull the volume of paid search nonbrand traffic landing on /home and /lander 1, trended weekly confirm 
-- the traffic is all routed correctly.  Also pull overall paid search bounce rate trended weekly.
-- STEP 1: finding the first website_pageview_id for relevant sessions
SELECT 
	wp.website_session_id,
	MIN(website_pageview_id) AS first_website_pageview_id,
    COUNT(wp.website_pageview_id) AS count_pageviews
FROM website_pageviews wp
JOIN website_sessions ws
	ON wp.website_session_id = ws.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    AND wp.created_at BETWEEN '2012-06-01' AND '2012-08-31'
GROUP BY wp.website_session_id;

CREATE TEMPORARY TABLE first_website_pageview
SELECT 
	wp.website_session_id,
	MIN(website_pageview_id) AS first_website_pageview_id,
    COUNT(wp.website_pageview_id) AS count_pageviews
FROM website_pageviews wp
JOIN website_sessions ws
	ON wp.website_session_id = ws.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    AND wp.created_at BETWEEN '2012-06-01' AND '2012-08-31'
GROUP BY wp.website_session_id;

-- STEP 2: indentifying the landing page of each session
SELECT 
	fwp.website_session_id, 
    fwp.first_website_pageview_id,
    fwp.count_pageviews,
    wp.pageview_url AS landing_page,
    wp.created_at AS session_created_at
FROM first_website_pageview fwp
LEFT JOIN website_pageviews wp
	ON fwp.first_website_pageview_id = wp.website_pageview_id;

CREATE TEMPORARY TABLE session_landing_page
SELECT 
	fwp.website_session_id, 
    fwp.first_website_pageview_id,
    fwp.count_pageviews,
    wp.pageview_url AS landing_page,
    wp.created_at AS session_created_at
FROM first_website_pageview fwp
LEFT JOIN website_pageviews wp
	ON fwp.first_website_pageview_id = wp.website_pageview_id;
    
-- STEP 3: summarizing by week (bounce rate, sessions to each lander)
SELECT
	-- YEARWEEK(session_created_at) AS year_week,
    MIN(DATE(session_created_at)) AS week_start_date,
    -- COUNT(DISTINCT website_session_id) AS total_sessions,
    -- COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
	COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT website_session_id) AS bounce_rate,
    COUNT(DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
    COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
FROM session_landing_page
GROUP BY YEARWEEK(session_created_at);
-- Conclusion: The overall bounce rate has come down over time.

/*
Building Conversion Funnels & Testing Conversion Paths

Conversion funnel analysis is about understanding and optimizing 
step of your user's experience on their journey toward purchasing 
your products.

Common Use Cases: 1) Identifying the most common paths customers take before
					 purchasing your products
				  2) Identifying how many of your users continue on to each 
                     next step in your conversion flow, and how many users 
                     abandon at each step
				  3) Optimizing critical pain points where users are abandoning, 
                     so that you can convert more users and sell more products
                     
Conversion Funnels: 1) We will create temporary tables using pageview data in order
						to build our multi-step funnels
					2) We will first identify the sessions we care about, then bring the
					   relevant pageviews, then flag each session as having made it to
                       to certain funnel steps. and finally perform a summary analysis

-- BUSINESS CONTEXT
	-- we want to build a mini conversion funnel, from /lander-2 to /cart
    -- we want to know how many people reach each step, and also dropoff rates

-- STEP 1: select all pageviews for relevant sessions
-- STEP 2: identify each relevant pageview as the specific funnel step
-- STEP 3: create the session-level conversion funnel view
-- STEP 4: aggregate the data to assess funnel perfomance
*/

-- Building Conversion Funnels
-- Analyzing how many customers make it to each step
SELECT 
	ws.website_session_id,
    wp.pageview_url,
    CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions ws
LEFT JOIN website_pageviews wp
	ON ws.website_session_id = wp.website_session_id
WHERE ws.created_at BETWEEN '2012-08-05' AND '2012-09-05'
	AND ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand'
    AND wp.pageview_url IN ( '/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
ORDER BY ws.website_session_id,
		 wp.created_at;

SELECT 
	website_session_id, 
    MAX(products_page) AS products_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT 
	ws.website_session_id,
    wp.pageview_url,
    CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions ws
LEFT JOIN website_pageviews wp
	ON ws.website_session_id = wp.website_session_id
WHERE ws.created_at BETWEEN '2012-08-05' AND '2012-09-05'
	AND ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand'
    AND wp.pageview_url IN ( '/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
ORDER BY ws.website_session_id,
		 wp.created_at
) AS pageview_level
GROUP BY website_session_id;

CREATE TEMPORARY TABLE conversion_funnel
SELECT 
	website_session_id, 
    MAX(products_page) AS products_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT 
	ws.website_session_id,
    wp.pageview_url,
    CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions ws
LEFT JOIN website_pageviews wp
	ON ws.website_session_id = wp.website_session_id
WHERE ws.created_at BETWEEN '2012-08-05' AND '2012-09-05'
	AND ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand'
    AND wp.pageview_url IN ( '/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
ORDER BY ws.website_session_id,
		 wp.created_at
) AS pageview_level
GROUP BY website_session_id;

SELECT 
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM conversion_funnel;

SELECT 
    COUNT(CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END)
    / COUNT(DISTINCT website_session_id) AS lander_click_rt,
    COUNT(CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) 
    / COUNT(CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS product_click_rt,
    COUNT(CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)
    /  COUNT(CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,
    COUNT(CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)
    / COUNT(CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
    COUNT(CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)
    / COUNT(CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
    COUNT(CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)
    / COUNT(CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM conversion_funnel_demo;
-- Conclusion: It looks like we should focus on the lander (0.4709), Mr. Fuzzy page (0.4352) ,
--             and the billing page(0.4361), which have the lowest click rates.  A new billing page test
-- 			   and then analyze its performance.

-- Analyzing Conversion Funnel Tests
-- See whether /billing 2 is doing any better than the original /billing page
-- first, finding the starting point to frame the analysis
SELECT 
	MIN(created_at) AS first_created_at,
    53550 AS first_pv_id
FROM website_pageviews
WHERE pageview_url = '/billing-2';

SELECT 
	wp.website_session_id,
    wp.pageview_url AS billing_version_seen,
    o.order_id
FROM website_pageviews wp
LEFT JOIN orders o
	ON wp.website_session_id = o.website_session_id 
WHERE wp.created_at < '2012-11-10'
	AND wp.website_pageview_id >= 53550
    AND pageview_url IN ('/billing-2', '/billing');

 -- Then, wrapping as a subquery and summarizing  
 SELECT 
	billing_version_seen,
    COUNT(DISTINCT website_session_id) AS seesions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS billing_to_order_rt
FROM (
SELECT 
	wp.website_session_id,
    wp.pageview_url AS billing_version_seen,
    o.order_id
FROM website_pageviews wp
LEFT JOIN orders o
	ON wp.website_session_id = o.website_session_id 
WHERE wp.created_at < '2012-11-10'
	AND wp.website_pageview_id >= 53550
    AND pageview_url IN ('/billing-2', '/billing')
) AS billing_sessions_w_orders
GROUP BY
	billing_version_seen;
 
SELECT
	website_session_id,
    pageview_url,
    MAX(billing_page) AS to_billing,
	MAX(billing2_page) AS to_billing2,
	MAX(thankyou_page) AS to_thankyou
FROM (
SELECT 
	ws.website_session_id,
    wp.pageview_url,
    CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN wp.pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing2_page,
    CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions ws
LEFT JOIN website_pageviews wp
	ON ws.website_session_id = wp.website_session_id 
WHERE ws.created_at BETWEEN '2012-09-10' AND '2012-11-10'
	AND wp.website_pageview_id >= 53550
    AND pageview_url IN ('/billing-2', '/billing', '/thank-you-for-your-order')
ORDER BY 
	ws.website_session_id,
    wp.pageview_url
) AS flag_page_demo
GROUP BY
	website_session_id,
    pageview_url;
-- Conclusion: The new version of the billing page is doing a much better job converting customers, with a
--             click rate of 0.6269, while the original billing page is 0.4566.




