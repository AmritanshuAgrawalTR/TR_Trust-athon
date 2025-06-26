WITH component_scores AS (
    -- Data Quality Score (Percentage Logic)
    SELECT 
        'DQ' as component_name,
        'Data Quality' as component_full_name,
        ROUND(
            (SELECT COUNT(*) FROM MYDATASPACE.A208309_DATA_TRUSTATHON_2025_CODE_CRAFTERS.DATAQUALITY) * 100.0 / 
            (SELECT COUNT(*) FROM MYDATASPACE.A208309_METADATATHON_DATAANALYTICS.REVENUE_DETAIL_DATA_TRUST_TARGET), 2
        ) as individual_score,
        50.0 as weightage
    
    UNION ALL
    
    -- Metadata Assessment Score (Percentage Logic) 
    SELECT 
        'MA' as component_name,
        'Metadata Assessment' as component_full_name,
        ROUND(
            (SELECT COUNT(*) FROM MYDATASPACE.A208309_DATA_TRUSTATHON_2025_CODE_CRAFTERS.METADATA) * 100.0 / 
            (SELECT COUNT(*) FROM MYDATASPACE.A208309_METADATATHON_DATAANALYTICS.DATA_CATALOG_REVENUE), 2
        ) as individual_score,
        20.0 as weightage
    
    UNION ALL
    
    -- Data Lineage Score (From Component Table)
    SELECT 
        'DL' as component_name,
        'Data Lineage' as component_full_name,
        ROUND(AVG(data_lineage_score), 2) as individual_score,
        30.0 as weightage
    FROM MYDATASPACE.A208309_DATA_TRUSTATHON_2025_CODE_CRAFTERS.DATALINEAGE
),

final_calculation AS (
    SELECT 
        *,
        ROUND((individual_score * weightage) / 100, 2) as weighted_contribution
    FROM component_scores
)

SELECT 
    component_name,
    component_full_name,
    individual_score,
    weightage,
    weighted_contribution,
    CURRENT_TIMESTAMP() as assessment_timestamp
FROM final_calculation

UNION ALL

-- Add final score row
SELECT 
    'FINAL' as component_name,
    'Overall Data Score' as component_full_name,
    ROUND(SUM(weighted_contribution), 2) as individual_score,
    100.0 as weightage,
    ROUND(SUM(weighted_contribution), 2) as weighted_contribution,
    CURRENT_TIMESTAMP() as assessment_timestamp
FROM final_calculation

ORDER BY 
    CASE component_name 
        WHEN 'DQ' THEN 1 
        WHEN 'DL' THEN 2 
        WHEN 'MA' THEN 3 
        WHEN 'FINAL' THEN 4 
    END