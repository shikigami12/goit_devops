from django.contrib import admin
from django.db import connection
from django.http import JsonResponse
from django.urls import path


def index(request):
    """Smoke endpoint: confirms Django is up and the DB is reachable."""
    db_ok = False
    db_error = None
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            db_ok = cursor.fetchone() == (1,)
    except Exception as exc:  # pragma: no cover - dev-only diagnostic
        db_error = str(exc)

    return JsonResponse(
        {
            "status": "ok",
            "service": "django",
            "message": "Hello from Dockerized Django + Postgres + Nginx!",
            "database_reachable": db_ok,
            "database_error": db_error,
        }
    )


urlpatterns = [
    path("admin/", admin.site.urls),
    path("", index),
]
