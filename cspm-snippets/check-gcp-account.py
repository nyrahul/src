import json
from google.cloud import compute_v1
from google.oauth2 import service_account

with open("./gcp.json") as fd:
    private_key = json.load(fd)
    print(private_key)
    project_id = private_key.get("project_id")
    print(project_id)
    service_account_email = private_key.get("client_email")
    print(service_account_email)
    if not private_key.get("client_email") == service_account_email:
        print("Invalid credentials.")
    credentials = service_account.Credentials.from_service_account_info(private_key)
    try:
        print("hello\n")
        credentials = service_account.Credentials.from_service_account_info(private_key)
        instance_client = compute_v1.InstancesClient(credentials=credentials)
        instance_list = instance_client.list(project=project_id, zone="us-west4-b")
    except Unauthorized as e:
                raise ValidationError("Invalid private key.")
    except NotFound as e:
                raise ValidationError("Invalid project ID.")
    except Exception as e:
                raise ValidationError("Invalid credentials.")
