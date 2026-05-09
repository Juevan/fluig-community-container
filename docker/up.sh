#!/bin/bash

export $(grep -v '^#' .env | xargs)

COMPOSE_FILES="-f docker-compose.yml"

if [ "$INSTALL_SOLR" = "true" ]; then
    COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.solr.yml"
fi

if [ "$INSTALL_NODE" = "true" ]; then
    COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.node.yml"
fi

echo "Iniciando ambiente com os arquivos: $COMPOSE_FILES"

if docker compose version > /dev/null 2>&1; then
    docker compose $COMPOSE_FILES up -d "$@"
elif docker-compose --version > /dev/null 2>&1; then
    docker-compose $COMPOSE_FILES up -d "$@"
else
    echo "ERRO: Docker Compose não encontrado!"
    exit 1
fi
