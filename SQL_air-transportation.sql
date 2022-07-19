-- 1. Â êàêèõ ãîðîäàõ áîëüøå îäíîãî àýðîïîðòà?

select city as "Ãîðîä", count(city) as "Êîë-âî àýðîïîðòîâ"
from airports a 
group by 1
having count(city) >1

-- Âàðèàíò ¹2 ñ âûâîäîì íàçâàíèé àýðîïîðòîâ â îäíîé ñòðîêå

select a.city as "Ãîðîä", count(city) as "Êîë-âî àýðîïîðòîâ", group_concat(a.airport_name) as "Íàçâàíèÿ àýðîïîðòîâ"
from airports a
where city in ( -- óñëîâèå îòáîðà
	select city -- âûáîð ãîðîäà, ãäå áîëüøå 2-õ àýðîïîðòîâ
	from airports a2 
	group by 1
	having count(city) >1	
)
group by 1

-- 2. Â êàêèõ àýðîïîðòàõ åñòü ðåéñû, âûïîëíÿåìûå ñàìîëåòîì ñ ìàêñèìàëüíîé äàëüíîñòüþ ïåðåëåòà?
-- ïî óñëîâèþ çàäàíèÿ íåîáõîäèìî èñïîëüçîâàòü ïîäçàïðîñ

select a3.airport_name as "Àýðîïîðò", a3.city as "Ãîðîä", f.aircraft_code as "Ìîäåëü ñàìîëåòà"
from flights f -- âûáèðàåì ýòó òàáëèöó, ò.ê. â íåé åñòü êîä ìîäåëè ñàìîëåòà, ïî êîòîðîé íèæå èäåò âûáîðêà
join airports a3 on a3.airport_code = f.departure_airport -- ïðèñîåäèíÿåì òàáëèöó ñ íóæíûìè äëÿ âûâîäà ñòîëáöàìè
where aircraft_code in ( 
	select aircraft_code -- âûâîä ðåéñà ñ ìàêñèìàëüíîé äàëüíîñòüþ ïîëåòà
	from aircrafts a
	where "range" = (
		select max("range") from aircrafts a2
		)
	)
group by 1,2,3

-- 3. Âûâåñòè 10 ðåéñîâ ñ ìàêñèìàëüíûì âðåìåíåì çàäåðæêè âûëåòà
-- ïî óñëîâèþ çàäàíèÿ íåîáõîäèìî èñïîëüçîâàòü îïåðàòîð LIMIT

select flight_id as "Ðåéñ", actual_arrival - scheduled_departure as "Âðåìÿ çàäåðæêè ðåéñà" -- ïîä ðåéñîì ïîäðàçóìåâàåòñÿ flight_id
from flights f 
where actual_arrival > scheduled_departure -- âûáîð ðåéñîâ ñ äàòîé/âðåìåíåì âûëåòà ïîçæå ÷åì çàïëàíèðîâàííûå
order by 2 desc -- ñîðòèðîâêà ïî óáûâàíèþ
limit 10 -- îãðàíè÷åíèå âûâîäà

-- 4. Áûëè ëè áðîíè, ïî êîòîðûì íå áûëè ïîëó÷åíû ïîñàäî÷íûå òàëîíû?
-- ïî óñëîâèþ çàäàíèÿ íåîáõîäèìî âûáðàòü âåðíûé òèï JOIN

select b.book_ref as "Íîìåð áðîíè áåç ïîñàäî÷íîãî òàëîíà"
from bookings b 
join tickets t on b.book_ref = t.book_ref -- ñòûêóåì òàáëèöó "tickets" ÷òîáû ïðèâÿçàòü òàáëèöó "boarding_passes"
right join boarding_passes bp on t.ticket_no = bp.ticket_no -- èç íåå áóäåì âûâîäèòü ñòîëáåö ïî áðîíè
where bp.boarding_no is null -- óñëîâèå âûáîðà áðîíè áåç ïîñàäî÷íîãî òàëîíà
-- Çàïðîñ íå âîçâðàùàåò äàííûå, ñëåäîâàòåëüíî òàêèõ áðîíåé íåò

