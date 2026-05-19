
  create or replace   view dw_dev.dev_jkizer_staging.stg_carenet_daily_extract_detailed
  
  copy grants
  
  
  as (
    -- Sources from the second file, more detailed
-- Too many rows due to bug in their mapping, limiting to only 5 rows for now. Takes a long time to process


with raw as (
    select
        data['record_index']            as record_index,
        data['source_file']             as source_file,
        parse_xml(data['xml_content']::string) as xml_parsed
    from airbyte_source_prod.carenet.carenet_daily_extract
    where regexp_substr(data['source_file']::string, '[0-9]{8}')::int >= 20260101
    and data['source_file'] ilike ('%_2.xml')
    limit 5
),

base as (
    select
        record_index,
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
        xmlget(xml_parsed, 'TrxDetail')['@ServiceNumber']::string                           as service_number,
        try_cast(xmlget(xml_parsed, 'TrxDetail')['@ServiceDateOpened']::string as timestamp) as service_date_opened,
        try_cast(xmlget(xml_parsed, 'TrxDetail')['@ServiceDateClosed']::string as timestamp) as service_date_closed,
        xmlget(xml_parsed, 'TrxDetail')['@userFName']::string                               as user_fname,
        xmlget(xml_parsed, 'TrxDetail')['@userLName']::string                               as user_lname,
        xmlget(xml_parsed, 'TrxDetail')['@ContactMethod']::string                           as contact_method,
        xmlget(xml_parsed, 'TrxDetail')['@servicesProvided']::string                        as services_provided,
        xmlget(xml_parsed, 'TrxDetail')['@ServiceType']::string                             as service_type,
        xmlget(xml_parsed, 'TrxDetail')['@CallerFirstName']::string                         as caller_first_name,
        xmlget(xml_parsed, 'TrxDetail')['@CallerLastName']::string                          as caller_last_name,
        xmlget(xml_parsed, 'TrxDetail')['@callerType']::string                              as caller_type,

        -- trxTriage
        xmlget(xml_parsed, 'trxTriage')['@TriageId']::string                                as triage_id,
        xmlget(xml_parsed, 'trxTriage')['@Comment']::string                                 as triage_comment,
        xmlget(xml_parsed, 'trxTriage')['@RedFlag']::string                                 as red_flag,
        xmlget(xml_parsed, 'trxTriage')['@PregnancyRelated']::string                        as pregnancy_related,
        xmlget(xml_parsed, 'trxTriage')['@PrescriptionRefill']::string                      as prescription_refill,
        xmlget(xml_parsed, 'trxTriage')['@CallbackNumber']::string                          as callback_number,
        xmlget(xml_parsed, 'trxTriage')['@FollowupDateTime']::string                        as followup_datetime,
        xmlget(xml_parsed, 'trxTriage')['@UrgencyDesc']::string                             as urgency_desc,

        -- Contacts
        xmlget(xml_parsed, 'Contacts')['@PatientFirstName']::string                         as patient_first_name,
        xmlget(xml_parsed, 'Contacts')['@PatientLastName']::string                          as patient_last_name,
        xmlget(xml_parsed, 'Contacts')['@PreferredName']::string                            as preferred_name,
        xmlget(xml_parsed, 'Contacts')['@Gender']::string                                   as gender,
        xmlget(xml_parsed, 'Contacts')['@DOB']::string                                      as dob,
        xmlget(xml_parsed, 'Contacts')['@Language']::string                                 as language,
        xmlget(xml_parsed, 'Contacts')['@InsuranceDesc']::string                            as insurance_desc,
        xmlget(xml_parsed, 'Contacts')['@MemberId']::string                                 as member_id,
        xmlget(xml_parsed, 'Contacts')['@ExternalId']::string                               as external_id,
        xmlget(xml_parsed, 'Contacts')['@Address1']::string                                 as patient_address1,
        xmlget(xml_parsed, 'Contacts')['@Address2']::string                                 as patient_address2,
        xmlget(xml_parsed, 'Contacts')['@City']::string                                     as patient_city,
        xmlget(xml_parsed, 'Contacts')['@State']::string                                    as patient_state,
        xmlget(xml_parsed, 'Contacts')['@Zip']::string                                      as patient_zip,

        -- Session
        xmlget(xml_parsed, 'Session')['@GuidelineSessionId']::string                        as guideline_session_id,
        xmlget(xml_parsed, 'Session')['@GuideLineDesc']::string                             as guideline_desc,
        xmlget(xml_parsed, 'Session')['@cComplaint']::string                                as chief_complaint,
        xmlget(xml_parsed, 'Session')['@SearchWords']::string                               as search_words,
        xmlget(xml_parsed, 'Session')['@Disposition']::string                               as disposition,
        xmlget(xml_parsed, 'Session')['@DispositionId']::string                             as disposition_id,
        xmlget(xml_parsed, 'Session')['@DispositionGuideLine']::string                      as disposition_guideline,
        xmlget(xml_parsed, 'Session')['@DispositionOverride']::string                       as disposition_override,
        xmlget(xml_parsed, 'Session')['@OverrideNote']::string                              as override_note,
        xmlget(xml_parsed, 'Session')['@Status']::string                                    as session_status,

        -- SessionNotes
        xmlget(xml_parsed, 'SessionNotes')['@NursingNotes']::string                         as nursing_notes,
        xmlget(xml_parsed, 'SessionNotes')['@NurseCareAdvice']::string                      as nurse_care_advice,
        xmlget(xml_parsed, 'SessionNotes')['@ComfortNote']::string                          as comfort_note,
        xmlget(xml_parsed, 'SessionNotes')['@UnderstandingNote']::string                    as understanding_note,

        -- AddendumNotes
        xmlget(xml_parsed, 'AddendumNotes')['@AddendumNote']::string                        as addendum_note,
        xmlget(xml_parsed, 'AddendumNotes')['@UserID']::string                              as addendum_user_id,
        try_cast(xmlget(xml_parsed, 'AddendumNotes')['@DateTimeStamp']::string as timestamp) as addendum_datetime,

        xml_parsed
    from raw
),

assessment as (
    select
        r.record_index,
        f.value['@GuidelineSessionId']::string                      as guideline_session_id,
        f.value['@AssessmentQuestion']::string                      as assessment_question,
        f.value['@Answer']::string                                  as assessment_answer,
        try_cast(f.value['@DateTimeStamp']::string as timestamp)    as datetime_stamp,
        row_number() over (
            partition by r.record_index
            order by try_cast(f.value['@DateTimeStamp']::string as timestamp)
        )                                                           as question_seq
    from raw r,
    lateral flatten(input => r.xml_parsed:"$") f
    where f.value:"@"::string = 'AssessmentAnswers'
),

care_advice as (
    select
        r.record_index,
        f.value['@CareAdvice']::string                                          as care_advice,
        f.value['@GuidelineRecommended']::string                                as guideline_recommended,
        try_cast(f.value['@CareAdviceSeqNumber']::string as float)              as care_advice_seq,
        row_number() over (
            partition by r.record_index
            order by try_cast(f.value['@CareAdviceSeqNumber']::string as float)
        )                                                                       as advice_seq
    from raw r,
    lateral flatten(input => r.xml_parsed:"$") f
    where f.value:"@"::string = 'CareAdviceGiven'
),

guidelines as (
    select
        r.record_index,
        f.value['@GuideLineDesc']::string                                       as guideline_desc,
        f.value['@Disposition']::string                                         as disposition,
        try_cast(f.value['@AcuityOrder']::string as int)                        as acuity_order,
        f.value['@DispositionId']::string                                       as disposition_id,
        row_number() over (
            partition by r.record_index
            order by try_cast(f.value['@AcuityOrder']::string as int)
        )                                                                       as guideline_seq
    from raw r,
    lateral flatten(input => r.xml_parsed:"$") f
    where f.value:"@"::string = 'GuidelinesUsed'
),

triage_answers as (
    select
        r.record_index,
        f.value['@PositiveTriageDesc']::string                                  as positive_triage_desc,
        try_cast(f.value['@DateTimeStamp']::string as timestamp)                as datetime_stamp,
        row_number() over (
            partition by r.record_index
            order by try_cast(f.value['@DateTimeStamp']::string as timestamp)
        )                                                                       as answer_seq
    from raw r,
    lateral flatten(input => r.xml_parsed:"$") f
    where f.value:"@"::string = 'TriageAnswers'
)

select
    b.record_index,
    b.source_file,
    b.transaction_number,
    b.transaction_start_time,
    b.transaction_end_time,
    b.trx_status,
    b.profile_name,
    b.profile_address1,
    b.profile_address2,
    b.profile_city,
    b.profile_state,
    b.profile_zip,
    b.service_number,
    b.service_date_opened,
    b.service_date_closed,
    b.user_fname,
    b.user_lname,
    b.contact_method,
    b.services_provided,
    b.service_type,
    b.caller_first_name,
    b.caller_last_name,
    b.caller_type,
    b.triage_id,
    b.triage_comment,
    b.red_flag,
    b.pregnancy_related,
    b.prescription_refill,
    b.callback_number,
    b.followup_datetime,
    b.urgency_desc,
    b.patient_first_name,
    b.patient_last_name,
    b.preferred_name,
    b.gender,
    b.dob,
    b.language,
    b.insurance_desc,
    b.member_id,
    b.external_id,
    b.patient_address1,
    b.patient_address2,
    b.patient_city,
    b.patient_state,
    b.patient_zip,
    b.guideline_session_id,
    b.guideline_desc,
    b.chief_complaint,
    b.search_words,
    b.disposition,
    b.disposition_id,
    b.disposition_guideline,
    b.disposition_override,
    b.override_note,
    b.session_status,
    b.nursing_notes,
    b.nurse_care_advice,
    b.comfort_note,
    b.understanding_note,
    b.addendum_note,
    b.addendum_user_id,
    b.addendum_datetime,

    array_agg(object_construct(
        'question',     a.assessment_question,
        'answer',       a.assessment_answer,
        'timestamp',    a.datetime_stamp::string
    )) within group (order by a.question_seq)       as assessment_answers,

    array_agg(object_construct(
        'advice',       ca.care_advice,
        'recommended',  ca.guideline_recommended,
        'seq',          ca.care_advice_seq::string
    )) within group (order by ca.advice_seq)        as care_advice_given,

    array_agg(object_construct(
        'guideline',    g.guideline_desc,
        'disposition',  g.disposition,
        'acuity_order', g.acuity_order::string
    )) within group (order by g.guideline_seq)      as guidelines_used,

    array_agg(
        ta.positive_triage_desc
    ) within group (order by ta.answer_seq)         as triage_answers

from base b
left join assessment a      on b.record_index = a.record_index
left join care_advice ca    on b.record_index = ca.record_index
left join guidelines g      on b.record_index = g.record_index
left join triage_answers ta on b.record_index = ta.record_index

group by
    b.record_index,
    b.source_file,
    b.transaction_number,
    b.transaction_start_time,
    b.transaction_end_time,
    b.trx_status,
    b.profile_name,
    b.profile_address1,
    b.profile_address2,
    b.profile_city,
    b.profile_state,
    b.profile_zip,
    b.service_number,
    b.service_date_opened,
    b.service_date_closed,
    b.user_fname,
    b.user_lname,
    b.contact_method,
    b.services_provided,
    b.service_type,
    b.caller_first_name,
    b.caller_last_name,
    b.caller_type,
    b.triage_id,
    b.triage_comment,
    b.red_flag,
    b.pregnancy_related,
    b.prescription_refill,
    b.callback_number,
    b.followup_datetime,
    b.urgency_desc,
    b.patient_first_name,
    b.patient_last_name,
    b.preferred_name,
    b.gender,
    b.dob,
    b.language,
    b.insurance_desc,
    b.member_id,
    b.external_id,
    b.patient_address1,
    b.patient_address2,
    b.patient_city,
    b.patient_state,
    b.patient_zip,
    b.guideline_session_id,
    b.guideline_desc,
    b.chief_complaint,
    b.search_words,
    b.disposition,
    b.disposition_id,
    b.disposition_guideline,
    b.disposition_override,
    b.override_note,
    b.session_status,
    b.nursing_notes,
    b.nurse_care_advice,
    b.comfort_note,
    b.understanding_note,
    b.addendum_note,
    b.addendum_user_id,
    b.addendum_datetime
  );

