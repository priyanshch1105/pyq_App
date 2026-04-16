from datetime import datetime


def heartbeat() -> str:
    return f"scheduler alive: {datetime.utcnow().isoformat()}"
