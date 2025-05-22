# openstack-cleaner
<h1>Инфо</h1>
<p>Скрипт автоматического удаления инфраструктуры, созданной с помощью openstack cli, используя исходный скрипт установки.</p>
<p>Скрипт анализирует файл с командами <code><strong>openstack create</strong></code>, извлекает типы ресурсов и удаляет их в порядке, обратном установки, чтобы избежать ошибок.</p>
<h1><strong>Основные возможности</strong></h1>
<ul>
  <li>Автоматическое извлечение всех команд <code><strong>openstack ... create</strong></code> из файла</li>
  <li>Формирование обратных команд: <code><strong>openstack &lt;type&gt; delete &lt;name&gt;</strong></code></li>
  <li>Удаление в обратном порядке (серверы → порты → сети и т.д.)</li>
  <li>Поддержка сложных команд:<ul>
      <li>Флаги (<code><strong>--image</strong></code>, <code><strong>--network</strong></code>, <code><strong>--port</strong></code>)</li>
      <li>Значения после флагов</li>
      <li>Команды с <code><strong>--insecure</strong></code></li>
    </ul>
  </li>
</ul>
<p>&nbsp;</p>
<h1>Поддерживаемые типы ресурсов</h1>
<ul>
  <li>security group</li>
  <li>volume</li>
  <li>loadbalancer<ul>
      <li>loadbalancer_pool</li>
      <li>loadbalancer_member</li>
      <li>loadbalancer_listener</li>
    </ul>
  </li>
  <li>floating ip</li>
  <li>port</li>
  <li>keypair</li>
  <li>router<ul>
      <li>router_port</li>
    </ul>
  </li>
  <li>server<ul>
      <li>server_port</li>
      <li>server_volume</li>
    </ul>
  </li>
  <li>network</li>
  <li>subnet</li>
  <li>user</li>
  <li>project</li>
  <li>domain</li>
</ul>
<p>&nbsp;</p>
<p>Операции управления пользователями, само собой, будут работать только от admin пользователя облака.</p>
<h1>Требования</h1>
<ul>
  <li>Установленный opestack-client, neutron-client, octavia-client (Если скрипт установки запускался с машины, где будет проводиться удаление, то все требования, понятно дело, удовлетворены)</li>
  <li>Файл-скрипт установки вида:</li>
</ul>
<pre><code class="language-plaintext">#!/bin/bash 
source ./cloud-vars.conf
openstack domain create Domain1 --insecure
openstack project create Project1 --domain Domain1 --insecure
openstack user create --password 'P@ssw0rd' --domain Domain1 User1 --insecure
openstack network create net1 --insecure</code></pre>
<p>&nbsp;</p>
<ul>
  <li>Файл с переменными вида:</li>
</ul>
<pre><code class="language-plaintext">#!/bin/bash
export OS_AUTH_URL=https://10.0.0.81:5000/v3/
export OS_PROJECT_NAME="admin"
export OS_USER_DOMAIN_NAME="Default"
export OS_PROJECT_DOMAIN_ID="default"
export OS_USERNAME="admin"
export OS_PASSWORD=password</code></pre>
<p>Немного подробнее о переменных, актуальных для Кибер Инфраструктуры <a href="https://wiki.plesx.ru/ru/openstack/openstack-cli-with-cyber-infra">тут</a>.</p>
<h2>Требования к командам "openstack .. create .." в скрипте установки</h2>
<p>Дабы скрипт мог нормально воспринимать команды создания и далее переделать их в команды удаления, необходимо хотя бы немного думать о их читаемости.</p>
<p>Стоит указывать имя создаваемого объекта с помощью --name, либо в конце команды, например:&nbsp;</p>
<pre><code class="language-plaintext">openstack user create --password 'P@ssw0rd' --domain Domain1 User1 --insecure</code></pre>
<p>Флаг --insecure, в данном контексте, ни на что не влияет, его можно указывать где угодно.</p>
<p>В целом, любой help от openstack cli выдаст именно такие же хотелки, но от неверного порядка cli не сломается, а вот скрипт иногда может не удалять объект.</p>
<pre><code class="language-plaintext">openstack user create
usage: openstack user create [-h] [-f {json,shell,table,value,yaml}] [-c COLUMN] [--noindent] [--prefix PREFIX] [--max-width &lt;integer&gt;] [--fit-width] [--print-empty] [--domain &lt;domain&gt;] [--project &lt;project&gt;] [--project-domain &lt;project-domain&gt;]
                             [--password &lt;password&gt;] [--password-prompt] [--email &lt;email-address&gt;] [--description &lt;description&gt;] [--ignore-lockout-failure-attempts] [--no-ignore-lockout-failure-attempts] [--ignore-password-expiry] [--no-ignore-password-expiry]
                             [--ignore-change-password-upon-first-use] [--no-ignore-change-password-upon-first-use] [--enable-lock-password] [--disable-lock-password] [--enable-multi-factor-auth] [--disable-multi-factor-auth] [--multi-factor-auth-rule &lt;rule&gt;]
                             [--enable | --disable] [--or-show]
                             &lt;name&gt;</code></pre>
