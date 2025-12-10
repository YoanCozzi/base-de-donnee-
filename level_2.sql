create or replace function add_person( -- fonction qui va permettre d'ajouter une personne à notre bdd
firstname varchar(32),
lastname varchar(32),
email varchar(128),
phone varchar(10),
address text,
town varchar(32),
zipcode varchar(5)
)
returns boolean as $$
begin
	insert into person(firstname,lastname,email,phone,address,town,zipcode)
	values(firstname,lastname,email,phone,address,town,zipcode);
	return true;
exception
    when others then
        return False;
end;
$$ language plpgsql;


create or replace function add_offer( -- fonction qui va nous permettre à ajouter une offre à notre bdd
code varchar(5),
name varchar(32),
price float,
nb_month int,
zone_from int,
zone_to int
)
returns boolean as $$ 
begin
	insert into offer(code,name,price,nb_month,zone_from,zone_to)
	values(code,name,price,nb_month,zone_from,zone_to);
	return true;
exception
    when others then
        return False;
end;
$$ language plpgsql;


create or replace function add_subscription( -- on créé une fonction pour abonner une personne à une offre
num int,
aemail varchar(128),
code varchar(5),
date_sub date
)
returns boolean as $$
declare
	user_pi boolean; -- attention il faut faire gaffe que si une personne a le statu pending ou incomplete cela nous revoie false
begin 
    select exists (select 1 from subscription where email = aemail and status in ('Pending', 'Incomplete')) into user_pi;
    if user_pi then
        return false;
    end if;
	insert into subscription(num,email,code,date_sub)
	values(num,aemail,code,date_sub);
	return true;
exception
    when others then
        return False;
end;
$$ language plpgsql;

-------------update function ------------------------

create or replace function update_status( -- fonction qui va permettre de modifier le statut dans subscription
unum int,
new_status varchar(32)
)
returns boolean as $$
begin
	update subscription set status=new_status where unum=num;
	return true;
exception
    when others then
        return False;
end;
$$ language plpgsql;

create or replace function update_offer_price( -- fonction qui va modifier le prix d'une offre
offer_code varchar(5),
uprice float
)
returns boolean as $$
begin
	update offer set price=uprice where offer_code=code;
	return true;
exception
    when others then
        return False;
end;
$$ language plpgsql;

----------------vues-----------------------

create view view_user_small_name as
select lastname,firstname from person 
where length(lastname)<=4 -- on veut afficher que les personnes avec un nom au minimum de 4 lettre
order by lastname asc;

create view view_user_subscription as -- on affiche l'offre de la personne, pour cela il faut recuperer le nom et prenom de la table person et le nom de l'offre de la table offer
select concat(person.lastname,' ',person.firstname) as user, offer.name as offer from offer
join subscription on offer.code=subscription.code
join person on subscription.email = person.email
order by person.lastname asc;

create view view_unloved_offers as 
select name as offer from offer
where code not in (select distinct code from subscription) -- affiche toutes les offres qui n'ont pas été utilisé par les personnes
order by offer.name asc;

create view view_pending_subscriptions as
select lastname, firstname from person -- affiche toutes les personnes ayant le status pending, il faut donc passer par la table subscription et person
join subscription on person.email=subscription.email
where subscription.status='Pending'
order by subscription.date_sub asc;

create view view_old_subscription as -- affiche toutes les personnes ayant souscrit à un abonnement d'au moins un an et qui sont toujours avec le status incomplete ou pending
select person.lastname, person.firstname,offer.name as subscrption, subscription.status as status from offer
join subscription on offer.code=subscription.code
join person on subscription.email = person.email
where ((subscription.status='Pending' or subscription.status='Incomplete') and (current_date-subscription.date_sub)>=365)
order by person.lastname asc;

------------- Procedures -------------------

create or replace function list_station_near_user( -- renvoie toutes les stations qui sont dans la même ville que l'utilisateur
luser varchar(128)
)
returns setof varchar(64) as $$
declare
    user_town varchar(32);
begin
    user_town=(select town from person where luser=email);
    return query select name from station where user_town=town;
end;
$$ language plpgsql;


create or replace function list_subscribers( -- renvoie toutes les personnes qui ont souscrit à une certaine offre demandé
code_offer varchar(5)
)
returns setof text as $$
declare
    sub_email varchar(128)[];
begin
	select array(select email from subscription where code_offer=code)into sub_email;
    return query select concat(lastname,' ',firstname) from person where email=any(sub_email);
end;
$$ language plpgsql;


create or replace function list_subscription( -- renvoie tout les code de des offre pour une personne qui a le status registered pour une date donnée
lemail varchar(128),
ldate date
)
returns setof varchar(5) as $$
begin
    return query select code from subscription where (lemail=email) and (ldate=date_sub) and (status='Registered');
end;
$$ language plpgsql;
