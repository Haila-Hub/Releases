#!/bin/bash

# Solicitar as senhas e o ID da rede ZeroTier ao usuário usando /dev/tty
haila_senha=$(read -p "Digite a senha para o usuário haila: " </dev/tty && echo $REPLY)

echo

postgres_senha_secreta=$(read -p "Digite a senha secreta para o usuário postgres no PostgreSQL: " </dev/tty && echo $REPLY)

echo

zerotier_id=$(read -p "Digite o ID da rede ZeroTier: " </dev/tty && echo $REPLY)

# 1 - Criar um usuário root chamado haila
sudo useradd -m -s /bin/bash haila

echo "haila:$haila_senha" | sudo chpasswd

sudo usermod -aG sudo haila

# 2 - Definir a senha para o usuário haila
echo "haila:$haila_senha" | sudo chpasswd


# 3 - Atualizar o Ubuntu
sudo apt-get update

sudo apt-get upgrade -y

sudo apt-get install -y update-manager-core

sudo do-release-upgrade -d -f DistUpgradeViewNonInteractive

sudo apt-get autoremove -y

sudo apt-get clean

# 4 - Instalar o PostgreSQL
sudo apt-get update

sudo apt-get install -y postgresql postgresql-contrib

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf

cat <<EOL | sudo tee /etc/postgresql/$(ls /etc/postgresql)/main/pg_hba.conf
# Database administrative login by Unix domain socket
local   all             postgres                                peer
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
host    all             all             0.0.0.0/0               md5
EOL

sudo systemctl restart postgresql

# 5 - Mudar a senha do usuário postgres no PostgreSQL
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$postgres_senha_secreta';"

# 6 - Instalar o aplicativo ccze
sudo apt-get install -y ccze

# 7 - Fazer download do arquivo tar.xz da pasta haila-pi-bridge e descompactar em /home/haila
wget -O /tmp/haila-pi-bridge-001.tar.xz https://raw.githubusercontent.com/Haila-Hub/Releases/main/haila-pi-bridge-001.tar.xz

sudo tar -xvf /tmp/haila-pi-bridge-001.tar.xz -C /home/haila/

sudo chmod 777 -R /home/haila

# 8 - Instalar os serviços
sudo cp /home/haila/haila-pi-bridge/haila-bridge/haila-pi-bridge.service /etc/systemd/system/

sudo cp /home/haila/haila-pi-bridge/haila-bridge/haila-pi-bridge-health.service /etc/systemd/system/

# 9 - Habilitar os serviços no boot
sudo systemctl enable haila-pi-bridge.service

sudo systemctl enable haila-pi-bridge-health.service

# 10 - Adicionar permissão de execução para os arquivos
sudo chmod +x /home/haila/haila-pi-bridge/haila-bridge/start.sh

sudo chmod +x /home/haila/haila-pi-bridge/haila-bridge/start_health.sh

sudo chmod +x /home/haila/haila-pi-bridge/haila-bridge/haila-bridge

sudo chmod +x /home/haila/haila-pi-bridge/workers/workers

sudo chmod +x /home/haila/haila-pi-bridge/haila-bridge/dist/services/hikvision/compress-image

sudo chmod +x /home/haila/haila-pi-bridge/haila-bridge/dist/services/hikvision/ISAPISendFace

# 11 - Instalar o zerotier
curl -s https://install.zerotier.com | sudo bash

# 12 - Habilitar e iniciar o serviço do zerotier
sudo systemctl start zerotier-one

sudo systemctl enable zerotier-one

# 13 - Ingressar na rede zerotier
sudo zerotier-cli join $zerotier_id

# 14 - Executar o arquivo SQL para inicializar o banco de dados
sudo -u postgres psql -f /home/haila/haila-pi-bridge/haila-bridge/init_db.sql

# 15 - Instalar o network-manager
sudo apt-get install -y network-manager

# 16 - Identificar o dispositivo Wi-Fi
wifi_interface=$(nmcli device status | grep wifi | grep -i connected | awk '{print $1}' | head -n 1)

if [ -z "$wifi_interface" ]; then
  wifi_interface=$(nmcli device status | grep wifi | grep -i unavailable | awk '{print $1}' | head -n 1)
fi

if [ -z "$wifi_interface" ]; then
  echo "Nenhum dispositivo Wi-Fi disponível foi encontrado."
  exit 1
fi

# 17 - Criar o Wi-Fi hotspot usando a interface identificada

# Executa o comando e captura o ID do ZeroTier
zerotier_id=$(sudo zerotier-cli info | awk '{print $3}')

sudo nmcli device wifi hotspot ifname $wifi_interface ssid HAILA-BRIDGE-$zerotier_id password HailaBridge2024#

echo
echo "Instalação concluída com sucesso!"
echo
echo "Dados da rede Wifi: "
echo "---------------------------------------"
echo " SSID: HAILA-BRIDGE-$zerotier_id"
echo " PASS: HailaBridge2024#"
echo "---------------------------------------"
