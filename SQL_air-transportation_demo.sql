-- 1. � ����� ������� ������ ������ ���������?

select city as "�����", count(city) as "���-�� ����������"
from airports a 
group by 1
having count(city) >1

-- ������� �2 � ������� �������� ���������� � ����� ������

select a.city as "�����", count(city) as "���-�� ����������", group_concat(a.airport_name) as "�������� ����������"
from airports a
where city in ( -- ������� ������
	select city -- ����� ������, ��� ������ 2-� ����������
	from airports a2 
	group by 1
	having count(city) >1	
)
group by 1

-- 2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?
-- �� ������� ������� ���������� ������������ ���������

select a3.airport_name as "��������", a3.city as "�����", f.aircraft_code as "������ ��������"
from flights f -- �������� ��� �������, �.�. � ��� ���� ��� ������ ��������, �� ������� ���� ���� �������
join airports a3 on a3.airport_code = f.departure_airport -- ������������ ������� � ������� ��� ������ ���������
where aircraft_code in ( 
	select aircraft_code -- ����� ����� � ������������ ���������� ������
	from aircrafts a
	where "range" = (
		select max("range") from aircrafts a2
		)
	)
group by 1,2,3

-- 3. ������� 10 ������ � ������������ �������� �������� ������
-- �� ������� ������� ���������� ������������ �������� LIMIT

select flight_id as "����", actual_arrival - scheduled_departure as "����� �������� �����" -- ��� ������ ��������������� flight_id
from flights f 
where actual_arrival > scheduled_departure -- ����� ������ � �����/�������� ������ ����� ��� ���������������
order by 2 desc -- ���������� �� ��������
limit 10 -- ����������� ������

-- 4. ���� �� �����, �� ������� �� ���� �������� ���������� ������?
-- �� ������� ������� ���������� ������� ������ ��� JOIN

select b.book_ref as "����� ����� ��� ����������� ������"
from bookings b 
join tickets t on b.book_ref = t.book_ref -- ������� ������� "tickets" ����� ��������� ������� "boarding_passes"
right join boarding_passes bp on t.ticket_no = bp.ticket_no -- �� ��� ����� �������� ������� �� �����
where bp.boarding_no is null -- ������� ������ ����� ��� ����������� ������
-- ������ �� ���������� ������, ������������� ����� ������ ���

-- 5. ������� ���������� ��������� ���� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
-- ������� �������:
-- �������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ � ������� ���.
-- ������� �������
-- ���������� ���/� cte
-- ������� ������ �� ���������� ���������, �.�. ��������� ���������� ���������� �������� �� ���������� ����������, �.�. � ��� ��������� � �� ���, ��� � ������

select f.flight_id as "id �����", 
	f.aircraft_code as "��� ��������", 
	f.departure_airport as "��� ���������", 
	date(f.actual_departure) as "���� ������",
	(s.count_seats - bp.count_bp) as "��������� �����",
	round(((s.count_seats - bp.count_bp) * 100. / s.count_seats), 2) as "% �� ������ ���������� ����",
	sum(bp.count_bp) over (partition by date(f.actual_departure), f.departure_airport order by f.actual_departure) as "�������������",
	bp.count_bp as "���������� ���������� ����������"
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

-- 6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
-- ������� ��� ���������� ������:
-- ��������� ��� ����
-- �������� ROUND
-- ����� �� � ������� ������������ �� ����� "���������", �.�. ������� ���� ��� ������ ���� ��� ���������

-- explain analyze (cost=2751.03..2755.03 rows=1600 width=44) (actual time=25.489..25.491 rows=8 loops=1))
select t.aircraft_code as "������ ��������", t.count_by_aircraft_code as "���-�� ���������",
round(t.count_by_aircraft_code*100/sum (t.count_by_aircraft_code) over (),2)||'%' as "% ��������� �� ���������" -- ��������� �� 2-� ������. ���� '%' �������� ������������
from (
	select aircraft_code,
	count (aircraft_code) over (partition by aircraft_code) as count_by_aircraft_code -- ���-�� ��������� ���������� � ���������
	from flights f
	where status = 'Departed' or status = 'Arrived') t
group by 1,2
order by 2

-- ������� �2 (��. ����) ����� �������������
-- explain analyze (cost=1018.34..1018.36 rows=9 width=80) (actual time=19.631..19.633 rows=8 loops=1)
select aircrafts.model as "������ ��������", aircrafts.aircraft_code, 
round((count(flights.flight_id)::numeric)*100 / sum(count(flights.flight_id)) over (), 2) as "���� ���������"
from aircrafts
join flights on aircrafts.aircraft_code = flights.aircraft_code
group by aircrafts.aircraft_code
order by "���� ���������" desc;

