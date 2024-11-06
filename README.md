<!--StartFragment-->

# Implementation of a FastAPI application on GCP using Terraform

<!--StartFragment-->


## How to deploy the API 

#### From Google Cloud portal: 

1. Create a project in Google Cloud Platform named this way : \<application>-\<environment>-\<region>. Example : gcpfastapi-dev-west-europe1
   For the part concerning the region, please use the exact name of the desired region from <https://cloud.google.com/compute/docs/regions-zones>.

2. From this project, create a service account, named as you like. You must grant him ownership rights over the project. Save a service account key in json format and store it locally in the keyvault software of your choice.

3) Enable the Cloud Resource Manager API from the portal.

#### From Github: 

1. In Settings -> Secrets & Variables -> Action -> Secrets, create a new Repository secret named after your project\_id. Please replace the “-” by “\_”. Write the content of your previously generated JSON Service Account key in the secret section : ![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXe6EY74ad62_ZooiMAS24vhLUnTRF27xsfsDQeMCHrghlz47fvEqYb3I_VsB6A9balwPY3kkGBDw74TvhcG8TjarsGhzVu_P5dT2uLx7FxibZ6sOqqPLLPoPnOIlC_31W1mo4qoDTkVsg1TpLUlN5Ly0zBg?key=QZKkidtLdG74wxg8ycs8D6EV)

2. Create a branch from main, named exactly like your project\_id. 

3) From the Action tab, run the workflow “Deploy Infrastructure”, select the branch named after your project and fill the desired inputs. ![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXccgLrBQqQcu2eNLleUzfcSQY7fqdcXxMukF8YdBEK0WX3coNQayLXuUK64k50oo_lXLObsoGZqHPuuPXDidP6Nv2z0GSjmMZZsDBZKO9ttZoXYKfOnlFWeeg0q21AW3g7Ld_rsYUYdFFfeYG3_Wg-qx-E?key=QZKkidtLdG74wxg8ycs8D6EV)

4) Wait up to 15 minutes, go on “Terraform Output” step and retrieve the IP under bastion\_instance\_external\_ip = \<external\_ip>

#### From your internet browser: 

Past \<retrieved\_external\_ip>/docs in a browser search bar and test the API endpoints in the swagger.

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXfQ75TjpbUc2wlO5PGR08WM3V6v2IFlm__PibzaBNIXq9FdGuOUz4Iwk_f1hKda5IoLubvOAAM7BD1IZBY9v5cdD2JtHKXMdO_fqpliZOx62eUGXaLStrNjTrlWdSF9vOBQ4kqVMHqB17ftYw_l2BRTUAV3?key=QZKkidtLdG74wxg8ycs8D6EV)


## How to destroy the API infrastructure

#### From Github:

1. From the Action tab, run the workflow “Destroy Infrastructure” by selecting the branch named after your project.

2) Wait up to 10 minutes and verify that your resources have been deleted on the GCP portal. 


## Solution architecture

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXeA5epzBV9pW2UYDs7UtptWG_LvaPvTQspEZ4YIyf2XiOD1Ej2GIticcV0TMfYh0UjjMFsC3uJ2aPtxPv5g6ODAJQqw6QUwe-82HD15Wl_AoB5w6VFj76FUxXWkMg1fL2WbC0dwwuNtVbtDTqWhuXLMeeWr?key=QZKkidtLdG74wxg8ycs8D6EV)

All azure components are stored in the same project. This project is unique for the \<application>-\<environment>-\<region> combination and is named accordingly.

The infrastructure comprises a virtual network hosting two subnets. 

- The **first subnet is private**, in the region contained in the project\_id. 
  It contains a **VM compute engine named \<project\_id>-fast-api-instance**. This VM contains the API source code and a systemd service that allows it to be exposed on port 8000 as long as the machine is switched on. For security reasons. The machine does not have an external IP address. It is therefore not possible to request the API directly from the Internet using a browser.

- The **second subnet is public**, in the region contained in the project\_id
  It hosts the **VM compute engine named \<project\_id>-bastion-host**.
  This VM acts as a bridge between the VM in the private subnet and the Internet. To do this, it uses nginx to proxy requests to the FastAPI app through port 8000.
  The API is then available at the external address of the bastion (retrievable on GCP or on the step terraform output on Github action) from a browser. The swagger can be used on \<bastion\_external\_ip>/docs.

- The **Cloud SQL instance** contains a MySQL server. It contains an example database containing tables on actors and films. It comes from <https://gist.github.com/ShubhamS32/4c9ccec78a97e7c2bd3461b4e696a559>.
  The tables and data are initialised by the VM in the private subnet to the database when it is first started. 
  The API then queries the data in the database on Cloud SQL and exposes it on its endpoints.
  To call the database, the API uses the password of the user \<var.project\_id>-sql defined randomly on Terraform and stored in a secret on **Secret Manager**.

