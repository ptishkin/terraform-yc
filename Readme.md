## Example of CD/CD (and destroy pipelines) via terraform on yandex cloud

./.github/workflow/
dependencies of setup rancher on kubernetes
ydb => backend => vpc => kube => kube/addons

### key features
- multi envirotment setup
  - via secret keys in envirotment: stage, dev, production
- on pull request: checking where change in steps and apply infra before it, and plan infra only for current change dir
  - next conditionally build steps dirs will fail
  - steps before current changed dir = steps from master then ci/cd must apply not created services
  - on manual start: the same as PR
- on push into master all steps will apply
  - on manual start: the same as push
- on PR or push with fail job
  - deploy will stop apply next jobs
- detailed comments about all steps (exported from terraform-setup and optimized for mine req)
  - where step skipped or applied
  - apply & destroy outs added after plan content
  - cropped plan content to show end of results
- all jobs write with reusable workflow / scripts
- jobs for destroy
  - only for manual start
  - with selected envirotment and group of removed services (conditionally crossed via needs and checks)
  (not aply remove vpc without previously remove kube)
  - backend not remove from those pipeline (and will fail remove non empty s3 bucket)
  - comments adding on last closed PR issue (github actions not support, but not im)
- backend/ydb creats service account for s3 bucket and result of this step stored in aws secret creds)
- backend manually switch from local backend into s3 backend after create s3 bucket
- all steps use YC_TOKEN created manually

## TODO
terraform needs
- use less uniq names, example with prefixes (stage, dev) to apply conf on same folder
- needs more complex flow with VPC
- LB ip must glue with DNS
- rancher boostrap password must be setted/getted into/from vault storage
  - rancher helm bug on destroy: stops first run of destroy pipeline
- variables of versions

<details>
  <summary>Integrate plan</summary>

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
То есть, сервисный аккаунт должен иметь cli профиль, чтобы можно было переключаться между пользователями и их токенами
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

</details>
