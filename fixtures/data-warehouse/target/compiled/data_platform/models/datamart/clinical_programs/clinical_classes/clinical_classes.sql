with classes as (
      select
          suvida_id,
          appointment_date,
          case
            when appointment_type like '%MH P:%' then 'MH-P'
            when appointment_type = 'MH: Palabras Sanadoras' then 'MH: Palabras Sanadoras'
            when appointment_type like '%MH T:%' then 'MH-T'
            when appointment_type like 'MH: TOC%' then 'MH: Transitions of Care'
            when appointment_type = 'ZZZMOB: Matter of Balance' then 'Steady Strides'
               else trim(appointment_type_category)
                    end as appointment_type_category,
          case
            when appointment_type = 'MH: Palabras Sanadoras' then 'Mental Health'
            when appointment_type like 'MH: TOC%' then 'Mental Health'
            when appointment_type = 'ZZZMOB: Matter of Balance' then 'Physical Therapy'
                else appointment_provider_category
                    end as appointment_provider_category,
          appointment_type,
          appointment_description,
          appointment_status,
          appointment_location_name,
          appointment_completed_ind,
          is_guia_appt,
          is_pt_appt,
          is_mh_appt,
          is_nutrition_appt
      from dw_dev.dev_jkizer.fct_appointment
      where (trim(appointment_type_category) in (
          'SuBienestar Class 6', 'SuBienestar Class 5', 'SuBienestar Class 4',
          'SuBienestar Class 3', 'SuBienestar Class 2', 'SuBienestar Class 1',
          'SuBienestar', 'Food RX', 'Food as Medicine',
          '¡Viva el Bienestar!', 'Viviendo con el Duelo', '¡Sabor y Vida!',
          '1:1 Treatment-OFFICE', '2:1 Treatment-OFFICE', 'Steady Strides')
          or appointment_type = 'ZZZMOB: Matter of Balance'
          or
          (appointment_type like '%MH P:%' or appointment_type = 'MH: Palabras Sanadoras' or appointment_type like '%MH T:%' or
          appointment_type like 'MH: TOC%')
      )
      and appointment_status not in ('cancelled', 'notSeen', 'scheduled')
      and appointment_date <= current_date()
  ),
  cte_with_row_num as (
      select
          *,
          row_number() over(partition by suvida_id, appointment_type_category order by appointment_date) as apt_number
      from classes
  ),
  appointments_agg as (
      select
          suvida_id,
          appointment_type_category,
          count(*) as total_apts_attended
      from cte_with_row_num
      group by suvida_id, appointment_type_category
  ),
  previous_apt as (
      select
          a.*,
          lag(a.appointment_date) over(
              partition by a.suvida_id, a.appointment_type_category order by a.appointment_date) as previous_apt_date,
          aa.total_apts_attended
      from cte_with_row_num a
      join appointments_agg aa
          on a.suvida_id = aa.suvida_id
          and a.appointment_type_category = aa.appointment_type_category
  )
  select
      *,
      datediff('day', previous_apt_date, appointment_date) as days_since_last_apt
  from previous_apt