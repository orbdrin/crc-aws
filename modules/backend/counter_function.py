import boto3
import json
import os

dynamodb = boto3.resource('dynamodb')
ddbTable = os.environ['databaseName']
table    = dynamodb.Table(ddbTable)

def lambda_handler(event, context):
    response = table.get_item(Key={
        "id": 0
    })
    
    count = response['Item']['count']
    count = count + 1
    
    response = table.put_item(Item={
        "id": 0,
        "count": count
    })
    
    apiResponse = {
        "isBase64Encoded": False,
        "statusCode": response['ResponseMetadata']['HTTPStatusCode'],
        "headers": {'Content-Type': 'application/json'},
        "multiValueHeaders": {},
        "body": json.dumps({"count": int(count)})
    }
    
    return apiResponse