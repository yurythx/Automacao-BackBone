# Guia de Integração: Chatwoot + MinIO (S3 Externo)

Este documento detalha a configuração para o Chatwoot salvar arquivos (anexos, avatares, exportações) no MinIO principal do servidor, utilizando a rede unificada do projeto.

> **Ambiente:** `projetoravenna.cloud` | **Status:** Unificado e Validado.

---

## 1. Visão Geral da Arquitetura

Nesta stack, **não criamos um novo MinIO**. Em vez disso, conectamos o Chatwoot ao MinIO já existente no servidor (container `backbone_minio`).

| Componente | Papel |
|---|---|
| **Chatwoot** | Plataforma de atendimento — envia arquivos via rede interna. |
| **MinIO** | Container principal (referenciado via `${AWS_S3_ENDPOINT_URL}`) |
| **Rede** | `backbone_internal` — permite comunicação direta sem sair para a internet. |
| **Bucket** | `${AWS_STORAGE_BUCKET_NAME}` (gerenciado pelo serviço `minio_setup_sync`). |

---

## 2. Comunicação e Portas

A comunicação é feita pela rede interna, e o Chatwoot serve os anexos em modo proxy:

- **Interna (Chatwoot → MinIO):** O Chatwoot acessa o endpoint definido em `${AWS_S3_ENDPOINT_URL}` para upload/download.
- **Externa (Navegador → Chatwoot):** O navegador acessa os anexos via `https://atendimento.projetoravenna.cloud/rails/active_storage/...` (proxy), sem precisar resolver o MinIO diretamente.

---

## 3. Configuração do Chatwoot (`Chatwoot/.env`)

As variáveis críticas no Chatwoot para esta integração são:

```env
# Ativa o backend S3
ACTIVE_STORAGE_SERVICE=s3_compatible

# Configuração do Endpoint (interno Docker)
S3_ENDPOINT=${AWS_S3_ENDPOINT_URL}
AWS_S3_ENDPOINT=${AWS_S3_ENDPOINT_URL}
STORAGE_PROXY=true
ACTIVE_STORAGE_URL_STRATEGY=proxy
ACTIVE_STORAGE_HOST=https://atendimento.projetoravenna.cloud

# Bucket e Credenciais
S3_BUCKET_NAME=${AWS_STORAGE_BUCKET_NAME}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
AWS_REGION=${AWS_S3_REGION_NAME}
AWS_S3_FORCE_PATH_STYLE=true
```

---

## 4. Gerenciamento Automatizado de Bucket

O serviço **`minio_setup_sync`** no `compose.yaml` raiz garante a infraestrutura:
- Ele verifica se o bucket definido em `${AWS_STORAGE_BUCKET_NAME}` existe no MinIO principal.
- Ele cria a pasta `/public` necessária.
- Ele define a política de acesso como **pública** para a pasta de arquivos comuns.

---

## 5. Troubleshooting (Resolução de Problemas)

| Sintoma | Causa Provável | Solução |
|---|---|---|
| Erro 500 no Chatwoot ao abrir imagem | Falha na comunicação interna | Verifique se o container `backbone_minio` está na rede `backbone_internal`. |
| Imagem não carrega no navegador | DNS ou Túnel quebrado | Verifique se a rota `minio.projetoravenna.cloud` no Cloudflare aponta para `http://backbone_minio:9000`. |
| Erro de Permissão (403) | Bucket não é público | Rode as instruções do `minio_setup_sync` ou ajuste via Console Web do MinIO. |

---

*Documentação atualizada em 19/03/2026 — Arquitetura Unificada Backbone.*
