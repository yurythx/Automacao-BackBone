# 💿 Guia de Integração: Chatwoot + MinIO (Local v2.0)

Este documento detalha como o Chatwoot utiliza o **MinIO Dedicado** desta stack para armazenamento persistente de mídias, garantindo que o seu sistema seja resiliente e totalmente independente de serviços externos.

> **Ambiente:** `projetoravenna.cloud` | **Status:** Refatorado para MinIO Local.

---

## 🏗️ 1. Arquitetura de Mídia

O sistema opera com um container dedicado `minio/minio:latest`, orquestrado no diretório `minio/`.

| Componente | Papel | Endereço Interno |
|---|---|---|
| **Chatwoot** | Plataforma de atendimento (Proxy) | `http://chatwoot_web:3000` |
| **MinIO** | Object Storage Dedicado | `http://minio:9000` |
| **Console UI** | Painel administrativo do S3 | `http://minio:9001` |
| **Rede** | `backbone_internal` | Canal de comunicação interno |

---

## 🔌 2. Configurações de Conectividade

O Chatwoot utiliza a rede Docker interna para se comunicar com o MinIO. Isso garante que a mídia nunca passe pelo Cloudflare ou pela internet pública durante o upload do servidor:

- **Interna (Upload):** `http://minio:9000/backbone-media/`
- **Externa (Download/Proxy):** `https://atendimento.projetoravenna.cloud/rails/active_storage/...`

Isso melhora o tempo de resposta e a segurança.

---

## ⚙️ 3. Variáveis de Ambiente (Chatwoot/.env)

Configure as seguintes variáveis no arquivo do Chatwoot:

```env
# Ativar S3-Compatible
ACTIVE_STORAGE_SERVICE=s3_compatible

# URLs Internas (DNS Docker)
S3_ENDPOINT=http://minio:9000
AWS_S3_ENDPOINT=http://minio:9000

# Estratégia de Proxy (Segurança)
STORAGE_PROXY=true
ACTIVE_STORAGE_URL_STRATEGY=proxy
ACTIVE_STORAGE_HOST=https://atendimento.projetoravenna.cloud

# Bucket e Credenciais
S3_BUCKET_NAME=backbone-media
AWS_ACCESS_KEY_ID=${MINIO_ROOT_USER}
AWS_SECRET_ACCESS_KEY=${MINIO_ROOT_PASSWORD}
AWS_REGION=us-east-1
AWS_S3_FORCE_PATH_STYLE=true
```

---

## 🤖 4. Automação de Bucket (minio_setup_sync)

O serviço `minio_setup_sync` no `minio/compose.yaml` realiza:
1.  **Garantia de Existência:** Cria o bucket `backbone-media` se não existir.
2.  **Estrutura de Pastas:** Cria a pasta `/public`.
3.  **Políticas de Acesso:** Define as permissões necessárias para o Chatwoot.

---

## 🩺 5. Troubleshooting (Resolução de Problemas)

| Sintoma | Causa Provável | Solução |
|---|---|---|
| Erro 500 ao abrir imagem no Dashboard | Erro de DNS interno | Verifique se `backbone_minio` está na mesma rede Docker do `chatwoot_web`. |
| Imagem não carrega | Proxy rails falhando | Verifique se `ACTIVE_STORAGE_HOST` no `Chatwoot/.env` está correto (usar https). |
| `mc fail` nos logs | Credenciais erradas | Confira `MINIO_ROOT_PASSWORD` no `.env` raiz. |

---

*Documentação revisada pela equipe de Automação — 2026.*