-- 5. Íàéäèòå êîëè÷åñòâî ñâîáîäíûõ ìåñò äëÿ êàæäîãî ðåéñà, èõ % îòíîøåíèå ê îáùåìó êîëè÷åñòâó ìåñò â ñàìîëåòå.
-- Óñëîâèÿ çàäàíèÿ:
-- Äîáàâüòå ñòîëáåö ñ íàêîïèòåëüíûì èòîãîì - ñóììàðíîå íàêîïëåíèå êîëè÷åñòâà âûâåçåííûõ ïàññàæèðîâ èç êàæäîãî àýðîïîðòà íà êàæäûé äåíü. Ò.å. â ýòîì ñòîëáöå äîëæíà îòðàæàòüñÿ íàêîïèòåëüíàÿ ñóììà - ñêîëüêî ÷åëîâåê óæå âûëåòåëî èç äàííîãî àýðîïîðòà íà ýòîì èëè áîëåå ðàííèõ ðåéñàõ â òå÷åíèè äíÿ.
-- Îêîííàÿ ôóíêöèÿ
-- Ïîäçàïðîñû èëè/è cte
-- ÐÅØÅÍÈÅ òîëüêî ïî âûëåòåâøèì ñàìîëåòàì, ò.ê. ñóììàðíîå íàêîïëåíèå íåîáõîäèìî ïðîâåñòè ïî ÂÛÂÅÇÅÍÍÛÌ ïàññàæèðàì, ò.å. è óæå ïðèáûâøèì è ïî òåì, êòî â ïîëåòå

select f.flight_id as "id ðåéñà", 
	f.aircraft_code as "Êîä ñàìîëåòà", 
	f.departure_airport as "Êîä àýðîïîðòà", 
	date(f.actual_departure) as "Äàòà âûëåòà",
	(s.count_seats - bp.count_bp) as "Ñâîáîäíûå ìåñòà",
	round(((s.count_seats - bp.count_bp) * 100. / s.count_seats), 2) as "% îò îáùåãî êîëè÷åñòâà ìåñò",
	sum(bp.count_bp) over (partition by date(f.actual_departure), f.departure_airport order by f.actual_departure) as "Íàêîïèòåëüíàÿ",
	bp.count_bp as "Êîëè÷åñòâî âûëåòåâøèõ ïàññàæèðîâ"
from flights f
left join (
	select bp.flight_id, count(bp.seat_no) as count_bp
	from boarding_passes bp
	group by bp.flight_id
	order by bp.flight_id) as bp on bp.flight_id = f.flight_id 
left join (
	select s.aircraft_code, count(*) as count_seats
	from seats s 
	group by s.aircraft_code) as s on f.aircraft_code = s.aircraft_code
where f.actual_departure is not null and bp.count_bp is not null
order by date(f.actual_departure)

-- 6. Íàéäèòå ïðîöåíòíîå ñîîòíîøåíèå ïåðåëåòîâ ïî òèïàì ñàìîëåòîâ îò îáùåãî êîëè÷åñòâà.
-- Óñëîâèÿ äëÿ âûïîëíåíèÿ çàäà÷è:
-- Ïîäçàïðîñ èëè îêíî
-- Îïåðàòîð ROUND
-- Îïÿòü æå â ðåøåíèè îòòàëêèâàëñÿ îò ñëîâà "ÏÅÐÅËÅÒÎÂ", ò.å. êîòîðûå ëèáî åùå äëÿòñÿ ëèáî óæå ñîâåðøåíû

-- explain analyze (cost=2751.03..2755.03 rows=1600 width=44) (actual time=25.489..25.491 rows=8 loops=1))
select t.aircraft_code as "Ìîäåëü ñàìîëåòà", t.count_by_aircraft_code as "Êîë-âî ïåðåëåòîâ",
round(t.count_by_aircraft_code*100/sum (t.count_by_aircraft_code) over (),2)||'%' as "% ïåðåëåòîâ îò àýðîïàðêà" -- îêðóãëÿåì äî 2-õ çíàêîâ. Çíàê '%' ïðèáàâèë èñêóññòâåííî
from (
	select aircraft_code,
	count (aircraft_code) over (partition by aircraft_code) as count_by_aircraft_code -- êîë-âî ñàìîëåòîâ âûëåòåâøèõ è ïðèáûâøèõ
	from flights f
	where status = 'Departed' or status = 'Arrived') t
group by 1,2
order by 2

-- ÂÀÐÈÀÍÒ ¹2 (ñì. íèæå) áîëåå îïòèìèçèðîâàí
-- explain analyze (cost=1018.34..1018.36 rows=9 width=80) (actual time=19.631..19.633 rows=8 loops=1)
select aircrafts.model as "Ìîäåëü ñàìîëåòà", aircrafts.aircraft_code, 
round((count(flights.flight_id)::numeric)*100 / sum(count(flights.flight_id)) over (), 2) as "Äîëÿ ïåðåëåòîâ"
from aircrafts
join flights on aircrafts.aircraft_code = flights.aircraft_code
group by aircrafts.aircraft_code
order by "Äîëÿ ïåðåëåòîâ" desc;

