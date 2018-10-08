#!/bin/bash
export PACKER_TEMPLATE="aws-centos7-base.json"
export AWS_REGION=$1
if [ -z $AWS_REGION ];
then
  echo "Error!  A region must be specified!"
  echo "$0 [AWS_REGION]"
  exit 1
elif [[ "$AWS_REGION" == "-h" ]] || [[ "$AWS_REGION" == "-?" ]] || [[ "$AWS_REGION" == "--help" ]]
then
  echo "$0 [AWS_REGION]"
  exit 1
fi
if [ -z $AWS_PROFILE ];
then
  export AWS_PROFILE='default';
fi
if [ -z $AWS_ACCESS_KEY_ID ];
then
  export AWS_ACCESS_KEY_ID=`aws --profile $AWS_PROFILE configure get aws_access_key_id`
fi
if [ -z $AWS_SECRET_ACCESS_KEY ];
then
  export AWS_SECRET_ACCESS_KEY=`aws --profile $AWS_PROFILE configure get aws_secret_access_key`
fi

if [ -z "$AMI_DESCRIPTION" ];
then
  echo "Determining AMI description... Please wait, this may take awhile!"
  export AMI_DESCRIPTION=$(aws --region ${AWS_REGION} ec2 describe-images --owners aws-marketplace --filters '[ { "Name": "product-code", "Values": ["aw0evgkw8e5c1q413zgy5pjce"] }, { "Name": "virtualization-type", "Values": ["hvm"] } ]' --query 'Images[*].{CreationDate:CreationDate,Description:Description}' --output text | sort -r | head -1 | awk '{ $1=""; print};' | sed -e 's/^[ \t]*//')
  echo "Done!  Continuing with build..."

  if [ -z "$AMI_DESCRIPTION" ];
  then
    echo "Failed to get AMI description!  Try setting manually and re-running!"
    exit 2;
  fi
fi

packer build ${PACKER_TEMPLATE}

echo "Waiting 1 minute before cleaning up extra resources..."
sleep 60
VOL_ID=`aws --region ${AWS_REGION} ec2 describe-volumes --filters='Name=status,Values=available,Name=tag-key,Values="Builder",Name=tag-value,Values="Packer*"' --query 'Volumes[*].{VolumeId:VolumeId}' --output text`
echo "Deleting unattached volume id ${VOL_ID}..."
for V_ID in $VOL_ID
do
  aws --region ${AWS_REGION} ec2 delete-volume --volume-id ${V_ID}
done
