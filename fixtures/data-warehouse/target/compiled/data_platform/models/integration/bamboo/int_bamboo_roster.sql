-- =============================================================================
-- Purpose: Patient roster feed for the Bamboo Health integration. Provides
--          Bamboo with the demographic, insurance, provider, and practice
--          information needed to enroll and manage Suvida patients in their
--          platform. The schema of this model is formatted to match Bamboo
--          Health's required roster specification. Bamboo uses the patient data
--          in the roster to match against patient data received from admitting
--          facilities across their network. If there is a patient match, as
--          identified through Bamboo Health's matching algorithm, Suvida will
--          receive a Ping notifying end users about a patient's care event.
--
-- Content: One row per patient including identity, contact details, insurance,
--          attributed provider, and practice information. The following fields
--          are required by Bamboo Health for patient matching upon admission
--          and are tested for nullness: PATIENT_ID, PATIENT_FIRST_NAME,
--          PATIENT_LAST_NAME, PATIENT_DOB, and PATIENT_GENDER.
--
-- Grain:   One row per patient (suvida_id).
--
-- Filter:  Includes patients who are actively assigned to Suvida, plus
--          unassigned patients who have an upcoming care team appointment.
--          Excludes deceased patients.
-- =============================================================================

-- dim_provider can have multiple rows per NPI (e.g. providers with multiple location records). Deduplicate to ensure a 1:1 join
with dim_provider_deduped as (
    select *
    from dw_dev.dev_jkizer.dim_provider
    qualify row_number() over (partition by npi order by npi) = 1
)

select
    ps.suvida_id as PATIENT_ID,
    
    trim(
        regexp_replace(
            regexp_replace(
                regexp_replace(
                    regexp_replace(
                        translate(
                            ps.first_name,
                            'áàâãäåéèêëíìîïóòôõöúùûüýñÁÀÂÃÄÅÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÝÑçÇ',
                            'aaaaaaeeeeiiiiooooouuuuynAAAAAAEEEEIIIIOOOOOUUUUYNcC'
                        ),
                        '\\s*"[^"]*"', ''
                    ),
                    '\\s*\\([^)]*\\)', ''
                ),
                '\\d{1,2}/\\d{1,2}/\\d{4}', ''
            ),
            '\\s+', ' '
        )
    )
 as PATIENT_FIRST_NAME,
    ps.middle_initial as PATIENT_MIDDLE_INITIAL,
    
    trim(
        regexp_replace(
            regexp_replace(
                regexp_replace(
                    regexp_replace(
                        translate(
                            ps.last_name,
                            'áàâãäåéèêëíìîïóòôõöúùûüýñÁÀÂÃÄÅÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÝÑçÇ',
                            'aaaaaaeeeeiiiiooooouuuuynAAAAAAEEEEIIIIOOOOOUUUUYNcC'
                        ),
                        '\\s*"[^"]*"', ''
                    ),
                    '\\s*\\([^)]*\\)', ''
                ),
                '\\d{1,2}/\\d{1,2}/\\d{4}', ''
            ),
            '\\s+', ' '
        )
    )
 as PATIENT_LAST_NAME,
    null as PATIENT_SUFFIX,
    ps.birth_date as PATIENT_DOB,
    ps.gender as PATIENT_GENDER,
    null as PATIENT_SSN,
    ps.address_line_1 as PATIENT_ADDRESS_1,
    ps.address_line_2 as PATIENT_ADDRESS_2,
    ps.city as PATIENT_ADDRESS_CITY,
    ps.state as PATIENT_ADDRESS_STATE,
    ps.zip as PATIENT_ADDRESS_ZIP,
    coalesce(
        iff(ps.phone_type = 'Mobile', ps.phone, null),
        iff(ps.secondary_phone_type = 'Mobile', ps.secondary_phone, null)
    ) as PATIENT_PHONE_MOBILE,
    coalesce(
        iff(ps.phone_type != 'Mobile', ps.phone, null),
        iff(ps.secondary_phone_type != 'Mobile', ps.secondary_phone, null)
    ) as PATIENT_PHONE_HOME,
    ps.payer_name as INSURER_1,
    ps.payer_plan_name as INSURANCE_PLAN_1,
    ps.payer_member_id as INSURANCE_NUMBER_1,
    prov.user_first_name as ATTRIBUTED_PROVIDER_FIRST_NAME_1,
    prov.user_last_name as ATTRIBUTED_PROVIDER_LAST_NAME_1,
    prov.title as ATTRIBUTED_PROVIDER_HONORIFICS_1,
    ps.provider_npi as ATTRIBUTED_PROVIDER_NPI_1,
    null as ATTRIBUTED_PROVIDER_PHONE_1,
    null as ATTRIBUTED_PROVIDER_FAX_1,
    prov.user_email as ATTRIBUTED_PROVIDER_EMAIL_1,
    prov.provider_type as ATTRIBUTED_PROVIDER_TYPE_1,
    ps.location_name as PRACTICE_NAME_1,
    loc.location_phone as PRACTICE_PHONE_1,
    loc.location_fax as PRACTICE_FAX_1,
    null as PRACTICE_EMAIL_1,
    'suvida_healthcare_adt_enrollment' as PROGRAM_1

from dw_dev.dev_jkizer.patient_summary ps
left join dim_provider_deduped prov 
    on ps.provider_npi = prov.npi
left join dw_dev.dev_jkizer.dim_location loc
    on ps.location_name = loc.location_name

-- include actively assigned patients and unassigned patients who have an upcoming care team appointment
-- exclude deceased patients
where (ps.is_active_assignment = 1
    or ps.next_careteam_appt_date is not null)
    and ps.deceased_date is null