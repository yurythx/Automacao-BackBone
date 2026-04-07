# ⚡ Guia de Integração: Chatwoot → n8n (Webhooks Internos v2.0)

Este documento explica como configurar a comunicação via Webhook entre o **Chatwoot** e o **n8n v2.x** usando a rede interna do Docker para máxima performance e segurança.

> **Ambiente:** `projetoravenna.cloud` | **Status:** Validado e compatível com n8n 2.x.

---

## 🛠️ 1. O Problema da Validação de URL no Frontend

Ao tentar adicionar um Webhook no painel do Chatwoot apontando para hostnames internos (ex: `http://n8n:5678`), a interface bloqueia a URL exibindo:
> _"Por favor, insira uma URL válida"_

No entanto, o **backend** do Chatwoot aceita esses endereços perfeitamente.

---

## 🚀 2. Solução Recomendada: Criação via API

Para contornar o bloqueio de frontend e garantir o uso da rede interna (Docker DNS), crie o Webhook via **API do Chatwoot**.

### Chamada cURL (Substitua `TOKEN` e `ID`)
```bash
curl -X POST "https://atendimento.projetoravenna.cloud/api/v1/accounts/1/webhooks" \
  -H "Content-Type: application/json" \
  -H "api_access_token: SEU_TOKEN_AQUI" \
  -d '{
    "webhook": {
      "url": "http://n8n:5678/webhook/atendimento",
      "subscriptions": [
        "conversation_created",
        "conversation_status_changed",
        "message_created",
        "message_updated"
      ]
    }
  }'
```

> **Dica:** Obtenha seu `api_access_token` no perfil do Chatwoot (clique no seu avatar → Perfil).

---

## ⚙️ 3. Configuração no n8n v2.x

Para que o n8n receba os eventos:

1.  Crie um novo **Workflow** no n8n.
2.  Adicione o nó **Webhook** como trigger.
3.  Defina o **Path** como `atendimento`.
4.  A URL interna (para o Chatwoot) será: `http://n8n:5678/webhook/atendimento`.
5.  A URL externa (para o reverse proxy) será: `https://n8n.projetoravenna.cloud/webhook/atendimento`.

---

## 🗺️ 4. Fluxograma de Comunicação Interna

A comunicação é "estanque", ou seja, os dados nunca saem da rede do Docker:

```plaintext
[Cliente WhatsApp] → [Evolution API] ──(HTTP)──→ [Chatwoot Web]
                                                     ↓ (Webhook Interno)
                                              [n8n 2.x Workflow]
                                                     ↓ (Processamento)
                                              [Evolution API] → [WhatsApp]
```

---

## 🩺 5. Verificação Pós-Configuração

Para listar os webhooks ativos via terminal:
```bash
curl -s "https://atendimento.projetoravenna.cloud/api/v1/accounts/1/webhooks" \
  -H "api_access_token: SEU_TOKEN_AQUI" | jq '.[] | {id, url, subscriptions}'
```

Se o `url` for `http://n8n:5678/...`, a integração está otimizada.

---

*Documentação revisada pela equipe de Automação — 2026.4*
