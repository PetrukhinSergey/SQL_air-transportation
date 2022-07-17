<h2 align="center">Проектная работа по модулю “SQL и получение данных”!</a></h2>
Проектная работа проводилась на основе демонстрационной базы данных для СУБД PostgreSQL. В качестве предметной области выбраны авиаперевозки по России.
<div align="center"><img src="https://user-images.githubusercontent.com/108893866/179029883-79a402d1-1b1f-40c0-8ebf-50c54e4d1ce2.png" width="800" /></div>
В работе использовался DBeaver. Для наглядности базы данных ниже представлена ER-диаграмма:
<div align="center"><img src="https://user-images.githubusercontent.com/108893866/179030907-fa460ba0-2e71-43cc-ac81-45b8adea0f55.png" width="600" /></div>
<details> 
  <summary>:arrow_heading_down: Развернутый анализ БД - описание таблиц, логики, связей :eyes: </summary><br>
    
> **aircrafts**:  Каждая модель самолета идентифицируется своим трехзначным кодом (aircraft_code). Указывается также название модели (model) и максимальная дальность полета в километрах (range).  
➢ Индексы: PRIMARY KEY, btree (aircraft_code)  
➢ Ограничения-проверки: CHECK (range > 0)  
➢ Ссылки извне: TABLE "flights" FOREIGN KEY (aircraft_code) REFERENCES aircrafts (aircraft_code) TABLE "seats" FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE

> **airports**: Аэропорт идентифицируется трехбуквенным кодом (airport_code) и имеет свое имя (airport_name). Название города (city) указывается и может служить для того, чтобы определить аэропорты одного города. Также указывается широта (longitude), долгота (latitude) и часовой пояс (timezone).  
➢ Индексы: PRIMARY KEY, btree (airport_code)  
➢ Ссылки извне: TABLE "flights" FOREIGN KEY (arrival_airport) REFERENCES airports (airport_code) TABLE "flights" FOREIGN KEY (departure_airport) REFERENCES airports (airport_code)

> **boarding_passes**: При регистрации на рейс, которая возможна за сутки до плановой даты отправления, пассажиру выдается посадочный талон. Он идентифицируется также, как и перелет — номером билета и номером рейса. Посадочным талонам присваиваются последовательные номера (boarding_no) в порядке регистрации пассажиров на рейс (этот номер будет уникальным только в пределах данного рейса). В посадочном талоне указывается номер места (seat_no).  
➢ Индексы: PRIMARY KEY, btree (ticket_no, flight_id) UNIQUE CONSTRAINT, btree (flight_id, boarding_no) UNIQUE CONSTRAINT, btree (flight_id, seat_no)  
➢ Ограничения внешнего ключа: FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights (ticket_no, flight_id)  

> **bookings**: Пассажир заранее (book_date, максимум за месяц до рейса) бронирует билет себе и, возможно, нескольким другим пассажирам. Бронирование идентифицируется номером (book_ref, шестизначная комбинация букв и цифр). Поле total_amount хранит общую стоимость включенных в бронирование перелетов всех пассажиров.  
➢ Индексы: PRIMARY KEY, btree (book_ref)  
➢ Ссылки извне: TABLE "tickets" FOREIGN KEY (book_ref) REFERENCES bookings (book_ref)  

> **flights**: Естественный ключ таблицы рейсов состоит из двух полей — номера рейса (flight_no) и даты отправления (scheduled_departure). Чтобы сделать внешние ключи на эту таблицу компактнее, в качестве первичного используется суррогатный ключ (flight_id). Рейс всегда соединяет две точки — аэропорты вылета (departure_airport) и прибытия (arrival_airport). Такое понятие, как «рейс с пересадками» отсутствует: если из одного аэропорта до другого нет прямого рейса, в билет просто включаются несколько необходимых рейсов. У каждого рейса есть запланированные дата и время вылета (scheduled_departure) и прибытия (scheduled_arrival). Реальные время вылета (actual_departure) и прибытия (actual_arrival) могут отличаться: обычно не сильно, но иногда и на несколько часов, если рейс задержан.  
➢ Индексы: PRIMARY KEY, btree (flight_id) UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure)  
➢ Ограничения-проверки: CHECK (scheduled_arrival > scheduled_departure) CHECK ((actual_arrival IS NULL) OR ((actual_departure IS NOT NULL AND actual_arrival IS NOT NULL) AND (actual_arrival > actual_departure))) CHECK (status IN ('On Time', 'Delayed', 'Departed', 'Arrived', 'Scheduled', 'Cancelled'))  
➢ Ограничения внешнего ключа: FOREIGN KEY (aircraft_code) REFERENCES aircrafts (aircraft_code)  
FOREIGN KEY (arrival_airport) REFERENCES airports (airport_code) FOREIGN KEY (departure_airport)  
REFERENCES airports (airport_code)  
➢ Ссылки извне: TABLE "ticket_flights" FOREIGN KEY (flight_id) REFERENCES flights (flight_id)  

