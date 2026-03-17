# 📱 Guia de Integração: WhatsApp → Chatwoot → n8n

Este guia detalha o fluxo completo de mensagens: desde a chegada no WhatsApp via **Evolution API**, passar pelo **Chatwoot** (atendimento humano), e acionar automações no **n8n**.

> **Ambiente:** `projetoravenna.cloud` | **Status:** Validado e funcional em produção.

---

## Visão Geral do Fluxo

```
[WhatsApp do Cliente]
       ↓ mensagem
[Evolution API v2.3.7]   ← gateway WhatsApp (porta externa: 8081)
       ↓ integração nativa (CHATWOOT_URL=http://chatwoot_web:3000)
[Chatwoot v4.11.0]       ← plataforma de atendimento (porta externa: 3000)
       ↓ webhook interno (http://n8n:5678/webhook/n8n)
[n8n 2.8.3]              ← hub de automação (porta externa: 5678)
       ↓ resposta automática via API
[Evolution API] → [WhatsApp do Cliente]
```

---

## Fase 1: Pré-requisitos de Infraestrutura

Antes de configurar as integrações, garanta que a stack está operacional:

```bash
# Verificar se todos os containers estão saudáveis:
docker compose ps

# Checks de conectividade interna:
docker exec evolution_api wget --spider -q http://chatwoot_web:3000 && echo "Evolution → Chatwoot: OK"
docker exec chatwoot_web wget --spider -q http://n8n:5678/ && echo "Chatwoot → n8n: OK"
docker exec chatwoot_web curl -s http://backbone_minio_automation:9000/minio/health/live && echo "Chatwoot → MinIO: OK"
```

---

## Fase 2: Configurar a Instância WhatsApp (Evolution API)

### 2.1. Acessar o Manager da Evolution

Acesse `https://evolution.projetoravenna.cloud/manager` com a API Key definida no `.env`:

```
AUTHENTICATION_API_KEY=<sua_chave>
```

### 2.2. Criar a Instância

Via Manager ou via API:

```bash
curl -X POST "https://evolution.projetoravenna.cloud/instance/create" \
  -H "Content-Type: application/json" \
  -H "apikey: SUA_API_KEY" \
  -d '{
    "instanceName": "chatwoot_session",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }'
```

### 2.3. Parear o WhatsApp (QR Code)

```bash
curl "https://evolution.projetoravenna.cloud/instance/connect/chatwoot_session" \
  -H "apikey: SUA_API_KEY"
```

O campo `base64` da resposta contém a imagem do QR Code. Escaneie com o aplicativo WhatsApp.

> ✅ **Variáveis obrigatórias para estabilidade da conexão** (já configuradas no `.env`):
> ```env
> CONFIG_SESSION_PHONE_CLIENT=Chrome
> CONFIG_SESSION_PHONE_NAME=Chrome
> ```
> Sem essas variáveis, a instância pode ficar presa em "connecting" ou não exibir o QR Code.

---

## Fase 3: Conectar Evolution API ao Chatwoot (Inbox)

No Chatwoot, crie uma **Caixa de Entrada** do tipo WhatsApp:

1. Acesse `Configurações > Caixas de Entrada > Adicionar Caixa de Entrada`
2. Selecione **API**
3. Configure:

| Campo | Valor |
|---|---|
| **Evolution API URL** | `http://evolution_api:8080` ← porta **interna** do container |
| **Evolution API Key** | Valor de `AUTHENTICATION_API_KEY` no `.env` |
| **Nome da Instância** | `chatwoot_session` (ou o nome que você criou) |

> ⚠️ Use **sempre** o nome do serviço Docker (`evolution_api`) e a porta **interna** (`8080`), não a porta externa (`8081`). A porta 8081 é apenas para acesso externo via proxy reverso.

---

## Fase 4: Configurar Webhook Chatwoot → n8n

Para que mensagens do Chatwoot acionem automações no n8n, um Webhook deve ser criado via API (a interface web do Chatwoot bloqueia URLs internas).

