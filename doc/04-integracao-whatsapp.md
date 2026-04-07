# 📱 Guia de Integração: WhatsApp (Evolution API v2.3.7)

Este guia detalha como conectar seu WhatsApp à stack **Automacao-BackBone** usando a Evolution API para atendimento no Chatwoot e fluxos no n8n.

> **Status:** Versão Estável v2.3.7.

---

## 🏗️ 1. Arquitetura do Gateway

A Evolution API funciona como o principal motor de comunicação WhatsApp da stack:

| Papel | Serviço | Endereço Interno |
|---|---|---|
| **Motor de Mensagens** | Evolution API | `http://evolution_api:8080` |
| **Integração Chatwoot** | Built-in Evolution | `http://chatwoot_web:3000` |
| **Integração n8n** | Eventos via Webhook | `http://n8n:5678` |

---

## 🛠️ 2. Passos para Conectar um Número

### 2.1. Criar uma Instância
Acesse o seu gestor de Evolution ou use a API via cURL:

```bash
# Exemplo de criação de instância
curl -X POST "https://evolution.projetoravenna.cloud/instance/create" \
  -H "Content-Type: application/json" \
  -H "apikey: SUAPERSONAL_APIKEY" \
  -d '{
    "instanceName": "meu_numero",
    "token": "token_opcional",
    "qrcode": true
  }'
```

### 2.2. Ler o QR Code
1.  Acesse a URL externa: `https://evolution.projetoravenna.cloud`.
2.  Leia o QR Code com o WhatsApp (Dispositivos Conectados).

---

## 🔗 3. Configuração Chatwoot

Para conectar a Evolution ao Chatwoot de forma otimizada:

1.  No painel da Evolution, em **Chatwoot**, defina:
    - **Chatwoot URL:** `http://chatwoot_web:3000` (Use DNS interno!)
    - **Account ID:** Seu ID de conta no Chatwoot (ex: 1).
    - **Token:** O Token de acesso da sua conta Chatwoot.
2.  **Habilitar Chatwoot:** Ajuste o `.env` para `CHATWOOT_ENABLED=true`.

---

## 💡 4. Dicas de Estabilidade

- **Desconexão:** Se o celular desconectar, verifique se `CONFIG_SESSION_PHONE_CLIENT=Chrome` está no `.env`.
- **Mídia:** Certifique-se de que o MinIO está rodando para que os áudios e imagens sejam persistidos corretamente.
- **Portas:** A porta externa é a `8081`, mas a interna para webhooks é a `8080`.

---

## 🩺 5. Troubleshooting (WhatsApp)

- **Instância Offline:** Reinicie a Evolution: `docker compose restart evolution_api`.
- **Mensagens não chegam no Chatwoot:** Verifique os logs: `docker compose logs -f evolution_api`.

---

*Manual revisado pela equipe de Automação — 2026.4*
