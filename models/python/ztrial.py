import snowflake.snowpark.functions as F

def model(dbt, session):
    df = dbt.ref("DQ")

    total_employees = df.count()
    engineering_employees = df.filter(F.col("department") == "Engineering").count()

    result = session.create_dataframe([
        (engineering_employees, total_employees, round((engineering_employees/total_employees)*100, 2))
    ], schema=["engineering_count", "total_count", "percent"])

    return result