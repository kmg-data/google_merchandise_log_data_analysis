-- ﻿의류 카테고리의 하위 카테고리 집계
with base as(select urlfrom `funnel-analysis-490904.ga4_analysis.mart_ga4_refined`where event_name='page_view')select lower(regexp_extract(url, r'(?i)apparel/([^/]*)')) as apparel_url, count(*)as cntfrom basewhere url is not null and url not like '%+%' and regexp_contains(url, r'(?i)apparel/')group by 1order by 2 descwith page_location as (
select (select value.string_value from unnest(event_params) where key='page_location')as url
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name='page_view'),

cate as (
select lower(regexp_extract(url, r'[Aa]pparel/([^/]*)')) as row_category from page_location)

select category, count(*) as cnt
from(select case 
when regexp_contains(row_category, 'women') then 'womens'
when regexp_contains(row_category, 'men') then 'mens'
when regexp_contains(row_category, 'unisex') then 'unisex'
when regexp_contains(row_category, r'(?i)kids|toddler|infant|youth') then 'kids'
when regexp_contains(row_category, r'(?i)hat|headgear|beanie') then 'hats'
when regexp_contains(row_category, 'socks') then 'socks'
when regexp_contains(row_category, r'(?i)accessories|Lanyards|Patches|Pins|Shoelaces|Sunglasses|Zipper Pulls') then 'accessories'
else row_category end as category
from cate)
where category is not null
group by 1
order by 2 desc
limit 6
