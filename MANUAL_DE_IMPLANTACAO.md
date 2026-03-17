# Manual de Implantação e Operação
## Stack Automacao-BackBone: Chatwoot · Evolution API · MinIO · n8n

Este documento é a **referência primária** para operação, manutenção e diagnóstico da solução integrada de atendimento via WhatsApp.

**Data da Versão:** 17/03/2026
**Status:** Produção / Validado
**Domínio:** `projetoravenna.cloud`

---

## 1. Visão Geral da Arquitetura

A solução é composta por serviços containerizados orquestrados via Docker Compose, todos conectados à rede Docker externa `stack_network`.

| Serviço | Versão | Função |
|---|---|---|
| **Evolution API** | `v2.3.7` | Gateway WhatsApp. Converte mensagens em Webhooks e integra ao Chatwoot. |
| **Chatwoot** | `v4.11.0` | Plataforma de atendimento multicanal. Recebe mensagens da Evolution API. |
| **MinIO** | `2024-11-07` | Object Storage S3-Compatible. Armazena anexos e mídias do Chatwoot. |
| **n8n** | `2.8.3` | Hub de automação de fluxo (Low-Code). Orquestra regras de negócio. |
| **Postgres** (×3) | `16` / `pg15` | Bancos de dados isolados por serviço. |
| **Redis** (×3) | `7-alpine` | Cache e filas isolados por serviço. |

---

## 2. Configuração do Ambiente

### 2.1. Domínios Configurados

| Domínio | Serviço | Proxy Reverso (aaPanel) |
|---|---|---|
| `atendimento.projetoravenna.cloud` | Chatwoot | `http://127.0.0.1:3000` |
| `evolution.projetoravenna.cloud` | Evolution API | `http://127.0.0.1:8081` |
| `n8n.projetoravenna.cloud` | n8n | `http://127.0.0.1:5678` |
| `minio.projetoravenna.cloud` | MinIO API S3 | `http://127.0.0.1:9006` |

### 2.2. Arquivos de Configuração Críticos

#### A. `.env` (Raiz)
Controla variáveis globais da Evolution API, n8n, MinIO e senhas compartilhadas.

| Variável | Valor atual | Observação |
|---|---|---|
| `SERVER_URL` | `https://evolution.projetoravenna.cloud` | URL pública da Evolution |
| `EVOLUTION_PORT` | `8081` | Porta externa no host |
| `S3_PORT` | `9006` | Porta MinIO API (diferente do MinIO backbone) |
| `S3_CONSOLE_PORT` | `9007` | Porta MinIO Console (diferente do MinIO backbone) |

#### B. `Chatwoot/.env`
Controla configuração do Chatwoot: Rails, banco, Redis e MinIO.

| Variável | Valor | Observação |
|---|---|---|
| `FRONTEND_URL` | `https://atendimento.projetoravenna.cloud` | URL pública do Chatwoot |
| `AWS_S3_ENDPOINT` | `https://minio.projetoravenna.cloud` | Endpoint público do MinIO |
| `FORCE_SSL` | `true` | Obrigatório em produção |
| `SECRET_KEY_BASE` | _(deve ser gerado)_ | Mínimo 128 chars — use `openssl rand -hex 64` |

#### C. `n8n/compose.yaml`
| Variável | Valor |
|---|---|
| `WEBHOOK_URL` | `https://n8n.projetoravenna.cloud/` |
| `N8N_EDITOR_BASE_URL` | `https://n8n.projetoravenna.cloud/` |

---

## 3. Procedimento de Implantação (Deploy)

### 3.1. Pré-Deploy (apenas na primeira vez)

```bash
# 1. Criar a rede Docker compartilhada (se não existir):
docker network create stack_network

# 2. Verificar se as portas do MinIO estão livres:
ss -tlnp | grep -E '9006|9007'
```

### 3.2. Deploy ou Atualização

```bash
# Parar containers (mantém volumes de dados):
docker compose down

# Subir a stack completa:
docker compose up -d

# Acompanhar os logs (Ctrl+C para sair):
docker compose logs -f
```

### 3.3. Aguardar Inicialização

| Serviço | Tempo estimado | O que acontece |
|---|---|---|
| `chatwoot_web` | 1–2 min | Executa `db:prepare` (migrações de banco) |
| `evolution_api` | 30–60 s | Aguarda Postgres e Redis passarem no healthcheck |
| `createbuckets` | 10–30 s | Cria o bucket `chatwoot` no MinIO e encerra |

