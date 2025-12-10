create or replace function add_service( -- cette fonction va servir à ajouter des services dans notre table service
aname varchar(32),
adiscount int 
)
returns boolean as $$
begin
	insert into service(name,discount)
	values(aname,adiscount);
	return true;
exception
    when others then
        return False; -- retourne faux si il y a une erreur 
end;
$$ language plpgsql;

create or replace function add_contract( -- on rejoute des contract dans notre table employees
aemail varchar(128),
date_beginning date,
service varchar(32)
) -- j'ai un probleme sur cette fonction, je n'arrive pas à ajouter une nouvelle personne qui a déjà eu un emploi dans employees, a cause du login
returns boolean as $$
declare 
    fname varchar(32);
    lname varchar(32);
    alogin varchar(8);
begin
    fname=(select firstname from person where aemail=email);
    lname=(select lastname from person where aemail=email);
    alogin=concat(substring(lname,1,6),'@',substring(fname,1,1)); -- attention le login doit s'ecrire de cette maniere

	insert into employees(firstname,lastname,login,email,hire_date,service)
	values(fname,lname,alogin,aemail,date_beginning,service);
	return true;
exception
    when others then
        return False;
end;
$$ language plpgsql;

-- j'ai tenté de faire ça, mais ça ne fonctionne pas 
--create or replace function add_contract( -- on rejoute des contract dans notre table employees
--aemail varchar(128),
--date_beginning date,
--service varchar(32)
--)
--returns boolean as $$
--declare 
 --   fname varchar(32);
  --  lname varchar(32);
  --  alogin varchar(8);
--	dd_exist date;
--	login_exist boolean;
--begin
--    fname=(select firstname from person where aemail=email);
--   lname=(select lastname from person where aemail=email);
--    alogin=concat(substring(lname,1,6),'@',substring(fname,1,1)); -- attention le login doit s'ecrire de cette maniere
	
--	select exists (select 1 from employees where aemail=email) into login_exist;
--    if login_exist then
--		dd_exist=(select departure_date from employees where aemail=email);
--		if dd_exist is null then
--			return false;
--		end if;
--		alogin=concat(substring(lname,1,6),'@','z');
--    end if;
	
--	insert into employees(firstname,lastname,login,email,hire_date,service)
--	values(fname,lname,alogin,aemail,date_beginning,service);
--	return true;
--exception
--    when others then
--        return False;
--end;
--$$ language plpgsql;

create or replace function end_contract( -- on fait un update pour terminer le contract d'une personne employee
aemail varchar(128),
date_end date
)
returns boolean as $$
declare
	dd_exist date;
begin
	dd_exist=(select departure_date from employees where aemail=email);
	if dd_exist is not null then
		return false; -- si departure date existe déjà on retourne false
	end if;
    update employees set departure_date=date_end where aemail=email;
	return true;
exception
    when others then
        return False;
end;
$$ language plpgsql;

----------- update function ----------------------------

create or replace function update_service(  -- on fait un update pour fixer un nouveau prix de remise à un service
uname varchar(32),
udiscount int
)
returns boolean as $$
begin
    update service set discount=udiscount where uname=name;
	return true;
exception
    when others then
        return False;
end;
$$ language plpgsql;


create or replace function update_employee_email( -- Cette fonction ne marche pas ! Surement car j'ai mis email comme clé primaire dans la table person
ulogin varchar(8),
uemail varchar(128)
)
returns boolean as $$
declare 
	email_employee varchar(128);
begin
	email_employee=(select email from employees where ulogin=login);
    update person set email=uemail where email_employee=email;
	return true;
exception
    when others then
        return False;
end;
$$ language plpgsql;


---------------- vues ------------------------------

create view view_employees as -- on regarde les services associé a tout nos employées
select lastname, firstname, login, service from employees
where departure_date is null or departure_date>=current_date
order by lastname asc;


create or replace function nb_employees_per_service(
nservice varchar(32)
)
returns int as $$
declare
    total_employees int;
begin
	total_employees=0;
    select count(login) into total_employees from employees -- on va calculé le nombre d'employé dans une service donné
    where nservice=service and (departure_date is null or departure_date>=current_date);
    return total_employees;
end;
$$ language plpgsql;

create view view_nb_employees_per_service as -- on regarde le nombre d'employé par service
select name, nb_employees_per_service(name) from service
order by name asc;


---------------- Procedures --------------------------

create or replace function list_login_employee( -- renvoie toute les personne qui travaille dans les transport en commun à une date donnée
date_service date
)
returns setof varchar(8) as $$
begin
	return query select login from employees where hire_date<=date_service and (departure_date is null or departure_date>date_service);
end;
$$ language plpgsql;


-- j'ai teste plusieurs fonctions pour la suite mais rien ne marche
--create or replace function list_not_employee( -- ne marche pas !
--date_service date
--)
--returns table(lastname varchar(32),firstname varchar(32),has_worked text) as $$
--declare
 --   work varchar(3);
--begin
--    if person.email is not in employees.email then 
--        work='NO';
--    elsif employees.departure_date<=date_service then
--        work='YES';
--    end if;
--	return query select lastname, firstname, work from person where hire_date<=date_service and (departure_date is null or departure_date>date_service);
--end;
--$$ language plpgsql;

create or replace function list_not_employee( -- ne marche pas !
date_service date
)
returns table(lastname varchar(32),firstname varchar(32),has_worked text) as $$
declare
    hd_exist date[];
    work varchar(3);
begin
    select array(select hire_date from employees)into hd_exist;
    if hd_exist<=date_service then
        work='YES';
    else 
        work='NO';
    end if;
    return query select lastname,firstname,work from employees;
end;
$$ language plpgsql;


--create or replace function list_not_employee(-- ne marche pas !
--date_service date
--)
--returns table(email varchar(128),has_worked text) as $$
--declare
--    hd_exist date[];
--    work varchar(3)[];
--begin
--    select array(select hire_date from employees)into hd_exist;
--	for i in 1..array_length(hd_exist,1) loop
--    	if date_service>=hd_exist[i] then
--        	work[i]='YES';
--    	else 
 --       	work[i]='NO';
 --   	end if;
--	end loop;
--    return query select employees.email,work from employees;
--end;
--$$ language plpgsql;


-- de même celle ci ne fonctionne pas !
create or replace function list_subscription_history( -- ne marche pas du tout !
lemail varchar(128)
)
returns table(type text, name varchar, start_date date, duration interval) as $$
declare
    employee_exist boolean;
    ltype text;
    lname varchar;
    lstart_date date;
    lduration interval;
begin
    select exists(select 1 from employees where lemail=email)into employee_exist;
    if employee_exist then
        ltype='ctr';
        lname=(select name from employees where lemail=email);
        lstart_date=(select hire_date from employees where lemail=email);
        lduration=(select departure_date-hire_date from employees where lemail=email);
	    return query select ltype,lname,lstart_date,lduration from employees;
    else 
        ltype='sub';
        lname=(select code from subscription where lemail=email);
        lstart_date=(select date_sub from subscription where lemail=email);
        lduration=0;
	    return query select ltype,lname,lstart_date,lduration from employees;
end;
$$ language plpgsql;