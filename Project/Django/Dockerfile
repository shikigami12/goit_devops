FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

RUN groupadd -g 1001 app \
 && useradd -u 1001 -g app -m -s /bin/bash app

COPY --chown=app:app requirements.txt ./
RUN pip install -r requirements.txt

COPY --chown=app:app . .

USER 1001

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
