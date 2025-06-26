SELECT *
FROM MYDATASPACE.A208309_METADATATHON_DATAANALYTICS.DATA_CATALOG_REVENUE
WHERE 
    -- DTMC_001: Source System populated 
    source_system IS NOT NULL AND TRIM(source_system) != ''

    -- DTMC_002: Asset Insight ID populated and numeric 
    AND ASSET_INSIGHT_ID IS NOT NULL 
    AND REGEXP_LIKE(CAST(ASSET_INSIGHT_ID AS STRING), '^[0-9]+$')

    -- DTMC_003: Information Security Classification valid 
    AND INFORMATION_SECURITY_CLASSIFICATION IS NOT NULL
    AND INFORMATION_SECURITY_CLASSIFICATION IN ('{"Strictly Confidential"}', '{"Confidential"}', '{"Internal"}', '{"Public"}')
        
    -- DTMC_004: Information Security Sub Classification validation 
    AND (INFORMATION_SECURITY_SUB_CLASSIFICATION IS NULL 
     OR (
         -- Part 1: Only allow approved values
         (INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%Standard PII%'
          OR INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%Sensitive PII%'
          OR INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%PCI%'
          OR INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%TR IP%'
          OR INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%No PII%'
          OR INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%No PCI%'
          OR INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%No IP%')
         
         -- Part 2: No contradictions
         AND NOT (INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%Sensitive PII%' AND INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%Standard PII%')
         AND NOT (INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%TR IP%' AND INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%No IP%')
         AND NOT (INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%No PII%' AND (INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%Standard PII%' OR INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%Sensitive PII%'))
     ))
    
    -- DTMC_005: Domain populated 
    AND DOMAIN IS NOT NULL AND TRIM(DOMAIN) != ''

    -- DTMC_006: Sub Domain populated 
    AND SUB_DOMAIN IS NOT NULL AND TRIM(SUB_DOMAIN) != ''
    
    -- DTMC_007: Data Steward populated 
    AND DATA_STEWARD IS NOT NULL AND TRIM(DATA_STEWARD) != ''
    
    -- DTMC_008: Security Control Group populated 
    AND SECURITY_CONTROL_GROUP IS NOT NULL AND TRIM(SECURITY_CONTROL_GROUP) != ''

    -- DTMC_009: Owning Data Asset populated 
    --AND OWNING_DATA_ASSET IS NOT NULL AND TRIM(OWNING_DATA_ASSET) != ''

    -- DTMC_010: Column classification not higher than main classification
    AND (COLUMN_INFORMATION_SECURITY_CLASSIFICATION IS NULL 
         OR NOT (
             -- Column: Strictly Confidential > Asset: others
             (COLUMN_INFORMATION_SECURITY_CLASSIFICATION = '{"Strictly Confidential"}' 
              AND INFORMATION_SECURITY_CLASSIFICATION != '{"Strictly Confidential"}')
             OR
             -- Column: Confidential > Asset: Internal/Public  
             (COLUMN_INFORMATION_SECURITY_CLASSIFICATION = '{"Confidential"}'
              AND INFORMATION_SECURITY_CLASSIFICATION IN ('{"Internal"}', '{"Public"}'))
             OR
             -- Column: Internal > Asset: Public
             (COLUMN_INFORMATION_SECURITY_CLASSIFICATION = '{"Internal"}'
              AND INFORMATION_SECURITY_CLASSIFICATION = '{"Public"}')
         ))
    
    -- DTMC_011: Column sub classification not higher than main sub classification
    AND (column_information_security_sub_classification IS NULL
         OR NOT (
             -- Column: Sensitive PII > Asset: Standard PII/No PII
             (column_information_security_sub_classification LIKE '%Sensitive PII%'
              AND (INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%Standard PII%'
                   OR INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%No PII%'))
             OR
             -- Column: Standard PII > Asset: No PII
             (column_information_security_sub_classification LIKE '%Standard PII%'
              AND column_information_security_sub_classification NOT LIKE '%Sensitive PII%'
              AND INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%No PII%')
             OR
             -- Column: PCI > Asset: No PCI
             (column_information_security_sub_classification LIKE '%PCI%'
              AND column_information_security_sub_classification NOT LIKE '%No PCI%'
              AND INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%No PCI%')
             OR
             -- Column: TR IP > Asset: No IP
             (column_information_security_sub_classification LIKE '%TR IP%'
              AND INFORMATION_SECURITY_SUB_CLASSIFICATION LIKE '%No IP%')
         ))