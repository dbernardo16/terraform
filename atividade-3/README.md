# INFRASTRUCTURE & CLOUD ARCHTETURE

### Atividade 3

Subir dois contêineres, nginx e mysql, mapeando a porta 8080 do nginx para acesso pelo host e permitir que o contêiner do nginx tenha comunicação de rede no contêiner mysql. 

#### Instalação

```
# Faça o download do repositório
git clone https://github.com/thyagomakiyama/ica-impacta.git

# Navegue até o diretório da atividade
cd ica-impacta/atividade-3

#Inicie o terraform no projeto
docker-compose up

#Acesse localhost:8080 para encontrar a pagina inicial do ngnix

#Credenciais do mysql
#host: localhost:3306
#db: teste
#user: root
#pass: secret
```

