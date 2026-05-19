with latest_answers_filtered as (
    select
        zf.suvida_id,
        zf.question,
        zf.question_id,
        zf.form_name,
        zf.form_id,
        zf.answer,
        zf.completed_at_datetime,
        mz.secure_status,
        case when mz.secure_status = 'Insecure' then true else false end as is_insecure
    from dw_dev.dev_jkizer.intmdt_zentake_form zf
    left join dw_dev.dev_jkizer_source.map_zentake_security_status_concept mz
      on zf.form_id = mz.form_id
     and zf.question_id = mz.question_id
     and trim(upper(zf.answer)) = trim(upper(mz.question_answer))
    where zf.form_name in (
        'Health Risk Assessment (HRA) (Spanish)',
        'Health Risk Assessment (HRA) (English)',
        'Accountable Health Communities Screening (Spanish)',
        'Accountable Health Communities Screening',
        'Health Risk Assessment (HRA) (Spanish) (new)',
        'Health Risk Assessment (HRA) (English) (new)'
    )
      and zf.suvida_id is not null
    qualify row_number() over (partition by zf.suvida_id, zf.question order by zf.completed_at_datetime desc) = 1
),

latest_forms as (
    select
        suvida_id,
        max(case when form_name like 'Health Risk Assessment%' then completed_at_datetime end) as latest_hra_completion,
        max(case when form_name like 'Accountable Health Communities%' then completed_at_datetime end) as latest_ahc_completion
    from intmdt_zentake_form
    where form_name like 'Health Risk Assessment%'
       or form_name like 'Accountable Health Communities%'
    group by suvida_id
), 

insecurity_counts as(
    select
        suvida_id,
        sum(case when secure_status = 'Insecure' then 1 else 0 end) as insecurity_total
    from latest_answers_filtered
    where question in (
        '1. What is your living situation today?',
        '4. Within the past 12 months, the food you bought just didn’t last and you didn’t have money to get more.',
        '6. In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?',
        '2. Think about the place you live. Do you have problems with any of the following? (CHOOSE ALL THAT APPLY)',
        '5. In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?',
        '8. How often does anyone, including family, insult or talk down to you?',
        '3. Within the past 12 months, you worried that your food would run out before you got money to buy more.',
        '7. How often does anyone, including family and friends, physically hurt you?',
        '9. How often does anyone, including family and friends, threaten you with harm?',
        '10. How often does anyone, including family and friends, scream or curse at you?'
    )
    group by suvida_id
),

