WITH lineage_rule_assessment AS (
    SELECT 
        "TargetObjectName" AS dataset_name,
        "SourceObjectName",
        "TargetObjectName",
        
        -- DTDL_010: Table Coverage Score (0-100)
        CASE 
            WHEN "TargetObjectName" IS NOT NULL AND TRIM("TargetObjectName") != ''
                 AND "SourceObjectName" IS NOT NULL AND TRIM("SourceObjectName") != ''
                 AND ("TargetObjectName" LIKE '%REVENUE%' OR "SourceObjectName" LIKE '%REVENUE%')
            THEN 100
            WHEN "TargetObjectName" IS NOT NULL AND TRIM("TargetObjectName") != ''
                 AND "SourceObjectName" IS NOT NULL AND TRIM("SourceObjectName") != ''
            THEN 85
            WHEN "TargetObjectName" IS NOT NULL AND TRIM("TargetObjectName") != ''
            THEN 60
            WHEN "SourceObjectName" IS NOT NULL AND TRIM("SourceObjectName") != ''
            THEN 40
            ELSE 0
        END AS table_coverage_score,
        
        -- DTDL_011: Granularity Score (0-100)
        CASE 
            WHEN "SourceColumnName" IS NOT NULL AND TRIM("SourceColumnName") != ''
                 AND "TargetColumnName" IS NOT NULL AND TRIM("TargetColumnName") != ''
                 AND "SourceColumnType" = 'Column' AND "TargetColumnType" = 'Column'
            THEN 100
            WHEN "SourceColumnName" IS NOT NULL AND TRIM("SourceColumnName") != ''
                 AND "TargetColumnName" IS NOT NULL AND TRIM("TargetColumnName") != ''
            THEN 80
            WHEN ("SourceColumnName" IS NOT NULL AND TRIM("SourceColumnName") != '')
                 OR ("TargetColumnName" IS NOT NULL AND TRIM("TargetColumnName") != '')
            THEN 60
            WHEN "SourceObjectName" IS NOT NULL AND "TargetObjectName" IS NOT NULL
            THEN 40
            ELSE 0
        END AS granularity_score,
        
        -- DTDL_012: Metadata Completeness Score (0-100)
        CASE 
            WHEN "SourcePath" IS NOT NULL AND "TargetPath" IS NOT NULL
                 AND LENGTH("SourcePath") > 100 AND LENGTH("TargetPath") > 100
                 AND "RevisionState" = 'STABLE'
            THEN 100
            WHEN "SourcePath" IS NOT NULL AND "TargetPath" IS NOT NULL
                 AND LENGTH("SourcePath") > 80 AND LENGTH("TargetPath") > 80
            THEN 90
            WHEN "SourcePath" IS NOT NULL AND "TargetPath" IS NOT NULL
                 AND LENGTH("SourcePath") > 50 AND LENGTH("TargetPath") > 50
            THEN 75
            WHEN "SourcePath" IS NOT NULL AND "TargetPath" IS NOT NULL
            THEN 60
            WHEN "SourceObjectName" IS NOT NULL AND "TargetObjectName" IS NOT NULL
            THEN 40
            ELSE 0
        END AS metadata_completeness_score
        
    FROM MYDATASPACE.A208309_METADATATHON_DATAANALYTICS.MANTA_USE_CASE_REVENUE_RELATIONS
    WHERE ("TargetObjectName" LIKE '%REVENUE%' OR "SourceObjectName" LIKE '%REVENUE%')
),

aggregated_lineage_scores AS (
    SELECT 
        dataset_name,
        
        -- Aggregated scores per dataset (for datasets with multiple lineage relationships)
        ROUND(AVG(table_coverage_score), 2) AS table_coverage_score,
        ROUND(AVG(granularity_score), 2) AS granularity_score,
        ROUND(AVG(metadata_completeness_score), 2) AS metadata_completeness_score,
        
        -- Sub-component weights (can be adjusted based on business needs)
        35.0 AS table_coverage_weight,
        40.0 AS granularity_weight,
        25.0 AS metadata_completeness_weight,
        
        -- Calculated weighted sub-scores
        ROUND(AVG(table_coverage_score) * 0.35, 2) AS table_coverage_weighted_score,
        ROUND(AVG(granularity_score) * 0.40, 2) AS granularity_weighted_score,
        ROUND(AVG(metadata_completeness_score) * 0.25, 2) AS metadata_completeness_weighted_score,
        
        -- Final data lineage component score
        ROUND(
            (AVG(table_coverage_score) * 0.35) + 
            (AVG(granularity_score) * 0.40) + 
            (AVG(metadata_completeness_score) * 0.25), 2
        ) AS data_lineage_score,
        
        -- Record count for validation
        COUNT(*) AS lineage_relationships_count,
        
        -- Assessment metadata
        CURRENT_TIMESTAMP() AS assessment_timestamp
        
    FROM lineage_rule_assessment
    GROUP BY dataset_name
)

SELECT 
    -- Primary identifier for joining with other components
    dataset_name,
    
    -- Individual sub-component scores (0-100)
    table_coverage_score,
    granularity_score,
    metadata_completeness_score,
    
    -- Sub-component weights (for transparency in final algorithm)
    table_coverage_weight,
    granularity_weight,
    metadata_completeness_weight,
    
    -- Weighted sub-component contributions
    table_coverage_weighted_score,
    granularity_weighted_score,
    metadata_completeness_weighted_score,
    
    -- Final component score (0-100)
    data_lineage_score,
    
    -- Supporting metrics
    lineage_relationships_count,
    assessment_timestamp,
    
    -- Component identifier for final scoring framework
    'DATA_LINEAGE' AS component_type,
    'v1.0' AS scoring_version

FROM aggregated_lineage_scores
ORDER BY dataset_name