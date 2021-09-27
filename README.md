# AWS infrastructure deploy by Terraform and configured by Ansible

This code automaticly creates AWS infrastruture with Terraform that consists of: 
  1. Three Ubuntu 20.04 Web servers
  2. Bastion host to provide secured ssh connection to Web servers (ssh connection to Web severs allowed only private IP of Bastion host).
  3. Amazon Elasitic Load Balancer instance, used as proxy for Web Servers
After infrastructure was created, Terraform installs Ansible to Bastion host and it becomes Ansible master for Web servers.
With Ansible Master we deliver cofigurations that installs ngnix and forms a static HTML page to the Web Servers. This page shows as current private IP of the Web Server instance, we use as a proof that Load balancer gives us content from different servers.

# How to use the code:

1. Install terraform using guideline from iffical recource
2. Clone this repository to the location in which you will execute terraform.
3. If you need to add your AWS credentials, you can use "./cred.sh" and it will guide you to add it.
4. Being in the location, in where you cloned the repository run "terraform init" and "terraform apply"
5. Wait for script to finish its work and use Load Balancers DNS name in your Internert browser 
  5.1 DNS will be showing in stdout output after finishing Terraform script. Example: "terraform output
BalancerDNS = "terraform-elb-XXXXXXXXX.eu-central-1.elb.amazonaws.com".

# Инфраструктура AWS развернутая при помощи Terraform и сконфигурирована Ansible

Данный код автоматически создает AWS инфраструктуру с помощи Terraform. Инфраструктура состоит из:
  1. Три веб-сервера Ubuntu 20.04
  2. Бастион хост, через который осуществляется ssh подключение к Веб серверам (К Веб серверу невозможно подключиться по ssh с любого IP, кроме private ip Бастиона).
  3. Amazon Elasitic Load Balancer - балансировщик нагрузки, проксирующий траффик из сети Интернет на Веб сервера.
После создания инфраструктуры, Terraform устанавливает Ansible на Бастион хост и он становится Ansible Master для Веб серверов.
При помощи Ansible Master доставляются конфигурации, которые устанавливают ngnix и формируют статическую HTML страницу, содержающую приватный IP адрес того Веб сервера, на котором она создана. Данная страница используется для иллюстрации того, что Load Balancer отдает контент с разных Веб серверов. 

# Как использовать данный код:

1. Установите terraform используя официальное руководство разработчика.
2. Склонируйте данный репозиторий в директорию из которой будет осуществляться запуск бинарного файла Terraform.
3. Если вам необходимо укзать реквизиты для входа в AWS, запустите скрипт "./cred.sh".
4. Для создание инфраструктуры на ресурсах облачного провайдера AWS  и последующего деплоя приложения NGINX на вновь созданные инстансы, используются стандартные команды запуска terraform init" и "terraform apply" из директории в которую был склонирован текущий репозиторий.
5. Дождитесь окончания работы скрипта и откройте в Интернет браузере Веб страницу, используя DNS имя балансировщика.
6.  DNS имя выводится в консоль, после окончания разворачивания инфраструктуры на ресурсах облачного провайдера AWS, посредством terraform output. Пример "terraform output BalancerDNS = "terraform-elb-XXXXXXXXX.eu-central-1.elb.amazonaws.com"

