# Readme do projeto aws-docker (1)

# AWS e Dokcer - Hospedagem de um site WordPress em um instância EC2

## Objetivo

Neste projeto foi desenvolvido um ambiente escalável na AWS para hospedar um site WordPress, baseado na imagem Docker WordPress, utilizando o Amazon RDS, Auto Scaling Group (ASG), Classic Load Balancer (CLB), Amazon RDS, Amazon EFS e monitoramento com CloudWatch.

## Tecnologias utilizadas

- [Ferramentas AWS](https://docs.aws.amazon.com/pt_br/) (Amazon EC2, Amazon RDS, Auto Scaling Group (ASG), Classic Load Balancer (CLB) e CloudWatch)
- [Docker](https://docs.docker.com/manuals/) e Docker Compose
- Git e Github

## Pré-requisitos

- Uma conta na AWS com permissões de administrador
- Conhecimento básico em versionamento git

---

## VPC

1. Realize o cadastro na Amazon AWS; entre no Console de gerenciamento da AWS
    1. Selecione a região de United States - N. Virginia, que foi escolhida para o projeto.
2. Clique na barra de pesquisa e digite ‘VPC’
3. Na seção de **Virtual private cloud**, selecione **Your VPCs**. Logo em seguida, clique em **Create VPC.**
    1. Em VPC settings, selecione **VPC and more**, para pré-visualizar as subnets públicas e privadas, a tabela de rotas  e conexão de redes.
    2. Dê um nome para a VPC.
    3. No restante das configurações, faça as seguintes alterações:
        
        ![criando vpc2.png](criando_vpc2.png)
        
    4. O preview da VPC deverá estar assim:
        
        ![image.png](image.png)
        
    5. Clique em **Create**

---

## Regras de Entrada e Saída - Security Groups

Será necessário criar SG’s para cada ferramenta, para que possa ser possível a conexão entre elas.

1. Clique na barra de pesquisa e digite **EC2**
2. Em seguida, vá para **Security Groups** na seção **Network & Security** e crie 4 Security Groups**:** um para a instância EC2, um para o RDS, um para o CLB e outro para EFS.
    1.  **sg-ec2**; **sg-rds**; **sg-clb**; **sg-efs**
    2. Aplique as Inbound e Outbound rules de acordo com o quadro abaixo
    
    🏷️ Insira tags “Name” para facilitar na busca entre SG’s
    
    | **Ferramenta** | **Nome SG** | **Inbound rules** | **Outbound rules** |
    | --- | --- | --- | --- |
    | EC2 | SG EC2 | HTTP (`sg-lb`) | HTTP (`sg-clb`); MYSQL/Aurora (`sg-rds`); NFS (`sg-efs`); All trafic (`0.0.0.0/0`) |
    | Aurora and RDS (Mysql) | SG RDS | MYSQL/Aurora (`sg-ec2`) | MYSQL/Aurora (`sg-ec2`) |
    | CLB | SG CLB | HTTP (All trafic) (`0.0.0.0/0`) | HTTP (`sg-ec2`) |
    | EFS | SG EFS | NFS (`sg-ec2`) | NFS (`sg-ec2`) |

---

## RDS

1. Clique na barra de pesquisa e digite ‘RDS’
2. Em seguida, vá para **Databases** e clique em **Create database**
3. Segue abaixo o passo a passo para a criação do banco de dados:
    1. **Choose a database creation method → Standard create**
    2. **Engine options → MySQL**
        
        ![image.png](image%201.png)
        
    3. **Engine version** → Escolha a última versão do MySQL (8.4.4) 
    4. **Templates → Free Tier** (automaticamente selecionará a opção **Single-AZ DB instance deployment**)
        
        ![image.png](image%202.png)
        
        ![image.png](image%203.png)
        
    5. **Settings →** Vá para **DB identifier** e dê um nome para seu identificador de banco de dados → Escolha **Self managed** e crie um nome de usuário e uma senha forte
        
        ![image.png](image%204.png)
        
    6. **Instance configuration →** Selecione o tipo de instância **db.t3.micro**
        
        ![image.png](image%205.png)
        
    7. **Storage → Additional storage configuration → Maximum storage threshold →** digite **22** (mínimo permitido)
        
        ![image.png](image%206.png)
        
    8. **Connectivity → Compute resource (**Don’t connect to an EC2 compute resource**) → Network type (**IPv4**) → Virtual private cloud (VPC) (**selecione a VPC criada**) → Public access** (No) → **VPC security group (firewall)** (selecione o SG criado para o RDS) → **Availability Zone (**No preference**)**
        
        ![image.png](image%207.png)
        
        ![image.png](image%208.png)
        
    9. Role para baixo em **Additional configuration** e crie um nome para o banco de dados. Não altere mais nehuma configuração e clique em **Create database**
        
        ![image.png](image%209.png)
        

---

## EFS

1. Clique na barra de pesquisa e digite ‘EFS’
2. Vá em ‘Create file system’
3. Crie um nome, selecione a VPC criada para o projeto e depois vá para **Costumize**
    
    ![image.png](image%2010.png)
    
4. Siga as próximas etapas a partir dos prints a seguir:
    1. Na etapa 1, em Lifecycle management, selecione **None** nas três seções
        
        ![image.png](image%2011.png)
        
    2. Em Throughput mode, selecione **Bursting**
        
        ![image.png](image%2012.png)
        
    3. Na etapa 2, selecione as subnets PRIVADAS de cada zona de disponibilidade e selecione o SG do EFS para os dois
        
        ![image.png](image%2013.png)
        
    4. Avance as próximas etapas até aparecer na última etapa o botão **Create**
    5. Armazene o endereço do banco de dados e o ponto de montagem EFS
        1. ponto de montagem EFS:
            
            ![image.png](image%2014.png)
            
        2. Clique em Attach
            
            ![image.png](image%2015.png)
            
        3. 
            
            ![image.png](image%2016.png)
            
        
    6. O endereço do banco de dados é o endpoint do RDS
        
        ![image.png](image%2017.png)
        
    7. Alterar o use-data e o docker-compose.yml
    8. user-data
        
        ```bash
        #!/bin/bash
        
        sudo yum update -y
        sudo yum install -y docker wget amazon-efs-utils
        
        sudo service docker start
        sudo systemctl enable docker.service
        sudo usermod -aG docker ec2-user
        
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        sudo mkdir -p /wordpress
        sudo mount -t efs -o tls #mount efs /wordpress
        
        wget -O /home/ec2-user/docker-compose.yml https://raw.githubusercontent.com/hidalgobru/script/refs/heads/main/docker-compose.yml
        sudo chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml
        
        cd /home/ec2-user
        sudo docker-compose up -d
        ```
        
    9. docker-compose.yml
        
        ```yaml
        services:
          web:
            image: wordpress
            restart: always
            ports:
              - "80:80"
            environment:
              WORDPRESS_DB_HOST: #endpoint database
              WORDPRESS_DB_USER: #username
              WORDPRESS_DB_PASSWORD: #password
              WORDPRESS_DB_NAME: #db_name
            volumes:
              - /wordpress:/var/www/html
            networks:
              - tunel
        
        networks:
          tunel:
            driver: bridge
        ```
        
    10. 
    11. sdfsdf
    12. sdfsdf

---

## Launch Template

1. Volte para o console do Amazon EC2 e navegue em **Instances** para **Launch Template**
    
    ![image.png](image%2018.png)
    
2. Clique em **Create launch template**
3. Dê um nome e uma descrição. Assinale a opção de **Auto Scaling guidance**
    
    ![image.png](image%2019.png)
    
4. Em **Application and OS Images:** Quick start → AMI: Amazon Linux → Instance type: t2.micro (disponível do free tier)
5. Não selecione nenhum par de chave 
6. Em **Network settings**, não escolha nenhuma subnet. Depois, selecione o SG da EC2 criada anteriormente
    
    ![image.png](image%2020.png)
    
7. Em **Advanced details**, copie e cole o user-data, com suas configurações já personalizadas e crie o launch template

---

## Classic Load Balancer

1. Ainda no console da EC2, vá para Load balancer e clique em **Create load balancer**
2. Navegue para baixo na seção do **Classic load balancer** e clique em **Create**
    
    ![image.png](image%2021.png)
    
3. Em Basic configuration, dê um nome para o CLB e selecione **Internet-facing** em **Scheme**
    
    ![image.png](image%2022.png)
    
4. Em **Network mapping**, selecione a VPC criada e escolha as subnets PÚBLICAS de cada AZ
    
    ![image.png](image%2023.png)
    
5. Em **Security groups**, selecione a SG criado para o CLB
    
    ![image.png](image%2024.png)
    
6. gdfgd
7. Em **Health checks**, digite `/wp-admin/install.php` no Ping path (serve para verificar se a página de instalação do WordPress está acessível)
    
    ![image.png](image%2025.png)
    
8. Crie o CLB

---

## Auto Scaling Group

1. No console da EC2, clique em **Auto Scaling Group** e clique em create
2. Dê um nome ao ASG e selecione o Launch template criado anteriormente. Depois, vá para a próxima etapa
    
    ![image.png](image%2026.png)
    
3. Em Network, selecione a VPC criada para o projeto e nas subnets, escolha as PRIVADAS de cada AZ. Vá para próxima etapa
    
    ![image.png](image%2027.png)
    
4. Em **Load balacing,** selecione a opção do meio e escolha o CLB criado anteriormente
    
    ![image.png](image%2028.png)
    
5. Em **Health checks**, marque a primeira opção. Avance para a próxima etapa
    
    ![image.png](image%2029.png)
    
6. Em Scaling, faça as configurações abaixo para permitir o escalonamento
    
    ![image.png](image%2030.png)
    
7. Não escolha nenhuma política de manutenção de instância
    
    ![image.png](image%2031.png)
    
8. Em **Additional settings**, selecione a caixinha do meio para o monitoramento do CloudWatch
    
    ![image.png](image%2032.png)
    
9. Avance as etapas e crie o ASG

---

## Acessando o WordPress

1. Após a criação das duas instâncias definidas pelo ASG, acesse o DNS do seu LB pelo navegador
    
    ![image.png](image%2033.png)
    
    ![image.png](image%2034.png)
    
2. ATENÇÃO: coloque `http://` antes de colar o DNS do load balancer
    
    ![image.png](image%2035.png)
    
3. Crie seu login e instale o WordPress
    
    ![image.png](image%2036.png)
    
4. Página criada na instalação
    
    ![image.png](image%2037.png)
    

---

## Cloud Watch