from django.contrib import admin
from django.db import connection
from django.http import JsonResponse
from django.urls import path


def index(request):
    """Health endpoint: confirms Django is up and the DB is reachable."""
    db_ok = False
    db_error = None
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            db_ok = cursor.fetchone() == (1,)
    except Exception as exc:
        db_error = str(exc)

    return JsonResponse(
        {
            "status": "ok",
            "service": "django",
            "database_reachable": db_ok,
            "database_error": db_error,
        }
    )


urlpatterns = [
    path("admin/", admin.site.urls),
    path("", index),
]
