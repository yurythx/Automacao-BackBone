# Guia de Integração: Chatwoot + MinIO (S3)

Este documento detalha a configuração para o Chatwoot salvar arquivos (anexos, avatares, exportações) no MinIO em vez do disco local.

> **Ambiente:** `projetoravenna.cloud` | **Status:** Validado e funcional em produção.

---

## 1. Visão Geral

| Componente | Papel |
|---|---|
| **Chatwoot** | Plataforma de atendimento — gera URLs dos arquivos |
| **MinIO** | Object Storage S3-Compatible — armazena os arquivos |
| **Bucket** | `chatwoot` (criado automaticamente na inicialização da stack) |

O Chatwoot usa o protocolo S3 para enviar e buscar arquivos. O MinIO age como um servidor S3 local, sendo acessível publicamente via proxy reverso no domínio `https://minio.projetoravenna.cloud`.

---

## 2. Portas do MinIO nesta Stack

> ⚠️ Este servidor já possui outro MinIO (app backbone) rodando internamente. Para evitar conflito, esta stack usa portas alternativas:

| Interface | Porta no Host | Porta no Container |
|---|---|---|
| API S3 (usado pelo Chatwoot) | `9006` | `9000` |
| Console Web (administração) | `9007` | `9001` |

O proxy reverso do aaPanel aponta `https://minio.projetoravenna.cloud` → `http://127.0.0.1:9006`.

---

## 3. Configuração do Chatwoot (`Chatwoot/.env`)

Usamos a **estratégia de variáveis duplas** (`AWS_*` e `STORAGE_*`) para garantir compatibilidade com diferentes versões das bibliotecas internas do Chatwoot/Rails.

```env
# Ativa o backend S3
ACTIVE_STORAGE_SERVICE=s3_compatible

# Variáveis padrão AWS (usadas pela gem aws-sdk-s3)
S3_BUCKET_NAME=chatwoot
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
AWS_REGION=us-east-1
AWS_S3_ENDPOINT=https://minio.projetoravenna.cloud
AWS_S3_FORCE_PATH_STYLE=true

# Aliases de compatibilidade específicos do Chatwoot
STORAGE_ACCESS_KEY_ID=minioadmin
STORAGE_SECRET_ACCESS_KEY=minioadmin
STORAGE_REGION=us-east-1
STORAGE_ENDPOINT=https://minio.projetoravenna.cloud
STORAGE_BUCKET_NAME=chatwoot
STORAGE_FORCE_PATH_STYLE=true
```

### Pontos críticos

| Variável | Por quê importa |
|---|---|
| `AWS_S3_ENDPOINT` | Deve ser o domínio HTTPS público — o navegador do usuário precisa resolver essa URL para abrir arquivos |
| `AWS_S3_FORCE_PATH_STYLE=true` | Obrigatório no MinIO: usa `host/bucket` em vez de `bucket.host` |
| Após alterar `.env` | Execute `docker compose up -d` para recriar o container |

---

## 4. Bucket e Pasta Pública (Auto-Criados)

O serviço `createbuckets` (definido em `minio/compose.yaml`) é executado automaticamente na primeira inicialização da stack e garante:

- Bucket `chatwoot` criado
- Subpasta `chatwoot/public` com acesso anônimo (`mc anonymous set public`)

```bash
# Para verificar manualmente se o bucket existe:
docker exec backbone_minio_automation mc ls minio/
```

---

## 5. Validação e Testes

Scripts PowerShell disponíveis na pasta `scripts/`:

### `scripts/test_minio_connection.ps1`
Testa conectividade e autenticação com o MinIO.
- ✅ Sucesso: `StatusCode: 200` + XML com lista de buckets
- ❌ Falha: `403 Forbidden` → credenciais incorretas

### `scripts/test_storage_integration.ps1`
Simula upload de anexo via Chatwoot e verifica o redirecionamento para o MinIO.
- ✅ Sucesso: resposta `302 Found` com `Location:` apontando para `https://minio.projetoravenna.cloud/...` (porta `9006` via proxy)
- ❌ Erro 422: Chatwoot não consegue autenticar no S3

---

## 6. Troubleshooting

| Sintoma | Causa Provável | Solução |
|---|---|---|
| Erro 422 ao enviar arquivo | Chatwoot não autentica no S3 | Verifique `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`. Reinicie o container. |
| Arquivo envia, mas não abre (404) | URL interna (`minio:9000`) sendo gerada | Ajuste `AWS_S3_ENDPOINT` para `https://minio.projetoravenna.cloud` |
| `SignatureDoesNotMatch` | Credenciais erradas ou relógio desincronizado | Verifique credenciais. Sincronize o relógio com `timedatectl set-ntp true` |
| Arquivo envia mas URL aponta para porta 9006 | Comportamento esperado — o proxy reverso deve redirecionar | Configure aaPanel: `minio.projetoravenna.cloud` → `http://127.0.0.1:9006` |
| Bucket não existe na inicialização | `createbuckets` falhou | Verifique `docker logs backbone_minio_setup_automation` |

---

*Documentação atualizada em 17/03/2026 — Stack Automacao-BackBone.*
