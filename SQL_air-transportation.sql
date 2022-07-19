-- 1. В каких городах больше одного аэропорта?

select city as "Город", count(city) as "Кол-во аэропортов"
from airports a 
group by 1
having count(city) >1

-- Вариант №2 с выводом названий аэропортов в одной строке

select a.city as "Город", count(city) as "Кол-во аэропортов", group_concat(a.airport_name) as "Названия аэропортов"
from airports a
where city in ( -- условие отбора
	select city -- выбор города, где больше 2-х аэропортов
	from airports a2 
	group by 1
	having count(city) >1	
)
group by 1

-- 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
-- по условию задания необходимо использовать подзапрос

select a3.airport_name as "Аэропорт", a3.city as "Город", f.aircraft_code as "Модель самолета"
from flights f -- выбираем эту таблицу, т.к. в ней есть код модели самолета, по которой ниже идет выборка
join airports a3 on a3.airport_code = f.departure_airport -- присоединяем таблицу с нужными для вывода столбцами
where aircraft_code in ( 
	select aircraft_code -- вывод рейса с максимальной дальностью полета
	from aircrafts a
	where "range" = (
		select max("range") from aircrafts a2
		)
	)
group by 1,2,3

-- 3. Вывести 10 рейсов с максимальным временем задержки вылета
-- по условию задания необходимо использовать оператор LIMIT

select flight_id as "Рейс", actual_arrival - scheduled_departure as "Время задержки рейса" -- под рейсом подразумевается flight_id
from flights f 
where actual_arrival > scheduled_departure -- выбор рейсов с датой/временем вылета позже чем запланированные
order by 2 desc -- сортировка по убыванию
limit 10 -- ограничение вывода

-- 4. Были ли брони, по которым не были получены посадочные талоны?
-- по условию задания необходимо выбрать верный тип JOIN

select b.book_ref as "Номер брони без посадочного талона"
from bookings b 
join tickets t on b.book_ref = t.book_ref -- стыкуем таблицу "tickets" чтобы привязать таблицу "boarding_passes"
right join boarding_passes bp on t.ticket_no = bp.ticket_no -- из нее будем выводить столбец по брони
where bp.boarding_no is null -- условие выбора брони без посадочного талона
-- Запрос не возвращает данные, следовательно таких броней нет

-- 5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Условия задания:
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.
-- Оконная функция
-- Подзапросы или/и cte
-- РЕШЕНИЕ только по вылетевшим самолетам, т.к. суммарное накопление необходимо провести по ВЫВЕЗЕННЫМ пассажирам, т.е. и уже прибывшим и по тем, кто в полете

select f.flight_id as "id рейса", 
	f.aircraft_code as "Код самолета", 
	f.departure_airport as "Код аэропорта", 
	date(f.actual_departure) as "Дата вылета",
	(s.count_seats - bp.count_bp) as "Свободные места",
	round(((s.count_seats - bp.count_bp) * 100. / s.count_seats), 2) as "% от общего количества мест",
	sum(bp.count_bp) over (partition by date(f.actual_departure), f.departure_airport order by f.actual_departure) as "Накопительная",
	bp.count_bp as "Количество вылетевших пассажиров"
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

-- 6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.
-- Условия для выполнения задачи:
-- Подзапрос или окно
-- Оператор ROUND
-- Опять же в решении отталкивался от слова "ПЕРЕЛЕТОВ", т.е. которые либо еще длятся либо уже совершены

-- explain analyze (cost=2751.03..2755.03 rows=1600 width=44) (actual time=25.489..25.491 rows=8 loops=1))
select t.aircraft_code as "Модель самолета", t.count_by_aircraft_code as "Кол-во перелетов",
round(t.count_by_aircraft_code*100/sum (t.count_by_aircraft_code) over (),2)||'%' as "% перелетов от аэропарка" -- округляем до 2-х знаков. Знак '%' прибавил искусственно
from (
	select aircraft_code,
	count (aircraft_code) over (partition by aircraft_code) as count_by_aircraft_code -- кол-во самолетов вылетевших и прибывших
	from flights f
	where status = 'Departed' or status = 'Arrived') t
group by 1,2
order by 2

-- ВАРИАНТ №2 (см. ниже) более оптимизирован
-- explain analyze (cost=1018.34..1018.36 rows=9 width=80) (actual time=19.631..19.633 rows=8 loops=1)
select aircrafts.model as "Модель самолета", aircrafts.aircraft_code, 
round((count(flights.flight_id)::numeric)*100 / sum(count(flights.flight_id)) over (), 2) as "Доля перелетов"
from aircrafts
join flights on aircrafts.aircraft_code = flights.aircraft_code
group by aircrafts.aircraft_code
order by "Доля перелетов" desc;

