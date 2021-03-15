# Custom Docker Image for Azure Machine Learning Project

# Prerequisites

Azure Data Science VM – Ubuntu 18, which already has Python, Docker and Visual Studio Code installed. Please verify and if not present install below –

- Python version 3.8 or later. [Download Python](https://www.python.org/downloads/)
- Docker running locally. Follow the instructions to [download and install Docker](https://docs.docker.com/desktop/)
- An IDE or a text editor to edit files. We recommend using [Visual Studio Code](https://code.visualstudio.com/Download).

If you want to login to the Ubuntu Desktop, download and install [X2GoClient](https://wiki.x2go.org/doku.php/doc:installation:x2goclient) in your laptop to connect to the Azure DSVM. Alternatively, you can ssh to the Ubuntu DSVM for the tasks below, as well.

# Create my custom Docker Image

Create the Dockerfile and requirements.txt

Login to the Azure DSVM created above in Prerequisite section, to carry out this project. And open a &#39;Terminal&#39; / bash shell to run the following.

$ git clone [https://github.com/tirtho/docker-python-aml.git](https://github.com/tirtho/docker-python-aml.git)

$ cd docker-python-aml

The _ **requirements.txt** _ contains the list of python packages we plan to put in the docker image.

The _ **Dockerfile** _ file contains information on how to build the docker image. We will create a docker image that includes Conda version 4.9.2 with Python 3.8.5.final.0 from the _ **continuumio/miniconda3** _base image.

The _ **testPythonModulesNeeded.py** _ contains small piece of code to test if the image has all the packages you added in your above _ **requirements.txt** _file.

The Azure Machine Learning notebook is in _ **CreateCustomEnvFromADockerImage.ipynb.** _

The training code and data are in _ **diabetes-training** _ folder.

### Create docker image

	# Name your docker image
	> export MY_DOCKER_IMAGE=tr-linux64-conda-python3.8-docker
	# Build the docker image MY_DOCKER_IMAGE
	# Make sure you have created the requirements.txt and the Dockerfile
	# in the current directory and then run - 
	> sudo docker build –tag $MY_DOCKER_IMAGE .
	# Run the image and do quick test of python location, version, conda version etc
	> sudo docker run -t -i $MY_DOCKER_IMAGE
	# This above command should return a shell in the container.
	# Check the conda and python versions (expected 4.9.2 and 3.8.5.final.0
	(base) root@33396fc07e2:/app# conda info
	# Check if all ML packages are available in the image, by running this test python code
	(base) root@33396fc07e2:/app# python testPythonModulesNeeded.py
	Hello <azureml.core.run. OfflineRun object at …>
	# Exit the container shell
	(base) root@33396fc07e2:/app# exit



# Setup Azure Container Registry

### Create an Azure Container Registry instance

### Create a Service Principal to access images in Azure Container Registry

To access the docker images from the Azure Container Registry, you need to have the credentials to login first. There are multiple ways to achieve this. We will use the service principal option, which is common pattern for access by script.

Run the following Azure CLI code to create the service principal. You can run it in the Cloud Shell from the Azure Portal or from your local machine provided it has the Azure CL installed.

	#!/bin/bash

	# Modify for your environment.
	# ACR_NAME: The name of your Azure Container Registry
	# SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant
	ACR_NAME=<container-registry-name>
	SERVICE_PRINCIPAL_NAME=acr-service-principal
	
	# Obtain the full registry ID for subsequent command args
	ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)

	# Create the service principal with rights scoped to the registry.
	# Default permissions are for docker pull access. Modify the '--role'
	# argument value as desired:
	# acrpull:     pull only
	# acrpush:     push and pull
	# owner:       push, pull, and assign roles
	SP_PASSWD=$(az ad sp create-for-rbac --name http://$SERVICE_PRINCIPAL_NAME --scopes $ACR_REGISTRY_ID --role acrpull --query password --output tsv)
	SP_APP_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)
	
	# Output the service principal's credentials; use these in your services and
	# applications to authenticate to the container registry.
	echo "Service principal ID: $SP_APP_ID"
	echo "Service principal password: $SP_PASSWD"

Check the [documentation](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal#create-a-service-principal) on details on creating service principal.

### Register image in Azure Container Registry

	> sudo az login
	> sudo az acr login –name tbdemoacr
	> sudo docker tag $MY_DOCKER_IMAGE tbdemoacr.azurecr.io/demo-aml/$MY_DOCKER_IMAGE
	> sudo docker push tbdemoacr.azurecr.io/demo-aml/$MY_DOCKER_IMAGE
	# Check if you can pull the image from your registry now
	> sudo docker pull tbdemoacr.azurecr.io/demo-aml/$MY_DOCKER_IMAGE
	# Test the image
	> sudo docker run -t -i $MY_DOCKER_IMAGE

# Setup Azure Machine Learning Environment

### Create Azure Machine Service

### Create AML Environment in notebook

Open Azure Machine Learning Studio and create your notebook or import the notebook _ **CreateCustomEnvFromADockerImage.ipynb** _ from my repository [docker-python-aml](https://github.com/tirtho/docker-python-aml) in github,

Create a folder _ **diabetes-training** _ in the above notebook at the same level where you have created the .ipynb file above. Then, copy the _ **diabetes\_training.py** _ and the _ **diabetes.csv** _ files from my repository [docker-python-aml](https://github.com/tirtho/docker-python-aml) in github.

In _ **CreateCustomEnvFromADockerImage.ipynb** _ edit the following variables to enter your Azure Container Registry address and Service Principal details.

	> env name.docker.base_image = &quot;\&lt;your azure container registry name\&gt;.azurecr.io/demo-aml/\&lt;name of the docker image\&gt;:latest&quot;
	> env\_name.docker.base\_image\_registry.username = &quot;\&lt;azure container registry service principal id\&gt;&quot;
	> env\_name.docker.base\_image\_registry.password = &quot;\&lt;service principal password\&gt;&quot;

Create a Compute Target named CustomAMLCompute or attach to your existing Compute Target by setting the following parameter, cluster\_name in the _ **CreateCustomEnvFromADockerImage.ipynb** _ notebook

	> cluster_name = &quot;CustomAMLCompute&quot;

Now run your notebook _ **CreateCustomEnvFromADockerImage.ipynb** _.

Once it completes go to the Run history and find that the output folder contains the pickled file containing your trained model.

That&#39;s it!!

# Miscellaneous

### Useful Commands

	# Check if image is running in a container
	> sudo docker ps

	# Stop if it is running
	> sudo docker stop $MY\_DOCKER\_IMAGE

	# Check if MY\_DOCKER\_IMAGE is in local docker images list
	> sudo docker images -a

	# List dangling images
	> sudo docker images -f dangling=true

	# Remove dangling images
	> sudo docker image prune

	# Remove existing container named MY\_DOCKER\_IMAGE
	> sudo docker rm $MY\_DOCKER\_IMAGE

	# Remove existing MY\_DOCKER\_IMAGE image
	> sudo docker rmi $MY\_DOCKER\_IMAGE

	# Remove all docker images
	> sudo docker rmi -f $(sudo docker images -a -q)
