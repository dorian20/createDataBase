#!/bin/bash
  
clear

rds_region=""
rds_profile=""
AllowRedShiftAndS3="AllowRedShiftAndS3"
DataBaseName=""

# RedShift resgion 
rds_region=$1

# AWS Account profile
rds_profile=$2

# Database name
DataBaseName=$3

# Database user name
USER_NAME="b2_dba"

# Database user password
USER_PASS="Qwer1234"

# Database instance type
INSTANCE_CLASS="dc1.large"

# Paramater Group Family
PARAM_GROUP_FAM="redshift-1.0"

# ellotte-vpc-184df470

# Cluster subnet group
# b2-dev : b2-dev-olap
# ellotte-dev : elltolap-dev-sg
CLUSTER_SUBNET_GROUP_NAME="ellt-dev-share-vpc-redshift-pri-sng"

# Vpc security group
# b2-dev : sg-d4a520bf
# ellotte-dev : sg-fc068297
VPC_SECURITY_GROUP_IDS="sg-fc068297"
	
if [ "$#" -ne 3 ]
then
     echo "---------------------------------------------------------------------------------------------"
     echo " C R E A T E       R E D S H I F T       D A T A B A S E         S H E L L "
     echo ""
     echo " S T E P 1"
     echo "    - C R E A T E   P A R A M E T E R   G R O U P"
     echo "    - C R E A T E   R E D S H I F T    C L U S T E R "
     echo "    - M O D I F Y    C L U S T E R     S 3    A C C E S S    R O L E"
     echo ""
     echo " usage : MakeRed.sh [region] [profile] [new database instance name]"
     echo ""
     echo "---------------------------------------------------------------------------------------------"
     exit 0
fi

if [ -z $rds_region  ]
then
     echo " No input region argument "
     exit 0
fi

echo ""
echo " R E G I O N : " $rds_region
echo ""

if [ -z $rds_profile  ]
then
     echo " No input profile argument "
     exit 0
fi

echo ""
echo " P R O F I L E : " $rds_profile
echo ""

if [ -z $DataBaseName  ]
then
     echo " No input DataBase argument "
     exit 0
fi

echo ""
echo " D A T A    B A S E    N A M E : " $DataBaseName
echo ""

# Paramater Group Name
CLUSTER_PARAM_NAME=$DataBaseName"-cluster-parameter-group"

# Cluster Indent
CLUSTER_INDENT=$DataBaseName

AllowRedShiftAndS3_ARN=$(aws iam get-role --role-name $AllowRedShiftAndS3 --region=$rds_region --profile=$rds_profile --output text --query 'Role.Arn')

aws redshift create-cluster-parameter-group \
--parameter-group-name $CLUSTER_PARAM_NAME \
--parameter-group-family $PARAM_GROUP_FAM \
--description "LEPS cluster parameter group" \
--region $rds_region \
--profile $rds_profile

sleep 300

aws redshift create-cluster \
--db-name $DataBaseName \
--node-type $INSTANCE_CLASS \
--number-of-nodes 2 \
--master-username $USER_NAME \
--master-user-password $USER_PASS \
--cluster-identifier $CLUSTER_INDENT \
--cluster-parameter-group-name $CLUSTER_PARAM_NAME \
--preferred-maintenance-window sat:03:30-sat:04:00 \
--cluster-type multi-node \
--cluster-subnet-group-name $CLUSTER_SUBNET_GROUP_NAME \
--vpc-security-group-ids $VPC_SECURITY_GROUP_IDS \
--region $rds_region \
--profile $rds_profile


#--cluster-type multi-node
#--number-of-nodes 3

sleep 1000

aws redshift modify-cluster-iam-roles \
--cluster-identifier $CLUSTER_INDENT \
--add-iam-roles $AllowRedShiftAndS3_ARN \
--region $rds_region \
--profile $rds_profile