> **seats**: Места определяют схему салона каждой модели. Каждое место определяется своим номером (seat_no) и имеет закрепленный за ним класс обслуживания (fare_conditions) — Economy, Comfort или Business.  
➢ Индексы: PRIMARY KEY, btree (aircraft_code, seat_no)  
➢ Ограничения-проверки: CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))  
➢ Ограничения внешнего ключа: FOREIGN KEY (aircraft_code) REFERENCES aircrafts (aircraft_code) ON DELETE CASCADE  

> **ticket_flights**: Перелет соединяет билет с рейсом и идентифицируется их номерами. Для каждого перелета указываются его стоимость (amount) и класс обслуживания (fare_conditions).  
➢ Индексы: PRIMARY KEY, btree (ticket_no, flight_id)  
➢ Ограничения-проверки: CHECK (amount >= 0) CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))  
➢ Ограничения внешнего ключа: FOREIGN KEY (flight_id) REFERENCES flights (flight_id) FOREIGN KEY (ticket_no) REFERENCES tickets (ticket_no)  
➢ Ссылки извне: TABLE "boarding_passes" FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights (ticket_no, flight_id)  

> **tickets**: Билет имеет уникальный номер (ticket_no), состоящий из 13 цифр. Билет содержит идентификатор пассажира (passenger_id) — номер документа, удостоверяющего личность, — его фамилию и имя (passenger_name) и контактную информацию (contact_date).  
➢ Индексы: PRIMARY KEY, btree (ticket_no)  
➢ Ограничения внешнего ключа: FOREIGN KEY (book_ref) REFERENCES bookings (book_ref)  
➢ Ссылки извне: TABLE "ticket_flights" FOREIGN KEY (ticket_no) REFERENCES tickets (ticket_no)
</details>

<details>
  <summary>:arrow_heading_down:Список поставленных задач, которые необходимо было решить: :eyes:</summary>
  
* В каких городах больше одного аэропорта?  
* В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?  
* Вывести 10 рейсов с максимальным временем задержки вылета.  
* Были ли брони, по которым не были получены посадочные талоны?  
* Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.  
* Найдите процентное соотношение перелетов по типам самолетов от общего количества.  
* Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?  
* Между какими городами нет прямых рейсов?  
* Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы.

Помимо задач, указанных выше  в файле запросов, база данных позволяет отследить по направлениям пассажиропоток и используемые модели самолетов. Это позволит определить, следует ли добавить количество рейсов (или использовать более вместительные самолеты) при постоянно полной нагрузке по направлению.  
И наоборот, если количество пассажиров минимально и самолеты летают полупустые, то целесообразно заменить на подходящую модель самолета (опять же учитывая дальность перелета) или сделать рейсы реже.  
Данные по городам, между которыми нет прямых рейсов, гипотетически предполагает развитие новых направлений перелетов, а список рейсов с задержкой вылета требует изучения причин данного обстоятельства и как это может быть использовано для бизнеса.  
Также, как вариант, посчитать количество рейсов прибывающих в один аэропорт за определенный промежуток времени. Это уже больше к теоретической части вместительности того или иного аэропорта.
</details>

#### Cсылка на файл .sql со структурой запросов по поставленным задачам

<div align="left"><img src="https://user-images.githubusercontent.com/108893866/179385582-25cdd117-2530-42e3-b7dc-1edd323f3e68.png" width="130" /></div> https://github.com/PetrukhinSergey/SQL_air-transportation_demo/blob/main/SQL_air-transportation_demo.sql

