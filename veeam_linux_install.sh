######## INSTALANDO E CONFIGURANDO O VEEAM BACKUP AGENT LINUX ########

#!/bin/bash

# Atualiza o sistema e instala pacotes
apt update && apt upgrade -y
apt install -y net-tools cifs-utils ntp ntpdate ntfs-3g

# Nome do usuário
usuario="backup.user"

# Senha padrão
senha_padrao="bkpserver"

# Verifica se o usuário já existe
if id "$usuario" &>/dev/null; then
    echo "O usuário $usuario já existe."
else
    # Cria o usuário
    sudo useradd "$usuario"
    echo "$usuario:$senha_padrao" | sudo chpasswd

    # Confirmação
    echo "Usuário $usuario criado com a senha padrão '$senha_padrao'."
fi

# Defina os novos servidores NTP
novos_servidores=("server a.ntp.br" "server b.ntp.br" "server c.ntp.br")

# Caminho para o arquivo ntp.conf
ntp_conf="/etc/ntp.conf"

# Faça backup do arquivo ntp.conf original
cp "$ntp_conf" "$ntp_conf.backup"

# Altere as configuracoes no arquivo ntp.conf
sed -i '/^pool/d' "$ntp_conf"
for servidor in "${novos_servidores[@]}"; do
    echo "$servidor" >> "$ntp_conf"
done

# Reinicie o servico NTP
service ntp restart

# Mostre uma mensagem de conclusao
echo "As configuracoes do NTP foram atualizadas e o servico foi reiniciado."

#!/bin/bash

# 1. Criar uma pasta para o HD externo
sudo mkdir -p /mnt/BACKUP

# Ajustando permissoes da pasta
sudo chmod -R 770 /mnt/BACKUP

# Mudar dono da pasta
sudo chown -R root:backup.user /mnt/BACKUP

# 2. Montar a partição NTFS em um diretório no Linux sem formatar
sudo mount -t ntfs-3g /dev/sdb1 /mnt/BACKUP

# 3. Adicionar uma linha ao arquivo /etc/fstab para montar a partição NTFS automaticamente
echo "UUID=4E55231A061070A4 /mnt/BACKUP ntfs-3g defaults 0 0" | sudo tee -a /etc/fstab

# 4. Verificar se a partição está montada corretamente
df -h

# Baixa o Veeam Backup Agent
wget https://download2.veeam.com/veeam-release-deb_1.0.8_amd64.deb

# Instala o Veeam Backup Agent
dpkg -i ./veeam-release*
apt-get update
apt-get install veeam -y

# Verifica o status do serviço do Veeam Agent
sudo systemctl status veeamservice.service

echo "Concluído!"