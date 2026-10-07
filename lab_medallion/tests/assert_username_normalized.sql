-- Exercise 1: the normalized username must be lowercase and trimmed
select
    user_id,
    username,
    username_normalized
from {{ ref('stg_users') }}
where username_normalized <> lower(trim(username_normalized))
