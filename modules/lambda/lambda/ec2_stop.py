import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')

    try:
        response = ec2.describe_instances(
            Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
        )
        instance_ids = [
            instance['InstanceId']
            for r in response['Reservations']
            for instance in r['Instances']
        ]

        if not instance_ids:
            return {
                'statusCode': 200,
                'body': 'No running instances found.'
            }

        ec2.stop_instances(InstanceIds=instance_ids)

        return {
            'statusCode': 200,
            'body': f'Stopping instances: {instance_ids}'
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': str(e)
        }
