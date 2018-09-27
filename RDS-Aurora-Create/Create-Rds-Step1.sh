#!/bin/bash

clear

rds_region=""
rds_profile=""
Aurora2S3Role=""
DataBaseName=""
VPC_SG_ID=""

# AWS RDS resion at create aurora
rds_region=$(echo $1 | tr '[A-Z]' '[a-z]')

# AWS Account profile
rds_profile=$(echo $2 | tr '[A-Z]' '[a-z]')

# Access role aurora to s3 bucket
Aurora2S3Role=$(echo $3 | tr '[A-Z]' '[a-z]')

# Aurora Database name
DataBaseName=$(echo $4 | tr '[A-Z]' '[a-z]')

# Aurora database user name
RDS_USER_NAME="b2_dba"

# Aurora database user password
RDS_USER_PASS="qwer1234"

# Aurora Engine type
RDS_ENGINE_NAME="aurora-mysql"

# RDS Subnet Group
SUBNET_GROUP_ID=$(echo $6 | tr '[A-Z]' '[a-z]')

# VPC Security Group
#VPC_SG_ID="sg-107ea07b"
VPC_SG_ID=$(echo $5 | tr '[A-Z]' '[a-z]')

# Replication Count
# if 0 or null then Single
REPLICATION_COUNT=$7

# Aurora database instance type
RDS_INSTANCE_CLASS="db.t2.small"

if [ "$#" -ne 6 ] && [ "$#" -ne 7 ]
then
     echo "---------------------------------------------------------------------------------------------"
     echo " C R E A T E     D A T A B A S E     S H E L L "
     echo ""
     echo " S T E P 1"
     echo "    - C R E A T E   P A R A M E T E R   G R O U P"
     echo "    - C R E A T E   P A R A M E T E R "
     echo "    - C R E A T E   A U R O R A   C L U S T E R"
     echo ""
     echo " usage : b.sh [region] [profile] [aurora to s3 access role name] [new database instance name] [security group] [subnetgroup name]"
     echo ""
     echo "---------------------------------------------------------------------------------------------"
     exit 0
fi

echo "---------------------------------------"
echo "          Database Create"
echo "---------------------------------------"


if [ -z $rds_region  ]
then
     echo " No input region argument "
     exit 0
fi

echo " Region                  : " $rds_region

if [ -z $rds_profile  ]
then
     echo " No input profile argument "
     exit 0
fi

echo " Profile                 : " $rds_profile

if [ -z $Aurora2S3Role  ]
then
     echo " No input s3role argument "
     exit 0
fi

echo " Aurora To S3 Acess Role : " $Aurora2S3Role

if [ -z $DataBaseName  ]
then
     echo " No input DataBase argument "
     exit 0
fi

echo " Database Name           : " $DataBaseName

if [ -z $VPC_SG_ID  ]
then
     echo " No input Security Group "
     exit 0
fi

echo " Subnet Group            : " $SUBNET_GROUP_ID
echo " Security Group          : " $VPC_SG_ID
if [ -z $REPLICATION_COUNT ]; then
    REPLICATION_COUNT=0
elif [ $((REPLICATION_COUNT+0)) -eq 0 ]; then
    REPLICATION_COUNT=0
fi
echo " Replication Count       : " $REPLICATION_COUNT
echo "---------------------------------------"
echo " "
echo -n " Do you want to create the database(y/[n])? "
read YN

if [[ "$YN" = "Y" ]] || [[ "$YN" = "y" ]];then

auroraS3Arn=$(aws iam get-role --role-name $Aurora2S3Role --region=$rds_region --profile=$rds_profile --output text --query 'Role.Arn')
ClusterParameterName=$DataBaseName"-cluster-param"
ParameterName=$DataBaseName"-param"
aws rds describe-db-cluster-parameters --db-cluster-parameter-group-name  $ClusterParameterName --region=$rds_region --profile=$rds_profile

if [ "$?" != "0" ]; then

echo ""
echo " C L U S T E R    P A R A M E T E R    C R E A T E "
echo ""

aws rds create-db-cluster-parameter-group  \
--db-cluster-parameter-group-name $ClusterParameterName \
--db-parameter-group-family aurora-mysql5.7 \
--description 'Aurora cluster parameter group' \
--profile=$rds_profile \
--region=$rds_region

echo ""
echo " C L U S T E R    P A R A M E T E R    M O D I F Y "
echo ""

aws rds modify-db-cluster-parameter-group --db-cluster-parameter-group-name $ClusterParameterName --parameters "ParameterName=aws_default_s3_role,ParameterValue= $auroraS3Arn,ApplyMethod=pending-reboot" --profile=$rds_profile --region=$rds_region

aws rds modify-db-cluster-parameter-group \
--db-cluster-parameter-group-name $ClusterParameterName \
--cli-input-json file://Cluster-Parameter-Modify.json \
--profile=$rds_profile \
--region=$rds_region