-- 7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
-- Условия для выполнения задачи:
-- CTE
-- explain analyze (cost=76213.84..77457.24 rows=1 width=36) (actual time=451.859..451.989 rows=0 loops=1)
with CTE as ( -- заводим результат в СТЕ
select flight_id, min(min_business), max (max_economy) -- запрос для последующей группировки
from (
	select  distinct flight_id, -- разбил на два столбца с выбором min по бизнесс-классу и max по эконом-классу
	case when tf.fare_conditions = 'Business' then min(tf.amount) end min_business,
	case when tf.fare_conditions = 'Economy' then max(tf.amount) end max_economy
	from ticket_flights tf
	group by 1,tf.fare_conditions
	) t
group by 1
)
select *
from (
	select flight_id, -- весь наш труд выше выводим по условию, что min бизнец-цена меньше max эконом-цены
		case
			when min < max then 'Да'
			else 'Нет'
			end as "Халява"
	from CTE) x 
where "Халява" = 'Да' -- если бы условие было выполнено, то получим нужный номер перелета, а там уже можно и города цеплять. Результат пустой.
-- КОММЕНТАРИЙ:
-- Не нравиться сама структура запроса и ее производительность. 

-- ВАРИАНТ №2 (см. ниже) решения задачи №7
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

-- 8. Между какими городами нет прямых рейсов?
-- Условия для выполнения задачи:
-- Декартово произведение в предложении FROM
-- Самостоятельно созданные представления (если облачное подключение, то без представления)
-- Оператор EXCEPT

select a.city as "Город 1", a2.city as "Город 2"
	from airports a 
	cross join airports a2 -- декартово произведение по городам
	where a.city <> a2.city
except -- условие на вывод только тех пар городов, которых нет в нижнем наборе
select a.city, a3.city 
	from airports a 
	join routes r on a.city = r.departure_city -- к первому столбцу цепляем город потенциально отправления
	join airports a3 on r.arrival_city = a3.city -- к второму столбцу цепляем город потенциального прибытия	

-- Вариант №2 (см. ниже) решения задачи №8
create view route as 
	select distinct a.city as departure_city , b.city as arrival_city, a.city||'-'||b.city as route 
	from airports as a, (select city from airports) as b
	where a.city != b.city
	--where a.city > b.city если хотим убрать зеркальные варианты
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
		
-- 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы *
-- Условия для выполнения задачи:
-- Оператор RADIANS или использование sind/cosd
-- CASE 

select distinct -- убрал задвоение маршрутов (откуда они?.. разобраться потом)
	r.departure_airport_name ||' ('|| r.departure_airport ||')' as "Отправление из:", 
	r.arrival_airport_name ||' ('|| r.arrival_airport ||')' as "Прибытие в:",
	round((acos(sind(a.latitude) * sind(a2.latitude) + cosd(a.latitude) * cosd(a2.latitude) * cosd(a.longitude - a2.longitude)) * 6371)::int,0) ||' км' as "Расстояние м/у аэропортами",
	a3.aircraft_code ||', дальность '|| a3."range" ||' км' as "Хар-ки модели",
case 
	when a3."range" > round(acos(sind(a.latitude) * sind(a2.latitude) + cosd(a.latitude) * cosd(a2.latitude) * cosd(a.longitude - a2.longitude)) * 6371) then 'Да'
	else 'Нет'
	end as "Долетит:"
from routes r
join airports a on r.departure_airport = a.airport_code -- присоединил для получения координат
join airports a2 on r.arrival_airport = a2.airport_code -- присоединил для получения координат
join aircrafts a3 on r.aircraft_code = a3.aircraft_code -- для вывода модели самолета

-- Вариант №2 (см. ниже) решения задачи №9
select departure_airport, a1.latitude as x, arrival_airport, a2.longitude as y, 
(acos(sin(radians(a1.latitude))*sin(radians(a2.latitude)) +cos(radians(a1.latitude))*
cos(radians(a2.latitude))*cos(radians(a1.longitude - a2.longitude)))*6371)::integer as "Расстояние", range
from 
	(select distinct departure_airport, arrival_airport, aircraft_code 
	from flights) as foo
join airports a1 on foo.departure_airport = a1.airport_code
join airports a2 on foo.arrival_airport = a2.airport_code
join aircrafts on aircrafts.aircraft_code = foo.aircraft_code
order by arrival_airport
