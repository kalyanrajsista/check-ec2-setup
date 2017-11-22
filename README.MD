# Configuration Management v1.0
### Playbooks, Roles and Modules

## Setup

1. Clone this repository.
2. Make sure the awscli is installed:  pip install awscli
3. Install required Python modules:    pip install -r requirements.txt
4. Create and populate the secrets.yml file with your credentials. Use secrets.yml.example as an example.

## Playbooks

### To create a new environment:

- Edit inventory/hosts and add the new environment name under [product_infrastructure]
- Create a new [ENV_ID:children] based on an existing environment.
- Create a new host variables file as host_vars/ENV_ID by copying an existing environment.
    - After copying, you must change at LEAST env_name and the IP address assignments.
    - It is RECOMMEDED to create a new keypair in AWS and set the new environment to use it.
    - If you are changing regions, you will need to reconfigure all the AMI IDs
- Run the playbook as described below

### Updating an environment:
- Make any changes to host_vars/*, group_vars/*, modules or the playbook itself that are required
- Run the playbook as described below

### Running the playbook for Homeshare
- Run `ansible-playbook slice.yml -e"env_id=ENV_ID"`

### Running the playbook for Rideshare (WIP)
- Run `ansible-playbook slice-rs.yml -e"env_id=ENV_ID"`


# The information below MAY be out of date - Peter K - 08 Jun 2017

*Notes -*
To automatically create an AMI, specify the instance ID in the host_vars YAML file of the desired environment.

### lambda-deploy

Used to deploy Lambda functions.

`WIP`
