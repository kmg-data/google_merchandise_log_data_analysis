-- ﻿브랜드별로 선택하는 경로에서의 하위 카테고리 집계
with base as(
select url
from `funnel-analysis-490904.ga4_analysis.mart_ga4_refined`
where event_name='page_view'
)

select 
lower(regexp_extract(url, r'(?i)shopbybrand/([^/]*)')) as apparel_url, 
count(*)as cnt
from base
where url is not null 
-- and url not like '%+%' 
and regexp_contains(url, r'(?i)shopbybrand/')
group by 1
order by 2 desc
