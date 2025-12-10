create or replace function add_journey( -- dans cette fonction on rentre tout ce que l'utilisateur fait dans une journee
email varchar(128),
time_start timestamp,
time_end timestamp,
station_start int,
station_end int
)
returns boolean as $$
begin
	insert into journey(email,time_start,time_end,station_start,station_end)
	values(email,time_start,time_end,station_start,station_end);
	return true;
exception
    when others then
        return False;
end;
$$ language plpgsql;


-- malhereusement je n'ai pas reussi a créer add_bill, il était vraiment compliqué !

--create or replace function add_bill(
--aemail varchar(128),
--ayear int,
--amonth int
--)
--returns boolean as $$
--declare
--	employee_service varchar(32);
--	name_service varchar(32);
--	sub_code varchar(128);
--	price_offer
--	journey_email varchar(128);
--begin
--    employee_service=(select service from employees where aemail=email);
--	discount_service=(select discount from service where employee_service=name);
--	sub_code=(select code from subscription where aemail=email);
--	price_offer=(select price from offer where sub_code=code);

--	insert into bill(email,year,month)
--	values(email,year,month);
--	return true;
--exception
--    when others then
--        return False;
--end;
--$$ language plpgsql;



create or replace function pay_bill( -- en envoie true pour les personnes qui ont payé leurs facture et false ceux qui n'ont pas payé ou qui n'ont pas de facture
pemail varchar(128),
pyear int,
pmonth int
)
returns boolean as $$
declare 
	pprice float;
	pstatus varchar;
begin
	pprice=(select price from bill where (pemail=email) and (pyear=year) and (pmonth=month));
	pstatus=(select status from bill where pemail=email and (pyear=year) and (pmonth=month));
	if pprice is null then
		return false;
	end if;
	if pstatus='true' then
		return true;
	else
		return false;
	end if;
end;
$$ language plpgsql;


-- je n'ai pas compris ce qu'il fallait faire de plus pour generate_bill ???

------------- vues ----------------------------------

create or replace function all_bills( -- on recupere juste le nom et le prenom
aemail varchar(128)
)
returns varchar(64) as $$
declare
    plastname varchar(32);
    pfirstname varchar(32);
begin
    plastname=(select lastname from person where aemail=email);
	pfirstname=(select firstname from person where aemail=email);
    return (plastname,pfirstname);
end;
$$ language plpgsql;


create view view_all_bills as  -- affiche tout les paiements avec le motant pour chaque personne
select all_bills(email) as name, id as bill_number, price as bill_amount from bill;



create or replace function total_bill( -- on recupere le nombre de facture généré pour un mois et une annee
year_bill integer,
month_bill integer
)
returns integer as $$
declare
    total_bill integer;
begin
	total_bill=0;
	select count(id) into total_bill from bill where year_bill=year and month_bill=month;
    return total_bill;
end;
$$ language plpgsql;

create or replace function total_price( -- on recupere le prix total des factures pour un mois et une annee
year_bill integer,
month_bill integer
)
returns float as $$
declare
	price_ym float[];
    total_price float;
begin
	total_price=0;
	select array(select price from bill where year_bill=year and month_bill=month)into price_ym;
	for i in 1..array_length(price_ym,1) loop
        total_price=total_price+price_ym[i];
    end loop;
    return total_price;
end;
$$ language plpgsql;

create view view_bill_per_month as -- affiche le nombre de facture et la somme des factures pour un mois et une annee
select year, month, total_bill(year,month) as bills, total_price(year,month) as total from bill;


create or replace function count_station( -- ne fonctionne pas ! je voulais prendre le nombre de stations par jour
)
returns integer as $$
declare
	total_station integer;
begin
	total_station=0;
	select count(id) into total_station from journey where current_date=to_char(time_start,'yyyy-mm-dd');
    return total_station;
end;
$$ language plpgsql;

-- ne fonctionne pas 
create view view_average_entries_station as -- affiche le nombre d'entrée au niveau des stations par jours
select transport_type.name as type, station.name as station, count_station() as entries from journey
join station on journey.station_start=station.id
join transport_type on station.transport_type_code = transport_type.code
order by transport_type.name asc;


create view view_current_non_paid_bills as -- affiche toute les personnes qui n'ont pas encore payé leur facture 
select person.lastname as lastname, person.firstname as firstname, bill.id as bill_number, bill.price as bill_amount from bill
join person on bill.email=person.email
where bill.status='false'
order by person.lastname asc;