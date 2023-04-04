# DataTalk Club Data Engineering Course Project 

- [DataTalk Club Data Engineering Course Project](#datatalk-club-data-engineering-course-project)
  - [Introduction](#introduction)
  - [Problem description](#problem-description)
    - [Dataset](#dataset)
    - [Problem](#problem)
  - [Cloud](#cloud)
  - [Batch data ingestion](#batch-data-ingestion)
  - [Data warehouse](#data-warehouse)
  - [Transformations with dbt](#transformations-with-dbt)
  - [Dashboard using Looker Studio](#dashboard-using-looker-studio)
  - [Reproducibility](#reproducibility)

## Introduction
*Quite often marketing department needs to evaluate how effective online store and what should be optimized on the site to increase sales. One of the standard tasks for user acqusition manager is to study the statistics of site visits and user behavior on the site.
Fortunately, some of the world's largest Internet companies are helping to capture user activity on websites and provide site owners access to this information.
In my project, I'd like to consider the issue of obtaining basic information about user purchases in the Internet store using the example of a dataset from Google Analytics.*

## Problem description
### Dataset
For the project I choose Google Analytics Sample (https://console.cloud.google.com/marketplace/product/obfuscated-ga360-data/obfuscated-ga360-data?_ga=2.165046975.1820670614.1680343879-1408202468.1646750351&project=bold-azimuth-236219). The Google description of the dataset "The dataset provides 12 months (August 2016 to August 2017) of obfuscated Google Analytics 360 data from the Google Merchandise Store, a real ecommerce store that sells Google-branded merchandise, in BigQuery. It’s a great way analyze business data and learn the benefits of using BigQuery to analyze Analytics 360 data Learn more about the data.
The data includes The data is typical of what an ecommerce website would see and includes the following information:
- Traffic source data: information about where website visitors originate, including data about organic traffic, paid search traffic, and display traffic
- Content data: information about the behavior of users on the site, such as URLs of pages that visitors look at, how they interact with content, etc.
- Transactional data: information about the transactions on the Google Merchandise Store website". 

### Problem
Analyzing the data superficially (https://support.google.com/analytics/answer/3437719?hl=en), you can notice that the user session data is recorded in quite detail and the marketing department can answer a large number of questions using this dataset.
I'd like to focus on four problems, two of which are proposed to be solved by the GA dataset authors (*italic*), and two of my own (**bolded**). When solving problems, I will try to answer the questions posed with the help of graphs on the dashboard in the most understandable form.
1. *What is the average number of transactions per purchaser?*
2. *What is the total number of transactions generated per device browser?*
3. **What is the average time purchasers spent on site per country?**
4. **What is new users compare the old ones per channel group?**

## Cloud
For my project I chose to use Google Cloud Platform (GCP) and dbt cloud tool. I have experience with GCP, AWS and Yandex Cloud and prefered GCP not accidentally. GCP has user-friendly interfaces and a huge set of various tools to build and process data. This project uses only a very small part of the GCP, in reality there are many more tools.
The project stack consists of VM, Cloud Storage, BigQuery datasets/tables, prefect, Looker Studio and dbt cloud tool. The whole project might localized on VM's or even one VM with installed data tools on it (local file share or S3 storage, local PostgreSQL DB and local PowerBI dashboards) but there are two major disadvantages such approach:
- DevOps: time to install, setup, maintain
- Cost: VM is always running and spent resources 
Cloud managed tools allows to concetrate attention on data pipelines rather than setuping and provides pay-per-use model.

**Components used in project:**
1. Virtual machine as a main tool to to clone necessary scripts and manifests from repo, terraform bucket and dataset, orchestrate pipeline.
2. Cloud stoage to store objects (files) in the cloud.
3. BigQuery dataset to store raw and processed data.
4. Prefect to orchestrate data pipelines and ETL processes.
5. Looker Studio to visualize and publish dashboards.
6. dbt cloud to exceute ETL processes.

First of all I've created *terraform* main.tf and variable.tf files to setup environments variables and required resources. Then execute all terraform steps: init, plan, apply - to create storage bucket and BigQuery dataset. 

## Batch data ingestion
To get, process, transform and load data the one flow in prefect is used. Loading batch data separated to task 'read_from_bq'. Google Analytics data selected from public dataset to pandas dataframe, then dataframe returns back to flow for next task.
```python
def read_from_bq() -> pd.DataFrame:
    """Task to load data from BQ table to pandas dataframe. 
        Data gathered by usual SQL query.
        Data load to cloud stoarge in parquet format.
        
        Args:
            None.
        
        Returns:
            Dataframe.
    """
    query = """
                    SELECT
                        CAST(date AS DATE FORMAT 'YYYYMMDD') AS date,
                        CAST(fullVisitorId AS STRING) AS fullVisitorId,
                        totals.transactions AS transactions,
                        device.browser AS browser,
                        totals.timeOnSite AS timeOnSite,
                        channelGrouping,
                        geoNetwork.country AS country,
                        totals.newVisits AS newVisits,
                        totals.visits AS visits
                    FROM 
                        `bigquery-public-data.google_analytics_sample.ga_sessions_*`
            """
    return pd.read_gbq(query, project_id = PROJECT)
```

Next task uploads dataframe to Google Cloud Storage in parquet format.

```python
def write_to_gcs(df: pd.DataFrame) -> None:
    """
        Upload local parquet file to GCS
        
        Args:
            Dataframe and path.
        
        Returns:
            None.
    
    """

    gcs_block = GcsBucket.load("dtc-de-gcs")
    return gcs_block.upload_from_dataframe(df=df, to_path=GA_PARQUET_FILENAME, serialization_format='parquet')
```

## Data warehouse
I decided to add partitions by date and clusters by countries. Dates usually X-axis for many tiles on dashboards, country one of the coordinality for my dashboard tile. Usually tables in dataset created once and no need to do it in DAG. I created table in dataset using:
```sql
    CREATE OR REPLACE TABLE `ga_data.ga_data_raw`
    (
        date DATE,
        fullVisitorId STRING,
        transactions INTEGER,
        browser STRING,
        timeOnSite INTEGER,
        channelGrouping STRING,
        country STRING,
        newVisits INTEGER,
        visits INTEGER
    )
    CLUSTER BY country
    PARTITION BY date
```

Then using pandas read parquet from bucket:
```python
def extract_from_gcs(path) -> pd.DataFrame:
    """
        Download trip data from GCS
    
        Args:
            Dataframe and path.
        
        Returns:
            None.
    """
    print(path)
    df = pd.read_parquet(path)
    return df
```
 and load it to DWH.
```python
def write_to_bq(df: pd.DataFrame) -> None:
    """
        Write DataFrame to BiqQuery

        Args:
            Dataframe.
        
        Returns:
            None.
    """

    df['date'] = pd.to_datetime(df.date, format='%Y-%m-%dT%H:%M:%S.%f', errors='ignore')
    df['date'] = df.date.dt.date
    df['fullVisitorId'] = df['fullVisitorId'].astype(str)
    
    df.to_gbq(
        destination_table=f"{DATASET}.{GA_TABLE_RAW}",
        project_id=PROJECT,
        credentials=gcp_credentials_block.get_credentials_from_service_account(),
        chunksize=500_000,
        if_exists="replace",
    )
    return True
```


## Transformations with dbt
Cloud dbt job transforms DWH raw data (aka stage data) to data mart layer in DWH which is used to compile dashboard charts on next step. dbt models  (avg_num_trans.sql, avg_time_per_country.sql, trans_per_device.sql, users_per_channel.sql) compiled in job in dbt cloud and executed from flow
```python
result = run_dbt_cloud_job(
        dbt_cloud_job=DbtCloudJob.load("dtc-de-dbt"),
        targeted_retries=3,
    )
```

## Dashboard using Looker Studio
After transformation in DWH using dbt I've got mart tables which I used to solve initially identified problems. 
I created [dashboard](https://lookerstudio.google.com/reporting/0199ddec-d5e2-4e33-9938-2f958fd9add1/page/BdHLD?s=izhgVpIqG4g) with chart|tiles on one page with very simple design. This is for clarity and visibility. In real-life project I could spent much more time on design and ergonoics of dashboard (maybe even more than on data pipeline).


## Reproducibility
To reproduce my project you'll have to do following steps:
1. Prepare VM in GCP Cloud:
   1. Create VM in Compute service with suitable OS.
   2. Install git, python, pip, terraform, conda (if you like it) on it.
   3. Create service account and API json key for it
   4. Copy json key file to VM and set environment to use it working with GCP
2. Clone repository from [link](https://github.com/skipper-com/dtc_de_course_project.git)
3. Terraform components:
   1. Check GCS bucket name ("ga_storage" in my case), GCP project ("dtc-de-project-374319" in my case), GCP region ("europe-west3" in my case), BigQuery dataset ("ga_data" in my case) in 'variables.tf' file.
   2. Init, plan and apply terraform scripts
```python 
terraform init
terraform plan
terraform apply
```
4. Install prefect using with necessary modules 
```
python pip install -r requirements.txt
```
5. Create table in BQ dataset
```sql
    CREATE OR REPLACE TABLE `ga_data.ga_data_raw`
    (
        date DATE,
        fullVisitorId STRING,
        transactions INTEGER,
        browser STRING,
        timeOnSite INTEGER,
        channelGrouping STRING,
        country STRING,
        newVisits INTEGER,
        visits INTEGER
    )
    CLUSTER BY country
    PARTITION BY date
```
6. Prepare dbt
   - Sign in in dbt cloud
   - init project
   - create a branch
   - make a build
   - setup a job cloud

   - Then setup a job cloud
7. Setup prefect blocks:
   - block to connect GCP
   - block to connect GCS
   - block to run dbt job
8. After all preparements just run prefect flow using
```python
python ga_data_pipeline.py
```

Also, it's possible to create deployment with command:
```python
prefect deployment build ./ga_data_pipeline.py:ga_data_flow -n "GA data flow"
prefect deployment apply ga_data_flow-deployment.yaml
```
9. 5-10 minutes later dbt cloud job creates mart table in BQ dataset. These tables are used to create [dashboard](https://lookerstudio.google.com/reporting/0199ddec-d5e2-4e33-9938-2f958fd9add1/page/BdHLD?s=izhgVpIqG4g) like this. 