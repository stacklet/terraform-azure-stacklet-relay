# Copyright 2024 Stacklet
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

import json
import logging
import os

import azure.functions as func

from azure.identity import DefaultAzureCredential

import boto3
import botocore


def get_session(client_id, audience, role_arn):
    client = boto3.client("sts")
    creds = DefaultAzureCredential(
        managed_identity_client=client_id, exclude_environment_credential=True
    )
    token = creds.get_token(audience)
    res = client.assume_role_with_web_identity(
        WebIdentityToken=token.token,
        RoleArn=role_arn,
        RoleSessionName="StackletAzureRelay",
    )

    session = boto3.session.Session(
        aws_access_key_id=res["Credentials"]["AccessKeyId"],
        aws_secret_access_key=res["Credentials"]["SecretAccessKey"],
        aws_session_token=res["Credentials"]["SessionToken"],
    )
    logging.info("Got session")
    return session


def main(msg: func.QueueMessage):
    client_id = os.environ["AZURE_CLIENT_ID"]
    audience = os.environ["AZURE_AUDIENCE"]

    target_account = os.environ["AWS_TARGET_ACCOUNT"]
    region = os.environ["AWS_TARGET_REGION"]
    role_name = os.environ["AWS_TARGET_ROLE_NAME"]
    partition = os.environ["AWS_TARGET_PARTITION"]
    role_arn = f"arn:{partition}:iam::{target_account}:role/{role_name}"

    body_string = msg.get_body().decode("utf-8")
    body = json.loads(body_string)
    source = body["data"]["operationName"].split("/")[0]

    logging.info('Handling event:')
    logging.info(body_string)

    try:
        session = get_session(client_id, audience, role_arn)
    except botocore.exceptions.ClientError as e:
        logging.error(f"Error getting session: {e}")
        if e.response["Error"]["Code"] == "AccessDeniedException":
            return  # Don't retry AWS permission (configuration) errors.
        else:
            raise  # Retry other AWS errors (e.g. network errors, etc.) as they may be transient.
    except Exception as e:
        # Note: Unhandled exceptions will cause the event to be retried MaxDequeueCount (5) times
        # before being moved to the "poison" a.k.a. dead-letter queue.
        logging.error(f"Unexpected error getting session ({type(e).__name__}): {e}")
        raise

    try:
        events_client = session.client("events", region_name=region)
        events_client.put_events(
            Entries=[
                {
                    "Time": msg.insertion_time,
                    "Source": source,
                    "DetailType": "CloudEvent/Azure System Topic Event",
                    "Detail": body_string,
                    "EventBusName": os.environ["AWS_TARGET_EVENT_BUS"],
                }
            ]
        )
        logging.info("Event forwarded to Stacklet")
    except botocore.exceptions.ClientError as e:
        logging.error(f"Error forwarding event: {e}")
        if e.response["Error"]["Code"] == "AccessDeniedException":
            return  # Don't retry AWS permission (configuration) errors.
        else:
            raise  # Retry other AWS errors (e.g. network errors, etc.) as they may be transient.
    except Exception as e:
        logging.error(f"Unexpected error forwarding event ({type(e).__name__}): {e}")
        raise  # Not sure what other errors could happen, but maybe worth retrying.
