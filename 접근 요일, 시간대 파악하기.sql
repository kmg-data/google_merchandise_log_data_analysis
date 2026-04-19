-- 접근 요일, 시간대 파악하기
with session_starts as (
  select 
    user_pseudo_id,
    (select value.int_value from unnest(event_params) where key = 'ga_session_id') as session_id,
    min(event_timestamp) as first_event_time
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  group by 1, 2
),

base as (
select first_event_time,
-- 마이크로초를 1,000,000으로 나눠서 '초' 단위로 시작
cast(floor(first_event_time / 1000000) as int64) as pure_seconds,
-- 일요일(1)부터 토요일(7)까지의 현지 시간 기준 요일 번호 추출하기
extract(dayofweek from datetime(timestamp_micros(first_event_time), 'America/Los_Angeles')) as day,
-- 시간 간격을 30분으로 지정
30*60 as interval_time
from session_starts
),

floor_seconds as (
select *,
-- event_timestamp를 interval_time으로 나누기
cast((floor(pure_seconds/interval_time)*interval_time) as int64) as floor_micros
from base
),

sec_index as (select first_event_time,
day,
-- 초를 다시 현지 시간(LA)으로 변환해서 타임스탬프 형식으로 변환하기
format_datetime('%H:%M:%S', datetime(timestamp_seconds(floor_micros), 'America/Los_Angeles')) as index_time
from floor_seconds
)

select 
  index_time,
  -- 요일 번호를 이름으로 변환 
  case day 
    when 1 then 'Sun' when 2 then 'Mon' when 3 then 'Tue' 
    when 4 then 'Wed' when 5 then 'Thu' when 6 then 'Fri' 
    when 7 then 'Sat' 
  end as day_name,
  -- 정렬용: 원래 요일 번호(1~7) 유지
  day as day_num,
  count(*) as event_count
from sec_index
group by 1,2,3
order by 1,3
