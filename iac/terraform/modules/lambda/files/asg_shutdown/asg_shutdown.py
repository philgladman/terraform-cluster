# import boto3
# import logging
# import botocore
# import os

# # set up simple logging
# logging.getLogger().setLevel(os.environ['LOGGING_LEVEL'])

# # setting up connection to asg instances
# asg = boto3.client('autoscaling', region_name=os.environ.get('REGION'))
# asg_response = asg.describe_auto_scaling_groups()


# def lambda_handler(event, context):
#     """When triggered, the lambda handler will grab a list of autoscaling groups and set the desired capacity to 0"""
#     asg_list = get_asg_list(asg_response)
#     for g in range(len(asg_list)):
#         if asg_list[g] == "phil-il2-mgmt-bastion-asg" or asg_list[g] == "phil-il2-sbx-bastion-asg" or "eks" in asg_list[g]:
#             continue
#         else:
#             try:
#                 asg.update_auto_scaling_group(
#                     AutoScalingGroupName=asg_list[g],
#                     MinSize=0,
#                     MaxSize=0,
#                     DesiredCapacity=0,
#                 )
#                 logging.info(
#                     "Attempting to scale down ASG: {}".format(asg_list[g]))
#             except botocore.exceptions.ClientError as err:
#                 logging.error(
#                     "Cannot terminate autoscaling group %s, Reason: %s: %s", asg_list[
#                         g], err.response['Error']['Code'], err.response['Error']['Message']
#                 )


# def get_asg_list(response):
#     asg_list = []
#     for r in response['AutoScalingGroups']:
#         asg_name = r['AutoScalingGroupName']
#         asg_list.append(asg_name)

#     return asg_list