-- 7. Áûëè ëè ãîðîäà, â êîòîðûå ìîæíî  äîáðàòüñÿ áèçíåñ - êëàññîì äåøåâëå, ÷åì ýêîíîì-êëàññîì â ðàìêàõ ïåðåëåòà?
-- Óñëîâèÿ äëÿ âûïîëíåíèÿ çàäà÷è:
-- CTE
-- explain analyze (cost=76213.84..77457.24 rows=1 width=36) (actual time=451.859..451.989 rows=0 loops=1)
with CTE as ( -- çàâîäèì ðåçóëüòàò â ÑÒÅ
select flight_id, min(min_business), max (max_economy) -- çàïðîñ äëÿ ïîñëåäóþùåé ãðóïïèðîâêè
from (
	select  distinct flight_id, -- ðàçáèë íà äâà ñòîëáöà ñ âûáîðîì min ïî áèçíåññ-êëàññó è max ïî ýêîíîì-êëàññó
	case when tf.fare_conditions = 'Business' then min(tf.amount) end min_business,
	case when tf.fare_conditions = 'Economy' then max(tf.amount) end max_economy
	from ticket_flights tf
	group by 1,tf.fare_conditions
	) t
group by 1
)
select *
from (
	select flight_id, -- âåñü íàø òðóä âûøå âûâîäèì ïî óñëîâèþ, ÷òî min áèçíåö-öåíà ìåíüøå max ýêîíîì-öåíû
		case
			when min < max then 'Äà'
			else 'Íåò'
			end as "Õàëÿâà"
	from CTE) x 
where "Õàëÿâà" = 'Äà' -- åñëè áû óñëîâèå áûëî âûïîëíåíî, òî ïîëó÷èì íóæíûé íîìåð ïåðåëåòà, à òàì óæå ìîæíî è ãîðîäà öåïëÿòü. Ðåçóëüòàò ïóñòîé.
-- ÊÎÌÌÅÍÒÀÐÈÉ:
-- Íå íðàâèòüñÿ ñàìà ñòðóêòóðà çàïðîñà è åå ïðîèçâîäèòåëüíîñòü. 

-- ÂÀÐÈÀÍÒ ¹2 (ñì. íèæå) ðåøåíèÿ çàäà÷è ¹7
-- explain analyze (cost=40978.58..44143.52 rows=376577 width=102) (actual time=495.876..496.088 rows=0 loops=1)
with econom as
	(select flight_id, max(amount)
	from ticket_flights
	where fare_conditions = 'Economy'
	group by flight_id),
business as
	(select flight_id, min(amount) as min
	from ticket_flights
	where fare_conditions = 'Business' 
	group by flight_id)
select e.flight_id, min, max, a1.city, a2.city
from econom e
join business b on e.flight_id = b.flight_id
left join flights f on e.flight_id = f.flight_id and b.flight_id = f.flight_id
left join airports a1 on a1.airport_code = f.arrival_airport
left join airports a2 on a2.airport_code = f.departure_airport
where max > min;

select fv.departure_city, fv.arrival_city
from (
	select flight_id
	from ticket_flights
	group by flight_id
	having max(amount) filter (where fare_conditions = 'Economy') > min(amount) filter (where fare_conditions = 'Business')) t 
join flights_v fv on fv.flight_id = t.flight_id

-- 8. Ìåæäó êàêèìè ãîðîäàìè íåò ïðÿìûõ ðåéñîâ?
-- Óñëîâèÿ äëÿ âûïîëíåíèÿ çàäà÷è:
-- Äåêàðòîâî ïðîèçâåäåíèå â ïðåäëîæåíèè FROM
-- Ñàìîñòîÿòåëüíî ñîçäàííûå ïðåäñòàâëåíèÿ (åñëè îáëà÷íîå ïîäêëþ÷åíèå, òî áåç ïðåäñòàâëåíèÿ)
-- Îïåðàòîð EXCEPT

select a.city as "Ãîðîä 1", a2.city as "Ãîðîä 2"
	from airports a 
	cross join airports a2 -- äåêàðòîâî ïðîèçâåäåíèå ïî ãîðîäàì
	where a.city <> a2.city
