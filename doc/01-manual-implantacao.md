# 📖 Manual de Implantação e Operação (Refatorado v2.0)
## Stack Automacao-BackBone: Chatwoot · Evolution API · n8n

Este documento é a **referência primária** para operação, manutenção e diagnóstico da solução integrada de atendimento via WhatsApp.

**Data da Versão:** 07/04/2026
**Status:** Refatoração Completa (Clean Stack)
**Domínio Principal:** `projetoravenna.cloud`

---

## 🏗️ 1. Arquitetura da Solução

A stack foi desenhada para ser **modular**, **segura** e **auto-contida**. Todos os serviços rodam em containers Docker orquestrados por um arquivo raiz, comunicando-se através de uma rede interna isolada.

### Componentes Core
| Serviço | Versão | Função | Saúde (Porta Interna) |
|---|---|---|---|
| **Chatwoot** | `v4.12.1` | Dashboard de Atendimento | `http://chatwoot_web:3000` |
| **Evolution API** | `v2.3.7` | Gateway WhatsApp | `http://evolution_api:8080` |
| **n8n** | `v2.16.0` | Automação e Fluxos | `http://n8n:5678` |
| **MinIO** | `Latest` | Armazenamento de Objetos | `http://minio:9000` |

---

## 🛠️ 2. Procedimento Paso-a-Passo de Instalação

### 2.1. Preparação da Rede
A stack utiliza uma rede externa para isolamento. Crie-a no servidor antes do primeiro deploy:
```bash
docker network create backbone_backbone_internal
```

### 2.2. Checklist Pré-Voo
Antes de rodar o comando final, GARANTA que:
- [ ] O arquivo `.env` na raiz está preenchido com senhas únicas.
- [ ] As portas `3000, 5678, 8081 e 9001` estão livres no host (VPS).
- [ ] O Cloudflare Tunnel externo (modo host) está configurado apontando para `localhost`.

### 2.3. Configuração Inicial
1.  Clone o repositório.
2.  Copie os exemplos de ambiente: `cp .env.example .env`.
3.  **Importante:** Gere senhas fortes e rotacione todas as credenciais no `.env`. Gere os segredos para Chatwoot e n8n.

### 2.4. Deploy
```bash
# Subir toda a stack de forma orquestrada
docker compose up -d --force-recreate

# Verificar se o Bucket MinIO foi configurado automaticamente
docker logs minio_setup_sync
```

---

## 🌐 3. Configurações de Domínios e Túnel

Se o seu túnel (Cloudflared) rodar de forma independente em modo `host`, as rotas no painel Zero Trust devem ser:

| Domínio Público | Destino Interno |
|---|---|
| `atendimento.projetoravenna.cloud` | `http://localhost:3000` |
| `evolution.projetoravenna.cloud` | `http://localhost:8081` |
| `n8n.projetoravenna.cloud` | `http://localhost:5678` |
| `minio.projetoravenna.cloud` | `http://localhost:9001` (Console) |

---

## 🩺 4. Monitoramento e Troubleshooting

### 4.1. Verificação de Saúde
Cada serviço possui um `healthcheck` nativo. Verifique o status com:
```bash
docker compose ps
```

### 4.2. Logs em Tempo Real
```bash
# Ver log unificado
docker compose logs -f

# Se o Chatwoot não carregar mídias, confira o sync do MinIO:
docker logs minio_setup_sync
```

---

*Manual revisado pela equipe de Automação — Abril 2026.*
