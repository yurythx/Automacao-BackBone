# Manual de Implantação e Operação
## Stack Automacao-BackBone: Chatwoot · Evolution API · n8n

Este documento é a **referência primária** para operação, manutenção e diagnóstico da solução integrada de atendimento via WhatsApp.

**Data da Versão:** 19/03/2026
**Status:** Unificado e Validado (Clean Arch)
**Domínio:** `projetoravenna.cloud`

---

## 1. Visão Geral da Arquitetura

A solução utiliza serviços containerizados orquestrados via Docker Compose, integrados diretamente à rede principal do servidor (**`backbone_internal`**).

| Serviço | Versão | Função |
|---|---|---|
| **Evolution API** | `v2.3.7` | Gateway WhatsApp. Converte mensagens em Webhooks. |
| **Chatwoot** | `v4.11.0` | Plataforma de atendimento multicanal. |
| **MinIO (Backbone)** | `2024-11-07` | Object Storage — Utiliza o container principal do servidor. |
| **n8n** | `2.8.3` | Hub de automação de fluxo. |
| **Postgres / Redis** | `v16/v7` | Bancos de dados e cache isolados por serviço. |

---

## 2. Configurações de Rede e Domínios

Todos os serviços operam na rede **`backbone_internal`**. O Cloudflare Tunnel (`backbone_tunnel`) gerencia o acesso externo.

| Domínio | Destino do Túnel (Interno) |
|---|---|
| `atendimento.projetoravenna.cloud` | `http://chatwoot_web:3000` |
| `evolution.projetoravenna.cloud` | `http://evolution_api:8080` |
| `n8n.projetoravenna.cloud` | `http://n8n:5678` |
| `minio.projetoravenna.cloud` | `http://backbone_minio:9000` |

---

## 3. Procedimento de Deploy

### 3.1. Preparação de Ambiente
1. Certifique-se de que a rede `backbone_internal` já está criada.
2. Configure os arquivos `.env` e `Chatwoot/.env` a partir dos arquivos `.example`.

### 3.2. Subindo a Stack
```bash
# Sincronizar e subir containers
docker compose up -d --force-recreate

# Verificar se o bucket foi garantido no MinIO principal
docker logs minio_setup_sync
```

---

## 4. Manutenção e Comandos Rápidos

```bash
# Ver status de todos os containers
docker compose ps

# Ver logs em tempo real do Chatwoot
docker compose logs -f chatwoot_web

# Reiniciar um serviço específico
docker compose restart evolution_api
```

---

*Documentação atualizada em 19/03/2026 — Arquitetura Simplificada.*
