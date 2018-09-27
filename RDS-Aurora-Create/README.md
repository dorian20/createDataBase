#############################################################
Parameter-Modify.json			파라미터 그룹 파일 변경 JSON
Cluster-Prameter-Modify.json	클러스터 파라미터 그룹 JSON
Create-Rds-Step1.sh				파라미터 생성 쉘 스크립트
#############################################################



실행 명령 예제
Create-Rds-Step1.sh [region] [profile] [aurora to s3 access role name] [new database instance name] [security group] [subnetgroup name] [repl count]

Create-Rds-Step1.sh {리젼} {프로파일} {오로라 S3 엑세스 롤} {신규 인스턴스명} {보안 그룹 ID} {서브넷 그룹명} {레플리케이션 개수}
sh Create-Rds-Step1.sh ap-northeast-2 l-b2-dev AllowAuroraS3Role b2testlmj sg-8d9c19e6 b2-dev-share-vpc-rds-pri-sng 1


[b2-dev]
vpc : NEW-B2-DEV-SHARE-VPC (vpc-034df46b)
security group : sg-8d9c19e6
subnetgroup name : b2-dev-share-vpc-rds-pri-sng

[ellotte-dev]
vpc : NEW-ELLT-DEV-BIZ-VPC (vpc-184df470)
security group : sg-a59217ce
subnetgroup name : ellt-dev-biz-vpc-rds-pri-sng


[b2-tst]

[ellotte-tst]



# 파라미터 추출
aws rds describe-db-cluster-parameters --db-cluster-parameter-group-name elltdev-cluster-param > .\Sample-Cluster-Parameter.json
aws rds describe-db-parameters --db-parameter-group-name elltdev-param > .\Sample-Parameter.json

# AutoScaling 적용

# IAM ELLOTTE PRD
# arn:aws:iam::430340954761:role/aws-service-role/rds.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_RDSCluster

# Target 등록
aws --profile l-ellotte-prd application-autoscaling register-scalable-target ^
   --service-namespace rds ^
   --resource-id cluster:elltprd6 ^
   --scalable-dimension rds:cluster:ReadReplicaCount ^
   --min-capacity 1 ^
   --max-capacity 4 ^
   --role-arn arn:aws:iam::430340954761:role/aws-service-role/rds.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_RDSCluster

# Policy 등록
aws --profile l-ellotte-prd application-autoscaling put-scaling-policy ^
   --policy-name AutoScaling-Policy-elltprd6-Cpu ^
   --service-namespace rds ^
   --resource-id cluster:elltprd6 ^
   --scalable-dimension rds:cluster:ReadReplicaCount ^
   --policy-type TargetTrackingScaling ^
   --target-tracking-scaling-policy-configuration file://AutoScaling-Config.json
