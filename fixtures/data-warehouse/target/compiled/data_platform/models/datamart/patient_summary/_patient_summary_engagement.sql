

-- Component: Patient appointment completion/cancellation/no-show rates (rolling 12 months)
-- Extracted from patient_summary to reduce model complexity

select
    suvida_id,
    -- Completion rates
    div0null(sum(case when is_pcp_appt then appointment_completed_ind end), sum(case when is_pcp_appt then 1 end)) as pcp_appt_completion_rate_rolling_12,
    div0null(sum(case when is_guia_appt then appointment_completed_ind end), sum(case when is_guia_appt then 1 end)) as guia_appt_completion_rate_rolling_12,
    div0null(sum(case when is_mh_appt then appointment_completed_ind end), sum(case when is_mh_appt then 1 end)) as mh_appt_completion_rate_rolling_12,
    div0null(sum(case when is_nutrition_appt then appointment_completed_ind end), sum(case when is_nutrition_appt then 1 end)) as nutrition_appt_completion_rate_rolling_12,
    div0null(sum(case when is_pharmacy_appt then appointment_completed_ind end), sum(case when is_pharmacy_appt then 1 end)) as pharmacy_appt_completion_rate_rolling_12,
    div0null(sum(case when is_pt_appt then appointment_completed_ind end), sum(case when is_pt_appt then 1 end)) as pt_appt_completion_rate_rolling_12,
    -- Cancelled rates
    div0null(sum(case when is_pcp_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_pcp_appt then 1 end)) as pcp_appt_cancelled_rate_rolling_12,
    div0null(sum(case when is_guia_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_guia_appt then 1 end)) as guia_appt_cancelled_rate_rolling_12,
    div0null(sum(case when is_mh_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_mh_appt then 1 end)) as mh_appt_cancelled_rate_rolling_12,
    div0null(sum(case when is_nutrition_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_nutrition_appt then 1 end)) as nutrition_appt_cancelled_rate_rolling_12,
    div0null(sum(case when is_pharmacy_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_pharmacy_appt then 1 end)) as pharmacy_appt_cancelled_rate_rolling_12,
    div0null(sum(case when is_pt_appt and lower(appointment_status) = 'cancelled' then 1 else 0 end), sum(case when is_pt_appt then 1 end)) as pt_appt_cancelled_rate_rolling_12,
    -- No-show rates
    div0null(sum(case when is_pcp_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_pcp_appt then 1 end)) as pcp_appt_no_show_rate_rolling_12,
    div0null(sum(case when is_guia_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_guia_appt then 1 end)) as guia_appt_no_show_rate_rolling_12,
    div0null(sum(case when is_mh_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_mh_appt then 1 end)) as mh_appt_no_show_rate_rolling_12,
    div0null(sum(case when is_nutrition_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_nutrition_appt then 1 end)) as nutrition_appt_no_show_rate_rolling_12,
    div0null(sum(case when is_pharmacy_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_pharmacy_appt then 1 end)) as pharmacy_appt_no_show_rate_rolling_12,
    div0null(sum(case when is_pt_appt and lower(appointment_status) = 'notseen' then 1 else 0 end), sum(case when is_pt_appt then 1 end)) as pt_appt_no_show_rate_rolling_12
from dw_dev.dev_jkizer.fct_appointment
where appointment_date >= dateadd(month, -12, current_date())
group by suvida_id