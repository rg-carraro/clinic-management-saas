FROM python:3.13-slim
COPY --from=ghcr.io/astral-sh/uv:0.12.17 /uv /usr/local/bin/uv
WORKDIR /app
COPY api_backend /app
RUN uv sync --frozen --no-dev && useradd --create-home clinic
ENV PATH="/app/.venv/bin:$PATH"
USER clinic
EXPOSE 8000
CMD ["uvicorn", "clinic.presentation.api:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log"]
