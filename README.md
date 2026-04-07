# 🚀 Automacao-BackBone

> 🚨 **DOCUMENTAÇÃO OFICIAL DO AMBIENTE (projetoravenna.cloud)** 🚨
> Toda a documentação detalhada foi migrada para a pasta **`doc/`**.
> Utilize o manual de implantação como ponto de partida:
> 👉 **[MANUAL DE IMPLANTAÇÃO E OPERAÇÃO](./doc/01-manual-implantacao.md)** 👈

Stack de **Atendimento Omnichannel + Automação de Processos**, orquestrada via Docker Compose. Composta por **Chatwoot**, **Evolution API** e **n8n**, operando com **MinIO Local Dedicado** e as versões mais estáveis de Abril 2026.

---

## 🏗️ Arquitetura Modular

A solução agora é 100% modular, independente e focada em performance através da comunicação interna simplificada via Docker DNS.

- ✅ **Isolamento Total:** Cada serviço (com seu BD/Cache) reside em sua própria pasta.
- ✅ **Storage Dedicado:** MinIO local exclusivo da stack para mídias e backups.
- ✅ **Segurança:** Credenciais únicas e senhas fortes rotacionadas em toda a stack.
- ✅ **Rede Interna:** Comunicação nativa entre Chatwoot/n8n/Evolution sem sair para a internet.

---

## 🛠️ O que está incluído (Versões estáveis)

| Componente | Versão | Pasta |
|---|---|---|
| **Chatwoot** | `v4.12.1` | `Chatwoot/` |
| **Evolution API** | `v2.3.7` | `evolution/` |
| **n8n (Versão 2)** | `v2.16.0` | `n8n/` |
| **MinIO (Local)** | `Latest` | `minio/` |

---

## 📂 Guias e Documentação Completa (`doc/`)

Abaixo estão os guias detalhados para cada parte da integração:

1.  **[Manual de Operação](./doc/01-manual-implantacao.md):** Deploy, saúde e comandos rápidos.
2.  **[Integração MinIO (Storage)](./doc/02-integracao-chatwoot-minio.md):** Configurações de mídia persistente.
3.  **[Integração n8n (Webhooks)](./doc/03-integracao-chatwoot-n8n.md):** Comunicação Chatwoot ↔ n8n via API interna.
4.  **[Integração WhatsApp](./doc/04-integracao-whatsapp.md):** Como conectar números via Evolution API.
5.  **[Plano de Refatoração](./doc/05-plano-refatoracao.md):** Detalhes da migração realizada em Abril 2026.

---

## 🚀 Como Iniciar

1.  Configure o arquivo `.env` a partir do template: `cp .env.example .env`.
2.  Ajuste as credenciais no arquivo gerado.
3.  Suba a stack: `docker compose up -d`.
4.  Consulte o **[Manual](./doc/01-manual-implantacao.md)** para validação.

---

*Repositório refatorado e mantido em Abril de 2026 — Stack Automacao-BackBone.*
