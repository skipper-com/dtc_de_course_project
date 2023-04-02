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
    - [Composer](#composer)

## Introduction
*Quite often marketing department needs to evaluate how effective online store and what should be optimized on the site to increase sales. One of the standard tasks of a marketer is to study the statistics of site visits and user behavior on the site.
Fortunately, some of the world's largest Internet companies are helping to capture user activity on websites and provide site owners access to this information.
In my project, I'd loike to consider the issue of obtaining basic information about user purchases in the Internet store using the example of a small dataset from Google Analytics.*

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
4. **What is new users compare the old ones per channel group**

## Cloud
For my project I choose to use Google Cloud Platform (GCP) and dbt cloud tool. I have experience with GCP, AWS and Yandex Cloud and prefered GCP not accidentally. GCP has user-friendly interfaces and a huge set of various tools to build and process data. This project uses only a very small part of the GCP, in reality there are many more tools.
The project stack consists of VM, Cloud Storage, BigQuery datasets/tables, Composer (Airflow in GCP), Looker Studio and dbt cloud tool. The whole project might localized on VM's or even one VM with installed data tools on it (local file share or S3 storage, local PostgreSQL DB and local PowerBI dashboards) but there are two major disadvantages such approach:
- DevOps: time to install, setup, maintain
- Cost: VM is always running and spent resources 
Cloud managed tools allows to concetrate attention on data pipelines rather than setuping and provides pay-per-use model.

**Components used in project:**
1. VM to clone necessary scripts and manifests from repo. Terraform on VM prepares all other components (except dbt cloud tool).
2. Cloud stoage to store objects (files) in the cloud.
3. BigQuery to store raw and processed data.
4. Composer to orchestrate data pipelines and ETL processes[^1].
5. Looker Studio to publish dashboards
6. dbt cloud to exceute ETL processes.

[^1]:Google Composer (Airflow)
Airflow enables you to: orchestrate data pipelines over object stores and data warehouses run workflows that are not data-related create and manage scripted data pipelines as code (Python) Airflow organizes your workflows into DAGs composed of tasks. Airflow (managed cloud version in GCP named '**Composer**') is an easy way to run ETL pipelines quick and reliable. I prefer Airflow over Prefect for lots of guides and materials and also community which supports and develops Airflow.

First of all I've created *terraform* main.tf and variable.tf files to setup environments variables and required resources. Then execute all terraform steps: init, plan, apply - to create storage bucket and BigQuery dataset. 

## Batch data ingestion
To get, process, transform and load data the one DAG in Composer is used. Loading batch data separated to task 'ga_data_load' in which pandas method 'read_gbq' is used. This method helps to load data from BigQuery to Pandas dataframe, then dataframe saved to parquet on GCP.
Following code of this task (also in ga_data_transform.py)

## Data warehouse
I decided to add partitions by date and clusters by countries for researching purpose only. Dates usually X-axis for many tiles on dashboards, country one of the coordinality for my dashboard tile. 
Usually tables in dataset created once and no need to do it in DAG. But in that project for demonstration I decided to use BigQuery Operator in Composer to create table in DWH (partitioned and cluster). Then using pandas read parquet from bucket and load it to DWH.
Following code of these two tasks (also in ga_data_transform.py)

## Transformations with dbt
Cloud dbt transform DWH raw data (aka stage data) to data mart layer in DWH which is used to compile dashboard on next step. dbt scripts (ga_dbt.py) compiled in job inside dbt cloud and executed from DAG
Following code of dbt script and task (also in ga_data_transform.py)

## Dashboard using Looker Studio
After transformation in DWH using dbt I've got data_mart tables which I used to solve initially identified problems. All tiles I decided to place on the same page with very simple design. This is for clarity and visibility. In real-life project I could spent much more time on design and ergonoics of dashboard (maybe even more than on data pipeline).
https://lookerstudio.google.com/reporting/0199ddec-d5e2-4e33-9938-2f958fd9add1/page/BdHLD?s=izhgVpIqG4g

## Reproducibility
To reproduce my project you'll have to do following steps:
1. 
2. 
3. 
4. 
5. 
6. 
7. 
8. f



### Composer
enable composer API
create airflow v2 instance
grant required permissions to service account
set environment variables
