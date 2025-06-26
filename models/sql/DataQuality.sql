SELECT 
    doc_amt,
    MGMT_ENTITY_DESC,
    MGMT_ENTITY,
    SOLD_TO
FROM MYDATASPACE.A208309_METADATATHON_DATAANALYTICS.REVENUE_DETAIL_DATA_TRUST_TARGET
WHERE 
    doc_amt IS NOT NULL                                               
    AND MGMT_ENTITY_DESC = TRIM(MGMT_ENTITY_DESC)                    
    AND MGMT_ENTITY_DESC NOT LIKE '%  %'                             
    AND MGMT_ENTITY NOT REGEXP '[^A-Za-z0-9_]'                      
    AND SOLD_TO NOT REGEXP '[^0-9]'