#!/usr/bin/env bash
gcloud builds submit --tag gcr.io/engineering-devops/smoketest
gcloud run deploy --image gcr.io/engineering-devops/smoketest --platform managed
