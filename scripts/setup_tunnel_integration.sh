#!/bin/bash
# =============================================================================
# setup_tunnel_integration.sh
# =============================================================================
# Integra o Cloudflare Tunnel (backbone_tunnel) à stack do Automacao-BackBone.
#
# Execute UMA VEZ após cada deploy ou restart do backbone:
#   bash scripts/setup_tunnel_integration.sh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Automacao-BackBone — Setup de Integração de Rede   ${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
echo ""

# ─────────────────────────────────────────────────────────
# 1. Verificar pré-requisitos
# ─────────────────────────────────────────────────────────
echo -e "${YELLOW}[1/4] Verificando pré-requisitos...${NC}"

# Verificar se stack_network existe
if ! docker network ls | grep -q "stack_network"; then
    echo -e "${YELLOW}  → Criando rede stack_network...${NC}"
    docker network create stack_network
    echo -e "${GREEN}  ✓ stack_network criada${NC}"
else
    echo -e "${GREEN}  ✓ stack_network já existe${NC}"
fi

# Verificar se o backbone_tunnel está rodando
if ! docker ps --format '{{.Names}}' | grep -q "backbone_tunnel"; then
    echo -e "${RED}  ✗ ERRO: Container backbone_tunnel não está rodando!${NC}"
    echo -e "    Inicie o backbone antes de continuar:"
    echo -e "    cd ~/backbone && docker compose -f docker-compose.prod.yml --env-file .env.prod up -d"
    exit 1
fi
echo -e "${GREEN}  ✓ backbone_tunnel está rodando${NC}"

# ─────────────────────────────────────────────────────────
# 2. Conectar backbone_tunnel à stack_network
# ─────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[2/4] Conectando backbone_tunnel à stack_network...${NC}"

CURRENT_NETWORKS=$(docker inspect backbone_tunnel --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}')

if echo "$CURRENT_NETWORKS" | grep -q "stack_network"; then
    echo -e "${GREEN}  ✓ backbone_tunnel já está na stack_network${NC}"
else
    docker network connect stack_network backbone_tunnel
    echo -e "${GREEN}  ✓ Conexão realizada com sucesso${NC}"
fi

# ─────────────────────────────────────────────────────────
# 3. Verificar containers da stack
# ─────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[3/4] Verificando containers da stack...${NC}"

CONTAINERS=("chatwoot_web:3000" "n8n:5678" "evolution_api:8080" "backbone_minio_automation:9000")
ALL_OK=true

for ENTRY in "${CONTAINERS[@]}"; do
    CONTAINER="${ENTRY%%:*}"
    PORT="${ENTRY##*:}"

    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        STATUS=$(docker inspect "$CONTAINER" --format '{{.State.Status}}')
        HEALTH=$(docker inspect "$CONTAINER" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}')
        echo -e "${GREEN}  ✓ ${CONTAINER} → ${STATUS} (${HEALTH}) → porta interna: ${PORT}${NC}"
    else
        echo -e "${RED}  ✗ ${CONTAINER} → NÃO ENCONTRADO${NC}"
        ALL_OK=false
    fi
done

# ─────────────────────────────────────────────────────────
# 4. Imprimir as rotas corretas para o Cloudflare
# ─────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[4/4] Configuração do Cloudflare Tunnel${NC}"
echo ""
echo -e "${BLUE}Configure as seguintes rotas em:${NC}"
echo -e "${BLUE}https://one.dash.cloudflare.com → Zero Trust → Networks → Tunnels → tunel_VPS → Public Hostname${NC}"
echo ""
echo -e "  ┌─────────────────────────────────────────────────────────────────────────────────┐"
echo -e "  │  DOMÍNIO                               PATH   SERVIÇO                           │"
echo -e "  ├─────────────────────────────────────────────────────────────────────────────────┤"
echo -e "  │  projetoravenna.cloud                  *      http://backbone_frontend:3005      │"
echo -e "  │  api.projetoravenna.cloud              *      http://backbone_backend:8005       │"
echo -e "  │  atendimento.projetoravenna.cloud      *      http://chatwoot_web:3000           │"
echo -e "  │  n8n.projetoravenna.cloud              *      http://n8n:5678                   │"
echo -e "  │  evolution.projetoravenna.cloud        *      http://evolution_api:8080          │"
echo -e "  │  minio.projetoravenna.cloud            *      http://backbone_minio_automation:9000│"
echo -e "  └─────────────────────────────────────────────────────────────────────────────────┘"
echo ""

if [ "$ALL_OK" = true ]; then
    # Teste de conectividade do tunnel para cada serviço
    echo -e "${YELLOW}Testando conectividade do tunnel para os serviços...${NC}"
    for ENTRY in "${CONTAINERS[@]}"; do
        CONTAINER="${ENTRY%%:*}"
        PORT="${ENTRY##*:}"
        if docker exec backbone_tunnel wget --spider -q "http://${CONTAINER}:${PORT}" 2>/dev/null; then
            echo -e "${GREEN}  ✓ backbone_tunnel → ${CONTAINER}:${PORT} — ACESSÍVEL${NC}"
        else
            echo -e "${YELLOW}  ⚠ backbone_tunnel → ${CONTAINER}:${PORT} — sem resposta (pode ser normal para este serviço)${NC}"
        fi
    done
fi

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Setup concluído! Atualize as rotas no Cloudflare.  ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo ""
