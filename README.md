# Conception d'un système de transport public (pgSQL)-

Modélisation et implémentation d'une base de données pour gérer un réseau de transport (bus, tram, métro). Le projet s'appuie sur le langage pgSQL.

-- Voici toute les données que j'ai utilisé, je me suis permis de les prendres sur Chatgpt.

-- Data for transport_type
INSERT INTO transport_type (code, name, capacity, avg_interval) VALUES
('BUS', 'Bus', 50, 10),
('MET', 'Metro', 200, 5),
('TRM', 'Tram', 150, 7);

-- Data for zone
INSERT INTO zone (id, name, price) VALUES
(1, 'Zone 1', 1.50),
(2, 'Zone 2', 2.50),
(3, 'Zone 3', 3.50);

-- Data for station
INSERT INTO station (id, name, town, zone_id, transport_type_code) VALUES
(1, 'Central Station', 'Cityville', 1, 'MET'),
(2, 'North Park', 'Cityville', 1, 'BUS'),
(3, 'East Side', 'Townsville', 2, 'TRM'),
(4, 'West End', 'Cityville', 3, 'BUS');

-- Data for line
INSERT INTO line (code, transport_type_code) VALUES
('L1', 'MET'),
('L2', 'BUS'),
('L3', 'TRM');

-- Data for station_to_line
INSERT INTO station_to_line (station_id, line_code, position) VALUES
(1, 'L1', 1),
(2, 'L2', 1),
(3, 'L3', 1),
(4, 'L2', 2);

-- Data for person
INSERT INTO person (firstname, lastname, email, phone, address, town, zipcode) VALUES
('Alice', 'Smith', 'alice.smith@example.com', '0123456789', '123 Elm St', 'Cityville', '10001'),
('Bob', 'Jones', 'bob.jones@example.com', '0987654321', '456 Oak St', 'Townsville', '20002'),
('Carol', 'Davis', 'carol.davis@example.com', '1234567890', '789 Pine St', 'Cityville', '10003');

-- Data for offer
INSERT INTO offer (code, name, price, nb_month, zone_from, zone_to) VALUES
('O1', 'Monthly Zone 1', 30.00, 1, 1, 1),
('O2', 'Monthly Zone 1-2', 50.00, 1, 1, 2),
('O3', 'Yearly Zone 1-3', 300.00, 12, 1, 3);

-- Data for subscription
INSERT INTO subscription (num,email, code, date_sub, status) VALUES
(1,'alice.smith@example.com', 'O1', '2024-01-01', 'Registered'),
(2,'bob.jones@example.com', 'O2', '2024-02-15', 'Pending'),
(3,'carol.davis@example.com', 'O3', '2024-03-10', 'Incomplete');

-- Data for employees
INSERT INTO employees (email, firstname, lastname, login, hire_date, departure_date, service) VALUES
('alice.smith@example.com', 'Alice', 'Smith', 'smith@a', '2023-01-01', NULL, 'Customer Support'),
('bob.jones@example.com', 'Bob', 'Jones', 'jones@b', '2022-06-15', '2024-05-01', 'IT'),
('carol.davis@example.com', 'Carol', 'Davis', 'davis@c', '2021-09-10', NULL, 'Sales');

-- Data for service
INSERT INTO service (name, discount) VALUES
('Customer Support', 10),
('IT', 20),
('Sales', 15);

-- Data for journey
INSERT INTO journey (email, time_start, time_end, station_start, station_end) VALUES
('alice.smith@example.com', '2024-11-01 08:00:00', '2024-11-01 08:30:00', 1, 2),
('bob.jones@example.com', '2024-11-02 09:00:00', '2024-11-02 09:45:00', 2, 3),
('carol.davis@example.com', '2024-11-03 07:30:00', '2024-11-03 08:15:00', 3, 4);

-- Data for bill
INSERT INTO bill (email, year, month, price, status) VALUES
('alice.smith@example.com', 2024, 1, 30.00, TRUE),
('bob.jones@example.com', 2024, 2, 50.00, FALSE),
('carol.davis@example.com', 2024, 3, 300.00, TRUE);

-- on va tester tout ce que j'ai créé depuis le début maintenant: 

--------- treshold 1 --------------

select add_transport_type('BUS','bus nocturne',700,6); -- retourne faux car le code existe deja
select add_transport_type('BNS','Bus',700,6); -- retourne faux car le nom existe deja
select add_transport_type('TGV','Train',-700,6); -- retourne faux car le nombre de passager ne peut pas etre negatif
select add_transport_type('TGV','Train',700,-6); -- retourne faux car le l'intervalle de temps entre deux stations ne peux pas etre negatif
select add_transport_type('TGV','Train',700,6) ;-- retourne vrai !

