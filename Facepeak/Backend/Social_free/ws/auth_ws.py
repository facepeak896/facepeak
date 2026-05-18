from Backend.Social_free.login.token_service import decode_token, get_user_id

def get_current_user_ws(token: str) -> int:
    payload = decode_token(token)

    if payload.get("type") != "access":
        raise Exception("INVALID_TOKEN_TYPE")

    return get_user_id(payload)