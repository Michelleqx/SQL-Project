## Analyzing Business Patterns and Seasonality
/*
BUSINESS CONCEPT: ANALYZING SEASONALITY & BUSINESS PATTERNS
Analyzing business patterns is about generating insights to help you maximize
efficiency and anticipate future trends.

COMMON USE CASES: 1) Day-parting analysis to understand how much support staff 
				     you should have at different times of day or days of the week.
				  2) Analyzing seasonality to better prepare for upcoming spikes or 
                     slowdowns in demand.
Using DATE functions.
*/

-- ANALYZING SEASONALITY
-- Take a look at 2012’s monthly and weekly volume patterns to see if we can find any 
-- seasonal trends we should plan for in 2013. Pull session volume and order volume.
SELECT 
	YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE YEAR(ws.created_at) = '2012'
GROUP BY 
	YEAR(ws.created_at),
	MONTH(ws.created_at);
SELECT 
	MIN(DATE(ws.created_at)) AS week_start_date,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE YEAR(ws.created_at) = '2012'
GROUP BY 
	WEEK(ws.created_at);
-- Conclusion: The company grew fairly steadily all year, and saw significant volume around
-- 			   the holiday months (especially the weeks of Black Friday and Cyber Monday).

-- ANALYZING BUSINESS PATTERNS
-- Analyze the average website session volume, by hour of day and by day week
SELECT
    hr,
    AVG(website_sessions) AS avg_sessions,
    AVG(CASE WHEN wkday = 0 THEN website_sessions ELSE NULL END) AS 'mon',
    AVG(CASE WHEN wkday = 1 THEN website_sessions ELSE NULL END) AS 'tue',
    AVG(CASE WHEN wkday = 2 THEN website_sessions ELSE NULL END) AS 'wed',
    AVG(CASE WHEN wkday = 3 THEN website_sessions ELSE NULL END) AS 'thu',
    AVG(CASE WHEN wkday = 4 THEN website_sessions ELSE NULL END) AS 'fri',
    AVG(CASE WHEN wkday = 5 THEN website_sessions ELSE NULL END) AS 'sat',
    AVG(CASE WHEN wkday = 6 THEN website_sessions ELSE NULL END) AS 'sun'
FROM (
SELECT 
	DATE(created_at) AS created_date,
    WEEKDAY(created_at) AS wkday,
    HOUR(created_at) AS hr,
	COUNT(DISTINCT website_session_id) AS website_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY 1,2,3
) AS daily_hourly_sessions
GROUP BY hr
ORDER BY hr;
-- Conclusion: From the result, it seems like ~10 sessions per hour per employee staffed is
-- 			   about right. We can plan on one support staff around the clock and then we should 
-- 			   double up to two staff members from 8am to 5pm Monday through Friday.
