# Install Ghost Blog

The purpose of this project is to install infrastructure for ghost-docker project

## Domain and certificate

I have my own domain (metairie.dev) and a Lets Encrypt certificate bundle for https

To import certificate, let's do a conversion for windows user (.pfx)

```bash
# for windows only
# the certs are dropped into certs/ folder
openssl pkcs12 -export \
  -out domain.pfx \
  -inkey private.key.pem \
  -in domain.cert.pem
```

My registrar allows me to add A record for my IP address. Also https://metairie.dev/ goes to this setup by default

## Instal

Run locally in bash (.devcontainer) or gitbash

```bash
# windows pc
git config --local core.sshCommand "ssh -i /c/Users/steph/.ssh/github_eossf/id_rsa"
# macosx
git config --local core.sshCommand "ssh -i ~/.ssh/github_eossf/id_rsa"

git config --local user.email "stephane.metairiev@gmail.com"
git config --local user.name "Stephane Metairie"

cd src/infra/secrets
source ./export_TF_VARS.sh
cd src/infra
terraform fmt -recursive
terraform init
terraform validate
terraform plan
terraform apply
```

Remove compose file generation 

```bash
terraform destroy -target null_resource.launch
terraform destroy -target local_file.compose
```

# API Vultr

```bash
curl -k -X "GET" "https://$TF_VAR_domain/api/v1/workflows?active=true" \
  -H "accept: application/json" \
  -H "'X-N8N-API-KEY: $TF_VAR_n8n_api_key'"

curl -k -X "GET" "https://$TF_VAR_domain/api/v1/workflows?active=true" \
  -H "accept: application/json" -H "'Authorization: Bearer $TF_VAR_n8n_api_key'" -H "'X-N8N-API-KEY: $TF_VAR_n8n_api_key'"
```