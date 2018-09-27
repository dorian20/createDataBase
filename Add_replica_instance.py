# -*- coding: utf-8 -*-
import sys
import subprocess
import json

def getRemoveList(all_list):
    remove_list=[]
    if len(all_list) == 0:
        print("제거할 목록 없음")
        return remove_list

    for element in all_list:
        print(element)
    
    print("제외할 값을 입력해주세요.")
    print("더 이상 입력하지 않으시려면 QUIT_ 를 입력해주세요.")
    while True:
        check_flag=0
        input_val=input("제외할 리스트 입력: ")

        if(input_val == "QUIT_"):
            return remove_list

        for database in all_list:
            if(database == input_val):
                check_flag=1
                remove_list.extend([input_val])
        
        if(check_flag==0):
            print("리스트에 없는 값을 입력하였습니다.")
def InputNumber(min_number,max_number):
    while True:
        try:
            number = int(input("숫자를 입력하세요: "))
            if(number >=min_number and number <= max_number):
                return number
            
            print(str(min_number)+"~"+str(max_number)+"까지 입력")
        except Exception as ex:
            continue





if __name__=='__main__':


    next_line_continue="^"


    print("1. PRD")
    print("2. TEST")
    print("3. DEV")
    print("4. 종료")
    env_menu=InputNumber(1,4)
    if env_menu==4:
        sys.exit()
    elif env_menu==1:    
        env = "prd" 
    elif env_menu==2:    
        env = "tst"
    elif env_menu==3:    
        env = "dev" 

    print("인스턴스 총 갯수(추가후):")
    instance_input_count=InputNumber(1,20)

    b2_profile="l-b2-" + env
    ellt_profile="l-ellotte-" + env    



    result=subprocess.Popen("aws --profile "+ ellt_profile +" rds describe-db-clusters",shell=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT).communicate()[0]
    ellt_rds_cluster_list=json.loads(result)

    result=subprocess.Popen("aws --profile "+ b2_profile +" rds describe-db-clusters",shell=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT).communicate()[0]
    b2_rds_cluster_list=json.loads(result)


    b2_rds_cluster=[]
    for b2_cluster in b2_rds_cluster_list["DBClusters"]:
        print(b2_cluster["DBClusterIdentifier"])
        b2_rds_cluster.extend([b2_cluster["DBClusterIdentifier"]])

    

    ellt_rds_cluster=[]
    for ellt_cluster in ellt_rds_cluster_list["DBClusters"]:
        print(ellt_cluster["DBClusterIdentifier"])
        ellt_rds_cluster.extend([ellt_cluster["DBClusterIdentifier"]])

    print("1. 제거안함")
    print("2. 인스턴스제거")
    remove_menu=InputNumber(1,2)

    if remove_menu==2 :
        print("B2 RDS 제거")
        b2_remove_rds=getRemoveList(b2_rds_cluster)
        print("ellt RDS 제거")
        ellt_remove_rds=getRemoveList(ellt_rds_cluster)

        for b2_remove in b2_remove_rds:
            b2_rds_cluster.remove(b2_remove)

        for ellt_remove in ellt_remove_rds:
            ellt_rds_cluster.remove(ellt_remove)  

    b2_rds_instance = []
    for b2_cluster in b2_rds_cluster_list["DBClusters"]:
        for b2_cluster_target in b2_rds_cluster:
            if b2_cluster["DBClusterIdentifier"] ==  b2_cluster_target:                

                result=subprocess.Popen("aws --profile "+ b2_profile +" rds describe-db-instances --db-instance-identifier " + b2_cluster["DBClusterIdentifier"],shell=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT).communicate()[0]
                b2_rds_instance=json.loads(result)

                i=len(b2_cluster["DBClusterMembers"])

                
                for i in range(len(b2_cluster["DBClusterMembers"]),instance_input_count) :
                    print(b2_cluster["DBClusterIdentifier"] + "-" + str(i))
                    #b2_rds_instance.extend([b2_member["DBInstanceIdentifier"]])
                    print("aws rds create-db-instance " + next_line_continue)
                    print("--db-instance-identifier  " + b2_cluster["DBClusterIdentifier"] + "-" + str(i) + " " + next_line_continue)
                    print("--db-instance-class " + b2_rds_instance["DBInstances"][0]["DBInstanceClass"] + " " + next_line_continue)
                    print("--engine " + b2_rds_instance["DBInstances"][0]["Engine"] + " " + next_line_continue)
                    print("--db-parameter-group-name " + b2_rds_instance["DBInstances"][0]["DBParameterGroups"][0]["DBParameterGroupName"] + " " + next_line_continue)
                    print("--no-auto-minor-version-upgrade " + next_line_continue)
                    print("--no-publicly-accessible " + next_line_continue)
                    print("--db-cluster-identifier " + b2_cluster["DBClusterIdentifier"] + " " + next_line_continue)
                    print("--db-subnet-group-name " + b2_rds_instance["DBInstances"][0]["DBSubnetGroup"]["DBSubnetGroupName"] + " " + next_line_continue)
                    print("--preferred-maintenance-window Mon:02:00-Mon:02:30 " + next_line_continue)
                    print("--profile "+ b2_profile  + " " + next_line_continue)
                    print("--region ap-northeast-2 ")
                    print("")




    ellt_rds_instance = []
    for ellt_cluster in ellt_rds_cluster_list["DBClusters"]:
        for ellt_cluster_target in ellt_rds_cluster:
            if ellt_cluster["DBClusterIdentifier"] ==  ellt_cluster_target:                

                result=subprocess.Popen("aws --profile "+ ellt_profile +" rds describe-db-instances --db-instance-identifier " + ellt_cluster["DBClusterIdentifier"],shell=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT).communicate()[0]
                ellt_rds_instance=json.loads(result)

                i=len(ellt_cluster["DBClusterMembers"])

                
                for i in range(len(ellt_cluster["DBClusterMembers"]),instance_input_count) :
                    print(ellt_cluster["DBClusterIdentifier"] + "-" + str(i))
                    #ellt_rds_instance.extend([ellt_member["DBInstanceIdentifier"]])
                    print("aws rds create-db-instance " + next_line_continue)
                    print("--db-instance-identifier  " + ellt_cluster["DBClusterIdentifier"] + "-" + str(i) + " " + next_line_continue)
                    print("--db-instance-class " + ellt_rds_instance["DBInstances"][0]["DBInstanceClass"] + " " + next_line_continue)
                    print("--engine " + ellt_rds_instance["DBInstances"][0]["Engine"] + " " + next_line_continue)
                    print("--db-parameter-group-name " + ellt_rds_instance["DBInstances"][0]["DBParameterGroups"][0]["DBParameterGroupName"] + " " + next_line_continue)
                    print("--no-auto-minor-version-upgrade " + next_line_continue)
                    print("--no-publicly-accessible " + next_line_continue)
                    print("--db-cluster-identifier " + ellt_cluster["DBClusterIdentifier"] + " " + next_line_continue)
                    print("--db-subnet-group-name " + ellt_rds_instance["DBInstances"][0]["DBSubnetGroup"]["DBSubnetGroupName"] + " " + next_line_continue)
                    print("--preferred-maintenance-window Mon:02:00-Mon:02:30 " + next_line_continue)
                    print("--profile "+ ellt_profile  + " " + next_line_continue)
                    print("--region ap-northeast-2 ")
                    print("")
    '''
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
    '''