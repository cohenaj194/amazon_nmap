Required environmental variables:

```
AWS_ACCESS_KEY_ID: ((STORAGE_ACCOUNT_AWS_ACCESS_KEY_ID))
AWS_SECRET_ACCESS_KEY: ((STORAGE_ACCOUNT_AWS_SECRET_ACCESS_KEY))
SCAN_AWS_ACCESS_KEY_ID: ((SCANED_ACCOUNT_AWS_ACCESS_KEY_ID))
SCAN_AWS_SECRET_ACCESS_KEY: ((SCANED_ACCOUNT_AWS_SECRET_ACCESS_KEY))
AWS_REGION: us-west-2 
SCAN_ACCOUNT: 'SCANED_ACCOUNT'
NMAP_KEY: ((NMAP_KEY))
OUTLOOK_EMAIL: ((OUTLOOK_EMAIL))
OUTLOOK_EMAIL_PASSWORD: ((OUTLOOK_EMAIL_PASSWORD))
BUCKET_NAME: 'foobar'
BUCKET_PATH: 'path/to/s3/dir'
PEN_TEST_REQUEST_EMAIL_RECIPIENT: foo.bar@whatever.com
AWS_ACCOUNT_NUMBER: 1234567890
AWS_ACCOUNT_EMAIL: someaccount.email@whatever.com
SUBMITTERNAME: 'firstname lastname'
COMPANYNAME: 'Foobar Inc'
SOURCE_INSTANCE_ID: "i-asdfghjkl09876"
SOURCE_IP: "4.3.2.1"
OUTLOOK_DOMAIN: foobar.com
UNIT_TEST_BUCKET: foobucket
PORT_LIST: '["21","22","23","25","53","80"]'
AMI: foobar
SUBNET_ID: foobar
```

To create the needed aws resources run:

```
docker pull amazon-nmap
docker run -e NMAP_KEY_NAME='foobar' \
              SOURCE_IP='foobar' \
              AMI='foobar' \
              SUBNET_ID='foobar' \
              SEC_GROUP='foobar' \
              INSTANCE_NAME='foobar' \
              BUCKET_NAME='foobar' \
              BUCKET_PATH='path/to/s3/dir' \
              AWS_ACCESS_KEY_ID=foobar \
              AWS_SECRET_ACCESS_KEY=foobar \
              AWS_REGION=us-west-2 \
              amazon-nmap 'ansible-playbook /aws-setup/create-nmap-env.yml'
```