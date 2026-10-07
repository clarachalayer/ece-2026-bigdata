with source as (
    select * from {{ source('bronze', 'users') }}
),

typed as (
    select
        cast(uuid as uuid) as user_id,
        trim(username) as username,
        -- Exercise 1: trimmed and lowercased username, for reliable comparisons
        lower(trim(username)) as username_normalized,
        trim(name) as name,
        upper(trim(sex)) as sex,
        lower(trim(mail)) as email,
        cast(birthdate as date) as birthdate,
        -- The address spans 2 lines: the street, then the city, the state and the zip code
        split_part(address, chr(10), 1) as street,
        split_part(address, chr(10), 2) as address_line_2
    from source
),

-- Exercise 3: date of the first order of each user, read from the bronze source
-- to keep the staging models independent from each other
first_orders as (
    select
        cast(user_uuid as uuid) as user_id,
        min(cast(date as timestamptz)) as first_ordered_at
    from {{ source('bronze', 'orders') }}
    group by 1
),

-- Exercise 3: a birthdate is valid if it is known and not after the first order
-- (or not in the future for the users without any order)
validated as (
    select
        t.*,
        t.birthdate is not null
            and t.birthdate <= coalesce(cast(f.first_ordered_at as date), current_date)
            as birthdate_is_valid
    from typed t
    left join first_orders f on t.user_id = f.user_id
)

select
    user_id,
    username,
    username_normalized, -- Exercise 1
    name,
    sex,
    email,
    -- Exercise 3: invalid birthdates are replaced with NULL
    case when birthdate_is_valid then birthdate end as birthdate,
    birthdate_is_valid, -- Exercise 3
    street,
    -- Military addresses, such as "DPO AE 12345", have no comma
    nullif(regexp_extract(address_line_2, '^(.+), [A-Z]{2} \d{5}$', 1), '') as city,
    regexp_extract(address_line_2, '([A-Z]{2}) (\d{5})$', 1) as state,
    regexp_extract(address_line_2, '([A-Z]{2}) (\d{5})$', 2) as zip_code
from validated
