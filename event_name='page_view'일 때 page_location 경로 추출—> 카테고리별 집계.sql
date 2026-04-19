-- ﻿목적: 사용자가 페이지를 보고 있을 때 찍힌 url을 그룹화하여 어떤 경로를 많이 보는지 확인
with cate as (
select regexp_extract(url, r'/([^/]+)') as category,
regexp_extract(url, r'^/[^/]+/([^/]+)') as sub_category
from `funnel-analysis-490904.ga4_analysis.mart_ga4_refined`
)

select lower(replace(category,'+',' ')) as category, count(*) as cnt
from cate
where category not in ('shop.axd', 'store-policies', 'html') -- 기술/정책 페이지 제외
group by 1
order by 2 desc
