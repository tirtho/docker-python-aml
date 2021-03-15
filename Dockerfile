# Start with the Conda 4.9
FROM continuumio/miniconda3

# Create working directory and instruct Docker to use this path
# for all subsequent commands
WORKDIR /app

# Copy requirements.txt from local folder to WORKDIR
COPY requirements.txt requirements.txt

# Upgrade pip first to 20.1.1
# Otherwise azureml-sdk will complain about
# not finding ruamel-yaml package
# (a weird bug in ruamel package possibly)
RUN python -m pip install --upgrade pip==20.1.1

# Execute pip command to install from requirements.txt
RUN pip3 install -r requirements.txt

# In order to avoid the error - "....Failed to load entrypoint 
# automl = azureml.train.automl.run:AutoMLRun._from_run_dto.."
# Install this package
RUN pip3 install azureml-sdk[notebooks]

# Add source code into the image using the COPY command
COPY . .

ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD ["/bin/bash"]