<p>Если к какой-либо команде cli не поддерживает <code>&lt;name&gt;</code> , но поддерживает --name, то рекомендую указать его, так скрипт точно правильно найдет объект.</p>
<p>Так, например при создании пула балансировки:</p>
<pre><code class="language-plaintext">openstack loadbalancer pool create --name lb1_pool1 --lb-algorithm ROUND_ROBIN --protocol HTTPS --loadbalancer lb1</code></pre>
<h1>Использование</h1>
<p>Каким-либо способом качаем uninstall.sh с github <a href="https://github.com/govorunov-av/openstack-cleaner">репозитория</a>.</p>
<p>Для удобства даем права на выполнение:</p>
<pre><code class="language-plaintext">chmod +x ./uninstall.sh</code></pre>
<p>Если облако не доверенное, то необходимо указать переменной INSECURE опцию --insecure в скрипте удаления следующим образом:</p>
<pre><code class="language-plaintext">INSECURE=--insecure</code></pre>
<p>Так же, если необходимо удалять пользователей из домена, но без удаления домена (в скрипте установки не должно быть создания домена!), необходимо указать опцию в начале скрипта удаления:</p>
<pre><code class="language-plaintext">DOMAIN='--domain Domain1'</code></pre>
<p>&nbsp;</p>
<p>Далее использование простейшее:</p>
<pre><code class="language-plaintext">./uninstall.sh &lt;файл_переменных&gt; &lt;файл_установки&gt;</code></pre>
<p>Например:</p>
<pre><code class="language-plaintext">./uninstall.sh cloud-vars.conf install.sh</code></pre>
<p>&nbsp;</p>
<p>Тестировалось всё на следующем скрипте установки:</p>
<pre><code class="language-plaintext">#!/bin/bash 
source ./cloud-vars.conf
openstack domain create Domain1 --insecure
openstack project create Project1 --domain Domain1 --insecure
openstack user create User1 --password 'P@ssw0rd' --domain Domain1 --insecure
USER_ID=$(openstack user list --insecure --domain Domain1 | grep User1 | awk -F '|' '{print$2}' | awk -F ' ' '{print$1}')
openstack role add --user "$USER_ID" --project Project1 admin --insecure
openstack network create net1 --insecure
openstack subnet create --dhcp --subnet-range 10.21.1.0/24 --allocation-pool start=10.21.1.10,end=10.21.1.210 --gateway 10.21.1.1 --network net1 net1_subnet1 --insecure
openstack network create net2 --insecure
openstack subnet create --dhcp --subnet-range 10.22.1.0/24 --allocation-pool start=10.22.1.10,end=10.22.1.210 --gateway 10.22.1.1 --network net2 net2_subnet1 --insecure
openstack router create --enable-snat --external-gateway public router1 --insecure
openstack port create --network net1 --fixed-ip subnet=net1_subnet1,ip-address=10.21.1.1 router1_port1 --insecure
openstack router add port router1 router1_port1 --insecure
ROUTER1_EXT_IP=$(openstack router show router1 --insecure -c external_gateway_info -f yaml | grep ip_address | awk -F ' ' '{print$3}')
openstack router create --enable-snat --external-gateway public router2 --insecure
openstack port create --network net2 --fixed-ip subnet=net2_subnet1,ip-address=10.22.1.1 router2_port1 --insecure
openstack router add port router2 router2_port1 --insecure
openstack router set --route destination=10.21.1.0/24,gateway=$ROUTER1_EXT_IP router2 --insecure
openstack port create --network net1 --fixed-ip subnet=net1_subnet1,ip-address=10.21.1.211 vm1_port1 --insecure
openstack keypair create --public-key ~/.ssh/id_rsa.pub CloudVMKey1 --insecure
openstack server create --image alt-p10-cloud-x86_64 --boot-from-volume 10 --port vm1_port1 --flavor small --key-name CloudVMKey1 server1 --insecure
openstack floating ip create --port vm1_port1 public --insecure
openstack port create --network net2 --fixed-ip subnet=net2_subnet1,ip-address=10.22.1.211 vm2_port1 --insecure
openstack server create --image alt-p10-cloud-x86_64 --boot-from-volume 10 --port vm2_port1 --flavor small --key-name CloudVMKey1 server2 --insecure
openstack floating ip create --port vm2_port1 public --insecure
openstack port create --network net2 --fixed-ip subnet=net2_subnet1,ip-address=10.22.1.221 lb1_port1 --insecure
openstack loadbalancer create --name lb1 --vip-port-id lb1_port1 --insecure --wait
openstack loadbalancer pool create --name lb1_pool1 --lb-algorithm ROUND_ROBIN --protocol HTTPS --loadbalancer lb1 --insecure
openstack loadbalancer member create --address 10.21.1.211 --protocol-port 443 --name member1_lb1 lb1_pool1 --insecure
openstack loadbalancer member create --address 10.22.1.211 --protocol-port 443 --name member2_lb1 lb1_pool1 --insecure
openstack loadbalancer listener create --protocol HTTPS --protocol-port 443 --default-pool lb1_pool1 lb1 --insecure
openstack floating ip create --port lb1_port1 public --insecure
openstack volume create --image alt-p10-cloud-x86_64 --size 10 volume1 --insecure
openstack server add volume server2 volume1 --device /dev/sdv --insecure
openstack security group create sg1 --insecure
openstack security group rule create --ingress --protocol tcp --dst-port 44 sg1 --insecure
openstack port set --security-group sg1 vm1_port1 --insecure</code></pre>
<p>В данном случае всё отрабатывалось успешно.</p>
