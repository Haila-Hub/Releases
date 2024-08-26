#!/bin/bash

# Solicitar as senhas e o ID da rede ZeroTier ao usuário
read -sp "Digite a senha para o usuário haila: " haila_senha
echo
read -sp "Digite a senha secreta para o usuário postgres no PostgreSQL: " postgres_senha_secreta
echo
read -p "Digite o ID da rede ZeroTier: " zerotier_id

# 1 - Criar um usuário root chamado haila
sudo useradd -m -s /bin/bash haila
echo "haila:$haila_senha" | sudo chpasswd
sudo usermod -aG sudo haila

# 2 - Definir a senha para o usuário haila
echo "haila:$haila_senha" | sudo chpasswd

# 3 - Instalar o PostgreSQL
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib

# Configurar o postgresql.conf
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf

# Configurar o pg_hba.conf
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

# Reiniciar o PostgreSQL para aplicar as configurações
sudo systemctl restart postgresql

# 5 - Mudar a senha do usuário postgres no PostgreSQL
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$postgres_senha_secreta';"

# 6 - Instalar o aplicativo ccze
sudo apt-get install -y ccze

# 7 - Fazer download do arquivo tar.xz da pasta haila-pi-bridge e descompactar em /home/haila
wget -O /tmp/haila-pi-bridge.tar.xz https://exemplo.com/caminho/para/haila-pi-bridge.tar.xz
sudo tar -xvf /tmp/haila-pi-bridge.tar.xz -C /home/haila/
sudo chown -R haila:haila /home/haila/haila-pi-bridge/

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

# 14 - Criar uma rede Wi-Fi hospedada usando Netplan
cat <<EOL | sudo tee /etc/netplan/10-my-config.yaml
network:
  version: 2
  renderer: networkd
  wifis:
    wlan0:
      access-points:
        "HAILA-BRIDGE":
          password: "HAILA2024#"
      dhcp4: yes
      dhcp6: no
EOL

# Aplicar as configurações do Netplan
sudo netplan apply

echo "Instalação concluída com sucesso!"
