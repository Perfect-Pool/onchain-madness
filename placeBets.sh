#!/bin/bash

N=5

for ((i=1; i<=N; i++))
do
    echo "Execução número $i"
    yarn place-bets base-testnet
done