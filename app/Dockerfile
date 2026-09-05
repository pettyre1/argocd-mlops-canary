FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Download the spaCy model during build
RUN python -m spacy download en_core_web_sm

COPY . .

# Default to v1 (overridden in Kube deploy manifest for canary test)
ENV APP_VERSION=v1

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

