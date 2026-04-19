-- ﻿구매로 이어지는 페이지별 CVR
with base_path as (
select 
user,
event_ts,
event_name,
-- 구매한 것은 purchase로 분류
case when event_name='purchase' 
then 'purchase' 
-- 제품의 상세 정보 본 것은 url이 너무 다양 --> event_name='view_item'인 것을 조건으로 함
when event_name='view_item' and url not like '%asearch%'
then 'detail'
-- 마지막에 quickview로 끝나면 quickview로 분류
when event_name='page_view' and regexp_contains(url, r'(?i)quickview$')
then 'quickview'
-- 마지막에 asearch로 끝나면 search로 분류
when  event_name='page_view' and regexp_contains(url, r'(?i)asearch$')
then 'search' 
-- 상품들이 목록 형태로 나열된 화면 
when event_name='page_view' -- event_name='page_view'이면서
-- and url is not null 
and url not like '%+%' -- url에 '+'가 포함되지 않은 것(이것은 detail에 해당)이면서
and NOT REGEXP_CONTAINS(url, r'(?i)quickview[.]?$') -- url이 'quickview'로 끝나지 않는 것이면서(이것은 quickview에 해당)
-- and url NOT LIKE '% %' -- url에 공백이 없는 것
then 'list'
else 'other' end as path
from `funnel-analysis-490904.ga4_analysis.mart_ga4_refined`
),

-- 역순 누적합으로 '구매 그룹' 생성 (같은 사용자가 여러 번 구매를 한 경우 대비)
grouped_path AS (
  SELECT *,
    SUM(CASE WHEN path = 'purchase' THEN 1 ELSE 0 END) 
    OVER(PARTITION BY user ORDER BY event_ts DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS purchase_group
  FROM base_path
),

-- 각 그룹별 구매 시점 찾기(구매 전 2일 이내만 가져올 거기 때문) 및 구매한 집단에 플래그 추가(편의성 위해)
conversion_flag_logic AS (
  SELECT *,
    -- 구매가 발생한 그룹인지 확인
    SIGN(purchase_group) AS has_conversion,
    -- 해당 구매 그룹의 가장 최신 시점(구매 시점)을 가져옴
    MAX(event_ts) OVER(PARTITION BY user, purchase_group) AS group_purchase_ts
  FROM grouped_path
),

-- 구매 전 2일 이내만
real_conversion_flag as (
select
user,
purchase_group,
event_ts,
path,
has_conversion,
-- 이틀(48시간) 이내인지 여부 계산 
CASE WHEN (group_purchase_ts - event_ts) <= (2 * 24 * 60 * 60 * 1000000) THEN 1 ELSE 0 END AS is_within_2_days
from conversion_flag_logic 
where path != 'other' -- 상세, 검색, 퀵뷰, 구매만 남김
AND (group_purchase_ts - event_ts) <= (2 * 24 * 60 * 60 * 1000000) -- 이틀 이내 필터
ORDER BY user, event_ts ASC
)

-- 결과 확인
-- select *
-- from real_conversion_flag
-- where has_conversion>0

-- 경로(페이지)별 CVR 계산
SELECT
  path, 
  -- 분모: 이 페이지를 '한 번이라도' 본 구매 그룹의 수
  COUNT(DISTINCT CONCAT(user, purchase_group)) AS path_visit_groups,
  
  -- 분자: 그중에서 실제로 구매(has_conversion=1)까지 이어진 그룹의 수
  COUNT(DISTINCT CASE WHEN has_conversion > 0 THEN CONCAT(user, purchase_group) END) AS conversion_groups,
  
  -- CVR 계산
  round(1.0 * COUNT(DISTINCT CASE WHEN has_conversion > 0 THEN CONCAT(user, purchase_group) END) 
      / COUNT(DISTINCT CONCAT(user, purchase_group)),3) AS cvr
FROM real_conversion_flag
GROUP BY path 
ORDER BY cvr desc