echo ""
echo " P A R A M E T E R    C R E A T E "
echo ""

aws rds create-db-parameter-group --db-parameter-group-name $ParameterName --db-parameter-group-family aurora-mysql5.7 --description "New parameter group for B2" --profile=$rds_profile --region=$rds_region

echo ""
echo " P A R A M E T E R    M O D I F Y "
echo ""

aws rds modify-db-parameter-group --db-parameter-group-name $ParameterName --cli-input-json file://Parameter-Modify.json --profile=$rds_profile --region=$rds_region

else
     echo "-----------------------------------------------------------------------------"
     echo "    A L R E A D Y     E X I S T S      C L U S T E R     P A R A M E T E R   "
     echo "-----------------------------------------------------------------------------"
fi

echo ""
echo " C R E A T E   A U R O R A   C L U S T E R    "
echo ""

aws rds  create-db-cluster \
--backup-retention-period 1 \
--db-cluster-identifier $DataBaseName \
--db-cluster-parameter-group-name $ClusterParameterName \
--vpc-security-group-ids $VPC_SG_ID \
--db-subnet-group-name $SUBNET_GROUP_ID \
--master-username $RDS_USER_NAME \
--master-user-password $RDS_USER_PASS \
--preferred-backup-window 02:00-02:30 \
--preferred-maintenance-window Mon:00:30-Mon:01:00 \
--engine ${RDS_ENGINE_NAME} \
--profile $rds_profile \
--region $rds_region \
--enable-cloudwatch-logs-exports '["slowquery"]'

echo ""
echo " W A I T   C R E A T E    A U R O R A    C L U S T E R        "
echo ""

# not work..
#aws rds wait db-instance-available \
#--filter Name=db-cluster-id,Values=$DataBaseName \
#--profile $rds_profile \
#--region $rds_region

sleep 300

echo ""
echo " C R E A T E    A U R O R A    I N S T A N C E      "
echo ""

aws rds add-role-to-db-cluster \
--db-cluster-identifier $DataBaseName \
--role-arn $auroraS3Arn \
--profile $rds_profile \
--region $rds_region

aws rds create-db-instance \
--db-instance-identifier $DataBaseName \
--db-instance-class $RDS_INSTANCE_CLASS \
--engine $RDS_ENGINE_NAME \
--db-parameter-group-name $ParameterName \
--no-auto-minor-version-upgrade \
--no-publicly-accessible \
--db-cluster-identifier $DataBaseName \
--db-subnet-group-name ${SUBNET_GROUP_ID} \
--preferred-maintenance-window Mon:02:00-Mon:02:30  \
--profile $rds_profile \
--region $rds_region

if [ $((REPLICATION_COUNT+0)) -gt 0 ]; then
    ReplicaParameterName=$DataBaseName"-param"


    for i in `seq 1 $REPLICATION_COUNT`
    do
        ReplicaDataBaseName=$DataBaseName"-$i"
        echo "$ReplicaDataBaseName"

echo ""
echo " C R E A T E    A U R O R A    R E P L I C A    I N S T A N C E      "
echo ""

aws rds create-db-instance \
--db-instance-identifier $ReplicaDataBaseName \
--db-instance-class $RDS_INSTANCE_CLASS \
--engine $RDS_ENGINE_NAME \
--db-parameter-group-name $ReplicaParameterName \
--no-auto-minor-version-upgrade \
--no-publicly-accessible \
--db-cluster-identifier $DataBaseName \
--db-subnet-group-name ${SUBNET_GROUP_ID} \
--preferred-maintenance-window Mon:02:00-Mon:02:30  \
--profile $rds_profile \
--region $rds_region

    done
fi

echo ""
echo " W A I T   C R E A T E    A U R O R A    I N S T A N C E        "
echo ""

sleep 500

rdsEndPoint=`aws --profile $rds_profile rds describe-db-clusters --db-cluster-identifier $DataBaseName --query "DBClusters[0].Endpoint"`
rdsEndPoint="${rdsEndPoint%\"}"
rdsEndPoint="${rdsEndPoint#\"}"
echo "Binary Log Retention Before : "`MYSQL_PWD=$RDS_USER_PASS mysql -u $RDS_USER_NAME --host=$rdsEndPoint -N -e 'CALL mysql.rds_show_configuration;' | awk '{print $4}'`
result=`MYSQL_PWD=$RDS_USER_PASS mysql -u $RDS_USER_NAME --host=$rdsEndPoint -N -e "call mysql.rds_set_configuration('binlog retention hours', 168);"`
echo "Binary Log Retention After : "`MYSQL_PWD=$RDS_USER_PASS mysql -u $RDS_USER_NAME --host=$rdsEndPoint -N -e 'CALL mysql.rds_show_configuration;' | awk '{print $4}'`

fi
