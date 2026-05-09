# Fluig Community Container Platform

## 🚀 Objetivo
O **Fluig Community Container** é um projeto focado em modernizar a execução da plataforma TOTVS Fluig utilizando uma arquitetura Docker modular, leve e de fácil manutenção. O objetivo principal é facilitar a criação de ambientes de desenvolvimento, estudo e homologação, removendo a complexidade das instalações manuais tradicionais.

## ✨ Principais Diferenciais
- **Modularidade Total:** Ative ou desative os módulos de Indexação (Solr) e Real-time (Node.js) de forma independente via Docker Compose.
- **Auto-Instalação:** O `entrypoint.sh` executa a instalação silenciosa do Fluig automaticamente na primeira inicialização, incluindo download do driver JDBC e patching do `standalone.xml`.
- **Persistência Completa:** Todos os dados do banco e arquivos do GED (Volume) são preservados através de volumes Docker.
- **Configuração via .env:** Todo o ambiente (portas, senhas, memória, pools) é gerenciado em um único arquivo de variáveis de ambiente.

## 🏗️ Arquitetura
A solução é composta por quatro containers principais:

1. **fluig:** Servidor de aplicação Wildfly/JBoss executando o núcleo da plataforma (BPM, ECM, GED, APIs).
2. **fluig-db:** Instância MySQL 8.0 dedicada para persistência de dados.
3. **fluig-indexer (Opcional):** Servidor Solr dedicado para serviços de busca e indexação.
4. **fluig-realtime (Opcional):** Runtime Node.js para notificações e atualizações em tempo real.

---

## 🛠️ Stack Tecnológica
- **SO Base:** Ubuntu 24.04 LTS
- **Banco de Dados:** MySQL 8.0 (charset `utf8`, collation `utf8_general_ci`)
- **Runtime:** JDK 11 (incluído no instalador Voyager)
- **Orquestração:** Docker Compose v2

## 📁 Estrutura do Projeto
```text
fluig-community-container/
├── docker/
│   ├── .env                       # Central de configurações
│   ├── docker-compose.yml         # Orquestração (App + DB)
│   ├── docker-compose.solr.yml    # Módulo Solr (Indexer)
│   ├── docker-compose.node.yml    # Módulo Node.js (Realtime)
│   ├── Dockerfile                 # Imagem base Ubuntu + dependências
│   └── scripts/
│       ├── entrypoint.sh          # Auto-instalação, patching XML e boot
│       └── install.conf.template  # Template dinâmico para instalação silenciosa
├── docs/
│   ├── RUNBOOK.md                 # Guia operacional e troubleshooting
│   ├── INSTALLATION_LINUX.md      # Guia de instalação bare-metal
│   └── README_DOCKER.md           # Detalhes técnicos da configuração Docker
├── installer-package/             # Coloque aqui o instalador descompactado
└── README.md                      # Este documento
```

## ⚡ Quick Start
```bash
# 1. Descompacte o instalador do Fluig na pasta installer-package/
# 2. Configure o .env conforme necessário
cd docker

# 3. Suba o ambiente completo
docker compose -f docker-compose.yml -f docker-compose.solr.yml -f docker-compose.node.yml up -d --build

# 4. Acompanhe a instalação
docker logs -f fluig

# 5. Acesse no navegador
# http://localhost:8080/portal
```

## 📝 Documentação Adicional
- **[RUNBOOK.md](docs/RUNBOOK.md):** Guia passo a passo de operação, backup e troubleshooting.
- **[INSTALLATION_LINUX.md](docs/INSTALLATION_LINUX.md):** Guia de referência para instalação em bare-metal (Linux tradicional).
- **[README_DOCKER.md](docs/README_DOCKER.md):** Detalhes técnicos da configuração Docker e do `entrypoint.sh`.

---
> [!WARNING]
> Este projeto é voltado para uso em **Desenvolvimento** e **Estudo**. Para ambientes de produção, certifique-se de seguir as diretrizes oficiais de segurança e escalabilidade da TOTVS.
