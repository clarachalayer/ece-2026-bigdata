-- A user cannot order before being born: the test fails if this query returns rows
-- Exercise 3: invalid birthdates are replaced with NULL in stg_users, the test is blocking again
select
    o.order_id,
    o.ordered_at,
    u.user_id,
    u.birthdate,
    u.birthdate_is_valid
from {{ ref('stg_orders') }} o
join {{ ref('stg_users') }} u on o.user_id = u.user_id
where o.ordered_at < u.birthdate
