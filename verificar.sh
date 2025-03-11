#!/bin/bash

echo "Iniciando a verificação dos scripts..."

yarn verify-ppshare $1
yarn verify-madness $1
yarn verify-nft $1
# yarn verify-metadata $1
# yarn verify-image $1
# yarn verify-libraries $1

echo "Verificação concluída."
