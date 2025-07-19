import subprocess
import os
import boto3


def lambda_handler(event, context):
    """
    Get PAT stored in ssm and create a short-live deploy token for fly.io
    """
    FLY_TOKEN_PARAM = os.getenv("FLY_TOKEN_PARAM")
    APPLICATION_NAME = os.getenv("APPLICATION_NAME")

    ssm = boto3.client("ssm")
    pat = ssm.get_parameter(Name=FLY_TOKEN_PARAM, WithDecryption=True)["Parameter"]["Value"]
    os.environ["HOME"] = "/tmp"

    result = subprocess.run(
        ["flyctl", "tokens", "create", "deploy", "--name", "github-deploy-token", "--app", APPLICATION_NAME, "--expiry", "15m", "-t", pat],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )

    if result.returncode != 0:
        raise Exception(result.stderr.decode())

    output = result.stdout.decode().strip()

    return {
        'statusCode': 200,
        'body': output
    }