answer_mapping as (
    select
        la.suvida_id,
        lf.latest_hra_completion,
        lf.latest_ahc_completion,
        
    /* count of forms completed this year */
        case when lf.latest_hra_completion is not null and datediff(year, lf.latest_hra_completion, current_date) < 1 then 'Yes' else 'No' end as hra_completed_this_year,
        case when lf.latest_ahc_completion is not null and datediff(year, lf.latest_ahc_completion, current_date) < 1 then 'Yes' else 'No' end as ahc_completed_this_year,

    /* question answers */
        max(case when la.question = 'Have you recently lost weight without trying?' then la.answer end) as unintentional_weight_loss,
       
        max(case when la.question = 'Have you fallen in the last 12 months?' then la.answer end) as fallen_in_last_year,
        max(case when la.question = 'Have you fallen in the last 12 months?' then la.secure_status end) as falling_status,
        max(case when la.question in ('Do you have trouble with your balance? (i.e. feeling unsteady when you walk)', 'Do you have problem with your balance?') then la.answer end) as balance_problems,
        max(case when la.question in ('Do you have trouble with your balance? (i.e. feeling unsteady when you walk)', 'Do you have problem with your balance?') then la.secure_status end) as balance_status,
		max(case when la.question in ('Do you worry about falling?', 'Are you afraid of falling?') then la.answer end)  as afraid_of_falling,
		max(case when la.question in ('Do you worry about falling?', 'Are you afraid of falling?') then la.secure_status end)  as afraid_of_falling_status,

        max(case when la.question = 'Which of the following can you do on your own without help?' then la.answer end) as independently_able_tasks,
        max(case when la.question = 'Have you missed any doses of your medications in the last month?' then la.answer end) as missed_doses_of_medication_last_month,
        max(case when la.question = 'Have you had any problems getting your refills from your pharmacy in the last month?' then la.answer end) as problems_refilling_meds_in_last_month,
        max(case when la.question = 'How do you treat the pain?' then la.answer end) as how_do_you_treat_pain,
        max(case when la.question = 'In the past two weeks, how often have you felt pain?' then la.answer end) as frequency_of_pain_in_last_two_weeks,
        max(case when la.question = 'What best describes your living situation, please  select:' then la.answer end) as describe_current_living_situation,
        max(case when la.question = 'Does your home have rugs in the hallways?' then la.answer end) as rugs_in_hallway,
        max(case when la.question = 'Does your home have functioning smoke detectors?' then la.answer end) as working_smoke_detecotrs,
        max(case when la.question = 'From 0-10, how would your rate your current level of pain? (0 = No Pain, 10 = Worst Pain Ever)' then la.answer end) as pain_scale,
        max(case when la.question = '1. What is your living situation today?' or la.question ilike '%current living%' then la.answer end) as living_situation_today,
        max(case when la.question = '1. What is your living situation today?' or la.question ilike '%current living%' then la.secure_status end) as living_status,
        max(case when la.question = '4. Within the past 12 months, the food you bought just didn’t last and you didn’t have money to get more.' then la.answer end) as not_enough_money_for_food,
        max(case when la.question = '4. Within the past 12 months, the food you bought just didn’t last and you didn’t have money to get more.' then la.secure_status end) as not_enough_money_for_food_security_status,
        max(case when la.question = '6. In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' then la.answer end) as utilities_threatened,
        max(case when la.question = '6. In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' then la.secure_status end) as utilities_insecurity,
        max(case when la.question = '2. Think about the place you live. Do you have problems with any of the following? (CHOOSE ALL THAT APPLY)' then la.answer end) as home_safety,
        max(case when la.question = '2. Think about the place you live. Do you have problems with any of the following? (CHOOSE ALL THAT APPLY)' then la.secure_status end) as home_safety_insecurity,
        max(case when la.question = '5. In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?' then la.answer end) as no_transport_for_appointments,
        max(case when la.question = '5. In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?' then la.secure_status end) as transportation_insecurity,
        max(case when la.question = '8. How often does anyone, including family, insult or talk down to you?' then la.answer end) as talked_down_to,
        max(case when la.question = '8. How often does anyone, including family, insult or talk down to you?' then la.secure_status end) as talked_down_to_insecurity,
        max(case when la.question = '3. Within the past 12 months, you worried that your food would run out before you got money to buy more.' then la.answer end) as running_out_of_food,
        max(case when la.question = '3. Within the past 12 months, you worried that your food would run out before you got money to buy more.' then la.secure_status end) as running_out_of_food_security_status,
        max(case when la.question = '7. How often does anyone, including family and friends, physically hurt you?' then la.answer end) as physical_abuse,
        max(case when la.question = '7. How often does anyone, including family and friends, physically hurt you?' then la.secure_status end) as physical_abuse_security_status,
        max(case when la.question = '9. How often does anyone, including family and friends, threaten you with harm?' then la.answer end) as verbal_threats,
        max(case when la.question = '9. How often does anyone, including family and friends, threaten you with harm?' then la.secure_status end) as verbal_threats_security_status,
        max(case when la.question = '10. How often does anyone, including family and friends, scream or curse at you?' then la.answer end) as verbal_abuse,
        max(case when la.question = '10. How often does anyone, including family and friends, scream or curse at you?' then la.secure_status end) as verbal_abuse_security_status,

        ic.insecurity_total
        
    from latest_answers_filtered la
    left join latest_forms lf
      on la.suvida_id = lf.suvida_id 
    left join insecurity_counts ic
      on lf.suvida_id = ic.suvida_id
    group by
        la.suvida_id,
        lf.latest_hra_completion,
        lf.latest_ahc_completion,
        ic.insecurity_total
),

insecure_types as (
    select
        suvida_id,
        latest_hra_completion,
        latest_ahc_completion,
        hra_completed_this_year,
        ahc_completed_this_year,
        unintentional_weight_loss,

    -- Medication/ Script issues
        missed_doses_of_medication_last_month,
        problems_refilling_meds_in_last_month,
    
    -- safety
        rugs_in_hallway,
        working_smoke_detecotrs,
    
    --Functional Ability
        fallen_in_last_year,
        balance_problems,
        afraid_of_falling,
        case
            when falling_status = 'Insecure' or balance_status = 'Insecure' or afraid_of_falling_status = 'Insecure'
                then 'Insecure'
            when falling_status = 'Secure' or balance_status = 'Secure' or afraid_of_falling_status = 'Secure'
                then 'Secure'
            else null
                end as falls_insecurity,
        independently_able_tasks,
    
    -- Pain/ Pain Management
        pain_scale,
        frequency_of_pain_in_last_two_weeks,
        how_do_you_treat_pain,
    
    -- Utilities/Financial Insecurities: NOTE THIS IS THE QUESTION THE GUIAS USE FOR FINANCIAL INSEC.
        utilities_threatened,
        coalesce(utilities_insecurity, null) as financial_insecurity,
    
    -- housing insecurity
        living_situation_today,
        living_status,
        case
          when living_status = 'Insecure' or home_safety_insecurity = 'Insecure' then 'Insecure'
          when living_status = 'Secure' or home_safety_insecurity = 'Secure' then 'Secure'
          else null
                end as housing_insecurity,
    
    -- food insecurity
        not_enough_money_for_food,
        running_out_of_food,
        case
          when not_enough_money_for_food_security_status = 'Insecure' or running_out_of_food_security_status = 'Insecure' then 'Insecure'
          when not_enough_money_for_food_security_status = 'Secure' or running_out_of_food_security_status = 'Secure' then 'Secure'
          else null
                end as food_insecurity,    
    
    -- Transportation Insec
        no_transport_for_appointments,
        coalesce(transportation_insecurity, null) as transportation_insecurity,

    -- Abuse
        talked_down_to,
        talked_down_to_insecurity,  
        physical_abuse,
        physical_abuse_security_status,
        verbal_threats,
        verbal_threats_security_status,
        verbal_abuse,
        verbal_abuse_security_status,
        
        insecurity_total
    from answer_mapping
)

select * from insecure_types