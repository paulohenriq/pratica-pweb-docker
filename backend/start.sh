#!/bin/sh
set -e

echo "Aguardando banco de dados ficar pronto..."
# Aguarda alguns segundos para garantir que o banco está pronto
# (o depends_on com healthcheck já garante isso, mas aguardamos por segurança)
sleep 3

echo "Executando migrations..."
NODE_ENV=${NODE_ENV:-production} npx sequelize-cli db:migrate

if [ $? -eq 0 ]; then
  echo "✓ Migrations executadas com sucesso!"
else
  echo "✗ ERRO: Falha ao executar migrations"
  exit 1
fi

echo "Iniciando servidor..."
exec node server.js