```bash
# Acompanhar o Chatwoot especificamente:
docker logs -f chatwoot_web

# Verificar status de saúde de todos os containers:
docker compose ps
```

### 3.4. Setup Inicial (Primeira Execução)

1. Acesse `https://atendimento.projetoravenna.cloud` → Crie a conta administrador
2. Acesse `https://n8n.projetoravenna.cloud` → Configure usuário e senha
3. Acesse `https://evolution.projetoravenna.cloud/manager` → Crie a instância WhatsApp

Para as integrações entre serviços, consulte:
- **[INTEGRACAO_WHATSAPP.md](INTEGRACAO_WHATSAPP.md)**: Fluxo completo WhatsApp → Chatwoot → n8n
- **[INTEGRACAO_CHATWOOT_MINIO.md](INTEGRACAO_CHATWOOT_MINIO.md)**: Configuração do storage S3
- **[INTEGRACAO_CHATWOOT_N8N.md](INTEGRACAO_CHATWOOT_N8N.md)**: Webhooks internos Chatwoot → n8n

---

## 4. Validação e Testes (Scripts Automatizados)

Scripts PowerShell disponíveis em `scripts/`:

### 4.1. Diagnóstico Geral

```powershell
scripts/test_services.ps1
```
Verifica o status de todos os serviços (n8n, Chatwoot, Evolution) e lista instâncias/webhooks.
**Resultado esperado:** STATUS: ONLINE para todos os serviços.

### 4.2. Teste de Conexão com MinIO

```powershell
scripts/test_minio_connection.ps1
```
Autentica no MinIO e lista os buckets.
**Resultado esperado:** `StatusCode: 200` com XML de buckets.

### 4.3. Teste de Armazenamento (End-to-End)

```powershell
scripts/test_storage_integration.ps1
```
Cria uma conversa, faz upload de anexo e valida se o Chatwoot redireciona para o MinIO.
**Resultado esperado:** Redirecionamento `302` com URL apontando para `minio.projetoravenna.cloud`.

### 4.4. Configuração de Webhook (n8n)

```powershell
scripts/setup_n8n_webhook.ps1
```
Cria via API o webhook do Chatwoot apontando para o n8n interno (`http://n8n:5678/webhook/n8n`).

---

## 5. Referência Rápida de Comandos

```bash
# Ver status de todos os containers
docker compose ps

# Ver logs em tempo real
docker compose logs -f [nome_do_servico]

# Reiniciar um serviço específico
docker compose restart chatwoot_web

# Parar tudo (sem remover volumes)
docker compose down

# Parar tudo e remover volumes (⚠️ apaga dados)
docker compose down -v

# Forçar recriação dos containers (após mudança de .env)
docker compose up -d --force-recreate
```

---

## 6. Manutenção

### Atualizar uma Imagem

```bash
# Baixar nova versão da imagem
docker compose pull chatwoot_web

# Recriar o container com a nova imagem
docker compose up -d chatwoot_web
```

### Mudança de Domínio ou IP

Caso o domínio mude, atualize os arquivos:
- `.env` → `SERVER_URL`
- `Chatwoot/.env` → `FRONTEND_URL`, `AWS_S3_ENDPOINT`, `STORAGE_ENDPOINT`
- `n8n/compose.yaml` → `WEBHOOK_URL`, `N8N_EDITOR_BASE_URL`
- Scripts em `scripts/` que contenham URLs hardcoded

### Backup dos Volumes

Dados críticos estão nos volumes Docker:

| Volume | Conteúdo |
|---|---|
| `postgres_data` | Banco de dados do Chatwoot |
| `postgres_evolution_data` | Banco de dados da Evolution API |
| `postgres_n8n_data` | Banco de dados do n8n |
| `redis_evolution_data` | Cache e sessões da Evolution |
| `s3_data` | Arquivos e anexos (MinIO) |
| `evolution_data` | Instâncias e sessões WhatsApp |
| `n8n_data` | Workflows e credenciais do n8n |

```bash
# Exemplo de backup do volume de arquivos:
docker run --rm -v automacao-backbone_s3_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/s3_data_backup_$(date +%Y%m%d).tar.gz /data
```
