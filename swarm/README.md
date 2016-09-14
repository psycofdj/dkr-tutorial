# Pré-requis

## Installation de virtualbox

```bash
sudo apt-get install virtualbox
```

## Installation de docker-machine

```bash
sensible-browser https://docs.docker.com/machine/install-machine/
```

## Installation de docker-compose

```bash
sensible-browser https://docs.docker.com/compose/install/
```


# Bootstrap


## Création de l'infra test

```bash
# instantiation de la stack 'docker / swarm / etcd / registrator / skydns' dans une
#  serie de vm virtualbox

./infratest/cluster.sh create
```

## Update des images


Il est nécessaire de pousser les images dans la registry d'infratest
Cette étape est automatisée par le script ***infratests/build.sh***

```bash
./infratest/build.sh --env infratest
./warp --env infratest -- pull
```

# Utilisation

**Note :** Il est important de proceder en deux temps

1. up du premier container
2. scale au nombre de conainter désirés

Dans le cas contraire, le network overlay ne sera pas crée par docker-compose et les
commandes aboutissent en erreur.

## Instanciation

```bash
./wrap --env infratest -- up -d
./wrap --env infratest -- scale es-master=2 es-data=2
```

## Visualisation du résutlat

```bash
# récupération de l'ip:port des services
./wrap --env infratest -- ps es-client kibana proxy

# enter l'url ip:port retournée dans les navigateur
sensible-browser "ip:port"
```

## Autres interfaces
### Docker regitry (UI)

```bash
sensible-browser "http://$(docker-machine ip etcd-master):8080/repositories"
```

## Visualisation des logs

L'ensemble des containers envoient leur logs sur un syslog centralisé. Dans l'infratest, ce syslog (syslog-ng)
est gébergé sur le noeud etcd-master. Pour y accèder :

```bash
eval $(docker-machine env etcd-master);
docker exec -ti infra_syslog /bin/bash -c 'tail -f /var/log/syslog';
```

## Inspection du contenu du backend etcd

```bash
# pour visualiser l'ensemble des services enregistrés dans etcd
curl -qL "http://$(docker-machine ip etcd-master):4001/v2/keys/skydns/?recursive=true" | json_pp | less

# pour visualiser toutes les données etcd
curl -qL "http://$(docker-machine ip etcd-master):4001/v2/keys/?recursive=true" | json_pp | less
```
