# lnett-Infrasight

## Før publisering gjenstår følgende forbedringer

- Flytte hemmeligheter til Azure Key Vault eller tilsvarende løsning
- Forbedre autentisering mot Databricks og Grafana
- Etablere tilkobling til Neo4j-databasen som kjører på serveren

## Deploy (GitHub Actions → Azure App Service, Docker-containere)

Workflows: `.github/workflows/deploy-backend.yml` og `.github/workflows/deploy-frontend.yml` (kjører ved push til `main` eller manuelt).

Hver workflow bygger et image fra `backend/Dockerfile` eller `frontend/Dockerfile`, kjører en smoke test mot imaget, pusher det til Azure Container Registry (ACR) og peker App Service på imaget. Lokalt kan du teste med f.eks. `docker build -t infra-api backend` og `docker build --build-arg VITE_API_BASE_URL=http://localhost:8000 -t infra-web frontend`.

**GitHub-miljø `production` – secrets:**

- `AZURE_CREDENTIALS` – JSON fra `az ad sp create-for-rbac --sdk-auth`. Tjenesteprinsippen trenger contributor på ressursgruppen og `AcrPush` på ACR-en.
- `AZURE_RESOURCE_GROUP` – ressursgruppen til begge App Services
- `VITE_API_BASE_URL` – backend-URL, f.eks. `https://lnett-webapp-infrasight1-api.azurewebsites.net` (påkrevd, bakes inn i frontend-imaget ved bygging)

**GitHub-miljø `production` – variables:**

- `AZURE_ACR_NAME` – navnet på container registry (uten `.azurecr.io`)

**Engangsoppsett i Azure:**

- Opprett ACR og gi tjenesteprinsippen `AcrPush`.
- Gi begge App Services `AcrPull` på ACR-en. Workflowene forsøker å gjøre dette selv (system-assigned managed identity), men det krever rettigheter til å lage rolletildelinger. Hvis det mangler, får du en advarsel i loggen og må legge det til manuelt.

**App settings på backend (`lnett-webapp-infrasight1-api`) som må settes manuelt:**

- `NEO4J_URI`, `NEO4J_USER`, `NEO4J_PASSWORD`

Workflowene setter selv `WEBSITES_PORT` (8000 for backend, 8080 for frontend), image-konfigurasjonen, og `CORS_ALLOWED_ORIGINS` på backend (frontend-URL, kun hvis den ikke allerede er satt; kommaseparert liste). Eventuell gammel oppstartskommando nullstilles, siden den ellers overstyrer `CMD` i imaget.

Rekkefølge ved første deploy: backend først, deretter frontend.
