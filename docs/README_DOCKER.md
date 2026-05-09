# Fluig 2.0 Docker (Modular)

Este diretório contém a configuração para rodar o TOTVS Fluig 2.0 (Voyager) no Docker de forma modular e persistente.

## Estrutura
- **fluig:** Container principal com o Wildfly/JBoss (App Server).
- **fluig-db:** MySQL 8.0 (charset `utf8`, collation `utf8_general_ci`, `lower_case_table_names=1`).
- **fluig-indexer:** Container Solr para indexação (opcional, via `docker-compose.solr.yml`).
- **fluig-realtime:** Container Node.js para eventos em tempo real (opcional, via `docker-compose.node.yml`).

## Como Usar

### 1. Preparação
- Os arquivos do instalador (descompactados) devem estar na pasta `installer-package/` na raiz do projeto.
- O sistema localiza automaticamente o `fluig-installer.jar` e a pasta `jdk-64` dentro desta pasta.

### 2. Subir o Ambiente
```bash
# Ambiente completo (App + DB + Solr + Realtime)
docker compose -f docker-compose.yml -f docker-compose.solr.yml -f docker-compose.node.yml up -d --build

# Apenas App + DB
docker compose up -d --build
```

### 3. Acompanhar Logs
```bash
docker logs -f fluig
```

### 4. Acessar
- **Portal:** http://localhost:8080/portal
- **Admin Console:** http://localhost:9990

## O que o `entrypoint.sh` Faz Automaticamente

O script de inicialização executa as seguintes tarefas em cada boot:

1. **Aguarda o banco** ficar disponível via TCP.
2. **Gera o `install.conf`** a partir do template, substituindo variáveis de ambiente.
3. **Baixa o driver JDBC** (MySQL Connector/J 8.0.33) se necessário.
4. **Executa a instalação silenciosa** (apenas se `FLUIG_UPDATE=true` ou se é a primeira execução).
5. **Aplica patches no `standalone.xml`:**
   - Força interfaces de rede para `0.0.0.0` (acesso externo no Docker).
   - Substitui placeholders de e-mail (`__email_smtpServer__`, `__email_smtpPort__`).
   - Força a porta HTTP para `8080`.
   - Substitui `127.0.0.1` por `localhost` para redirecionamentos corretos.
6. **Inicia o Wildfly** com `-b 0.0.0.0 -bmanagement 0.0.0.0`.

## Persistência
- **`fluig-app-data`:** Volume com os binários e configurações do Fluig (`/opt/totvs/fluig`).
- **`fluig-db-data`:** Volume com os dados do MySQL (`/var/lib/mysql`).

> [!IMPORTANT]
> A primeira execução demora alguns minutos pois o instalador descompacta e configura todos os arquivos. Acompanhe com `docker logs -f fluig`.

> [!CAUTION]
> O comando `docker compose down -v` **apaga ambos os volumes**. Use apenas para reset total.
