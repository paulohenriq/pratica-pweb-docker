#!/bin/sh
set -e

echo "Aguardando banco de dados ficar pronto..."
# Aguarda alguns segundos para garantir que o banco está pronto
# (o depends_on com healthcheck já garante isso, mas aguardamos por segurança)
sleep 3

# Conecta ao banco postgres padrão e cria o banco se não existir
DB_NAME_VALUE=${DB_NAME:-todolist}
DB_HOST_VALUE=${DB_HOST:-db}
DB_PORT_VALUE=${DB_PORT:-5432}
DB_USER_VALUE=${DB_USER:-postgres}
DB_PASSWORD_VALUE=${DB_PASSWORD:-postgres}

echo "Verificando se o banco de dados '${DB_NAME_VALUE}' existe..."
export PGPASSWORD=${DB_PASSWORD_VALUE}

# Verifica se o banco existe
DB_EXISTS=$(psql -h ${DB_HOST_VALUE} -p ${DB_PORT_VALUE} -U ${DB_USER_VALUE} -d postgres -tc \
  "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME_VALUE}'" | xargs)

if [ "$DB_EXISTS" != "1" ]; then
  echo "Banco de dados '${DB_NAME_VALUE}' não existe. Criando..."
  psql -h ${DB_HOST_VALUE} -p ${DB_PORT_VALUE} -U ${DB_USER_VALUE} -d postgres -c \
    "CREATE DATABASE \"${DB_NAME_VALUE}\";"
  if [ $? -eq 0 ]; then
    echo "✓ Banco de dados '${DB_NAME_VALUE}' criado com sucesso!"
  else
    echo "✗ ERRO: Falha ao criar banco de dados"
    exit 1
  fi
else
  echo "✓ Banco de dados '${DB_NAME_VALUE}' já existe"
fi

unset PGPASSWORD

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
