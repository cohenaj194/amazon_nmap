https://hub.docker.com/r/cohenaj194/amazon_nmap/

Required environmental variables:

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

The container can be used outside of concourse through any system that utilizes docker.  Simply pass in the environmental variables above and activate the `/nmap-scan/describe` script to run the scan. For example:

```
$ docker --rm -it \
	-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
	-e SCAN_ACCOUNT=myaccountname \
	..put..the..others..in.... \
	cohenaj194/amazon_nmap /nmap-scan/describe
```

You can create your own s3 bucket and aws instance or use the playbooks in this repo to create them for you.  To use the playbook you will need to create an ec2 keypair (to be the nmap key), ec2 elastic ip (to be the source ip), vpc and subnet, security group, and pick a centos 7 ami to use. Then set the values for these resources as the following environmental variables:

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