- The \<project\_id>-bucket-data **bucket in Cloud Storage** hosts the source code for :
  - database initialisation: (sql and python script that can be run from the VM)
  - api operation (main.py using fastAPI)


## CI/CD deployment using Github Action and Terraform

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXeeCqWVTmCy-DyMhXuwkzNRmxCisjl8QakfR69jBqFS_Lc8pokZTajzhsyXHuHJYD-XXI_Dw6NtzpKsqDNM15LWXkDpw4N1t7TWGINyHhK1sqfTIdNb9SAXWUoPoJ195lszim_dZwmnkNFx_gvwvsKnJeY?key=QZKkidtLdG74wxg8ycs8D6EV)

The deployment and destruction of the GCP infrastructure and API is automated by a CI/CD workflow used by Github Action and using Terraform as the Infrastructure as Code (IaC) tool.
The deployment workflow is defined in 2 jobs (Terraform Plan and Terraform Apply). 
They are separated to allow the output of the terraform plan command to be checked before terraform apply is executed (feature not implemented).

These two jobs are separated into several steps:

#### Job Terraform Plan :

1. Checkout the code on the branch specified at input.

2) Extract service account credentials of the GCP project and export it as environment variable.

3. Create the GCP bucket containing the tfstate file and context.tfvars if it doesn't exist, to run terraform with externalised files.

4) Install Terraform

5. terraform init : to initialise the terraform configuration

6) terraform plan : to visualize the resources that will be deployed later with the described configuration.

#### Job Terraform Apply :

Uses the same 1, 2, 4, 5 steps as Terraform Plan job but 

1. Retrieves the context.tfvars file from the bucket created in the first job.

2. terraform apply to deploy the resources on GCP according to the configuration. A retry mechanism has been implemented to restart the command in the event of failure.

3. terraform output: to display the external ip of the bastion, which can be used to access the API. It also displays the characteristics of resources created for test purposes.

### How the FastAPI application is set up in the Compute Instance VMs?

Both private and public VMs are provisioned by Terraform with a specified startup script.

#### For the private VM (startup\_fastapi.sh): 

- Retrieve the current project information.

- Download the python and sql sources to set up the database and run fastAPI.

- Expose the application on port 8000 using systemd.

#### For the public VM (startup\_bastion.sh):

- Configures nginx for bastion functionality.


## GCP Access management

Initially, the aim was to create **IAM groups** and assign them rights over resources with role sets corresponding to business needs. **Users** would then be added to the groups according to their jobs. However, Cloud Identity could not be configured.

Another solution was adopted, that of creating a **Service Account** for each business need. These account services will then be made accessible to different users according to their business.

This is how roles are assigned: 

**API Administrators (api-admin@\<project\_id>.iam.gserviceaccount.com)**

Roles Assigned:

- roles/compute.admin: Full control over Compute Engine resources.

- roles/cloudsql.admin: Admin privileges for Cloud SQL, including instance creation and deletion.

- roles/storage.admin: Full control over Cloud Storage resources.

**API Developers (dev-api@\<project\_id>.iam.gserviceaccount.com)**

Roles Assigned:

- roles/compute.instanceAdmin.v1: Permissions to manage Compute Engine instances (but not full control over Compute Engine).

- roles/cloudsql.client: Limited access to interact with Cloud SQL, suitable for client applications.

**API Operators (operator-api@\<project\_id>.iam.gserviceaccount.com)**

Roles Assigned:

- roles/viewer: Read-only access across most resources in the project. Useful for monitoring without the ability to modify resources.

**Security Auditors (auditor-api@\<project\_id>.iam.gserviceaccount.com)**

Roles Assigned:

- roles/iam.securityReviewer: View permissions for security-related settings and configurations, enabling security audits without the ability to make changes.

#### **Two service accounts are not intended for users:**

- The first was created by you during project setup and allows Github Action to run terraform on the project.

* The second is dedicated to running the VM containing the FastAPI application: 

**FastAPI Compute Engine (private-vm-sa@\<project\_id>.iam.gserviceaccount.com)**

Roles Assigned:

- roles/cloudsql.client: Grants client privileges for Cloud SQL, allowing the VM to access Cloud SQL. This allows the VM to insert tables into the Cloud SQL database and run queries against them with the FastAPI application.

- roles/secretmanager.secretAccessor: Grants read access to secrets in Google Secret Manager, enabling FastAPI app to retrieve the database user password in Secret Manager.

- roles/storage.objectViewer (for the \<project-id>-bucket-data): Grants read-only access to objects within the Cloud Storage bucket, allowing the Compute Engine VM to upload source code stored in the bucket.

<!--EndFragment-->

<!--EndFragment-->
