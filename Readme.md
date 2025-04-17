Затащить ручной деплой кубера с rancher-ом в terraform
И посмотреть в чём будет разница между azure

`yc config profile activate default`
#https://yandex.cloud/en-ru/docs/tutorials/infrastructure-management/terraform-modules
- `yc iam service-account create --name terraform --folder-name terraform`
- `yc iam service-account list`

#https://yandex.cloud/en-ru/docs/iam/concepts/access-control/roles
- `yc resource-manager folder add-access-binding b1gsjjo950i2c5fs82pe --role admin --subject serviceAccount:aje9em2qi8p37a4lf138`

```
yc iam key create \
  --service-account-id aje9em2qi8p37a4lf138 \
  --folder-name terraform \
  --output key.json
```
=>
```
id: ajej1k719pvku10rc10s
service_account_id: ajeru7bh0mlfqiaulb4e
created_at: "2025-04-16T19:32:48.947714442Z"
key_algorithm: RSA_2048
```

Set up the CLI profile to run operations on behalf of the service account:
То есть, сервисный аккаунт должен иметь cli профиль?
- `yc config profile create terraform`

Profile 'terraform' created and activated
- `yc config profile activate terraform`
- `yc config set service-account-key key.json`
- `yc config set cloud-id b1g4aoclmf5bfpmghgju`
`yc config set folder-id b1gsjjo950i2c5fs82pe`


Это надо проделывать до terraform validate и после изменения main.tf
#по-умолчанию только для текущей платформы
- `terraform init`
#добавляем стандартную
- `terraform providers lock -net-mirror=https://terraform-mirror.yandexcloud.net -platform=linux_amd64`
- `terraform plan`
- `terraform apply`

#after first apply error and not clear tokens, and as result used old token for kms
=> `terraform destroy`
=> rm all dirs & caches

#установка addon-ов не работает без публичного ip master ноды (из интерфейса работает)
#module "addons" {

#https://developer.hashicorp.com/terraform/cli/config/environment-variables
#order of steps setup
- `terraform plan -json | jq > plan.json`