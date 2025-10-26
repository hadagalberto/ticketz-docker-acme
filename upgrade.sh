#!/bin/bash

# Função para mostrar a mensagem de uso
show_usage() {
    echo -e     "Uso: \n\n      curl -sSL https://update.ticke.tz | sudo bash\n\n"
    echo -e "Exemplo: \n\n      curl -sSL https://update.ticke.tz | sudo bash\n\n"
}

# Função para sair com erro
show_error() {
    echo $1
    echo -e "\n\nAlterações precisam ser verificadas manualmente, procure suporte se necessário\n\n"
    exit 1
}

# Função para mensagem em vermelho
echored() {
   echo -ne "\033[41m\033[37m\033[1m"
   echo -n "$1"
   echo -e "\033[0m"
}

if ! [ -n "$BASH_VERSION" ]; then
   echo "Este script deve ser executado como utilizando o bash\n\n" 
   show_usage
   exit 1
fi

# Verifica se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script deve ser executado como root" 
   exit 1
fi

if [ -n "$1" ]; then
  BRANCH=$1
fi

# Navegação para o diretório correto do projeto
if [ -d ticketz-docker-acme ] && [ -f ticketz-docker-acme/docker-compose.yaml ] ; then
  cd ticketz-docker-acme
elif [ -f docker-compose.yaml ] ; then
  ## nothing to do, already here
  echo -n "" > /dev/null
elif [ "${SUDO_USER}" = "root" ] ; then
  if [ -d /root/ticketz-docker-acme ] ; then
    cd /root/ticketz-docker-acme || exit 1
  else
    echo "Diretório ticketz-docker-acme não encontrado"
    exit 1
  fi
else
  if [ -d /home/${SUDO_USER}/ticketz-docker-acme ] ; then
      cd /home/${SUDO_USER}/ticketz-docker-acme || exit 1
  else
      echo "Diretório ticketz-docker-acme não encontrado"
      exit 1
  fi
fi

echo "Working on $PWD folder"

if ! [ -f docker-compose.yaml ] ; then
  echo "docker-compose.yaml não encontrado" > /dev/stderr
  exit 1
fi

echored "                                               "
echored "  Este processo irá converter uma instalação   "
echored "  do ticketz por uma instalação do ticketz     "
echored "  do hadagalberto, usando imagens pre          "
echored "  compiladas de uma versão customizada         "
echored "                                               "
echored "  Aguarde 20 segundos...                       "
echored "                                               "
echored "  ...ou aperte CTRL-C para cancelar            "
echored "                                               "
sleep 20
echo "Prosseguindo..."

echo "Removendo remotes git antigos..."
git remote remove origin 2> /dev/null
git remote remove upstream 2> /dev/null

echo "Adicionando remote git do hadagalberto..."
git remote add origin https://github.com/hadagalberto/ticketz-docker-acme.git

git fetch origin || show_error "Não foi possível conectar ao repositório remoto do hadagalberto"

git reset --hard origin/main || show_error "Não foi possível atualizar o repositório local do hadagalberto"

echo "Finalizando containers"
docker compose down || show_error "Erro ao finalizar containers"

echo "Removendo imagens antigas do ticketz original..."
docker rmi $(docker images -q ticketz/backend-acme) 2> /dev/null
docker rmi $(docker images -q ticketz/frontend-acme) 2> /dev/null
docker rmi $(docker images -q ticketz/reverse-proxy-acme) 2> /dev/null
docker rmi $(docker images -q ticketz/postgres-acme) 2> /dev/null

echo "Baixando novas imagens do hadagalberto"
docker compose pull || show_error "Não foi possível baixar as novas imagens do hadagalberto"

echo "Inicializando containers"
docker compose up -d || show_error "Não foi possível subir os containers com as novas imagens do hadagalberto"

echo -e "\nSeu sistema já deve estar funcionando"

echo "Removendo imagens anteriores..."
docker system prune -af &> /dev/null

echo "Atualização concluída com sucesso!"