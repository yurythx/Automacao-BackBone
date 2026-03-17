# Guia de Integração: Chatwoot → n8n (Webhooks Internos)

Este documento explica como configurar a comunicação via Webhook entre o **Chatwoot** e o **n8n** usando a rede interna do Docker.

> **Ambiente:** `projetoravenna.cloud` | **Status:** Validado e funcional em produção.

---

## 1. O Problema da Validação de URL

Ao tentar adicionar um Webhook no painel do Chatwoot (`Configurações > Integrações > Webhooks`) apontando para um endereço interno do Docker (ex: `http://n8n:5678/webhook/...`), o sistema retorna:

> _"Por favor, insira uma URL válida"_

O **frontend** do Chatwoot valida se a URL parece um domínio público (ex: `.com`, `.cloud`, `.br`). Hostnames internos como `n8n` são bloqueados na interface.

O **backend**, porém, aceita esses endereços sem restrição.

---

## 2. A Solução: Criação via API

Para contornar a validação de frontend, crie o Webhook diretamente via **API do Chatwoot**.

### Script Automatizado

```powershell
# Execute na raiz do projeto:
scripts/setup_n8n_webhook.ps1
```

O script realiza:
1. Autentica na API do Chatwoot (`https://atendimento.projetoravenna.cloud`)
2. Cria o Webhook apontando para `http://n8n:5678/webhook/n8n` (rede interna Docker)
3. Assina os eventos: `conversation_created`, `conversation_status_changed`, `conversation_updated`, `message_created`, `message_updated`, `webwidget_triggered`

### Criação Manual via cURL

```bash
curl -X POST "https://atendimento.projetoravenna.cloud/api/v1/accounts/1/webhooks" \
  -H "Content-Type: application/json" \
  -H "api_access_token: SEU_TOKEN_AQUI" \
  -d '{
    "webhook": {
      "url": "http://n8n:5678/webhook/n8n",
      "subscriptions": [
        "conversation_created",
        "conversation_status_changed",
        "conversation_updated",
        "message_created",
        "message_updated",
        "webwidget_triggered"
      ]
    }
  }'
```

> O token (`api_access_token`) é obtido em: Chatwoot → Perfil → Clique no avatar → "Access Token".

---

## 3. Configuração do Nó Webhook no n8n

Para que o n8n receba os eventos do Chatwoot:

1. Crie um novo Workflow no n8n
2. Adicione o nó **Webhook** como trigger
3. Configure:
   - **Authentication:** None
   - **HTTP Method:** POST
   - **Path:** `n8n`
4. A URL **interna** (usada no Chatwoot) será: `http://n8n:5678/webhook/n8n`
5. A URL **pública** (para testes externos) será: `https://n8n.projetoravenna.cloud/webhook/n8n`

> 💡 A variável `WEBHOOK_URL=https://n8n.projetoravenna.cloud/` no `n8n/compose.yaml` é o que faz o n8n exibir a URL pública correta na interface. A comunicação interna continua usando `http://n8n:5678`.

---

## 4. Verificação

### Confirmar que o Webhook foi criado

```bash
curl -s "https://atendimento.projetoravenna.cloud/api/v1/accounts/1/webhooks" \
  -H "api_access_token: SEU_TOKEN_AQUI" | jq '.[]  | {id, url}'
```

Deve retornar algo como:
```json
{
  "id": 1,
  "url": "http://n8n:5678/webhook/n8n"
}
```

### Teste ponta a ponta

1. **Ative o Workflow** no n8n (botão "Active")
2. **Envie uma mensagem** no WhatsApp conectado ao Chatwoot
3. No n8n, acesse o Workflow → "Executions" — deve aparecer uma execução nova

---

## 5. Diagrama de Comunicação

```
[Cliente WhatsApp]
       ↓ mensagem
[Evolution API] ──(http://chatwoot_web:3000)──→ [Chatwoot]
                                                      ↓ webhook interno
                                         [n8n] ←──── http://n8n:5678/webhook/n8n
                                           ↓
                                    [Automação / Resposta]
                                           ↓
                             [Evolution API] → [WhatsApp]
```

---

*Documentação atualizada em 17/03/2026 — Stack Automacao-BackBone.*
