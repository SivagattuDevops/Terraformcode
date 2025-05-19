import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')

    try:
        # Get all instances that are in 'stopped' state
        response = ec2.describe_instances(
            Filters=[
                {'Name': 'instance-state-name', 'Values': ['stopped']}
            ]
        )

        instance_ids = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])

        if not instance_ids:
            return {
                'statusCode': 200,
                'body': 'No stopped instances found.'
            }

        # Start all stopped instances
        ec2.start_instances(InstanceIds=instance_ids)

        return {
            'statusCode': 200,
            'body': f'Started instances: {instance_ids}'
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error: {str(e)}'
        }
