select
	"TRIP/EATS ID" as trip_eats_id,
	try_to_timestamp("Transaction Timestamp (UTC)", 'MM/DD/YY HH24:MI') as transaction_timestamp_utc,
	try_to_date("Request Date (UTC)", 'MM/DD/YY') as request_date_utc,
	"Request Time (UTC)" as request_time_utc,
	try_to_date("Request Date (Local)", 'MM/DD/YY') as request_date_local,
	"Request Time (Local)" as request_time_local,
	"Request Type" as request_type,
	try_to_date("Pickup Date (UTC)", 'MM/DD/YY') as pickup_date_utc,
	"Pickup Time (UTC)" as pickup_time_utc,
	try_to_date("Pickup Date (Local)", 'MM/DD/YY') as pickup_date_local,
	"Pickup Time (Local)" as pickup_time_local,
	try_to_date("Drop-off Date (UTC)", 'MM/DD/YY') as drop_off_date_utc,
	"Drop-off Time (UTC)" as drop_off_time_utc,
	try_to_date("Drop-off Date (Local)", 'MM/DD/YY') as drop_off_date_local,
	"Drop-off Time (Local)" as drop_off_time_local,
	"Request Timezone Offset from UTC" as request_timezone_offset_from_utc,
	"First Name" as first_name,
	"Last Name" as last_name,
	"Email" as email,
	"Employee ID" as employee_id,
	"Service" as service,
	"City" as city,
	"Distance (mi)" as distance_mi,
	"Haversine Distance (mi)" as haversine_distance_mi,
	"Duration (min)" as duration_min,
	"Pickup Address" as pickup_address,
	"Pickup Latitude" as pickup_latitude,
	"Pickup Longitude" as pickup_longitude,
	"Drop-off Address" as drop_off_address,
	"Drop Off Latitude" as drop_off_latitude,
	"Drop Off Longitude" as drop_off_longitude,
	"Ride Status" as ride_status,
	"Expense Code" as expense_code,
	"Expense Memo" as expense_memo,
	"Invoices" as invoices,
	"Program" as program,
	"Group" as "group",
	"Payment Method" as payment_method,
	--"Transaction Type" as transaction_type,
	sum(
		to_decimal(
			iff("Fare in Local Currency (excl. Taxes)" = '--', 0, "Fare in Local Currency (excl. Taxes)"),
			10, 2
		)
	) as fare_in_local_currency_excl__taxes,
	"Taxes in Local Currency" as taxes_in_local_currency,
	"Tip in Local Currency" as tip_in_local_currency,
	sum(
		to_decimal(
			iff("Transaction Amount in Local Currency (incl. Taxes)" = '--', 0, "Transaction Amount in Local Currency (incl. Taxes)"),
			10, 2
		)
	) as transaction_amount_in_local_currency_incl__taxes,
	"Local Currency Code" as local_currency_code,
	sum(
		to_decimal(
			iff("Fare in USD (excl. Taxes)" = '--', 0, "Fare in USD (excl. Taxes)"),
			10, 2
		)
	) as fare_in_usd_excl__taxes,
	"Taxes in USD" as taxes_in_usd,
	"Tip in USD" as tip_in_usd,
	sum(
		to_decimal(
			iff("Transaction Amount in USD (incl. Taxes)" = '--', 0, "Transaction Amount in USD (incl. Taxes)"),
			10, 2
		)
	) as transaction_amount_in_usd_incl__taxes,
	"Estimated Service and Technology Fee (incl. Taxes, if any) in USD" as "ESTIMATED_SERVICE_AND_TECHNOLOGY_FEE_INCL__TAXES,_IF_ANY_IN_USD",
	"Health Dashboard URL" as health_dashboard_url,
	"Invoice Number" as invoice_number,
	"Driver First Name" as driver_first_name,
	"Guest First Name" as guest_first_name,
	"Guest Last Name" as guest_last_name,
	"Guest Phone Number" as guest_phone_number,
	sum(
		to_decimal(
			iff("Deductions in Local Currency" = '--', 0, "Deductions in Local Currency"),
			10, 2
		)
	) as deductions_in_local_currency,
	"Member ID" as member_id,
	"Plan ID" as plan_id,
	"Network Transaction Id" as network_transaction_id,
	"IsGroupOrder" as isgrouporder,
	"Fulfilment Type" as fulfilment_type,
	"Country" as country,
	"Cancellation type" as cancellation_type,
	"Membership Savings(Local Currency)" as membership_savingslocal_currency,
	"Granular Service Purpose Type" as granular_service_purpose_type,
	regexp_substr("_AB_SOURCE_FILE_URL", 'transactions/(.+)', 1, 1, 'e', 1) src_file_name
from airbyte_source_prod.uber.transactions
where lower("Transaction Type") <> 'payment'
group by all