```bash
curl -X POST "https://atendimento.projetoravenna.cloud/api/v1/accounts/1/webhooks" \
  -H "Content-Type: application/json" \
  -H "api_access_token: SEU_TOKEN_CHATWOOT" \
  -d '{
    "webhook": {
      "url": "http://n8n:5678/webhook/n8n",
      "subscriptions": [
        "conversation_created",
        "conversation_status_changed",
        "conversation_updated",
        "message_created",
        "message_updated"
      ]
    }
  }'
```

Ou use o script automatizado:
```powershell
scripts/setup_n8n_webhook.ps1
```

Para mais detalhes sobre este passo, consulte **[INTEGRACAO_CHATWOOT_N8N.md](./INTEGRACAO_CHATWOOT_N8N.md)**.

---

## Fase 5: Configurar o n8n (Workflow de Recebimento)

1. Acesse `https://n8n.projetoravenna.cloud`
2. Crie um novo Workflow
3. Adicione o nó **Webhook** com:
   - **HTTP Method:** POST
   - **Path:** `n8n`
4. **Ative** o Workflow (botão "Active")
5. URL interna (para o Chatwoot): `http://n8n:5678/webhook/n8n`

Um workflow base pode ser importado de `n8n/workflow.json`.

---

## ✅ Lista de Verificação Pós-Configuração

```
[ ] Evolution API: Instância criada e status "open" (WhatsApp pareado)
[ ] Chatwoot: Inbox de WhatsApp criado e conectado à instância
[ ] n8n: Workflow ativo com nó Webhook escutando em /webhook/n8n
[ ] Webhook: Criado no Chatwoot apontando para http://n8n:5678/webhook/n8n
```

**Teste ponta a ponta:**
1. Envie uma mensagem WhatsApp para o número conectado
2. Verifique se a mensagem aparece no Chatwoot (Fase 2 & 3 OK)
3. Verifique se o n8n registra uma nova execução (Fase 4 & 5 OK)

---

## 🛠️ Troubleshooting

### QR Code não aparece ou conexão cai

- Confirme `CONFIG_SESSION_PHONE_CLIENT=Chrome` e `CONFIG_SESSION_PHONE_NAME=Chrome` no `.env`
- Remova a instância e recrie:
  ```bash
  curl -X DELETE "https://evolution.projetoravenna.cloud/instance/delete/chatwoot_session" \
    -H "apikey: SUA_API_KEY"
  ```

### Mensagem chega na Evolution mas não no Chatwoot

```bash
# Verificar conectividade:
docker exec evolution_api wget --spider -q http://chatwoot_web:3000 && echo "OK"

# Verificar logs da Evolution:
docker logs evolution_api --tail=50
```

Confirme que `CHATWOOT_URL=http://chatwoot_web:3000` está no `evolution/compose.yaml`.

### n8n não recebe o webhook

```bash
# Verificar se o webhook está ativo no Chatwoot:
curl "https://atendimento.projetoravenna.cloud/api/v1/accounts/1/webhooks" \
  -H "api_access_token: SEU_TOKEN"

# Verificar conectividade interna:
docker exec chatwoot_web wget --spider -q http://n8n:5678/ && echo "n8n acessível"

# Verificar logs do chatwoot worker (que dispara os webhooks):
docker logs chatwoot_worker --tail=50
```

Confirme que o Workflow no n8n está **ativado** (status "Active").

---

## Referências Rápidas

| Domínio | Serviço | Utilidade |
|---|---|---|
| `https://atendimento.projetoravenna.cloud` | Chatwoot | Interface dos agentes |
| `https://evolution.projetoravenna.cloud` | Evolution API | Manager + API REST |
| `https://n8n.projetoravenna.cloud` | n8n | Editor de Workflows |
| `https://minio.projetoravenna.cloud` | MinIO API S3 | Acesso aos arquivos |

---

*Documentação atualizada em 17/03/2026 — Stack Automacao-BackBone.*
