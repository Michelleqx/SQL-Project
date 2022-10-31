USE mavenfuzzyfactory;

## Section: Analyzing Traffic Sources
/* 
Traffic source analysis is about understanding where your customers are
coming from and which channels are driving the highest quality traffic.

Common use cases: 1) Analyzing search data and shifting budeget towards 
                     the engines, campaigns or keywords driving the strongest
                     conversion rates
				  2) Comparing user behavior patterns across traffic sources
                     to inform creative and messaging strategy
				  3) Identifying opportunities to eliminate wasted spend or
                     scale high-converting traffic
*/

-- use GROUP BY/COUNT/SUM to identify drivers

-- Finding Top Traffic Resources 
SELECT
	utm_source,
	utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY 
	utm_source, 
    utm_campaign,  
    http_referer
ORDER BY sessions DESC;
-- Conclusion: Next, we need to drill deeper into gsearch nonbrand campaign traffic to explore 
-- 			   potential optimization opportunities

-- Calculate the conversion rate (CVR) from session to order
SELECT 
	COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
	COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rate
FROM website_sessions ws
LEFT JOIN orders o
	ON o.website_session_id = ws.website_session_id
WHERE ws.created_at < '2012-04-14'
	AND ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand';
-- Conclusion: The conversion rate is 0.0288, below the 4% threshold we need to make the economics work.
-- 			   Next, we need to reduce the bid and monitor its impact.

## Section: Bid Optimization and Trend Analysis
/*
Analyzing for bid optimization is about understanding the value of various segments of paid traffic, 
so that you can optimize your marketing budget.

Common Use Cases: 1) Using conversion rate and revenue per click analyses to 
					 out how much you should spend per click to acquire customers
				  2) Understanding how your website and products perform for various 
 					 subsegments of traffic (i.e. mobile vs desktop) to optimize within channels
				  3) Analyzing the impact that bid changes have on your ranking in the 
					 auctions, and the valume of customers driven to your site
*/

-- Traffic Source Trending
-- Pull gsearch nonbrand trended session volume, by week
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
	COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-05-10'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);
-- Conclusion: The sessions drop down from 621 to 399, and it looks like gsearch nonbrand 
-- 			   is sensitive to bid changes. Think about how we could make the campaigns
--             more efficient so that we can increase volume again

-- Bid Optimization for Paid Traffic
-- Pull conversion rates from session to order , by device type
SELECT 
	ws.device_type,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rate
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-05-11'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY ws.device_type;
-- Conclusion: Conversion rate is 0.0373 for desktop and 0.0096 for mobile, so we shold increase bids
-- 			   on desktop.  Next, we need to analyze volume by device type to see if the bid changes make 
--             a material impact.

-- Trending w/ Granular Segments
-- Pull weekly trends for both desktop and mobile so we can see the impact on volume
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS dtop_sessions,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mob_sessions
FROM website_sessions 
WHERE created_at >= '2012-04-15' 
	AND created_at < '2012-06-09'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 
	WEEK(created_at);
-- Conclusion: Desktop is looking strong.  Things are moving in the right direction.  We need to continue 
--  		   to monitor conversion performance at the device level to optimize spend.













