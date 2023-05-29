import json
import logging
import os

import azure.functions as func

from azure.identity import DefaultAzureCredential

import boto3


def get_session(client_id, audience, role_arn):
    client = boto3.client('sts')
    creds = DefaultAzureCredential(
        managed_identity_client=client_id
    )
    token = creds.get_token(audience)
    try:
        res = client.assume_role_with_web_identity(
            WebIdentityToken=token.token,
            RoleArn=role_arn,
            RoleSessionName="ComingFromAzure"
        )
    except Exception as e:
        logging.error(f'unable to assume role:{e}')
        raise

    session = boto3.session.Session(
        aws_access_key_id=res['Credentials']['AccessKeyId'],
        aws_secret_access_key=res['Credentials']['SecretAccessKey'],
        aws_session_token=res['Credentials']['SessionToken']
    )
    return session


def main(msg: func.QueueMessage):
    client_id = os.environ['AZURE_CLIENT_ID']
    audience = os.environ['AZURE_AUDIENCE']

    target_account = os.environ["AWS_TARGET_ACCOUNT"]
    subscription = os.environ['AZURE_SUBSCRIPTION_ID']
    # TODO: change this
    role_name = "sonny4-azure-assume-role"
    role_arn = f"arn:aws:iam::{target_account}:role/{role_name}"
    region = os.environ['AWS_TARGET_REGION']

    session = get_session(client_id, audience, role_arn)

    events_client = session.client('events', region_name=region)
    body_string = msg.get_body().decode('utf-8')
    body = json.loads(body_string)
    op = body['data']['operationName']

    try:
        events_client.put_events(
           Entries=[
               {
                   "Time": msg.insertion_time,
                   "Source": subscription,
                   "DetailType": f"CloudEvent/azure/{op}",
                   "Detail": body_string,
               }
           ]
        )
    except Exception as e:
        logging.error(f"failed to put event:{e}")
        raise
