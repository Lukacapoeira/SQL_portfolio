/* STEP 1: JSON Extraction & Cleansing (a1)
   - JSON_EXTRACT reaches into the 'extra_info' column and targets the 'device' key.
   - The REPLACE function removes the double quotes ("") that JSON_EXTRACT leaves behind.
*/
with a1 as (
select 
replace(json_extract(extra_info, '$.device'), '"', '') as devices
from messy_leads ml)
	/* STEP 2: Aggregation
   - Grouping by the newly extracted 'devices' to count the user base per operating system.
	*/
	select
    devices
    ,count(*) as devices_number
	from a1
	group by 1
	order by devices_number desc