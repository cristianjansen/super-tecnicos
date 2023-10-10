############# FILE SERVER UBUNTU 22.04.3 LTS #############

#!/bin/bash

# Atualiza o sistema e instala pacotes
apt update && apt upgrade -y
apt install -y net-tools samba samba-common smbclient cifs-utils ntp ntpdate ntfs-3g

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

# Criar uma pasta para dados compartilhados
sudo mkdir -p /mnt/DADOS
sudo mkdir -p /mnt/DADOS/lixeira
sudo mkdir -p /mnt/DADOS/ti
sudo mkdir -p /mnt/DADOS/diretoria

# Ajustar permissões das pastas

sudo chmod -R 770 /mnt/DADOS/lixeira
sudo chmod -R 770 /mnt/DADOS/ti
sudo chmod -R 770 /mnt/DADOS/diretoria

#!/bin/bash

# Defina a senha padrão
senha_padrao="labtech@2023"

# Lista de usuários a serem criados
usuarios=("joao.tech" "maria.tech")

# Lista de grupos a serem criados
grupos=("TI" "DIRETORIA")

# Associação de usuários aos grupos
declare -A usuarios_grupos
usuarios_grupos["joao.tech"]="TI"
usuarios_grupos["maria.tech"]="TI DIRETORIA"

# Loop para criar usuários e adicionar senhas
for usuario in "${usuarios[@]}"; do
    # Crie o usuário no Linux
    sudo useradd "$usuario"
    
    # Defina a senha padrão para o usuário
    echo -e "$senha_padrao\n$senha_padrao" | sudo passwd "$usuario"
    
    # Crie o usuário no Samba e defina a senha padrão
    echo -e "$senha_padrao\n$senha_padrao" | sudo smbpasswd -a "$usuario"
    
    echo "Usuário $usuario criado no Samba com a senha padrão."
done

# Loop para criar grupos
for grupo in "${grupos[@]}"; do
    # Crie o grupo
    sudo groupadd "$grupo"
    echo "Grupo $grupo criado."
done

# Loop para adicionar usuários aos grupos
for usuario in "${!usuarios_grupos[@]}"; do
    grupos_usuarios="${usuarios_grupos[$usuario]}"
    for grupo in $grupos_usuarios; do
        sudo usermod -aG "$grupo" "$usuario"
        echo "Usuário $usuario adicionado ao grupo $grupo."
    done
done

# Reinicie o serviço Samba (opcional)
sudo systemctl restart smbd

# Mudar o dono das pastas para o os grupos

sudo chown -R root:TI /mnt/DADOS/ti
sudo chown -R root:DIRETORIA /mnt/DADOS/diretoria
sudo chown -R root:TI /mnt/DADOS/lixeira

# Conferir as permissões

ls -la /mnt/DADOS/

# CRIANDO BACKUP DO ARQUIVO SMB.CONF
cp /etc/samba/smb.conf /etc/samba/smb.conf-bkp

# EDITAR ARQUIVO DO SAMBA
cat <<EOL | sudo tee /etc/samba/smb.conf
# Configurações Globais do Samba

[global]
   workgroup = WORKGROUP
   server string = Samba Server
   security = user
   guest account = nobody
   log file = /var/log/samba/log.%m
   max log size = 50

#=============================LIXEIRA======================#
vfs objects = recycle audit
recycle:keeptree = yes
recycle:versions = yes
recycle:repository = /mnt/DADOS/lixeira/%U
recycle:exclude = *.~*, ~*.*, *.bak, *.old, *.iso, *.tmp
recycle:exclude_dir = temp, cache, tmp

[LIXEIRA]
   path = /mnt/DADOS/lixeira
   writeable = yes
   browseable = no
   valid users = @TI
   write list = @TI

#=======================COMPARTILHAMENTOS====================================#

[TI]
   comment = Pasta TI
   path = /mnt/DADOS/ti
   browseable = yes
   valid users = @TI
   write list = @TI
   read only = no
   force create mode = 0777
   force directory mode = 0777


[DIRETORIA]
   comment = Pasta DIRETORIA
   path = /mnt/DADOS/diretoria
   browseable = yes
   valid users = @DIRETORIA
   write list = @DIRETORIA
   read only = no
   force create mode = 0777
   force directory mode = 0777
   veto files = /*.exe/*.lnk/*.com/*.pif/*.bat/*.scr/
EOL

# REINICIANDO O SERVIÇO DO SAMBA
sudo systemctl restart smbd

echo "Servidor de Arquivos Linux Concluído!"