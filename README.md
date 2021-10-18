## Инфраструктура AWS развернутая при помощи Terraform и сконфигурирована Ansible

Данный код автоматически создает AWS инфраструктуру с помощи Terraform и доставляет конфигурации для запуска Веб-сервера с помощью Ansible. Инфраструктура состоит из:

    1. Три веб-сервера Ubuntu 20.04 
    
    2. Бастион хост, через который осуществляется ssh подключение к Веб серверам (К Веб серверу невозможно подключиться по ssh с любого IP, кроме private ip Бастиона). 
    
    3. Amazon Elastic Load Balancer - балансировщик нагрузки, проксирующий траффик из сети Интернет на Веб сервера распределяя нагрузку между серверами. 
    
Как использовать данный код:

Для возможности запуска и корректной работы данного кода необходимо установить:

    • terraform v1.0.8 или выше. 
    • ansible [core 2.11.5] или выше. 
    • git (для клонирования репозитория) 
    
Стабильная работа кода на более низких версиях не тестировалась.

## Запуск скрипта:

Склонируйте репозиторий любым удобным способом, например, используя команду:
```
git clone https://github.com/abogoderov/aws_terraform_ansible_infrastructure.git
````
Перед запуском скрипта вам необходимо отредактировать файл ```terraform.tfvars``` добавив в него следующие значения:
```
aws_access_key = "your_AK" # Ваш ключ доступа AWS
aws_secret_key = "your_SK" # Ваш секретный ключ AWS
pub_key_path = "path_public" # Путь до вашего публичного ssh ключа например "~/.ssh/id_rsa.pub"
priv_key_path = "your key here" #  Путь до вашего приватного ssh ключа например "~/.ssh/id_rsa"
```
Если у вас отсутствует пара ssh ключей, или вы хотите сгенерировать новую пару ключей, используейте команду:
```ssh-keygen -b 2048 -t rsa```
Находясь в директории, в которую был склонирован код, откройте консоль используйте команду:
```terraform init```

После отработки данной команды, используйте команду ```terraform apply -var-file terraform.tfvars``` После запуска данной команды будет иницирован процесс планирования запуска инфраструктуры. Если процесс планирования завершился корректно, в терминале вы увидите следующий вывод:
```
Do you want to perform these actions?
Terraform will perform the actions described above.
Only 'yes' will be accepted to approve.

Enter a value:
```
Введите yes и нажмите клавишу Enter. Данный шаг может быть пропущен при запуске команды ```terraform apply``` c ключем ```-auto-approve```. По окочанию работы, на выход консоли будут возвращены следующие значения:
```
BalancerDNS = "terraform-elb-xxxxxxxx.eu-central-1.elb.amazonaws.com"
WebServers_private_IPs = [
"xxx.31.30.129",
"xxx.31.44.149",
"xxx.31.12.113",
]
WebServers_public_IPs = [
"x.67.202.135",
"x.127.245.76",
"x.122.100.153",
]
public_ip_bastion = "x.xx2.116.18"
```
Проверку работы Веб сервера можно осуществить, перейдя по DNS-имени из параметра ```BalancerDNS =``` вставив его в адресную строку браузера.
По окончанию работы, для уничтожения инфраструктуры, находясь в директории, откуда был запущен Terraform скрипт используйте команду ```terraform destroy``` (аналогично команде ```terraform apply``` после планирования удаления необходимо ввести yes и нажать Enter или запускать ```terraform destroy``` использовав ключ ```-auto-approve```)
Вы так-же можете указывать дополнительные параметры запуска в виде переменных, совместно с параметром ```-var-file terraform.tfvars``` например:
```
terraform apply -var-file terraform.tfvars -var region=eu-central-1 -var instance_type=t3.micro
```
или не используя его передавать параметры вручную:
```
terraform apply -var aws_access_key=THISISFORTESTPURPOSE -var aws_secret_key=themostsecretkeyeverbeen -var region=ca-central-1
```
##### Перечень параметров, которые можно передавать в -var
```
aws_access_key    # Ключ доступа AWS
aws_secret_key    # Секретный ключ AWS
pub_key_path      # Путь до публичного ssh ключа на вашем компьютере
priv_key_path     # Путь до секретного ssh ключа на вашем компьютере
region            # Регион AWS, например eu-central-1
username          # Имя пользователя в создаваемом инстансе
instance_type     # Тип EC2 инстансов(применяется на все инстансы), например t3.micro
ami               # AMI образа используемой ОС
srv_count         # Количество инстансов с веб сервером 
```
##### Смена ami

Вы можете изменить значение ```ami``` для развертываемых инстансов, c использованием образа ОС , отличного от Debian. Пример:
1. Мы хотим запустить скрипт, разворачивая инстансы на RHEL. Для этого выбираем необходимый ```ami``` RHEL в выбранном регионе (по умолчанию eu1-central) 
2. После отработки ```terraform init``` используем ```terraform apply -var-file terraform.tfvars -var ami=выбранный RHEL-AMI -var username = ec2-user```
Для указания корректного значения ```username```, используйте стандартные значения (взято с оф. сайта AWS):


    For Amazon Linux 2 or the Amazon Linux AMI, the user name is ec2-user.

    For a CentOS AMI, the user name is centos or ec2-user.

    For a Debian AMI, the user name is admin.

    For a Fedora AMI, the user name is fedora or ec2-user.

    For a RHEL AMI, the user name is ec2-user or root.

    For a SUSE AMI, the user name is ec2-user or root.

    For an Ubuntu AMI, the user name is ubuntu.

    For an Oracle AMI, the user name is ec2-user.

    For a Bitnami AMI, the user name is bitnami.

    Otherwise, check with the AMI provider.



