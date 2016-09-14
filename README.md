<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [Docker](#docker)
    - [Installation](#installation)
    - [Architecture](#architecture)
        - [Concepts](#concepts)
        - [Commandes](#commandes)
        - [Exercice 1](#exercice-1)
    - [Utilisation des images](#utilisation-des-images)
        - [Les registries](#les-registries)
        - [Construire](#construire)
        - [Exercice 2](#exercice-2)
    - [Port mapping](#port-mapping)
        - [Publication port à port](#publication-port-à-port)
        - [Publication de tous les ports](#publication-de-tous-les-ports)
        - [Exercice 3](#exercice-3)
    - [Les volumes](#les-volumes)
        - [Exercice 4](#exercice-4)
- [Docker compose](#docker-compose)
    - [Installation](#installation)
    - [Architecture](#architecture)
    - [Du sucre pour docker](#du-sucre-pour-docker)
        - [Exercice 5](#exercice-5)
    - [Liens réseaux](#liens-réseaux)
        - [Exercice 6](#exercice-6)
    - [Scale des instances](#scale-des-instances)
        - [Exercice 7](#exercice-7)
- [Docker swarm & Docker machine](#docker-swarm--docker-machine)
    - [Installation](#installation)
    - [Architecture](#architecture)
        - [Machine](#machine)
        - [Swarm](#swarm)
    - [Exercice 8](#exercice-8)
        - [Creation des machines virtuelles](#creation-des-machines-virtuelles)
        - [Initialisation du swarm](#initialisation-du-swarm)

<!-- markdown-toc end -->

# Docker
## Installation


RTFM : https://docs.docker.com/engine/installation/linux/ubuntulinux/


## Architecture

* Les objectifs fonctionnels de docker :
  * Isoler et contrôler l'éxécution des processus d'une application
  * Embarquer l'intégralité des dépendences du run-time, jusqu'à l'OS tout
    en limitant au maximum la consomation disque

* Fonctionne sur un modèle client-server :
  * dockerd, un démon s'exécutant en privilèges administrateur
  * docker, un client communiquant avec son démon selon une API HTTP rest.
    https://docs.docker.com/engine/reference/api/docker_remote_api/


* Docker n'est pas une technologie de virtualisation
  * Virtualisation :

    ![Virtualisation](./docs/virt.png "Virtualisation")

  * Containerisation :

    ![Containersation](./docs/container.png "Containersation")


* Modèle d'éxécution des processus :
  * Les applications docker s'exécutent sur la machine hôte en tant que fils
    du démon docker

  * Les processus sont isolés du reste de la machine grâce à des features récentes
    du kernel. Ils s'exécutent sur un filesystem isolé oignonés en couches (aufs)


  * Vue de l'application docker :

  ```
        |_ init-script
             |_ your-process1
             |_ your-process2

  ```

  * Vue de la machine hôte :

  ```
         ... all your stuff
         |_ dockerd
            |_ container
               |_ init-script
                 |_ your-process1
                 |_ your-process2
  ```



### Concepts

Docker repose sur deux notions principales : les images et les containers

**Une image** contient le contexte d'exécution d'une application
* Un snapshot de filesystem contentant le code de application et toutes ses dépendances (jusqu'à l'os !)
* Une analogie possible serait un gros tar.gz de /
* Les images docker utilisent un type de filesystem malin (aufs) divisé en couches
  permettant la ré-utilisation de couches entre différentes images de différentes
  applications


**Un container** est l'instanciation d'une image avec des options particulières
* variable d'environnement
* configuration réseau
* paramètres de démarrage applicatif spécifiques
* ...


### Commandes

Les listes suivantes sont non-exhaustives.

Une images peut être :
* ```pull``` : téléchargée depuis un dépôt d'image distant sur le dépôt local
* ```build``` : construite à partir d'un fichier recette
* ```push``` : poussée sur un dépôt d'image distant
* ```rmi``` : supprimée du dépôt local
* ```images``` : listée dans la liste des images locales

Un container peut être :
* ```create``` :  créé à partir d'une image en donnant des options
* ```start``` :   démarré (si arrêté)
* ```run``` :     créé et démarré dans la foulée
* ```stop``` :    arrêté (si démarré)
* ```rm``` :      supprimé (si arrêté)
* ```inspect``` : inspecté de l'ensemble des paramètres données à sa création

Commandes supplémentaires :
* ```ps``` et ```ps -a``` : pour respectivement lister les containers démarrés et existant
* ```exec``` : pour ajouter un processus à un container démarré (debug !)
* ```logs``` : pour obtenir l'historique de stdout/stderr d'un container démarré ou ayant déjà démarré


### Exercice 1

```bash
# liste des images, aucun résultât
$ docker ps -a

CONTAINER ID  IMAGE  COMMAND  CREATED  STATUS  PORTS  NAMES
```

```bash
# création d'un container my_first_container à partir de l'image "ubuntu"
$ docker create --name my-container ubuntu:latest /bin/echo 'Hello world'
692508ca4c7a4636ed56fb39315bfc10e5d651cb4795fb20b5865e12ab75913a
```

```bash
# démarrage du container my-container en mode interactif
$ docker start -i my-container
Hello world
```

```bash
# liste des containers existants
$ docker ps -a

CONTAINER ID IMAGE         COMMAND                CREATED              STATUS                      PORTS  NAMES
692508ca4c7a ubuntu:latest "/bin/echo 'Hello wor" About a minute ago   Exited (0) 48 seconds ago          my-container
```

```bash
# start again and extract logs from my-container
$ docker start -i my-container
Hello world

$ docker logs my-container

Hello world
Hello world
```


```bash
# delete my-container
$ docker rm my-container
my-container
```

## Utilisation des images

### Les registries

Les images peuvent être téléchargées depuis des dépôts d'image appelés *regristry* un peu
à la manière qu'un package debian peut être téléchargé depuis un dépôt reprepro.

Comme debian, docker met à disposition un registry publique https://hub.docker.com/
interrogée par le client lorsqu'on cherche ou télécharge une image sans préfixe d'url.



![Registries](./docs/registries.png "Registries")


Exemple:

```bash
$ docker search grip
NAME                            DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
yokogawa/grip-export            Docker Image for https://github.com/joeyes...   2                    [OK]
psycofdj/grip                   docker package for https://github.com/joey...   0
...
```

Lorsqu'on télécharge une image, docker la stoque dans son espace local.

```bash
# liste des images dans l'espace local
$ docker images

REPOSITORY  TAG     IMAGE ID      CREATED      SIZE
ubuntu      latest  bd3d4369aebc  2 weeks ago  126.6 MB
...
```

Les images docker sont versionnées par des tags. Sans spécification explicite, le
tag **latest** sera utilisé.

```bash
# pulling ubuntu xenial
$ docker pull ubuntu

# pulling ubuntu precise
$ docker pull ubuntu:12.04
```


### Construire

Une image est construite à partir d'un fichier de recette **Dockerfile**. Ce fichier
est écrit dans un langage spécifique décrit sur la page
https://docs.docker.com/engine/reference/builder/.

L'exécution de la recette de construction se passe au niveau du démon docker. Le
client docker se contente de créer un contexte de construction (une sorte de .tar.gz du
dossier spécifié) et de l'envoyer au démon.


![Image build flow](./docs/image_flow.png "Image build flow")


### Exercice 2

La recette suivante génère une image contenant un apache, un petit site web et
quelques modification de la configuration par défaut.

On notera :
  * le *FROM* httpd:2.4, on part d'une image de base où le serveur apache est déjà installée.

  * les directives *COPY* qui copient des fichiers du contexte de construction
    dans le filesystem de l'image. En particulier, le *docker-entrypoint.sh*
    qui est une pratique standard pour donner la commande par défaut
    à exécuter dans les containers issus de cette image


```bash
$ cat apache2-front/Dockerfile

# une image peut se base sur image parente
FROM httpd:2.4

# chaque image doit déclarer le nom de son mainteneur
MAINTAINER Xavier MARCELET <xavier@marcelet.com>

# des arguments pouvant être passés à la commande de construction et leurs valeurs par défaut
ARG http_proxy=""
ARG https_proxy=""

# on copie des fichiers vers le filesystem de l'image
COPY ./conf/demo.conf /etc/apache2/sites-available/
COPY ./www/           /var/www/demo
COPY ./entrypoint.sh  /docker-entrypoint.sh

# on lance un certain nombre de commande
RUN apt-get update && apt-get install -y --force-yes libapache2-mod-php wget
RUN a2ensite demo
RUN a2dissite 000-default
RUN chmod +x /docker-entrypoint.sh

# on indique à docker que l'image est conçue pour exposé un port, ici le port 80
EXPOSE 80

# on indique la commande par défaut à exécuter dans les containers issus de cette image
ENTRYPOINT ["/docker-entrypoint.sh"]
```

Construction de l'image :

```bash
$ docker build                          \
  -t xmarcelet/apache-front             \
  ./apache2-front
```


Démarrage du container :

```bash
# l'option -d indique de lancer le container en mode background
# l'option --name front donne un nom au container, par défaut un nom est généré automatiquement
$ docker run -d --name front xmarcelet/apache-front
```

On rentre dans le container en cours d'exécution :

```bash
$ docker exec -ti front /bin/bash
root@45dda687ac49:/$ wget -q -O- http://localhost/host.php
```
```html
 <html>
   <head>
     <link rel="icon" type="image/png" href="data:image/png;base64,iVBORw0KGgo=">
   </head>
   <body>
     <table>
       <tbody>
         <tr>
           <th> hostname </th>
           <td> 45dda687ac49</td>
         </tr>
         <tr>
           <th> ip </th>
           <td> 172.17.0.5 </td>
         </tr>
       </tbody>
     </table>
   </body>
 </html>
```

Arrêt et suppression du container :
```bash
$ docker stop front
$ docker rm front
```

## Port mapping

Dans l'exemple précédant, nous avons été contraint de rentrer dans le
docker pour interroger le port 80 du apache. Un serveur n'étant pas interrogeable
depuis l'extérieur n'étant pas très pratique, docker permet de mapper
le port 80 de notre container vers un port accessible depuis la machine locale.


Le mapping se fait au moment de la création du container (docker create ou docker run)
a travers les options :
* ```{-p|--expose} <value>```
* ```{-P|--publish-all}```

### Publication port à port

Dans -p <value>, l'argument de l'option peut avoir plusieurs formes :
  * ```-p "<local_port>:<container_port>"``` : Ici nous demandons explicitement de
    faire correspondre le port du container ```<container_port>``` au port local
    ```<local_port>```. Ceci implique que ```<local_port>``` ne soit pas déjà utilisé
    localement

  * ```-p "<container_port>"``` : Dans cette version, docker s'occupe de choisir
    un port local libre pour le mapper vers ```<container_port>```. Le port sélectionné
    est disponible dans le docker ps ou le docker inspect
    ```bash
    $ docker run -d -p 80 --name front xmarcelet/apache-front
    $ docker ps
    CONTAINER ID  IMAGE                    COMMAND                 PORTS                 NAMES
    539d844c8d42  xmarcelet/apache-front   "/docker-entrypoint.s"  0.0.0.0:6578->80/tcp  front
    ```

  * ```-p "<local_mim>-<local_max>:<container_port>"``` : Même chose que précédemment à la
    différence que le port est sélectionné dans l'intervalle ```[ <local_min> .. <local_max> ]```

  * ```-p "<interface>:<local_port>:<container_port>"``` : Dans cette version, on spécifie
    l'interface locale sur laquelle effectuer le mapping.
    ```bash
    $ docker run -d -p 127.0.0.1:8080:80 --name front xmarcelet/apache-front
    ```

Cette option peut être donnée autant de fois que nécessaire.
La spécification complète du format de l'option est disponible sur
https://docs.docker.com/engine/userguide/networking/default_network/dockerlinks/


### Publication de tous les ports

L'option --publish-all permet de mapper automatiquement tous les ports exposés
par l'image container (directive EXPOSE du Dockerfile) sur des ports locaux
libres.

### Exercice 3

```bash
# on demande un mapping local sur un port libre
$ docker run -d -p 80 --name front xmarcelet/apache-front

# on récupère le port attribué via le json du docker inspect et
# de l'utilitaire jq (awk pour json)
$ local_port=$(docker inspect front | jq -r '.[0]["NetworkSettings"]["Ports"]["80/tcp"][0]["HostPort"]')

# on wget la page
$ wget -q -O- "http://localhost:${local_port}/host.php"
```

## Les volumes

Par défaut, toutes les modifications effectuées sur le filesystem seront perdues après
la destruction du container. Pour éviter cela, docker propose l'utilisation de volumes
dont les données sont conservées après la destruction du container et permettent
de partager des données entre plusieurs containers.

La déclaration des volumes peut se faire de plusieurs façons :
* À la création du container avec l'option ```-v <path>```. Cette version
  crée un volume docker et le monte dans le container sur ```<path>```.
  Note: Il est possible de cibler un répertoire ou directement un fichier.

* À la création du container avec l'option ```-v <local_path>:<path>```. Ici
  le point de la machine hôte ```<local_path>``` sera monté dans le container
  sur le chemin ```<path>```

* Dans le Dockerfile de l'image avec la directive ```VOLUME <path>```. L'instruction
  **VOLUME** d'un Dockerfile provque la création implicite d'un volume docker à
  la création du container équivalent à un ```-v <path>```.

Les volumes peuvent être crées, listés et supprimés indépendamment de la création
du container avec les commandes :
* ```docker volume ls```
* ```docker volume create <args>```
* ```docker volume rm <volume>```

En particulier pour être partagé entre plusieurs containers, un volume devra être
crée indépendamment avec un nom. Plus de détails sur
https://docs.docker.com/engine/tutorials/dockervolumes/

### Exercice 4

Par défaut, les modifications du filesystem sont perdues après la destruction du container

```bash
$ cat ./apache2-front/entrypoint.sh
# writing history of all container start for volume demo purpose
mkdir -p /data/
chmod 666 /data/history
echo "starting at $(date)" >> /data/history
cat /data/history

if [ "$#" -eq 0 ]; then
    export TMPDIR=/tmp
    rm -f /var/run/apache2/apache2.pid
    apache2 -DFOREGROUND
else
  $@
fi

# on crée et démarre une première fois le container
$ docker run --name front -d xmarcelet/apache-front

# on inspecte le contenu du fichier /data/history
$ docker exec -ti front cat /data/history

starting at jeudi 15 septembre 2016, 10:28:19 (UTC+0200)

# on stop et redémarre le container et on re-inspecte le fichier
$ docker stop front
$ docker start front
$ docker exec -ti front cat /data/history

starting at jeudi 15 septembre 2016, 10:28:19 (UTC+0200)
starting at jeudi 15 septembre 2016, 10:32:57 (UTC+0200)

# on détruit le container et recommence
$ docker stop front
$ docker rm front
$ docker run --name front -d xmarcelet/apache-front
$ docker exec -ti front cat /data/history

starting at jeudi 15 septembre 2016, 10:38:23 (UTC+0200)
```

Avec l'utilisation d'un volume :

```
# on crée un volume
$ docker volume create --name front-data

# on crée et démarre une première fois le container
$ docker run -v front-data:/data/ --name front -d xmarcelet/apache-front

# on inspecte le contenu du fichier /data/history
$ docker exec -ti front cat /data/history

starting at jeudi 15 septembre 2016, 10:42:19 (UTC+0200)

# on détruit le container et recommence
$ docker stop front
$ docker rm front
$ docker run -v front-data:/data --name front -d xmarcelet/apache-front
$ docker exec -ti front cat /data/history

starting at jeudi 15 septembre 2016, 10:42:19 (UTC+0200)
starting at jeudi 15 septembre 2016, 10:43:56 (UTC+0200)
```

Avec l'utilisation d'un volume monté sur la machine hôte :

```
# on crée et démarre une première fois le container
$ mkdir -p /tmp/data
$ docker run -v /tmp/data:/data/ --name front -d xmarcelet/apache-front

# on inspecte le contenu du fichier /data/history
# cat /tmp/data/history

starting at jeudi 15 septembre 2016, 10:42:19 (UTC+0200)

# on détruit le container et recommence
$ docker stop front
$ docker rm front
$ docker run -v /tmp/data:/data/ --name front -d xmarcelet/apache-front
$ cat /tmp/data/history


starting at jeudi 15 septembre 2016, 10:42:19 (UTC+0200)
starting at jeudi 15 septembre 2016, 10:43:56 (UTC+0200)
```

# Docker compose

Docker compose est un outil permettant de définir et gérer des applications composés
de plusieurs containers.

Dans compose, une application est composée d'un ou plusieurs **services** où chaque
service est composé d'une où plusieurs instanciations d'une image docker.
L'ensemble de l'écosystème d'un application est décrit dans un fichier de recette
**docker-compose.yml**.

## Installation

RTFM : https://docs.docker.com/compose/install/

## Architecture

Docker compose est un client à part entière du démon docker. Il n'utilise pas la commande
docker et parle directement au serveur à travers la même API HTTP rest. Vu du démon, on
ne distingue pas les appels venant du docker(cli) de ceux de docker-compose.

![Compose Architecture](./docs/compose.png "Compose Architecture")


## Du sucre pour docker


L'un des principaux avantage de compose est de permettre de définir une fois pour
toute les paramètres de création des containers et des images.

On retrouve les commandes principales de docker comme *create*, *build*, *run*, *start*, ...
où toutes les options et arguments prennent les valeurs définies dans le fichier
docker-compose.yml


```bash
$ cat ./docker-compose-ex1.yml
```
```yaml
version: "2"
services:
  front:
    build:
      context: ./apache2-front
      args:
        - http_proxy=${proxy}
        - https_proxy=${proxy}
    image: xmarcelet/apache-front
    ports:
      - "8888:80"
```

Dans cet exemple, on définit un service nommé *front* en indiquant :
* ```image: xmarcelet/apache-front``` : que le service doit être crée
  à pratir de l'image xmarcelet/apache-front
* ```ports: "8888:80"``` : que le container doit être lancé en mappant le port local
  8888 sur le port 80 du container
* ```build: ...``` : que l'image *xmarcelet/apache-front* doit être crée avec deux
  *--build-arg* en transmettant le dossier *./apache2-front* en contexte de construction.
  On notera la possibilité d'utiliser des variables d'environnement, comme par exemple
  ici *${proxy}*



Pour ce fichier docker-compose.yml, les commandes docker suivantes seront générées :

| commande docker-compose           | équivalent docker
|-----------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| ```docker-compose build front```  | ```docker build -t xmarcelet/apache-front --build-arg="http_proxy=${proxy}" --build-arg="https_proxy=${proxy}" ./apache2-front/``` |
| ```docker-compose run -d front``` | ```docker run --name front -p "8888:80" xmarcelet/apache-front```                                                                  |
| ```docker-compose logs front```   | ```docker logs front```                                                                                                            |
| ```docker-compose stop front```   | ```docker stop front```                                                                                                            |
| ```docker-compose rm front```     | ```docker rm front```                                                                                                              |






### Exercice 5

Dans ce premier exemple, on reprend notre container 'front' pour en crée un service.
On cible l'architecture finale suivante  :

![Exemple 1 Architecture](./docs/compose-ex1.png "Exemple 1 Architecture")


* construction de l'image

```bash
$ docker-compose -f docker-compose-ex1.yml build front
```


* démarrage du service

```bash
$ docker-compose -f docker-compose-ex1.yml up -d front
```

* interrogation du serveur apache

```bash
$ wget -q -O- "http://localhost:8888/host.php"
```

## Liens réseaux

En plus de permettre la définition de plusieurs service, Docker compose offre la
possibilité de créer un lien entre eux pour permettre leur communication réseau.

Lier le service *app1* au service *app2* aura pour effet la création
d'une entrée dans le /etc/hosts du container *app2* donnant l'ip qui aura été
attribué au démarrage du service *app1*. Dit autrement, le container *app2* pourra obtenir l'ip du container *app1* simplement
en résolvant simplement le hostname *app1*.


Un lien entre deux service se déclare dans le fichier docker-compose.yml via la directive **links** où
chaque lien peut s'écrire :
- ```- <service_name>``` : ajoute l'entrée ```<service_name>``` dans le /etc/hosts à destination de ip du container ```<service_name>```
- ```- <service_name>:<alias>``` : ajoute l'entrée ```<alias>``` dans le /etc/hosts à destination de ip du container ```<service_name>```


L'ajout de lien entre deux services compose aura également pour effet d'induire une dépendance
et un ordre de démarrage entre ces services.
Si *app1* est lié à *app2* et que app1 n'est pas démarré, alors la demande de démarrage
de *app2* provoquera en amont le démarrage de *app1*

### Exercice 6

Dans cet exemple, on ajoute le composant *proxy* à notre application. L'idée est
de protéger notre service *front* par un reverse proxy à authentification basic qui
forward le requêtes au service *front*.

L'architecture cible sera donc :

![Exemple 2 Architecture](./docs/compose-ex2.png "Exemple 2 Architecture")

On notera qu'il n'est plus nécessaire de mapper le port 80 du service front sur la
machine hôte puisqu'on souhaite faire passer toutes nos requêtes par le reverse proxy.


**Les commentaires des fichiers suivants expliquent les points clés.**


Le fichier docker-compose.yml :
``` bash
$ cat docker-compose-ex2.yml
```

```yaml
version: "2"
services:
  # nouveau service proxy
  proxy:
    # instruction de construction de la nouvelle image
    build:
      context: ./apache2-proxy
      args:
        - http_proxy=${proxy}
        - https_proxy=${proxy}
    image: xmarcelet/apache-proxy
    ports:
      - "8888:80"
    # on lie le service front sous l'alias "dest_node"
    links:
      - front:dest_node

  # service front identique au précédant sans mapping de port
  front:
    build:
      context: ./apache2-front
      args:
        - http_proxy=${proxy}
        - https_proxy=${proxy}
    image: xmarcelet/apache-front
```

Le Dockerfile du proxy :

```dockerfile
$ cat apache2-proxy/Dockerfile

FROM httpd:2.4
MAINTAINER Xavier MARCELET <xavier@marcelet.com>

ARG http_proxy=""
ARG https_proxy=""

RUN apt-get update && apt-get install -y --force-yes wget

COPY ./conf/proxy.conf /etc/apache2/sites-available/
COPY ./conf/htpasswd   /etc/apache2/
COPY ./entrypoint.sh  /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
# activation du mod_proxy et mod_proxy_http
RUN a2enmod proxy
RUN a2enmod proxy_http
# on remplace la conf 000-default par defaut par votre virtualhost
RUN a2ensite proxy
RUN a2dissite 000-default

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
```

La configuration apache du proxy :

```apache
$ cat apache2-proxy/conf/proxy.conf

<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  DocumentRoot /var/www/
  ProxyRequests On
  ProxyVia Full
  # on forward toutes les requêtes vers le host dest_node
  ProxyPass / http://dest_node:80/
  ProxyPassReverse / http://dest_node:80/

  <Proxy *>
    Order deny,allow
    Allow from all
    # on impose une authentification basic, user = demo, password = demo
    AuthType Basic
    AuthName "Auth"
    AuthBasicProvider file
    AuthUserFile /etc/apache2/htpasswd
    Require user demo
  </Proxy>

  ErrorLog /dev/stderr
  CustomLog /dev/stdout combined
</VirtualHost>
```

Build des images :
```bash
$ export proxy="..."
$ docker-compose -f docker-compose-ex2.yml build proxy front
```

Démarrage des services :
```bash
$ docker-compose -f docker-compose-ex2.yml up -d proxy front
```

Requête :
```bash
# sans authentification
$ wget -O- http://localhost:8888/host.php

Résolution de localhost (localhost)… 127.0.0.1
Connexion à localhost (localhost)|127.0.0.1|:8888… connecté.
requête HTTP transmise, en attente de la réponse… 401 Unauthorized

Échec d’authentification par identifiant et mot de passe.
```

```bash
# avec authentification
$ wget -q  -O- http://demo:demo@localhost:8888/host.php
```

```html
 <html>
   <head>
     <link rel="icon" type="image/png" href="data:image/png;base64,iVBORw0KGgo=">
   </head>
   <body>
     <table>
       <tbody>
         <tr>
           <th> hostname </th>
           <td> 16fe42c5db1b</td>
         </tr>
         <tr>
           <th> ip </th>
           <td> 172.21.0.2 </td>
         </tr>
       </tbody>
     </table>
   </body>
 </html>
```


## Scale des instances

Une autre fonctionnalité de docker compose est de contrôler le nombre d'instance
d'un service et de le faire évoluer dans le temps.

La commande ```docker-compose scale <name>=<num>``` démarrera ou éteindra autant
d'instances du service <name> que nécessaire pour atteindre ```<num>```.

A noter: docker compose mémorise le dernier nombre d'instance demandé pour chaque
service de manière à en relancer le bon nombre dans le cas où le service est arrêté
puis redémarré.

### Exercice 7


Dans cet exemple, on souhaite pouvoir scaler dynamiquement le nombre d'instance
de notre service front en distribuant les requêtes arrivant sur le reverse proxy.

Intuitivement, on voudrait que le reverse proxy distribue directement les
requête sur les différents host du service front. Malheureusement, les liens docker
compose sont calculé au démarrage du container proxy (donc pas dynamique) et la
résolution du host du lien ne fait pas de randrobin sur les instances du service
front.

Pour remplir l'objectif fonctionnel, on utilise une brique supplémentaire **haproxy**
qui est un reverse proxy tcp/http proposant des fonctionnalités de load balancing.
Pour comprendre comment fonctionne haproxy, il faut introduire une autre notion
de docker : les **events docker**

Le démon docker gère une file d'événement accessible depuis sont API HTTP. A peu
près tout ce qui se passe sur le serveur sont inscrit dans la file, en particulier
le démarrage et l'extinction des containers, tels qu'ils soient.

Au démarrage, haproxy s'abonne à la liste d'évènements du démon docker et va
dynamiquement mettre à jour son pool de machine destination en fonction des
évènements de démarrage/d'arrêt lus sur la file.

![Exemple 3 Architecture](./docs/compose-ex3.png "Exemple 3 Architecture")



* Le docker-compose

```bash
$ cat docker-compose-ex3.yml
```

```yaml
version: "2"
services:
  # on reprend notre service proxy
  proxy:
    build:
      context: ./apache2-proxy
      args:
        - http_proxy=${proxy}
        - https_proxy=${proxy}
    image: xmarcelet/apache-proxy
    ports:
      - "8888:80"
    # cette fois, le reverse proxy apache redirige vers le nouveau service 'lb'
    links:
      - lb:dest_node

  # le service 'lb' de haproxy
  lb:
    image: 'dockercloud/haproxy:latest'
    # on lui donne accès à l'api HTTP du démon docker, nécessaire pour la
    # lecture des événements
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    # Par défaut de cette image prête à l'emploi est configuré pour forward
    # et distribuer le trafic entrant sur l'ensemble de ses liens docker
    links:
      - front

# on reprend notre service front
  front:
    build:
      context: ./apache2-front
      args:
        - http_proxy=${proxy}
        - https_proxy=${proxy}
    image: xmarcelet/apache-front
```


* Utilisation des services

```bash
# on démarrage les services
$ docker-compose -f docker-compose-ex3.yml up -d front lb proxy

# Un premier test montrant qu'on tombe toujours sur l'unique instance de front.
$ wget -q  -O- http://demo:demo@localhost:8888/host.php | grep '<td>'

<td>45dda687ac49</td>
<td>172.17.0.4</td>

$ wget -q  -O- http://demo:demo@localhost:8888/host.php | grep '<td>'

<td>45dda687ac49</td>
<td>172.17.0.4</td>

# on demande une seconde instance du service front
$ docker-compose -f docker-compose-ex3.yml scale front=2

# cette fois, on tombe alternativement sur l'une ou l'autre de nos instances de front
$ wget -q  -O- http://demo:demo@localhost:8888/host.php | grep '<td>'
<td>45dda687ac49</td>
<td>172.17.0.4</td>
$ wget -q  -O- http://demo:demo@localhost:8888/host.php | grep '<td>'
<td>dee3ef9d4aab</td>
<td>172.17.0.5</td>

# pour le plaisir...
$ docker-compose -f docker-compose-ex3.yml scale front=20
$ watch -n1 -- "wget -q  -O- http://demo:demo@localhost:8888/host.php | grep '<td>'"
```

# Docker swarm & Docker machine

Docker swarm est une couche faisant discuter ensemble plusieurs démons docker installés
sur des machines différentes, permettant à l'utilisateur de distribuer ses containers
dans un cluster.

Docker machine est un outil permettant d'initialiser facilement des environements docker
sur des machines distantes. Compatibles avec de nombreuses API cloud comme EWS d'amazon,
Microsoft Azure ou encore VirtualBox pour des tests sur des machines virtuelles locales.

## Installation

Docker machine : https://docs.docker.com/machine/install-machine/
Docker swarm : builtin dans docker.

**/!\ Attention /!\** : Jusqu'à très récemment, swarm était un composant à part
entière de la dockershpère. Il a été intégré directement dans le démon docker
à partir de la version 1.12. La version standalone existe toujours et suit
sont cycle développement propre. Conséquence, il faut toujours faire attention
au quel des deux *swam* font référence les documentations disponibles sur le net.
Ce tutorial utilise la version directement intégrée de swarm.


## Architecture


### Machine

On utilise docker machine pour instancier des environements docker sur des machines
distantes. A la création :
* la machine est provisionnée sur le provider cible
* les démons ssh et docker sont installés
* des certificats SSL sont générés localement puis déployés sur la machine distante
  de manière à ce que seule la machine locale puisse communiquer avec le démon docker
  (en écoute sur l'interface 0.0.0.0)

Après la création d'une ou plusieurs machines, l'outils docker-machine nous permet
à partir du nom de la machine de générer les variables d'environnements indiquant
au client docker local de communiquer avec le démon de la machine distante.

Finnalement, on a :

![Docker Machine](./docs/docker-machine.png "Docker Machine")


Liste des commandes :

* ```docker-machine create [-d <driver> [<driver_opts>]] node_name``` : Création d'une
  nouvelle machine <node_name>. Le driver indique quel provider cloud cibler. Les options
  ```<driver_opts>``` changent selon le driver. **A noter:** L'un des drivers disponible
  est *virtualbox*, il aura pour effet de provisionner des machines virtuelle locale
  plutôt que de la provisionner sur un service de cloud.

* ```docker-machine ssh              <node_name>``` : Se connecte en ssh à la machine ```<node_name>```.

* ```docker-machine ip               <node_name>``` : Retourne l'ip affecté à la machine
  ```<node_name>```. Les machines étant provisionnées automatiquement, on ne connait pas à
  priori les ips qui vont être utilisées.

* ```docker-machine env              <node_name>``` : Renvoi sur la sortie standard
  la liste des variables d'environnement à utiliser pour communiquer avec le démon docker
  de la machine ```<node_name>```. Classiquement, on lancera la commande ```eval $(docker-machine
  env *<node_name>*)``` pour appliquer les variables dans la foulée. De plus, la commande génère une
  fonction bash *__docker_machine_ps1* qu'on peut utiliser dans la variable PS1 pour toujours
  savoir vers quelle machine le shell est configuré.

* ```docker-machine env              -u``` : Reset des variables d'environnement, s'utilise
  commme la commande précédante.

* ```docker-machine ls``` : Liste des machines disponibles

* ```docker-machine stop             <node_name>``` : Arret de la machine ```<node_name>```
* ```docker-machine start            <node_name>``` : Démarrage de la machine ```<node_name>```
* ```docker-machine rm               <node_name>``` : Suppression de la machine ```<node_name>```
* ```docker-machine regenerate-certs <node_name>``` : Re-création des certificats SSL de la
  machine ```<node_name>```. **A noter :** Il est fréquent que la commande de création du
  driver virtualbox termine en erreur à cause des certificats. La plus part du temps
  les regénérer suffit à corriger le problème.


### Swarm

Swarm est un mode de fonctionnement particulier du démon docker standard. Dans
ce mode, plusieurs démon communiquent entre eux pour former un cluster et quand
ce cluster reçoit une commande docker de création de container, un noeud est
sélectionné pour l'executer.

Au sein du cluster, les noeuds ont soit le role de *manager* soit de *worker*.
Au besoin, un noeud worker peut être manuellement promu manager et inversement.
* **manager** : Ces noeuds s'occupent de maintenir à jour l'état du cluster et de
  sélectionner les noeuds worker où éxecuter les commandes docker.
* **worker** : Ces noeuds éxécutent les commandes reçues des managers, de la même
  manière qu'on démon docker éxécute les commandes reçues par un docker client.

L'API exposé par le swarm-manager est la même que l'API du démon docker standard.
Par conséquence, l'utilisation du docker client et docker compose reste inchangé
en mode swarm.

![Docker Swarm](./docs/docker-swarm.png "Docker Swarm")


Liste des commandes :

* ```docker swarm init --advertise-addr <ip>``` : Active le mode swam sur le démon docker cible.
  En retour, la commmande génère un token d'authorization à fournir aux autres démon docker
  souhaitant rejoindre le cluster.

* ```docker swarm join-token worker``` : Imprime le token d'authorisation à fournir aux futures workers

* ```docker swarm join <token> <ip>:<port>``` : Demande au démon docker cible de rejoindre le cluster
  swarm dont le manager est joignable sur ```<ip>:<port>```. Le token d'authorisation est celui donné
  par le manager au moment de l'activation du mode swarm.

* ```docker info``` : Imprime l'état du cluster

* ```docker node ls``` : Liste les noeuds du cluster

## Exercice 8

Dans cet exercice, on reprend l'architecture cible précedante *proxy + lb + front* mais
cette fois on souhaite que les différents containers se répartissent sur plusieurs
machines. Ces machines seront des machines virutelle locale VirtualBox mais le
fonctionnement serait le même sur un pool de machine physique où dans un cloud prodiver.

### Creation des machines virtuelles

On commence par créer notre infrastructure de machine. On en profite pour explorer
l'utilisation du l'outil docker-machine.


```bash
# Création de 3 machines virtuelles, manager, node1 et node2
$ docker-machine create -d virtualbox manager
[...]

$ docker-machine create -d virtualbox node1
[...]

$ docker-machine create -d virtualbox node2
[...]
```


```bash
# Liste des machines disponibles

$ docker-machine ls
NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER
manager   -        virtualbox   Running   tcp://192.168.99.101:2376           v1.12.1
node1     -        virtualbox   Running   tcp://192.168.99.100:2376           v1.12.1
node2     -        virtualbox   Running   tcp://192.168.99.102:2376           v1.12.1
```


```bash
# Execution d'une commande de test sur la machine manager

$ docker-machine ssh manager head -n1 /etc/hosts
127.0.0.1 manager localhost localhost.local
```

```bash
# Execution d'une docker sur la machine node1

# On commence par positionner nos variables d'environnement docker
# -> pour voir a quoi ca ressemble
$ docker-machine env node1
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="~/.docker/machine/machines/node1"
export DOCKER_MACHINE_NAME="node1"
# Run this command to configure your shell:
# eval $(docker-machine env node1)

# -> on source la sortie de la commande
$ eval $(docker-machine env node1)

# A ce stade, notre docker (cli) local est configuré pour envoyer ses
# commandes sur l'url tcp://192.168.99.100:2376 en utilisant les certificats
# ssl du dossier ~/.docker/machine/machines/node1.
# Si vous avez configuré votre PS1 dans la commande __docker_machine_ps1,
# vous devriez lire "node1" dans votre prompt.
#
$ docker run ubuntu "echo Hello World"
Hello World

# On liste les containers
$ docker ps -a
CONTAINER ID IMAGE  COMMAND              CREATED              STATUS
d4fbf4b88287 ubuntu "echo 'Hello World'" About a minute ago   Exited (0) About a minute ago

# On change de machine cible et on reliste les containers
$ eval $(docker-machine env node2)
$ docker ps -a
CONTAINER ID IMAGE  COMMAND              CREATED              STATUS

# On se repositionne sur le démon docker local
$ eval $(docker-machine env -u)
```

### Initialisation du swarm


* Activation du swarm en mode manager

```bash
# Bien entendu, les tokens et IP générés dépendent
# de l'environnement. Les commandes suivantes seront à adapter.
#
$ eval (docker-machine env manager)
$ docker swarm init --advertise-addr $(docker-machine ip manager)
Swarm initialized: current node (dxn1zf6l61qsb1josjja83ngz) is now a manager.

To add a worker to this swarm, run the following command:

  docker swarm join \
        --token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \
        192.168.99.100:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

* Activation du swarm en mode woker sur les deux noeuds


```bash
# Récupération du token pour l'environnement en cours
$ eval (docker-machine env manager)
$ docker swarm join-token worker

<token>

# Activation du swarm sur node1
$ eval $(docker-machine env node1)
$ docker swarm join --token <token> $(docker-machine ip manager):2377

# Activation du swarm sur node2
$ eval $(docker-machine env node2)
$ docker swarm join --token <token> $(docker-machine ip manager):2377
```

* Inspection du cluster


```bash
$ eval $(docker-machine env manager)
$ docker node ls
ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
1mqx9rg4zicwec4d11g9uo4it *  manager   Ready   Active        Leader
7rdrgmvk7njkq2nvkncirgt6p    node2     Ready   Active
8pogc9k09g5wteia20cqhce31    node1     Ready   Active
```

<!--  LocalWords:  app name forward cat docker-compose-ex yml yaml -->
<!--  LocalWords:  context args apache-proxy apache-front Dockerfile -->
<!--  LocalWords:  dockerfile apt-get update install force-yes chmod -->
<!--  LocalWords:  default virtualhost -->
