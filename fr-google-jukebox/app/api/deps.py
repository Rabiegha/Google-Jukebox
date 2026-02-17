from typing import NoReturn

from fastapi import HTTPException, status
from fastapi.security import HTTPBearer

oauth2_scheme = HTTPBearer()


def raise_400(msg=None) -> NoReturn:
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=msg if msg else "Bad Request",
    )


def raise_401(msg=None) -> NoReturn:
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=msg if msg else "Not authorized.",
    )


def raise_403(msg=None) -> NoReturn:
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=msg if msg else "Forbidden.",
    )


def raise_404(msg=None) -> NoReturn:
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=msg if msg else "Not found.",
    )


def raise_500(msg=None) -> NoReturn:
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail=msg if msg else "Internal Server Error",
    )