except -- óñëîâèå íà âûâîä òîëüêî òåõ ïàð ãîðîäîâ, êîòîðûõ íåò â íèæíåì íàáîðå
select a.city, a3.city 
	from airports a 
	join routes r on a.city = r.departure_city -- ê ïåðâîìó ñòîëáöó öåïëÿåì ãîðîä ïîòåíöèàëüíî îòïðàâëåíèÿ
	join airports a3 on r.arrival_city = a3.city -- ê âòîðîìó ñòîëáöó öåïëÿåì ãîðîä ïîòåíöèàëüíîãî ïðèáûòèÿ	

-- Âàðèàíò ¹2 (ñì. íèæå) ðåøåíèÿ çàäà÷è ¹8
create view route as 
	select distinct a.city as departure_city , b.city as arrival_city, a.city||'-'||b.city as route 
	from airports as a, (select city from airports) as b
	where a.city != b.city
	--where a.city > b.city åñëè õîòèì óáðàòü çåðêàëüíûå âàðèàíòû
	order by route

create view direct_flight as 
	select distinct a.city as departure_city, aa.city as arrival_city, a.city||'-'|| aa.city as route  
	from flights as f
	inner join airports as a on f.departure_airport=a.airport_code
	inner join airports as aa on f.arrival_airport=aa.airport_code
	order by route

select r.* 
from route as r
except 
select df.* 
from direct_flight as df
		
-- 9. Âû÷èñëèòå ðàññòîÿíèå ìåæäó àýðîïîðòàìè, ñâÿçàííûìè ïðÿìûìè ðåéñàìè, ñðàâíèòå ñ äîïóñòèìîé ìàêñèìàëüíîé äàëüíîñòüþ ïåðåëåòîâ  â ñàìîëåòàõ, îáñëóæèâàþùèõ ýòè ðåéñû *
-- Óñëîâèÿ äëÿ âûïîëíåíèÿ çàäà÷è:
-- Îïåðàòîð RADIANS èëè èñïîëüçîâàíèå sind/cosd
-- CASE 

select distinct -- óáðàë çàäâîåíèå ìàðøðóòîâ (îòêóäà îíè?.. ðàçîáðàòüñÿ ïîòîì)
	r.departure_airport_name ||' ('|| r.departure_airport ||')' as "Îòïðàâëåíèå èç:", 
	r.arrival_airport_name ||' ('|| r.arrival_airport ||')' as "Ïðèáûòèå â:",
	round((acos(sind(a.latitude) * sind(a2.latitude) + cosd(a.latitude) * cosd(a2.latitude) * cosd(a.longitude - a2.longitude)) * 6371)::int,0) ||' êì' as "Ðàññòîÿíèå ì/ó àýðîïîðòàìè",
	a3.aircraft_code ||', äàëüíîñòü '|| a3."range" ||' êì' as "Õàð-êè ìîäåëè",
case 
	when a3."range" > round(acos(sind(a.latitude) * sind(a2.latitude) + cosd(a.latitude) * cosd(a2.latitude) * cosd(a.longitude - a2.longitude)) * 6371) then 'Äà'
	else 'Íåò'
	end as "Äîëåòèò:"
from routes r
join airports a on r.departure_airport = a.airport_code -- ïðèñîåäèíèë äëÿ ïîëó÷åíèÿ êîîðäèíàò
join airports a2 on r.arrival_airport = a2.airport_code -- ïðèñîåäèíèë äëÿ ïîëó÷åíèÿ êîîðäèíàò
join aircrafts a3 on r.aircraft_code = a3.aircraft_code -- äëÿ âûâîäà ìîäåëè ñàìîëåòà

-- Âàðèàíò ¹2 (ñì. íèæå) ðåøåíèÿ çàäà÷è ¹9
select departure_airport, a1.latitude as x, arrival_airport, a2.longitude as y, 
(acos(sin(radians(a1.latitude))*sin(radians(a2.latitude)) +cos(radians(a1.latitude))*
cos(radians(a2.latitude))*cos(radians(a1.longitude - a2.longitude)))*6371)::integer as "Ðàññòîÿíèå", range
from 
	(select distinct departure_airport, arrival_airport, aircraft_code 
	from flights) as foo
join airports a1 on foo.departure_airport = a1.airport_code
join airports a2 on foo.arrival_airport = a2.airport_code
join aircrafts on aircrafts.aircraft_code = foo.aircraft_code
order by arrival_airport
