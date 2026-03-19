# 🚀 Automacao-BackBone

> 🚨 **DOCUMENTAÇÃO OFICIAL DO AMBIENTE (projetoravenna.cloud)** 🚨
> Para detalhes específicos desta implantação (domínios, credenciais, scripts de validação), consulte o:
> 👉 **[MANUAL DE IMPLANTAÇÃO E OPERAÇÃO](./MANUAL_DE_IMPLANTACAO.md)** 👈

Stack de **Atendimento Omnichannel + Automação de Processos**, orquestrada via Docker Compose. Composta por **Chatwoot**, **Evolution API** e **n8n**, integrada à rede principal do projeto Backbone (**`backbone_internal`**).

O projeto é modular, seguro e utiliza o **MinIO principal** do servidor para armazenamento persistente de mídias, garantindo consistência de dados e economia de recursos.

---

## 🏛 Arquitetura da Solução

Todos os serviços compartilham a **rede Docker do Backbone** (`backbone_internal`), o que permite comunicação direta via DNS interno (nome do serviço) sem a necessidade de proxies manuais ou conectores bridge.

- ✅ **Isolamento de Dados:** Cada serviço possui seu próprio Postgres e Redis dedicados.
- ✅ **Storage Centralizado:** Utiliza o container `backbone_minio` pré-existente no servidor.
- ✅ **Comunicação Nativa:** Integração direta entre Chatwoot (via API) e Evolution API.

---

## 🔄 Fluxograma de Dados

```mermaid
graph TD
    classDef external fill:#f9f,stroke:#333,stroke-width:2px;
    classDef internal fill:#e1f5fe,stroke:#0277bd,stroke-width:2px;
    classDef db fill:#fff3e0,stroke:#ef6c00,stroke-width:1px;
    classDef main fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px;

    User(("Usuário / Agente")):::external
    Customer(("Cliente WhatsApp")):::external

    subgraph Backbone_Net ["☁️ backbone_internal (Rede Unificada Docker)"]
        direction TB

        EvolAPI["📱 Evolution API v2\n(Porta: 8081)"]:::internal
        n8n["⚡ n8n 2.8.3\n(Porta: 5678)"]:::internal
        Chatwoot["💬 Chatwoot v4.11.0\n(Porta: 3000)"]:::internal
        
        MinIOBackbone["🗄️ MinIO Principal\n(Hostname: backbone_minio)"]:::main

        PostgresEvol[("Postgres Evolution")]:::db
        PostgresN8N[("Postgres n8n")]:::db
        PostgresChat[("Postgres Chatwoot")]:::db
    end

    User -->|Acesso Web| Chatwoot
    Customer -->|Mensagens WhatsApp| EvolAPI

    EvolAPI -->|"Integração Nativa"| Chatwoot
    Chatwoot -.->|"Upload/Download"| MinIOBackbone
    n8n -->|API| EvolAPI
    n8n -->|API| Chatwoot
```

---

## 🧩 Componentes da Stack

### 1. Chatwoot `v4.11.0`
- **Função:** Plataforma de atendimento (WhatsApp, Live Chat, Email).
- **Storage:** Persistência no MinIO principal (`chatwoot` bucket).

### 2. Evolution API `v2.3.7`
- **Função:** Gateway WhatsApp baseado na biblioteca Baileys. Conecta aparelhos celulares.

### 3. n8n `2.8.3`
- **Função:** Hub de automação Low-Code. Orquestra fluxos entre sistemas.

---

## 📂 Estrutura de Diretórios (Atualizada)

```plaintext
Automacao-BackBone/
├── compose.yaml                    # Orquestrador raiz unificado
├── .env                            # Variáveis globais (DNS, passwords)
├── Chatwoot/
│   ├── compose.yaml                # Chatwoot Web + Worker + DBs
│   └── .env                        # Variáveis Chatwoot (Rails, S3)
├── evolution/
│   └── compose.yaml                # Evolution API + DBs
├── n8n/
│   └── compose.yaml                # n8n + DBs
├── scripts/                        # Scripts de diagnóstico e validação
├── MANUAL_DE_IMPLANTACAO.md        # ⭐ Referência primária
└── INTEGRACAO_CHATWOOT_MINIO.md    # Guia detalhado S3 (Externo)
```

---

*Repositório mantido para a solução Automacao-BackBone — 2026.*
