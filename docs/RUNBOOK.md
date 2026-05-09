# Run Book — Fluig Community Container

Este guia contém as instruções operacionais para gerenciar o ambiente Docker do Fluig.

## 🛠️ 1. Preparação Inicial
Antes de subir o ambiente pela primeira vez:
1. Descompacte o instalador do Fluig dentro da pasta `installer-package/` na raiz do projeto.
2. Edite o arquivo `docker/.env` e defina as senhas e configurações desejadas.
3. Certifique-se de que o Docker e o Docker Compose (v2+) estão instalados.

---

## 🚀 2. Comandos de Inicialização

### Subir Ambiente Completo (Recomendado)
```bash
cd docker
docker compose -f docker-compose.yml -f docker-compose.solr.yml -f docker-compose.node.yml up -d --build
```

### Subir Apenas o Básico (App + DB)
```bash
cd docker
docker compose up -d --build
```

### Subir com Módulos Específicos
```bash
# App + DB + Solr
docker compose -f docker-compose.yml -f docker-compose.solr.yml up -d

# App + DB + Realtime
docker compose -f docker-compose.yml -f docker-compose.node.yml up -d
```

---

## 📊 3. Monitoramento e Logs
A instalação inicial é automática. Acompanhe o progresso pelos logs:
```bash
# Logs do Fluig (instalação e boot)
docker logs -f fluig

# Logs do banco de dados
docker logs -f fluig-db

# Logs do indexador
docker logs -f fluig-indexer

# Logs do realtime
docker logs -f fluig-realtime
```

### Indicadores de Sucesso
Quando a instalação terminar e o servidor estiver pronto, você verá no log:
```
===============================================
== Fluig is up and running right now.        ==
===============================================
```

---

## 🌐 4. Acesso
- **URL:** http://localhost:8080/portal
- **Admin Console (JBoss):** http://localhost:9990
- **Solr:** http://localhost:8983

---

## 🔄 5. Atualização de Versão

### A) Atualização In-place (Recomendada)
1. Substitua o conteúdo da pasta `installer-package/` pela nova versão.
2. No arquivo `docker/.env`, altere `FLUIG_UPDATE=true`.
3. Rode:
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.solr.yml -f docker-compose.node.yml up -d --build
   ```
4. **Importante:** Após a conclusão, volte `FLUIG_UPDATE=false` no `.env`.

### B) Instalação Limpa (Reset Total)
1. Pare o ambiente e remova os volumes:
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.solr.yml -f docker-compose.node.yml down -v
   ```
2. Substitua o instalador na pasta `installer-package/`.
3. Certifique-se de que `FLUIG_UPDATE=true` no `.env`.
4. Suba o ambiente:
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.solr.yml -f docker-compose.node.yml up -d --build
   ```

> [!CAUTION]
> O comando `down -v` **apaga todos os dados** (banco e arquivos). Use apenas quando quiser um ambiente completamente novo.

---

## 💾 6. Backup e Restore

### Backup do Banco de Dados (MySQL)
```bash
docker exec fluig-db mysqldump -u fluig -pfluig fluig > backup_db.sql
```

### Restore do Banco de Dados
```bash
cat backup_db.sql | docker exec -i fluig-db mysql -u fluig -pfluig fluig
```

### Backup do GED (Volume)
Os arquivos do GED estão no volume `fluig-app-data`. Localize fisicamente no host:
```bash
docker volume inspect docker_fluig-app-data
```

---

## 🔧 7. Troubleshooting

### O Fluig não conecta no banco
Verifique no `.env` se o `DB_HOST` está definido como `db` (nome do serviço no compose).

### Erro de Collation (`utf8_general_ci`)
O MySQL deve estar configurado com `--character-set-server=utf8 --collation-server=utf8_general_ci`. Isso já está no `docker-compose.yml`, mas se você resetou os volumes, refaça o `down -v` e suba novamente.

### Erro de Case-Sensitivity nas Tabelas
O MySQL no Linux diferencia maiúsculas de minúsculas por padrão. O parâmetro `--lower-case-table-names=1` no `docker-compose.yml` corrige isso. Se o problema persistir, refaça o `down -v`.

### Redirecionamento para hostname errado
Se o navegador redireciona para um endereço como `http://db:8080` ou `http://fluig-server:8080`, o `entrypoint.sh` deveria ter corrigido isso automaticamente. Verifique se o container subiu com a versão mais recente do script (`docker compose build --no-cache`).

### Erro de Memória (Out of Memory)
Aumente os limites da JVM no `.env` (variáveis `JVM_MIN_HEAP` e `JVM_MAX_HEAP`) e certifique-se de que seu host tem pelo menos 8GB de RAM livre.

### Porta 8080 não responde
Verifique se o `standalone.xml` não está com a porta HTTP configurada incorretamente. O `entrypoint.sh` força a porta 8080 em cada boot, mas se o problema persistir:
```bash
docker exec fluig grep 'socket-binding name="http"' /opt/totvs/fluig/appserver/standalone/configuration/standalone.xml
```

### Reinstalação Forçada
Para forçar uma reinstalação completa:
1. Mude `FLUIG_UPDATE=true` no `.env`.
2. Rode `docker compose down -v && docker compose up -d --build`.

---

## ⚙️ 8. Variáveis de Ambiente (.env)

| Variável | Descrição | Padrão |
|---|---|---|
| `DB_TYPE` | Tipo do banco de dados | `mysql` |
| `DB_HOST` | Host do banco (nome do serviço) | `db` |
| `DB_PORT` | Porta do banco | `3306` |
| `DB_NAME` | Nome do banco | `fluig` |
| `DB_USER` | Usuário do banco | `fluig` |
| `DB_PASSWORD` | Senha do banco | `fluig` |
| `JVM_MIN_HEAP` | Memória mínima da JVM (MB) | `2048` |
| `JVM_MAX_HEAP` | Memória máxima da JVM (MB) | `4096` |
| `FLUIG_UPDATE` | Forçar (re)instalação no boot | `false` |
| `INSTALL_SOLR` | Habilitar módulo Solr | `true` |
| `INSTALL_NODE` | Habilitar módulo Node.js | `true` |

---
