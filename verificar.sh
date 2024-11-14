#!/bin/bash

echo "Iniciando a verificação dos scripts..."

yarn verify-madness base-testnet
# yarn verify-nft base-testnet
# yarn verify-metadata base-testnet
# yarn verify-image base-testnet
# yarn verify-libraries base-testnet

echo "Verificação concluída."
