/* STEP 1: Data Extraction (a1)
   - Selecting the raw phone numbers alongside the lead ID.
*/
with a1 as (select 
lead_id
,phone_number
from messy_leads ml)
,
	/* STEP 2: Cleansing & Extraction (a2)
	   - REPLACE(phone_number, '-', '') removes all hyphens.
	   - The outer REPLACE(..., ' ', '') removes all spaces from the result.
	   - RIGHT(..., 9) extracts exactly the 9 core digits, effectively ignoring any 
	     preceding country codes like '+48' or '0048'.
	*/
	a2 as (select 
	lead_id
	,right(replace(replace(phone_number,"-","")," ",""),9) as clean_number
	from a1)
		/* STEP 3: Final Output
		   - Reviewing the transformation side-by-side.
		*/
		select * from a2