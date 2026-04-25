FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Non-root user (UID/GID 1001) — container runs unprivileged.
RUN groupadd -g 1001 app \
 && useradd -u 1001 -g app -m -s /bin/bash app

# Install Python deps first so the layer is cached across source changes.
COPY --chown=app:app requirements.txt ./
RUN pip install -r requirements.txt

# Copy the rest of the application source.
COPY --chown=app:app . .

USER 1001

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
