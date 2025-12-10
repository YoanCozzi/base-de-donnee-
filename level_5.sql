-- Triggers

create table offer_updates(
code varchar(5) references offer(code),
time_modif timestamp not null,
old price float check(old_price>0) not null,
new_price float check(new_price>0) not null
);

create or replace function offer_changes()
returns trigger as $$
begin
if new.price is distinct from old.price then
    insert into offer_updates(code,time_modif,old_price,new_price)
    values (old.id,old.price,new.price,current_timestamp);
end if;
    return new;
end;
$$ language plpgsql;


create trigger store_offer_updates
before update on offer
for each row execute function offer_changes();


create table status_updates(
email varchar(128) references person(email),
num int references subscription(num),
time_modif timestamp,
old_status varchar(32),
new_status  varchar(32)
);

create or replace function status_changes()
returns trigger as $$
begin
if new.status is distinct from old.status then
    insert into status_updates(email,num,time_modif,old_status,new_status)
    values (old.email,old.num,current_timestamp,old.status,new.status);
end if;
    return new;
end;
$$ language plpgsql;


create trigger store_status_updates
before update on subscription
for each row execute function status_changes();


--------------- vues -----------------------------

create view view_offer_updates as 
select code as subscription, time_modif as modification, old_price, new_price from offer_updates;


create view view_status_updates as 
select email, num as sub, time_modif as modification, old_status, new_status from status_updates;
