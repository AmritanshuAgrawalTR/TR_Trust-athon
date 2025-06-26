def model(dbt, session):
    
    df = session.table("MYDATASPACE.A208309_METADATATHON_DATAANALYTICS.DATA_CATALOG_REVENUE")
    
    return df.select("*")

# this is just for trial and not letting the code file empty because it will pop an error. " So Ignore it "