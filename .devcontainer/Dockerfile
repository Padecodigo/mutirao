# PROPÓSITO: imagem mínima do ambiente de desenvolvimento — Node 22, git, bash e
# python3 (para ShrinkWrap/VibeGuard opcionais). Sem bancos, sem serviços e sem
# credenciais embutidas. Usada por .devcontainer/devcontainer.json.

FROM node:22-bookworm-slim

# Ferramentas exigidas por scripts/setup.sh e pelos scripts de segurança.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        bash \
        ca-certificates \
        curl \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

# O código do projeto é montado em /workspace pelo devcontainer (não copiado).
WORKDIR /workspace

# Usuário sem privilégios (o mesmo criado pela imagem oficial do Node).
USER node

# Verificação rápida de que o ambiente tem o que o setup.sh espera.
RUN node --version && git --version && bash --version | head -1 && python3 --version
