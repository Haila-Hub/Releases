#!/bin/bash
# 1 - Fazer download do arquivo tar.xz da pasta haila-pi-bridge e descompactar em /home/haila
wget -O /tmp/haila-pi-bridge-001.tar.xz https://raw.githubusercontent.com/Haila-Hub/Releases/main/haila-pi-bridge-001.tar.xz
sudo tar -xvf /tmp/haila-pi-bridge-001.tar.xz -C /home/haila/
sudo chmod 777 -R /home/haila

# 2 - Instalar os serviços
sudo cp /home/haila/haila-pi-bridge/haila-bridge/haila-pi-bridge.service /etc/systemd/system/
sudo cp /home/haila/haila-pi-bridge/haila-bridge/haila-pi-bridge-health.service /etc/systemd/system/

# 3 - Habilitar os serviços no boot
sudo systemctl enable haila-pi-bridge.service
sudo systemctl enable haila-pi-bridge-health.service

# 4 - Adicionar permissão de execução para os arquivos
sudo chmod +x /home/haila/haila-pi-bridge/haila-bridge/start.sh
sudo chmod +x /home/haila/haila-pi-bridge/haila-bridge/start_health.sh
sudo chmod +x /home/haila/haila-pi-bridge/haila-bridge/haila-bridge
sudo chmod +x /home/haila/haila-pi-bridge/workers/workers
sudo chmod +x /home/haila/haila-pi-bridge/haila-bridge/dist/services/hikvision/compress-image
sudo chmod +x /home/haila/haila-pi-bridge/haila-bridge/dist/services/hikvision/ISAPISendFace

sudo systemctl restart haila-pi-bridge && sudo systemctl restart haila-pi-bridge-health

echo
echo "Bride atualizado com sucesso!"
echo

