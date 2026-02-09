with row_generator as (
    select row_number() over (order by seq4()) as row_num
    from table(generator(rowcount => 100000))
),

note_templates as (
    select
        row_num,
        mod(row_num, 50000) + 1 as claim_id,
        'ADJ-' || lpad((mod(row_num, 500) + 1)::varchar, 5, '0') as adjuster_id,
        dateadd(day, -mod(row_num * 3, 365), current_date())::date as note_date,
        mod(row_num, 5) as note_type_idx,
        mod(row_num, 20) as note_template_idx
    from row_generator
)

select
    row_num as note_id,
    claim_id,
    adjuster_id,
    note_date,
    case note_type_idx
        when 0 then 'INITIAL'
        when 1 then 'INSPECTION'
        when 2 then 'ESTIMATE'
        when 3 then 'UPDATE'
        else 'RESOLUTION'
    end as note_type,
    case note_template_idx
        when 0 then 'Initial claim received. Policyholder reported incident via phone. Assigned for investigation.'
        when 1 then 'Conducted on-site inspection. Damage assessment in progress. Photos documented.'
        when 2 then 'Repair estimate received from approved vendor. Amount within policy limits.'
        when 3 then 'Follow-up call with policyholder completed. Additional information gathered.'
        when 4 then 'Subrogation opportunity identified. Contacting third-party carrier.'
        when 5 then 'Vehicle inspection completed at certified repair facility. Report attached.'
        when 6 then 'Claim approved for payment. Processing settlement check.'
        when 7 then 'Additional documentation requested from policyholder. Awaiting response.'
        when 8 then 'Independent appraisal scheduled for next week. Will update upon completion.'
        when 9 then 'Contacted witness listed in police report. Statement recorded.'
        when 10 then 'Total loss determination made. Salvage value calculated per guidelines.'
        when 11 then 'Rental car authorized for policyholder during repair period.'
        when 12 then 'Fraud indicators reviewed. No concerns identified. Proceeding with claim.'
        when 13 then 'Medical bills received and reviewed. Coordinating with health insurer.'
        when 14 then 'Claim settlement offer sent to policyholder. Awaiting acceptance.'
        when 15 then 'Repair completed and verified. Quality check passed. Closing claim.'
        when 16 then 'Policyholder dispute received. Escalating to supervisor for review.'
        when 17 then 'Supplemental damage discovered during repair. Revised estimate approved.'
        when 18 then 'Recovery received from at-fault party. Updating claim financials.'
        else 'Claim file reviewed and updated. All documentation complete and filed.'
    end as adjuster_notes
from note_templates
