--﻿ 전처리 및 데이터 마트 구축
create or replace table `funnel-analysis-490904.ga4_analysis.mart_ga4_refined` as
with base as (
select 
user_pseudo_id as user,
(select value.int_value from unnest(event_params) where key='ga_session_id')as session,
event_timestamp as event_ts,
event_name,
(select value.string_value from unnest(event_params) where key='page_location')as url
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),

-- 전처리 1
clean_base1 as(
select
user,
session,
event_ts,
event_name,
-- 첫 번째 http부터 시작해서, 두 번째 http가 나오기 직전까지의 글자만 추출(정규표현식 이용)
-- '.html' 삭제(replace 이용)
-- 제일 앞과 뒤의 공백 제거(trim 이용)
trim(replace(REGEXP_EXTRACT(url, r'(https?://.*?)(?:https?://|$)'),'.html','')) AS url
FROM base
),

-- 전처리 2
clean_base2 as (
SELECT 
user,
session,
event_ts,
event_name,
  CASE 
    WHEN REGEXP_CONTAINS(url, r'(?i)shop[+ _-]by([+ _-]brand)?') 
      THEN REGEXP_REPLACE(url, r'(?i)(shop)[+ _-](by)([+ _-](brand))?', r'\1\2\4')
      
    WHEN REGEXP_CONTAINS(url, r'(?i)eco[+ _-]friendly') 
      THEN REGEXP_REPLACE(url, r'(?i)(eco)[+ _-](friendly)', r'\1\2')
      
    WHEN REGEXP_CONTAINS(url, r'(?i)campus[+ _-]') 
      THEN REGEXP_REPLACE(url, r'(?i)(campus)[+ _-]', r'\1')
      
    WHEN REGEXP_CONTAINS(url, r'(?i)gift[+ _-]cards?') 
      THEN REGEXP_REPLACE(url, r'(?i)(gift)[+ _-](cards?)', r'\1\2')
      
    WHEN REGEXP_CONTAINS(url, r'(?i)google[+ _-]maps?') 
      THEN REGEXP_REPLACE(url, r'(?i)(google)[+ _-](maps?)', r'\1\2')
      
    ELSE url 
  END AS url
from clean_base1
),

-- 전처리 3
clean_base3 as (
select 
user,
session,
event_ts,
event_name,
case when regexp_contains(url, r'(?i)google[+ ]redesign')
then regexp_extract(url, r'design(.*)')
else regexp_extract(url, '.com(.*)') end as url
from clean_base2
)

select *
from clean_base3
where url is not null