-- 7. ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?
-- ������� ��� ���������� ������:
-- CTE
-- explain analyze (cost=76213.84..77457.24 rows=1 width=36) (actual time=451.859..451.989 rows=0 loops=1)
with CTE as ( -- ������� ��������� � ���
select flight_id, min(min_business), max (max_economy) -- ������ ��� ����������� �����������
from (
	select  distinct flight_id, -- ������ �� ��� ������� � ������� min �� �������-������ � max �� ������-������
	case when tf.fare_conditions = 'Business' then min(tf.amount) end min_business,
	case when tf.fare_conditions = 'Economy' then max(tf.amount) end max_economy
	from ticket_flights tf
	group by 1,tf.fare_conditions
	) t
group by 1
)
select *
from (
	select flight_id, -- ���� ��� ���� ���� ������� �� �������, ��� min ������-���� ������ max ������-����
		case
			when min < max then '��'
			else '���'
			end as "������"
	from CTE) x 
where "������" = '��' -- ���� �� ������� ���� ���������, �� ������� ������ ����� ��������, � ��� ��� ����� � ������ �������. ��������� ������.
-- �����������:
-- �� ��������� ���� ��������� ������� � �� ������������������. 

-- ������� �2 (��. ����) ������� ������ �7
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

-- 8. ����� ������ �������� ��� ������ ������?
-- ������� ��� ���������� ������:
-- ��������� ������������ � ����������� FROM
-- �������������� ��������� ������������� (���� �������� �����������, �� ��� �������������)
-- �������� EXCEPT

select a.city as "����� 1", a2.city as "����� 2"
	from airports a 
	cross join airports a2 -- ��������� ������������ �� �������
	where a.city <> a2.city
except -- ������� �� ����� ������ ��� ��� �������, ������� ��� � ������ ������
select a.city, a3.city 
	from airports a 
	join routes r on a.city = r.departure_city -- � ������� ������� ������� ����� ������������ �����������
	join airports a3 on r.arrival_city = a3.city -- � ������� ������� ������� ����� �������������� ��������	

-- ������� �2 (��. ����) ������� ������ �8
create view route as 
	select distinct a.city as departure_city , b.city as arrival_city, a.city||'-'||b.city as route 
	from airports as a, (select city from airports) as b
	where a.city != b.city
	--where a.city > b.city ���� ����� ������ ���������� ��������
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
		
-- 9. ��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� ����� *
-- ������� ��� ���������� ������:
-- �������� RADIANS ��� ������������� sind/cosd
-- CASE 

select distinct -- ����� ��������� ��������� (������ ���?.. ����������� �����)
	r.departure_airport_name ||' ('|| r.departure_airport ||')' as "����������� ��:", 
	r.arrival_airport_name ||' ('|| r.arrival_airport ||')' as "�������� �:",
	round((acos(sind(a.latitude) * sind(a2.latitude) + cosd(a.latitude) * cosd(a2.latitude) * cosd(a.longitude - a2.longitude)) * 6371)::int,0) ||' ��' as "���������� �/� �����������",
	a3.aircraft_code ||', ��������� '|| a3."range" ||' ��' as "���-�� ������",
case 
	when a3."range" > round(acos(sind(a.latitude) * sind(a2.latitude) + cosd(a.latitude) * cosd(a2.latitude) * cosd(a.longitude - a2.longitude)) * 6371) then '��'
	else '���'
	end as "�������:"
from routes r
join airports a on r.departure_airport = a.airport_code -- ����������� ��� ��������� ���������
join airports a2 on r.arrival_airport = a2.airport_code -- ����������� ��� ��������� ���������
join aircrafts a3 on r.aircraft_code = a3.aircraft_code -- ��� ������ ������ ��������

-- ������� �2 (��. ����) ������� ������ �9
select departure_airport, a1.latitude as x, arrival_airport, a2.longitude as y, 
(acos(sin(radians(a1.latitude))*sin(radians(a2.latitude)) +cos(radians(a1.latitude))*
cos(radians(a2.latitude))*cos(radians(a1.longitude - a2.longitude)))*6371)::integer as "����������", range
from 
	(select distinct departure_airport, arrival_airport, aircraft_code 
	from flights) as foo
join airports a1 on foo.departure_airport = a1.airport_code
join airports a2 on foo.arrival_airport = a2.airport_code
join aircrafts on aircrafts.aircraft_code = foo.aircraft_code
order by arrival_airport