select add_zone('Zone 1',5);-- retourne faux car le nom existe deja
select add_zone('Zone 4',0); -- retourne faux car le prix vaut 0
select add_zone('Zone 4',5); -- retourne vrai !

select add_station(1, 'stationjuif', 'Villejuif', 1, 'MET');-- retourne faux, car l'id existe deja
select add_station(5, 'stationjuif', 'Villejuif', 1, 'MET'); -- retourne vrai !

select add_line('L1','BUS'); -- retourne faux car la ligne 1 existe deja
select add_line('L4','MET'); -- retourne vrai !

select add_station_to_line(4,'L1',3); -- retourne faux car la station 4 est pour un transport type bus or la ligne L1 est de type metro
select add_station_to_line(4,'L2',3); -- retourne faux car la station 4 existe deja dans la ligne L2
select add_station_to_line(5,'L1',1); -- retourne faux car la station 5 est sur une position deja occupé de la ligne L1
select add_station_to_line(5,'L1',2); -- retourne vrai !
-- attention dans mon cas la derniere me rend faux car je n'ai pas du bien reussir a ecrire la fonction add_station_to_line

select * from view_transport_50_300_users; -- on obtient alors bus metro et tram, mais pas train
select * from view_stations_from_villejuif; -- on obtient la station : stationjuif
select * from view_stations_zones; -- nous renvoie bien toute les stations avec leurs zones 
select * from view_nb_station_type; -- renvoie le nombre de stations par types de transport, ici on a : bus=2, metro=2,tram=1,train=0 
select * from view_line_duration; -- renvoie le temps que prend chaque ligne, par exemple avec deux stations dans la ligne L2, on met 10 minutes, il est plus interessant bien sur de mettre plus de stations dans une ligne !
select * from view_a_station_capacity; -- renvoie la capacité que peut prendre chaque stations par rapport a son type de transport


select list_station_in_line('L2'); -- renvoie toutes les stations qui sont dans la ligne L2 : North Park et West End
select list_types_in_zone(1); -- donne le nom de tout les types de transports qui sont dans la zone 1, ici il y a bus et metro
select get_cost_travel(1,2); -- retourne 1.5 car ces deux stations sont dans la meme zone
select get_cost_travel(7,2); -- retourne 0 car la stations 7 n'existe pas
select get_cost_travel(1,4); -- retourne 7.5 car de la stations 1 à 4 on passe par la zone 1,2 et 3 donc il faut faire la somme des couts des 3 zones
select get_cost_travel(1,4); -- meme chose, c'est normal ! On s'assure bien qu'il n'y a pas de probleme quand on passe de zone 3 à 1

-------------- treshold 2 -------------------------

select add_person('lucas','michel','alice.smith@example.com','0676457899','67 route de la cite','Villejuif','25668');-- retourne faux car cette adresse mail existe deja
select add_person('lucas','michel','lucas.michel@gmail.com','0676457899','67 route de la cite','Villejuif','25668'); --retourne vrai !

select add_offer('O4','zone 3',80,-1,3,3); -- retourne false car le nombre de mois est negatifs
select add_offer('O4','zone 2',80,1,2,2); -- retourne vrai !

select add_subscription(3,'lucas.michel@gmail.com','O2','2024-03-03');-- retourne faux car ce numéro existe déja
select add_subscription(4,'lucas.michel@gmail.com','O2','2022-03-03');-- retourne vrai 
select add_subscription(5,'bob.jones@example.com','O2','2024-03-03');-- retourne faux car bob jones à un abonnement en pending ou incomplete
select add_subscription(5,'alice.smith@example.com','O2','2024-03-03');-- retourne vrai, car alice smith a un abonnement en registered, donc elle peut en reprendre un nouveau

select update_status(4,'lalalal'); -- retourne false car le status ne doit que etre Registered, Pending ou Incomplete
select update_status(4,'Pending'); -- retourne vrai, maintenant l'abonnement de lucas michel est registered

select update_offer_price('O4',-60); -- retourne faux car le prix doit etre positif
select update_offer_price('O6',-60); -- retourne faux car l'offre n'existe pas
select update_offer_price('O4',60); -- retourne vrai ! On a bien changer le prix de l'offre 4 qui passe maintenant à 60 euros


