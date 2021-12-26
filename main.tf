module vpc {
source = "./network/vpc"
availability_zones = ["ap-southeast-2a","ap-southeast-2b"]
env = "alb-apigw"
private_subnet_tag_name = "private-subnet"
tags = {
    Name        = "Private Subnet"
    Terraform   = "True"
 }
vpc_tag_name = "vpc for alb-apigw demo"

}

module ecr {
source = "./ecr"
image_name = "test"
source_path = "/home/ec2-user/aws-http-api-private-alb/infrastructure/modules/ecr"
}

module ecs_alb {
source = "./ecs_alb"
vpc_id = module.vpc.vpc_id
private_subnet_ids= module.vpc.private_subnet_ids
alb_security_group = module.vpc.alb_sg
app_port = "80"
env = "alb-apigw"
name = "alb-apigw"
tags  = {
    Name        = "ALB for ECS"
    Terraform   = "True"
 }
}


module ecs_cluster {
source = "./ecs_cluster"
env = "alb-apigw"
tags  = {
    Name        = "ECS cluster"
    Terraform   = "True"
 }
}

#module cognito {
#source = "./cognito"
#cognito_user_pool_name = "cognito_user_pool"
#domain = "poc.csnglobal.net"
#zone_id = "Z01584572MIJQ3CR4KP1B"
#tags  = {
#    Name        = "Cognito User Pool"
#    Terraform   = "True"
# }
#
#}


module api_gateway {
source = "./api_gateway"
env = "alb-apigw"
name = "apigw"
private_subnets=module.vpc.private_subnet_ids
alb_lister_arn = module.ecs_alb.alb_lister_arn
vpc_link_sg_ids = module.vpc.alb_sg
tags  = {
    Name        = "API GW"
    Terraform   = "True"
 }
route53_domain = "poc.csnglobal.net"
#user_pool_id =module.cognito.user_pool_id
#client_id = module.cognito.client_id
}

module cloudfront {
source = "./cloudfront"
api_endpoint = module.api_gateway.api_endpoint
}
    
    
module ecs_microservice {
source = "./ecs_microservice"
alb_listner_arn = module.ecs_alb.alb_lister_arn
#app_image = "996104769930.dkr.ecr.ap-southeast-2.amazonaws.com/test:latest"
app_image = module.ecr.ecr_image_id
alb_route_path = "/test1"
app_port = "80"
cluster_name = module.ecs_cluster.ecs_cluster_name
ecs_max_tasks = 3
ecs_min_tasks = 1
ecs_security_group_id = module.vpc.alb_sg
env = "alb-apigw"
fargate_cpu = 1024
fargate_memory = 2048
name = "carsales1"
private_subnet_ids = module.vpc.private_subnet_ids
tags = {
    Name        = "ECS Microservice"
    Terraform   = "True"
 }
vpc_cidr_block = module.vpc.vpc_cidr
vpc_id = module.vpc.vpc_id
alb_listner_priority = 100
}
