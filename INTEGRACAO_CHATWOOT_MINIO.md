# Guia de Integração: Chatwoot + MinIO (S3 Externo)

Este documento detalha a configuração para o Chatwoot salvar arquivos (anexos, avatares, exportações) no MinIO principal do servidor, utilizando a rede unificada do projeto.

> **Ambiente:** `projetoravenna.cloud` | **Status:** Unificado e Validado.

---

## 1. Visão Geral da Arquitetura

Nesta stack, **não criamos um novo MinIO**. Em vez disso, conectamos o Chatwoot ao MinIO já existente no servidor (container `backbone_minio`).

| Componente | Papel |
|---|---|
| **Chatwoot** | Plataforma de atendimento — envia arquivos via rede interna. |
| **MinIO** | Container `backbone_minio` — armazena os arquivos. |
| **Rede** | `backbone_internal` — permite comunicação direta sem sair para a internet. |
| **Bucket** | `chatwoot` (gerenciado pelo serviço `minio_setup_sync`). |

---

## 2. Comunicação e Portas

A comunicação é híbrida para garantir máxima performance e compatibilidade:

- **Interna (Container → MinIO):** O Chatwoot acessa `http://backbone_minio:9000`. Isso evita problemas de DNS e sobrecarga no proxy reverso.
- **Externa (Navegador → MinIO):** O navegador do usuário acessa os arquivos via `https://minio.projetoravenna.cloud`. O MinIO está configurado para gerar essas URLs automaticamente.

---

## 3. Configuração do Chatwoot (`Chatwoot/.env`)

As variáveis críticas no Chatwoot para esta integração são:

```env
# Ativa o backend S3
ACTIVE_STORAGE_SERVICE=s3_compatible

# Configuração do Endpoint Interno
AWS_S3_ENDPOINT=http://backbone_minio:9000
STORAGE_ENDPOINT=http://backbone_minio:9000
STORAGE_PROXY=true

# Bucket e Credenciais
S3_BUCKET_NAME=chatwoot
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
AWS_REGION=us-east-1
AWS_S3_FORCE_PATH_STYLE=true
```

---

## 4. Gerenciamento Automatizado de Bucket

O serviço **`minio_setup_sync`** no `compose.yaml` raiz garante a infraestrutura:
- Ele verifica se o bucket `chatwoot` existe no MinIO principal.
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
