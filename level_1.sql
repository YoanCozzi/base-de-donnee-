create or replace function add_transport_type( -- on utilise cette fonction pour ajouter un type de transport dans notre table transport_type
code varchar(3),
name varchar(32),
capacity int,
avg_interval int
)
returns boolean as $$
begin
	insert into transport_type(code,name,capacity,avg_interval)
	values(code,name,capacity,avg_interval);
	return true;
exception
    when others then -- retourne faux si il detecte une erreur qui ne convient pas aux parametre de la table
        return False;
end;
$$ language plpgsql;

create or replace function add_zone( -- on utilise cette fonction pour ajouter une zone dans notre table zone
name varchar(32),
price float
)
returns boolean as $$
begin
	insert into zone(name,price)
	values(name,price);
	return true;
exception
    when others then -- retourne faux si il detecte une erreur qui ne convient pas aux parametre de la table
        return False;
end;
$$ language plpgsql;

create or replace function add_station( -- on utilise cette fonction pour ajouter une station dans notre table station
id int,
name varchar(64),
town varchar(32),
zone int,
type varchar(3)
)
returns boolean as $$
begin
	insert into station(id,name,town,zone_id,transport_type_code)
	values(id,name,town,zone,type);
	return true;
exception
    when others then
        return False; -- retourne faux si il detecte une erreur qui ne convient pas aux parametre de la table
end;
$$ language plpgsql;

create or replace function add_line( -- on utilise cette fonction pour ajouter une ligne dans notre table line
code varchar(3),
type varchar(3)
)
returns boolean as $$
begin
	insert into line(code,transport_type_code)
	values(code,type);
	return true;
exception
    when others then
        return False; -- retourne faux si il detecte une erreur qui ne convient pas aux parametre de la table
end;
$$ language plpgsql;

create or replace function add_station_to_line( -- on utilise cette fonction pour ajouter une station pour une ligne voulu dans notre table station_to_line 
astation int,
aline varchar(3), -- attention j'ai un probleme cette fonction ne marche pas !
apos int
)
returns boolean as $$
declare
    station_type varchar(3);
    line_type varchar(3);
    station_identique boolean;
    pos_identique boolean;
begin
    station_type=(select transport_type_code from station where astation=id);
    line_type=(select transport_type_line from line where aline=code);
    if station_type!=line_type then -- retourne faux si l'on donne une station et une ligne qui n'ont pas le meme type de transport
        return False;
	end if;
    select exists (select 1 from station_to_line where astation=station_id and aline=line_code) into station_identique;
    if station_identique then
        return false;
    end if;
    select exists (select 1 from station_to_line where apos=position and aline=line_code) into pos_identique;
    if pos_identique then
        return false;
    end if;
	insert into station_to_line(station_id,line_code,position)
	values(astation,aline,apos);
	return true;
exception
    when others then
        return False; -- retourne faux si il detecte une erreur qui ne convient pas aux parametre de la table
end;
$$ language plpgsql;

--------------------------vues-----------------------

create view view_transport_50_300_users as
select name as transport from transport_type -- on créé une vue qui renvoie les noms des transport qui ont une capacité comprise entre 50 et 300
where capacity between 50 and 300 
order by name asc;

create view view_stations_from_villejuif as
select name as station from station -- création d'une vue qui renvoie tout les noms de stations qui sont dans la ville de Villejuif
where town='Villejuif'
order by name asc;

create view view_stations_zones as
select station.name as station,zone.name as zone from station 
join zone on station.zone_id=zone.id -- création d'une vue qui prend les noms des stations et qui les ordones par zones
order by zone.name asc; 


create or replace function nb_station_type( -- création d'une fonction qui va nous permettre de pouvoir compter le nombre de stations dans un type de transport donné
name_transport varchar(32)
)
returns int as $$
declare
    code_transport varchar(3);
    total_station int;
begin
    code_transport=(select code from transport_type where name_transport=name);
    select count(station.id) into total_station from station
    where station.transport_type_code=code_transport;
    return total_station;
end;
$$ language plpgsql;


create view view_nb_station_type as -- création d'une vue qui renvoie le nombre de stations par types de transports
select name as type, nb_station_type(name)  as stations from transport_type
order by nb_station_type(name) desc;


create or replace function line_duration( -- création d'une fonction qui va compter la durée en minutes d'une ligne donnée
tname varchar(32),
code_line varchar(3)
)
returns int as $$
declare
    ttime int;
    total_station int;
begin
    ttime=(select avg_interval from transport_type where tname=name);
    select count(station_id) into total_station from station_to_line
    where code_line=line_code;
    return ttime*(total_station-1);
end;
$$ language plpgsql;

create view view_line_duration as -- création d'une vue qui nous donne la durée en minutes de chaque ligne 
select transport_type.name as type, line.code as line, line_duration(transport_type.name,line.code) as minutes  from line
join transport_type on line.transport_type_code=transport_type.code
order by transport_type.name asc;



create or replace function station_capacity( -- création d'une fonction qui nous permet de donner la capacité de personne dans un type de transport grace à une station
station_name varchar(32)
)
returns int as $$
declare
    code_transport varchar(3);
    transport_capacity int;
begin
    code_transport=(select transport_type_code from station where station_name=name);
    select capacity into transport_capacity from transport_type where transport_type.code=code_transport;
    return transport_capacity;
end;
$$ language plpgsql;

create view view_a_station_capacity as -- cette vue nous donne pour toutes les stations la capacité que peut contenir son type de transport
select name as station, station_capacity(name) as capacity from station
order by name asc;


---------------- Procedures ------------------

create or replace function list_station_in_line( -- donne une liste de toute les stations qui sont dans une ligne
code_line varchar(3)
)
returns setof varchar(64) as $$
declare
    id_station int[];
begin
    select array(select station_id from station_to_line where code_line=line_code) into id_station;
    return query select name from station where id=any(id_station);
end;
$$ language plpgsql;


create or replace function list_types_in_zone( -- donne une liste de tout les types de transports qui circulent dans une zone donnée
zone int
)
returns setof varchar(32) as $$
declare
    transport_code varchar(3)[];
begin
    select array(select transport_type_code from station where zone=zone_id)into transport_code;
    return query select name from transport_type where code=any(transport_code);
end;
$$ language plpgsql;


create or replace function get_cost_travel( -- Renvoie le coût du trajet entre deux stations
station_start int,
station_end int
)
returns float as $$
declare
    id_zone_start int;
    id_zone_end int;
    price_zone float;
    total_price float;
	station_start_exist boolean;
	station_end_exist boolean;
begin
	select exists (select 1 from station where station_start=id) into station_start_exist;
    if not station_start_exist then
        return 0;
    end if;
	select exists (select 1 from station where station_end=id) into station_end_exist;
    if not station_end_exist then
        return 0; -- renvoie 0 si les stations qu'on a rentré n'existe pas
    end if;
	total_price=0;
    id_zone_start=(select zone_id from station where station_start=id);
    id_zone_end=(select zone_id from station where station_end=id);
    for i in least(id_zone_start,id_zone_end)..greatest(id_zone_start,id_zone_end) loop
        price_zone=(select price from zone where i=id); -- donne le coût entre deux stations
        total_price=total_price+price_zone;
    end loop;
    return total_price ;
end;
$$ language plpgsql;