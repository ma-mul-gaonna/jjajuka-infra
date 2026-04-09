import boto3
import os

rds = boto3.client("rds")
DB_IDENTIFIER = os.environ["DB_IDENTIFIER"]


def handler(event, context):
    action = event.get("action")

    if action == "stop":
        rds.stop_db_instance(DBInstanceIdentifier=DB_IDENTIFIER)
        print(f"RDS {DB_IDENTIFIER} 정지 요청 완료")
    elif action == "start":
        rds.start_db_instance(DBInstanceIdentifier=DB_IDENTIFIER)
        print(f"RDS {DB_IDENTIFIER} 시작 요청 완료")
    else:
        raise ValueError(f"알 수 없는 action: {action}")
