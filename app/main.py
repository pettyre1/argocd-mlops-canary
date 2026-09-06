import os
import time
from fastapi import FastAPI, Request
from pydantic import BaseModel
from prometheus_client import make_asgi_app, Histogram, Counter

from nlp import extract_named_entities

app = FastAPI(title="MLOps NLP Service")


# Prometheus Metrics Config
# This Histogram tracks latency to trigger
# the ArgoCD Rollouts AnalysisTemplate
REQUEST_LATENCY = Histogram(
  "http_request_latency_seconds",
  "Latency of HTTP requests in seconds",
  ["endpoint"]
)
REQUEST_COUNT = Counter(
  "http_requests_total",
  "Total HTTP requests",
  ["endpoint", "http_status"]
)

# Expose the metrics for Prometheus to scrape
matrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


# Middleware to automatically track metrics on all incoming requests
@app.middleware("http")
async def record_metrics(request: Request, call_next):
  start_time = time.time()
  response = await call_next(request)
  latency = time.time() - start_time

  # Ignore /metrics endpoint itself to prevent skewed data
  if request.url.path != "/metrics":
    REQUEST_LATENCY.labels(endpoint=request.url.path).observe(latency)
    REQUEST_COUNT.labels(endpoint=request.url.path,
                         http_status=response.status_code).inc()
  return response


# Application Logic
class TextPayload(BaseModel):
  text:str

APP_VERSION = os.getenv("APP_VERSION", "v1")

@app.post("/extract-entities")
async def extract_entities(payload: TextPayload):
  # Simulate model degradation in the v2 canary deployment
  if APP_VERSION == "v2":
     time.sleep(3) # push latency over 2-second GitOps threshold

  entities = extract_named_entities(payload.text)

  return {
    "version": APP_VERSION,
    "entities": entities
  }

# Trigger CI build
