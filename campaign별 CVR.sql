WITH base AS (
  SELECT 
    user_pseudo_id,
    event_name,
    event_timestamp,
    event_date,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key='ga_session_id') as session,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key='campaign') as campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),

-- 1. 캠페인 유입 기준점 추출 (중복 유입 허용)
target_events AS (
  SELECT 
    user_pseudo_id,
    campaign AS first_campaign,
    MIN(event_timestamp) AS campaign_ts,
    MIN(event_date) AS campaign_date
  FROM base
  WHERE campaign IN ('Data Share Promo','NewYear_V1','Holiday_V2','NewYear_V2','BlackFriday_V2','Holiday_V1','BlackFriday_V1')
  GROUP BY 1, 2
),

-- 2.'세션' 단위로 압축
session as (
SELECT 
  t.user_pseudo_id,
  b.session,
  t.first_campaign,
  t.campaign_date,
  b.event_date,
  -- 7일 이내에 해당 유저가 purchase를 한 기록이 하나라도 있다면 1
  MAX(CASE WHEN b.event_name = 'purchase' THEN 1 ELSE 0 END) AS flag
FROM target_events t
-- 캠페인 유입 시점(campaign_ts) 이후 7일 이내의 모든 활동(b)을 가져옴
JOIN base b ON t.user_pseudo_id = b.user_pseudo_id
WHERE b.event_timestamp BETWEEN t.campaign_ts AND (t.campaign_ts + 7 * 24 * 60 * 60 * 1000000)
GROUP BY 1,2,3,4,5
ORDER BY flag DESC, t.user_pseudo_id, b.event_date)

-- 3. CVR 계산 
SELECT 
first_campaign as campaign, 
COUNT(*)as session_count, 
COUNTIF(flag=1)as conversion,
round(AVG(flag),2)as cvr
FROM session
GROUP BY 1
ORDER BY 4 desc,1
