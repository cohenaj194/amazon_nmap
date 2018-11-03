https://hub.docker.com/r/cohenaj194/amazon_nmap/

## Required Environmental Variables:

```
AWS_ACCESS_KEY_ID: ((STORAGE_ACCOUNT_AWS_ACCESS_KEY_ID))
AWS_SECRET_ACCESS_KEY: ((STORAGE_ACCOUNT_AWS_SECRET_ACCESS_KEY))
SCAN_AWS_ACCESS_KEY_ID: ((SCANED_ACCOUNT_AWS_ACCESS_KEY_ID))
SCAN_AWS_SECRET_ACCESS_KEY: ((SCANED_ACCOUNT_AWS_SECRET_ACCESS_KEY))
AWS_REGION: us-west-2 
SCAN_ACCOUNT: 'SCANED_ACCOUNT'
NMAP_KEY_NAME: Foobar
NMAP_KEY: ((NMAP_KEY))
AMI: foobar
SUBNET_ID: foobar

BUCKET_NAME: 'foobar'
BUCKET_PATH: 'path/to/s3/dir'
UNIT_TEST_BUCKET: foobucket # for ci tests only used insteaed of BUCKET_NAME

AWS_ACCOUNT_NUMBER: 1234567890
AWS_ACCOUNT_EMAIL: someaccount.email@whatever.com
SUBMITTERNAME: 'firstname lastname'
COMPANYNAME: 'Foobar Inc'
SOURCE_INSTANCE_ID: "i-asdfghjkl09876"
SOURCE_IP: "4.3.2.1"

PEN_TEST_REQUEST_EMAIL_RECIPIENT: foo.bar@whatever.com
OUTLOOK_EMAIL: ((OUTLOOK_EMAIL))
OUTLOOK_EMAIL_PASSWORD: ((OUTLOOK_EMAIL_PASSWORD))
OUTLOOK_DOMAIN: foobar.com
```

## Use in CI Infastructure

The container was originally designed to be used in [concourse](https://concourse-ci.org/) and several pipeline files are included in this repo.  You can create a concourse server on vagrant using the vagrant file of this repo.  Then you can run the `create-pipeline.sh` bash script to deploy the ci piplines and a function pen testing pipeline into your vagrant. 

The tools container can be used outside of concourse through any system that utilizes docker.  Simply pass in the environmental variables above and activate the `/nmap-scan/describe` script to run the scan. For example:

```
$ docker --rm -it \
	-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
	-e SCAN_ACCOUNT=myaccountname \
	..put..the..others..in.... \
	cohenaj194/amazon_nmap /nmap-scan/describe
```

## Tool Resource Setup

The following aws environmental resources, are required to use the tool:

* An ec2 centos 7 instance, to serve as the nmap scan instance. 
* An S3 bucket with a directory to serve as the `BUCKET_PATH`
* An ec2 keypair (to be used as the NMAP_KEY to access the ec2 instance via ssh)
* An ec2 elastic ip (to be the SOURCE_IP)
* A vpc and subnet (for the ec2 instance)
* A security group (for the ec2 instance)

You can create your own s3 bucket and aws instance or use the playbooks in this repo to create them for you.  There is a set of playbooks that can deploy the ec2 instance and S3 bucket for you under the `aws-setup` directory of this repo.  To use the playbook you will need to create an ec2 keypair (to be the nmap key), ec2 elastic ip (to be the source ip), vpc and subnet, security group, and pick a centos 7 ami to use. Then set the values for these resources as the following environmental variables:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
NMAP_KEY_NAME
SOURCE_IP
AMI
SUBNET_ID
SEC_GROUP
INSTANCE_NAME
BUCKET_NAME
BUCKET_PATH
```

Then run the playbook that will get these values out of your environment to create an ec2 server, s3 bucket and some default master scan lists:

```
ansible-playbook create-nmap-env.yml
```