select add_person('emma','doe','emma.doe@gmail.com','0676457899','67 route de la cite','Villejuif','25668'); --retourne vrai !
select * from view_user_small_name; -- retourne toute les personnes qui ont un nom plus petit ou egale à 4 lettres ici emma doe
select * from view_user_subscription; -- affiche toutes les personnes qui ont pris un abonnement avec les le nom de l'offre(zones ou il peut voyager sans payer a chaque fois le trajet)
select * from view_unloved_offers; -- affiche toutes les offres qui n'ont pas été acheté par un utilisateur ici 'zone 2'
select * from view_pending_subscriptions; -- affiche toutes les personnes qui sont en status Pending ici Jones Bob et lucas michel
select * from view_old_subscription; -- affiche toutes les personnes qui ont un abonnement incomplet ou en pending de plus d'un an ici lucas michel

select list_station_near_user('alice.smith@example.com'); -- affiche toute les stations qui sont dans la meme ville que alice, on a central station, north park et west end
select list_subscribers('O2'); -- affiche toute les personne qui ont pris l'offre 2 ici on a alice, lucas et bob

------------- treshold 3 -------------------------------

select add_service('controleur',-25); -- faux car le discount est negatif
select add_service('controleur',125); -- faux car le discount vaiut plus de 100
select add_service('controleur',25); -- retourne vrai !

select add_contract('alice.smith@example.com','2024-01-01','Sales'); -- retourne faux, car alice est toujours en contract
select add_contract('bob.jones@example.com','2025-01-01','Sales'); -- doit retourner vrai, car bob n'est pas employé le 01/01/2025, sauf que j'ai un problème sur ma fonction !
select add_contract('lucas.michel@gmail.com','2024-01-01','IT'); -- retourne vrai 

select end_contract('lucas.michel@gmail.com','2023-01-01'); -- retourne faux car il n'a pas encore commencé a travailler a cette date la
select end_contract('lucas.michel@gmail.com','2025-01-01'); -- retourne vrai !
select end_contract('lucas.michel@gmail.com','2026-01-01'); -- retourne faux, car il n'a pas eu d'autre contract entre temps

select update_service('lala',5); -- ne fait rien car lala n'existe pas dans la table service
select update_service('controleur',130); -- retourne faux car le discount n'est pas entre 0 et 100
select update_service('controleur',30); -- on a bien modifié le discount des controleurs qui est passé a 30

select update_employee_email('lucas.michel@gmail.com','michel@l'); -- retourne vrai car l'email n'a pas changé
select update_employee_email('lucas.michel@example.com','michel@l'); -- doit changer l'email, mais ne fait rien, car la fonction ne marche pas, je l'ai expliqué dans le level_3
select update_employee_email('lucas.michel@example.com','mygdj@l'); -- ne fait rien du tout

select * from view_employees; -- affiche toute les personnes qui travaille dans les transports aujourd'hui
select * from view_nb_employees_per_service; -- affiche le nombre de personne qui travaille dans chaque secteur aujourd'hui

select list_login_employee('2023-01-01'); -- affiche toutes les personnes qui travillaient dans la compagnie à une date donnée
--select list_not_employee() je n'ai pas reussi a le faire
-- select list_subscription_history() de meme, je n'ai pas reussi a faire la fonction


----------- treshold 4 -----------------------------------------

select add_journey('alice.smith@example.com','2024-11-01 08:00:00','2024-11-01 08:45:00',3,4);-- ne marche pas car alice ne peut pas être a deux stations differentes au meme moment
select add_journey('alice.smith@example.com','2024-12-01 08:00:00','2024-12-02 08:45:00',3,4);-- ne marche pas car il y a plus de 1 jour d'ecart entre lorsqu'on est rentrée dans un transport et lorsqu'on est ressorti
select add_journey('alice.smith@example.com','2024-11-01 09:00:00','2024-11-01 09:45:00',3,4);-- retourne vrai !

-- pour add_bill, je n'ai pas reussi à le faire

select pay_bill('alice.smith@example.com',2024,1); -- retourne vrai, car alice a deja payé
select pay_bill('bob.jones@example.com',2024,1); -- retourne faux car le prix n'existe pas, car il n'a rien acheté en janvier 2024
select pay_bill('bob.jones@example.com',2024,2); -- retourne faux car il n'a encore payé sa facture de ce mois ci

-- de meme pour generate_bill, je n'ai pas reussi

select * from view_all_bills; -- affiche toute les factures de toutes les personnes 
select * from view_bill_per_month; -- affiche le nombre de facture et la somme des factures pour un mois et une annee
-- view_average_entries_station ne fonctionne pas !
select * from view_current_non_paid_bills; -- affiche toute les personnes qui n'ont pas encore payé leur facture 
