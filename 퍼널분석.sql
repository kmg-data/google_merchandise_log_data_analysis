-- 퍼널분석
with base_step as (
select 1 as step,'session_start' as step_name,
union all select 2 as step,'view_item_list' as step_name,
union all select 3 as step,'view_item' as step_name,
union all select 4 as step,'add_to_cart' as step_name,
union all select 5 as step,'begin_checkout' as step_name,
union all select 6 as step,'purchase' as step_name),

base_event as (
select 
user,
session,
-- session_start
case when event_name='session_start'
then 'session_start'
-- view_item_list
when event_name='page_view' -- event_name='page_view'이면서
and url not like '%+%' -- url에 '+'가 포함되지 않은 것(이것은 view_item에 해당)이면서
and NOT REGEXP_CONTAINS(url, r'(?i)quickview[.]?$') -- url이 'quickview'로 끝나지 않는 것이면서(이것은 quickview에 해당)
then 'view_item_list'
-- view_item
when event_name='view_item' and url not like '%asearch%'
then 'view_item'
-- add_to_cart
when event_name='add_to_cart' 
then 'add_to_cart'
-- begin_checkout
when event_name='begin_checkout' 
then 'begin_checkout'
-- purchase
when event_name='purchase' 
then 'purchase'
end as event
from `funnel-analysis-490904.ga4_analysis.mart_ga4_refined`
),

base_flag as (
select
user,
session, 
step,
step_name,
sign(sum(case when event=step_name then 1 else 0 end))as flag
from base_event
cross join base_step
group by 1,2,3,4
)

-- 확인
-- select *
-- from base_flag
-- order by user, session, step

-- funnel 분석
select 
step,
step_name,
-- 해당 단계에 도달한 세션 수
sum(flag)as step_cnt,
-- 전체 세션 수
COUNT(*) AS total_sessions,
-- 퍼널 도달률
round(avg(100.0 * flag),3) as funnel_rate
from base_flag
group by step, step_name
order by step
