ansible-playbook -e NMAP_KEY_NAME=$NMAP_KEY_NAME \
                 -e SOURCE_IP=$SOURCE_IP \
                 -e AMI=$AMI \
                 -e SUBNET_ID=$SUBNET_ID \
                 -e SEC_GROUP=$SEC_GROUP \
                 -e INSTANCE_NAME=$INSTANCE_NAME \
                 -e BUCKET_NAME=$BUCKET_NAME \
                 -e BUCKET_PATH=$BUCKET_PATH \
                 -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
                 -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
                 -e AWS_REGION=us-west-2 \
                 create-nmap-env.yml