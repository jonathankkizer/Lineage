---- There is currently a bug in Carenet's daily extract due to repeating assessment and question mappings
---- The 'core' fields around date, time, and number of phone calls are not impacted
---- For basic info around number of calls, use files ending in "..._1.xml", for more details use "..._2.xml"

with raw as (
    select
        data['record_index']            as record_index,
        data['source_file']             as source_file,
        parse_xml(data['xml_content']::string) as xml_parsed
    from  airbyte_source_prod.carenet.carenet_daily_extract
    where regexp_substr(data['source_file']::string, '[0-9]{8}')::int >= 20260101
    and data['source_file'] ilike ('%_1.xml')
    and regexp_substr(data['source_file']::string, '[0-9]{8}') != '20260506'
),

base as (
    select distinct
        source_file,

        -- trx root attributes
        xml_parsed['@TransactionNumber']::string                                            as transaction_number,
        try_cast(xml_parsed['@TransactionStartTime']::string as timestamp)                  as transaction_start_time,
        try_cast(xml_parsed['@TransactionEndTime']::string as timestamp)                    as transaction_end_time,
        xml_parsed['@TrxStatus']::string                                                    as trx_status,
        xml_parsed['@ProfileName']::string                                                  as profile_name,
        xml_parsed['@ProfileAddress1']::string                                              as profile_address1,
        xml_parsed['@ProfileAddress2']::string                                              as profile_address2,
        xml_parsed['@ProfileCity']::string                                                  as profile_city,
        xml_parsed['@ProfileState']::string                                                 as profile_state,
        xml_parsed['@ProfileZip']::string                                                   as profile_zip,

        -- TrxDetail
        xmlget(xml_parsed, 'trxdetails')['@ServiceNumber']::string                           as service_number,
        try_cast(xmlget(xml_parsed, 'trxdetails')['@ServiceDateOpened']::string as timestamp) as service_date_opened,
        try_cast(xmlget(xml_parsed, 'trxdetails')['@ServiceDateClosed']::string as timestamp) as service_date_closed,
        xmlget(xml_parsed, 'trxdetails')['@userFName']::string                               as user_fname,
        xmlget(xml_parsed, 'trxdetails')['@userLName']::string                               as user_lname,
        xmlget(xml_parsed, 'trxdetails')['@ContactMethod']::string                           as contact_method,
        xmlget(xml_parsed, 'trxdetails')['@servicesProvided']::string                        as services_provided,
        xmlget(xml_parsed, 'trxdetails')['@ServiceType']::string                             as service_type,
        xmlget(xml_parsed, 'trxdetails')['@CallerFirstName']::string                         as caller_first_name,
        xmlget(xml_parsed, 'trxdetails')['@CallerLastName']::string                          as caller_last_name,
        xmlget(xml_parsed, 'trxdetails')['@callerType']::string                              as caller_type,

        -- contacts (nested inside trxdetails)
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@PatientFirstName']::string   as patient_first_name,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@PatientLastName']::string    as patient_last_name,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@PreferredName']::string      as preferred_name,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@Gender']::string             as gender,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@DOB']::string                as dob,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@Language']::string           as language,
        
    
    case
        when regexp_replace(xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@PhoneHome']::string, '[^0-9]', '') = '' then null
        when length(regexp_replace(xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@PhoneHome']::string, '[^0-9]', '')) = 11
            and left(regexp_replace(xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@PhoneHome']::string, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@PhoneHome']::string, '[^0-9]', ''), 10)
        when length(regexp_replace(xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@PhoneHome']::string, '[^0-9]', '')) = 10
            then regexp_replace(xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@PhoneHome']::string, '[^0-9]', '')
        else null
    end
          as patient_phone,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@InsuranceDesc']::string      as insurance_desc,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@MemberId']::string           as member_id,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@ExternalId']::string         as external_id,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@Address1']::string           as patient_address1,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@Address2']::string           as patient_address2,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@City']::string               as patient_city,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@State']::string              as patient_state,
        xmlget(xmlget(xml_parsed, 'trxdetails'), 'contacts')['@Zip']::string                as patient_zip,

    from raw
)

select * from base