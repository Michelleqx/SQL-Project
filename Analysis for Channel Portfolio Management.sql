## Analysis For Channel Management
/*
Analyzing a portfolio of marketing channels is about bidding efficiently and
using data to maximize the effectiveness of your marketing budget.

COMMON USE CASES: 1) Understanding which marketing channels are driving the most sessions 
					 and orders through your website
				  2) Understanding differences in user characteristics and conversion performance
					 across marketing channels
				  3) Optimizing bids and allocating marketing spend across a multi-channel 
                     portfolio to achieve maximum performance

When businesses run paid marketing campaigns, they often obsess over performance and
measure everything ; how much they spend, how well traffic converts to sales, etc.

Paid traffic is commonly tagged with tracking (UTM) parameters, which are appended to
URLs and allow us to tie website activity back to specific traffic sources and campaigns.
*/

-- ANALYZING CHANNEL PORTFOLIOS
-- Pull weekly trended session volume of bsearch and compare to gsearch nonbrand
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
	COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-29'
	AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);
-- Conclusion: bsearch tends to get roughly a third the traffic of gsearch.

-- COMPARING CHANNEL CHARACTERISTICS
-- Pull the percentage of traffic coming on Mobile,and compare the bsearch nonbrand campaign to gsearch
SELECT 
	utm_source,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_session_id ELSE NULL END) 
    / COUNT(DISTINCT website_session_id) AS pct_mobile
FROM website_sessions
WHERE created_at BETWEEN "2012-08-22" AND "2012-11-30"
	AND utm_campaign = "nonbrand"
GROUP BY utm_source;
-- Conclusion: The percentage of traffic coming on mobile of bsearch is 0.0862, while gsearch is 0.2452.
-- 		 	   These channels are quite different from a device standpoint.

-- CROSS CHANNEL BID OPTIMIZATION
-- Pull nonbrand conversion rates from session to order for gsearch and bsearch, and slice the
-- data by device type.
SELECT 
	ws.device_type,
    ws.utm_source,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) /  COUNT(DISTINCT ws.website_session_id) AS conv_rate
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at BETWEEN "2012-08-22" AND "2012-09-19"
	AND ws.utm_campaign = "nonbrand"
GROUP BY 
	ws.device_type,
	ws.utm_source;
-- Conclusion: As conversion rates show, the channels don’t perform identically, so we
-- 			   should differentiate our bids in order to optimize our overall paid marketing budget.

-- CHANNEL PORTFOLIO TRENDS
-- Pull weekly session volume for gsearch and bsearch nonbrand, broken down by device, since November 4th
SELECT
	MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN utm_source = "gsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END) 
		AS g_dtop_sessions,
	COUNT(DISTINCT CASE WHEN utm_source = "bsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END) 
		AS b_dtop_sessions,
	COUNT(DISTINCT CASE WHEN utm_source = "bsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_source = "gsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END)
        AS b_pct_of_g_dtop,
	COUNT(DISTINCT CASE WHEN utm_source = "gsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END) 
		AS g_mob_sessions,
	COUNT(DISTINCT CASE WHEN utm_source = "bsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END) 
		AS b_mob_sessions,
	COUNT(DISTINCT CASE WHEN utm_source = "bsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN utm_source = "gsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END) 
        AS b_pct_of_g_mob
FROM website_sessions
WHERE created_at BETWEEN "2012-11-04" AND "2012-12-22"
	AND utm_campaign = "nonbrand"
GROUP BY WEEK(created_at);
-- Conclusion: bsearch traffic dropped off a bit after the bid down from 0.0896 to 0.0783.

/*
BUSINESS CONCEPT: ANALYZING DIRECT TRAFFIC
Analyzing your branded or direct traffic is about keeping a pulse on how well
your brand is doing with consumers, and how well your brand drives business.

COMMON USE CASES: 1) Identifying how much revenue you are generating from direct traffic 
					 – this is high margin revenue without a direct cost of customer acquisition
				  2) Understanding whether or not your paid traffic is generating a “halo” effect, 
                     and promoting additional direct traffic
				  3) Assessing the impact of various initiatives on
					 how many customers seek out your business

FREE TRAFFIC ANALYSIS: 1) To identify traffic coming to your site that you are not paying for
						  with marketing campaigns, we will again turn to our utm params

					   2) For non paid traffic (i.e. organic search, direct type in), we can
						  analyze data where the utm parameters are NULL
*/

-- ANALYZING FREE CHANNELS
-- Pull organic search, direct type in, and paid brand search sessions by month,and show those sessions
-- as a % of paid search nonbrand
SELECT 
    YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
	COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END) AS brand,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END)
        AS brand_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN http_referer IS NULL THEN website_session_id ELSE NULL END) AS direct,
    COUNT(DISTINCT CASE WHEN http_referer IS NULL THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END)
        AS direct_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN http_referer IS NOT NULL AND utm_source IS NULL THEN website_session_id ELSE NULL END) AS organic,
    COUNT(DISTINCT CASE WHEN http_referer IS NOT NULL AND utm_source IS NULL THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
FROM website_sessions
WHERE created_at < '2012-12-23'
GROUP BY YEAR(created_at),
         MONTH(created_at);
-- Conclusion: Looks like not only are our brand, direct, and organic volumes growing,but they are 
-- 			   growing as a percentage of our paid traffic volume.





