drop table station_to_line;
drop table journey;
drop table station;
drop table line;
drop table transport_type;
drop table subscription;
drop table offer;
drop table zone;
drop table employees;
drop table bill;
drop table person;
drop table service;

-- Création de toutes les tables que l'on va devoiur utiliser 

create table transport_type( 
code varchar(3) unique not null primary key, -- code pour différencier chaque type de transport
name varchar(32) not null unique, -- son nom
capacity integer check(capacity>0) not null, -- le nombre de passager max qu'il peut contenir
avg_interval integer check(avg_interval>0) not null -- le temps en minutes entre 2 stations 
);

create table zone(
id serial primary key, -- numéro identification de la zone
name varchar(32) unique not null, -- nom de la zone
price float check(price>0) not null -- prix lorsqu'on prend un transport en commun dans cette zone
);

create table station(
id int unique not null primary key, -- numero id de chaque stations
name varchar(64) not null, -- nom de la station
town varchar(32) not null, -- ville ou la station est situé 
zone_id int not null references zone(id), -- zone dans laquel la station est situé
transport_type_code varchar(3) not null references transport_type(code) -- on référence le type de transport dans stations, car une station ne doit appartenir qu'a un seul type de transport
);

create table line(
code varchar(3) unique not null primary key, -- numero id de la ligne
transport_type_code varchar(3) references transport_type(code) -- on reference le type de transport, car une ligne n'est utilisé que par un seul type de transport
);

create table station_to_line( -- creation d'une table intermediaire pour relier station et line celle ci sert a mettre plusieurs stations dans une ligne 
id serial primary key, -- numero id
station_id int references station(id), -- on reference le numero de la station
line_code varchar(3) references line(code), -- on reference le numero de la ligne
position int not null check(position>0) -- on donne la position de la station dans la ligne donee
);

create table person( -- on identifie toutes personnes prenant un transport
firstname varchar(32) not null, 
lastname varchar(32) not null,
email varchar(128) unique not null primary key, -- j'ai mis la clé primaire sur email car un email est unique à une personne
phone varchar(10) not null,
address text not null,
town varchar(32) not null,
zipcode varchar(5) not null
);

create table offer( -- creation d'offres 
code varchar(5) primary key,
name varchar(32) not null unique, -- nom de l'offre 
price float check(price>0) not null, -- prix par mois de l'offre
nb_month int check(nb_month>0) not null, -- nombr ede mois que dure l'offre
zone_from int not null references zone(id), 
zone_to int not null check(zone_to>=zone_from) references zone(id) -- offre vallable sur les zones de zone_from à zone_to
);

create table subscription( -- toute les personnes qui sont ou qui veulent souscrire à une offre
num int not null unique primary key,
email varchar(128) not null references person(email), -- une offre est associé à une personne qui est dans la table person
code varchar(5) references offer(code), -- code de l'offre que la personne a pris
date_sub date not null, -- la date à laquelle il a souscrie
status varchar(32) not null check(status in ('Registered','Pending','Incomplete')) default('Incomplete') -- regarde si il est bien souscri ou si il manque des infos 
);

create table service( -- chaque service peut avoir des avantages
name varchar(32) unique not null primary key, --nom du service
discount int check((discount>=0) and (discount<=100)) not null -- avantage en pourcentage qu'on peut avoir en utilisant les transport en commun dans un service
);

create table employees( -- personne employee dans les transport en commun
email varchar(128) not null unique references person(email), -- doit appartenir à la table personne
firstname varchar(32) not null,
lastname varchar(32) not null,
login varchar(8) not null unique primary key, -- un identifiant unique pour chaque employee
hire_date date not null, -- date à laquelle il c'est engagé
departure_date date default null, -- date à laquel il est parti (peut etre nul)
check(hire_date<=departure_date),
service varchar(32) not null references service(name)-- service dans lequel il travail
);

create table journey( -- on regarde ce qu'une personne fait dans une journee
id serial primary key,
email varchar(128) not null references person(email), -- doit appartenir a la table person
time_start timestamp unique not null, -- moment où il a pris le transport en commun
time_end timestamp unique not null, -- moment ou il est sorti du transport en commun
check(time_end>time_start),
check(time_end-time_start<='24:00:00'), -- doit durer une journee max 
station_start int not null references station(id), -- numero de station qu'il est parti
station_end int not null references station(id) -- numero de station ou il est sorti
);

create table bill( -- on genere une facture pour chaque personne a la fin de chaque mois
id serial primary key,
email varchar(128) not null references person(email), -- on associe une facture a une personne
year int not null, -- annee
month int not null, -- mois
price float, -- prix
status boolean -- a-t-il payé ?
);
