PGDMP             	    
    	    u           dh    10.0    10.0 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                       false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                       false            �           1262    16384    dh    DATABASE     r   CREATE DATABASE dh WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8';
    DROP DATABASE dh;
             postgres    false                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
             postgres    false            �           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'Standard public schema';
                  postgres    false    3                        3079    12980    plpgsql 	   EXTENSION     ?   CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
    DROP EXTENSION plpgsql;
                  false            �           0    0    EXTENSION plpgsql    COMMENT     @   COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
                       false    1            .           1247    16393    mpaa_rating    TYPE     Z   CREATE TYPE mpaa_rating AS ENUM (
    'G',
    'PG',
    'PG-13',
    'R',
    'NC-17'
);
    DROP TYPE public.mpaa_rating;
       public       postgres    false    3            �           1247    16403    year    DOMAIN     d   CREATE DOMAIN year AS integer
	CONSTRAINT year_check CHECK (((VALUE >= 1901) AND (VALUE <= 2155)));
    DROP DOMAIN public.year;
       public       postgres    false    3            �            1255    16405    _group_concat(text, text)    FUNCTION     �   CREATE FUNCTION _group_concat(text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT CASE
  WHEN $2 IS NULL THEN $1
  WHEN $1 IS NULL THEN $2
  ELSE $1 || ', ' || $2
END
$_$;
 0   DROP FUNCTION public._group_concat(text, text);
       public       postgres    false    3            �            1255    16576    film_in_stock(integer, integer)    FUNCTION       CREATE FUNCTION film_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
     SELECT inventory_id
     FROM inventory
     WHERE film_id = $1
     AND store_id = $2
     AND inventory_in_stock(inventory_id);
$_$;
 e   DROP FUNCTION public.film_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer);
       public       postgres    false    3            �            1255    16577 #   film_not_in_stock(integer, integer)    FUNCTION        CREATE FUNCTION film_not_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
    SELECT inventory_id
    FROM inventory
    WHERE film_id = $1
    AND store_id = $2
    AND NOT inventory_in_stock(inventory_id);
$_$;
 i   DROP FUNCTION public.film_not_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer);
       public       postgres    false    3            �            1255    16578 :   get_customer_balance(integer, timestamp without time zone)    FUNCTION        CREATE FUNCTION get_customer_balance(p_customer_id integer, p_effective_date timestamp without time zone) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
       --#OK, WE NEED TO CALCULATE THE CURRENT BALANCE GIVEN A CUSTOMER_ID AND A DATE
       --#THAT WE WANT THE BALANCE TO BE EFFECTIVE FOR. THE BALANCE IS:
       --#   1) RENTAL FEES FOR ALL PREVIOUS RENTALS
       --#   2) ONE DOLLAR FOR EVERY DAY THE PREVIOUS RENTALS ARE OVERDUE
       --#   3) IF A FILM IS MORE THAN RENTAL_DURATION * 2 OVERDUE, CHARGE THE REPLACEMENT_COST
       --#   4) SUBTRACT ALL PAYMENTS MADE BEFORE THE DATE SPECIFIED
DECLARE
    v_rentfees DECIMAL(5,2); --#FEES PAID TO RENT THE VIDEOS INITIALLY
    v_overfees INTEGER;      --#LATE FEES FOR PRIOR RENTALS
    v_payments DECIMAL(5,2); --#SUM OF PAYMENTS MADE PREVIOUSLY
BEGIN
    SELECT COALESCE(SUM(film.rental_rate),0) INTO v_rentfees
    FROM film, inventory, rental
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(IF((rental.return_date - rental.rental_date) > (film.rental_duration * '1 day'::interval),
        ((rental.return_date - rental.rental_date) - (film.rental_duration * '1 day'::interval)),0)),0) INTO v_overfees
    FROM rental, inventory, film
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(payment.amount),0) INTO v_payments
    FROM payment
    WHERE payment.payment_date <= p_effective_date
    AND payment.customer_id = p_customer_id;

    RETURN v_rentfees + v_overfees - v_payments;
END
$$;
 p   DROP FUNCTION public.get_customer_balance(p_customer_id integer, p_effective_date timestamp without time zone);
       public       postgres    false    1    3            �            1255    16579 #   inventory_held_by_customer(integer)    FUNCTION     4  CREATE FUNCTION inventory_held_by_customer(p_inventory_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_customer_id INTEGER;
BEGIN

  SELECT customer_id INTO v_customer_id
  FROM rental
  WHERE return_date IS NULL
  AND inventory_id = p_inventory_id;

  RETURN v_customer_id;
END $$;
 I   DROP FUNCTION public.inventory_held_by_customer(p_inventory_id integer);
       public       postgres    false    1    3            �            1255    16580    inventory_in_stock(integer)    FUNCTION     �  CREATE FUNCTION inventory_in_stock(p_inventory_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rentals INTEGER;
    v_out     INTEGER;
BEGIN
    -- AN ITEM IS IN-STOCK IF THERE ARE EITHER NO ROWS IN THE rental TABLE
    -- FOR THE ITEM OR ALL ROWS HAVE return_date POPULATED

    SELECT count(*) INTO v_rentals
    FROM rental
    WHERE inventory_id = p_inventory_id;

    IF v_rentals = 0 THEN
      RETURN TRUE;
    END IF;

    SELECT COUNT(rental_id) INTO v_out
    FROM inventory LEFT JOIN rental USING(inventory_id)
    WHERE inventory.inventory_id = p_inventory_id
    AND rental.return_date IS NULL;

    IF v_out > 0 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
END $$;
 A   DROP FUNCTION public.inventory_in_stock(p_inventory_id integer);
       public       postgres    false    3    1            �            1255    16581 %   last_day(timestamp without time zone)    FUNCTION     �  CREATE FUNCTION last_day(timestamp without time zone) RETURNS date
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT CASE
    WHEN EXTRACT(MONTH FROM $1) = 12 THEN
      (((EXTRACT(YEAR FROM $1) + 1) operator(pg_catalog.||) '-01-01')::date - INTERVAL '1 day')::date
    ELSE
      ((EXTRACT(YEAR FROM $1) operator(pg_catalog.||) '-' operator(pg_catalog.||) (EXTRACT(MONTH FROM $1) + 1) operator(pg_catalog.||) '-01')::date - INTERVAL '1 day')::date
    END
$_$;
 <   DROP FUNCTION public.last_day(timestamp without time zone);
       public       postgres    false    3            �            1255    16582    last_updated()    FUNCTION     �   CREATE FUNCTION last_updated() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_update = CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;
 %   DROP FUNCTION public.last_updated();
       public       postgres    false    1    3            �            1259    16462    customer_customer_id_seq    SEQUENCE     z   CREATE SEQUENCE customer_customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.customer_customer_id_seq;
       public       postgres    false    3            �            1259    16464    customer    TABLE     �  CREATE TABLE customer (
    customer_id integer DEFAULT nextval('customer_customer_id_seq'::regclass) NOT NULL,
    store_id smallint NOT NULL,
    first_name character varying(45) NOT NULL,
    last_name character varying(45) NOT NULL,
    email character varying(50),
    address_id smallint NOT NULL,
    activebool boolean DEFAULT true NOT NULL,
    create_date date DEFAULT ('now'::text)::date NOT NULL,
    last_update timestamp without time zone DEFAULT now(),
    active integer
);
    DROP TABLE public.customer;
       public         postgres    false    211    3            �            1255    16583     rewards_report(integer, numeric)    FUNCTION     &  CREATE FUNCTION rewards_report(min_monthly_purchases integer, min_dollar_amount_purchased numeric) RETURNS SETOF customer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    last_month_start DATE;
    last_month_end DATE;
rr RECORD;
tmpSQL TEXT;
BEGIN

    /* Some sanity checks... */
    IF min_monthly_purchases = 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases parameter must be > 0';
    END IF;
    IF min_dollar_amount_purchased = 0.00 THEN
        RAISE EXCEPTION 'Minimum monthly dollar amount purchased parameter must be > $0.00';
    END IF;

    last_month_start := CURRENT_DATE - '3 month'::interval;
    last_month_start := to_date((extract(YEAR FROM last_month_start) || '-' || extract(MONTH FROM last_month_start) || '-01'),'YYYY-MM-DD');
    last_month_end := LAST_DAY(last_month_start);

    /*
    Create a temporary storage area for Customer IDs.
    */
    CREATE TEMPORARY TABLE tmpCustomer (customer_id INTEGER NOT NULL PRIMARY KEY);

    /*
    Find all customers meeting the monthly purchase requirements
    */

    tmpSQL := 'INSERT INTO tmpCustomer (customer_id)
        SELECT p.customer_id
        FROM payment AS p
        WHERE DATE(p.payment_date) BETWEEN '||quote_literal(last_month_start) ||' AND '|| quote_literal(last_month_end) || '
        GROUP BY customer_id
        HAVING SUM(p.amount) > '|| min_dollar_amount_purchased || '
        AND COUNT(customer_id) > ' ||min_monthly_purchases ;

    EXECUTE tmpSQL;

    /*
    Output ALL customer information of matching rewardees.
    Customize output as needed.
    */
    FOR rr IN EXECUTE 'SELECT c.* FROM tmpCustomer AS t INNER JOIN customer AS c ON t.customer_id = c.customer_id' LOOP
        RETURN NEXT rr;
    END LOOP;

    /* Clean up */
    tmpSQL := 'DROP TABLE tmpCustomer';
    EXECUTE tmpSQL;

RETURN;
END
$_$;
 i   DROP FUNCTION public.rewards_report(min_monthly_purchases integer, min_dollar_amount_purchased numeric);
       public       postgres    false    1    212    3            �           1255    16406    group_concat(text) 	   AGGREGATE     U   CREATE AGGREGATE group_concat(text) (
    SFUNC = _group_concat,
    STYPE = text
);
 *   DROP AGGREGATE public.group_concat(text);
       public       postgres    false    3    245            �            1259    16385    actor_actor_id_seq    SEQUENCE     t   CREATE SEQUENCE actor_actor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.actor_actor_id_seq;
       public       postgres    false    3            �            1259    16387    actor    TABLE       CREATE TABLE actor (
    actor_id integer DEFAULT nextval('actor_actor_id_seq'::regclass) NOT NULL,
    first_name character varying(45) NOT NULL,
    last_name character varying(45) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.actor;
       public         postgres    false    196    3            �            1259    16407    category_category_id_seq    SEQUENCE     z   CREATE SEQUENCE category_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.category_category_id_seq;
       public       postgres    false    3            �            1259    16409    category    TABLE     �   CREATE TABLE category (
    category_id integer DEFAULT nextval('category_category_id_seq'::regclass) NOT NULL,
    name character varying(25) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.category;
       public         postgres    false    198    3            �            1259    16414    film_film_id_seq    SEQUENCE     r   CREATE SEQUENCE film_film_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.film_film_id_seq;
       public       postgres    false    3            �            1259    16416    film    TABLE     f  CREATE TABLE film (
    film_id integer DEFAULT nextval('film_film_id_seq'::regclass) NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    release_year year,
    language_id smallint NOT NULL,
    original_language_id smallint,
    rental_duration smallint DEFAULT 3 NOT NULL,
    rental_rate numeric(4,2) DEFAULT 4.99 NOT NULL,
    length smallint,
    replacement_cost numeric(5,2) DEFAULT 19.99 NOT NULL,
    rating mpaa_rating DEFAULT 'G'::mpaa_rating,
    last_update timestamp without time zone DEFAULT now() NOT NULL,
    special_features text[],
    fulltext tsvector NOT NULL
);
    DROP TABLE public.film;
       public         postgres    false    200    558    558    640    3            �            1259    16428 
   film_actor    TABLE     �   CREATE TABLE film_actor (
    actor_id smallint NOT NULL,
    film_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.film_actor;
       public         postgres    false    3            �            1259    16432    film_category    TABLE     �   CREATE TABLE film_category (
    film_id smallint NOT NULL,
    category_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);
 !   DROP TABLE public.film_category;
       public         postgres    false    3            �            1259    16436 
   actor_info    VIEW     �  CREATE VIEW actor_info AS
 SELECT a.actor_id,
    a.first_name,
    a.last_name,
    group_concat(DISTINCT (((c.name)::text || ': '::text) || ( SELECT group_concat((f.title)::text) AS group_concat
           FROM ((film f
             JOIN film_category fc_1 ON ((f.film_id = fc_1.film_id)))
             JOIN film_actor fa_1 ON ((f.film_id = fa_1.film_id)))
          WHERE ((fc_1.category_id = c.category_id) AND (fa_1.actor_id = a.actor_id))
          GROUP BY fa_1.actor_id))) AS film_info
   FROM (((actor a
     LEFT JOIN film_actor fa ON ((a.actor_id = fa.actor_id)))
     LEFT JOIN film_category fc ON ((fa.film_id = fc.film_id)))
     LEFT JOIN category c ON ((fc.category_id = c.category_id)))
  GROUP BY a.actor_id, a.first_name, a.last_name;
    DROP VIEW public.actor_info;
       public       postgres    false    738    197    197    197    199    199    201    201    202    202    203    203    3            �            1259    16441    address_address_id_seq    SEQUENCE     x   CREATE SEQUENCE address_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.address_address_id_seq;
       public       postgres    false    3            �            1259    16443    address    TABLE     �  CREATE TABLE address (
    address_id integer DEFAULT nextval('address_address_id_seq'::regclass) NOT NULL,
    address character varying(50) NOT NULL,
    address2 character varying(50),
    district character varying(20) NOT NULL,
    city_id smallint NOT NULL,
    postal_code character varying(10),
    phone character varying(20) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.address;
       public         postgres    false    205    3            �            1259    16448    city_city_id_seq    SEQUENCE     r   CREATE SEQUENCE city_city_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.city_city_id_seq;
       public       postgres    false    3            �            1259    16450    city    TABLE     �   CREATE TABLE city (
    city_id integer DEFAULT nextval('city_city_id_seq'::regclass) NOT NULL,
    city character varying(50) NOT NULL,
    country_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.city;
       public         postgres    false    207    3            �            1259    16455    country_country_id_seq    SEQUENCE     x   CREATE SEQUENCE country_country_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.country_country_id_seq;
       public       postgres    false    3            �            1259    16457    country    TABLE     �   CREATE TABLE country (
    country_id integer DEFAULT nextval('country_country_id_seq'::regclass) NOT NULL,
    country character varying(50) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.country;
       public         postgres    false    209    3            �            1259    16471    customer_list    VIEW     /  CREATE VIEW customer_list AS
 SELECT cu.customer_id AS id,
    (((cu.first_name)::text || ' '::text) || (cu.last_name)::text) AS name,
    a.address,
    a.postal_code AS "zip code",
    a.phone,
    city.city,
    country.country,
        CASE
            WHEN cu.activebool THEN 'active'::text
            ELSE ''::text
        END AS notes,
    cu.store_id AS sid
   FROM (((customer cu
     JOIN address a ON ((cu.address_id = a.address_id)))
     JOIN city ON ((a.city_id = city.city_id)))
     JOIN country ON ((city.country_id = country.country_id)));
     DROP VIEW public.customer_list;
       public       postgres    false    212    212    212    212    212    212    210    210    208    208    208    206    206    206    206    206    3            �            1259    16476 	   film_list    VIEW     �  CREATE VIEW film_list AS
 SELECT film.film_id AS fid,
    film.title,
    film.description,
    category.name AS category,
    film.rental_rate AS price,
    film.length,
    film.rating,
    group_concat((((actor.first_name)::text || ' '::text) || (actor.last_name)::text)) AS actors
   FROM ((((category
     LEFT JOIN film_category ON ((category.category_id = film_category.category_id)))
     LEFT JOIN film ON ((film_category.film_id = film.film_id)))
     JOIN film_actor ON ((film.film_id = film_actor.film_id)))
     JOIN actor ON ((film_actor.actor_id = actor.actor_id)))
  GROUP BY film.film_id, film.title, film.description, category.name, film.rental_rate, film.length, film.rating;
    DROP VIEW public.film_list;
       public       postgres    false    203    203    202    202    201    201    201    201    201    201    199    199    197    197    197    738    558    3            �            1259    16481    inventory_inventory_id_seq    SEQUENCE     |   CREATE SEQUENCE inventory_inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.inventory_inventory_id_seq;
       public       postgres    false    3            �            1259    16483 	   inventory    TABLE     �   CREATE TABLE inventory (
    inventory_id integer DEFAULT nextval('inventory_inventory_id_seq'::regclass) NOT NULL,
    film_id smallint NOT NULL,
    store_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.inventory;
       public         postgres    false    215    3            �            1259    16488    language_language_id_seq    SEQUENCE     z   CREATE SEQUENCE language_language_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.language_language_id_seq;
       public       postgres    false    3            �            1259    16490    language    TABLE     �   CREATE TABLE language (
    language_id integer DEFAULT nextval('language_language_id_seq'::regclass) NOT NULL,
    name character(20) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.language;
       public         postgres    false    217    3            �            1259    16495    nicer_but_slower_film_list    VIEW     V  CREATE VIEW nicer_but_slower_film_list AS
 SELECT film.film_id AS fid,
    film.title,
    film.description,
    category.name AS category,
    film.rental_rate AS price,
    film.length,
    film.rating,
    group_concat((((upper("substring"((actor.first_name)::text, 1, 1)) || lower("substring"((actor.first_name)::text, 2))) || upper("substring"((actor.last_name)::text, 1, 1))) || lower("substring"((actor.last_name)::text, 2)))) AS actors
   FROM ((((category
     LEFT JOIN film_category ON ((category.category_id = film_category.category_id)))
     LEFT JOIN film ON ((film_category.film_id = film.film_id)))
     JOIN film_actor ON ((film.film_id = film_actor.film_id)))
     JOIN actor ON ((film_actor.actor_id = actor.actor_id)))
  GROUP BY film.film_id, film.title, film.description, category.name, film.rental_rate, film.length, film.rating;
 -   DROP VIEW public.nicer_but_slower_film_list;
       public       postgres    false    738    197    197    197    199    199    201    201    201    201    201    201    202    202    203    203    558    3            �            1259    16500    payment_payment_id_seq    SEQUENCE     x   CREATE SEQUENCE payment_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.payment_payment_id_seq;
       public       postgres    false    3            �            1259    16502    payment    TABLE     *  CREATE TABLE payment (
    payment_id integer DEFAULT nextval('payment_payment_id_seq'::regclass) NOT NULL,
    customer_id smallint NOT NULL,
    staff_id smallint NOT NULL,
    rental_id integer NOT NULL,
    amount numeric(5,2) NOT NULL,
    payment_date timestamp without time zone NOT NULL
);
    DROP TABLE public.payment;
       public         postgres    false    220    3            �            1259    16506    payment_p2007_01    TABLE        CREATE TABLE payment_p2007_01 (
    CONSTRAINT payment_p2007_01_payment_date_check CHECK (((payment_date >= '2007-01-01 00:00:00'::timestamp without time zone) AND (payment_date < '2007-02-01 00:00:00'::timestamp without time zone)))
)
INHERITS (payment);
 $   DROP TABLE public.payment_p2007_01;
       public         postgres    false    3    221            �            1259    16511    payment_p2007_02    TABLE        CREATE TABLE payment_p2007_02 (
    CONSTRAINT payment_p2007_02_payment_date_check CHECK (((payment_date >= '2007-02-01 00:00:00'::timestamp without time zone) AND (payment_date < '2007-03-01 00:00:00'::timestamp without time zone)))
)
INHERITS (payment);
 $   DROP TABLE public.payment_p2007_02;
       public         postgres    false    3    221            �            1259    16516    payment_p2007_03    TABLE        CREATE TABLE payment_p2007_03 (
    CONSTRAINT payment_p2007_03_payment_date_check CHECK (((payment_date >= '2007-03-01 00:00:00'::timestamp without time zone) AND (payment_date < '2007-04-01 00:00:00'::timestamp without time zone)))
)
INHERITS (payment);
 $   DROP TABLE public.payment_p2007_03;
       public         postgres    false    3    221            �            1259    16521    payment_p2007_04    TABLE        CREATE TABLE payment_p2007_04 (
    CONSTRAINT payment_p2007_04_payment_date_check CHECK (((payment_date >= '2007-04-01 00:00:00'::timestamp without time zone) AND (payment_date < '2007-05-01 00:00:00'::timestamp without time zone)))
)
INHERITS (payment);
 $   DROP TABLE public.payment_p2007_04;
       public         postgres    false    3    221            �            1259    16526    payment_p2007_05    TABLE        CREATE TABLE payment_p2007_05 (
    CONSTRAINT payment_p2007_05_payment_date_check CHECK (((payment_date >= '2007-05-01 00:00:00'::timestamp without time zone) AND (payment_date < '2007-06-01 00:00:00'::timestamp without time zone)))
)
INHERITS (payment);
 $   DROP TABLE public.payment_p2007_05;
       public         postgres    false    3    221            �            1259    16531    payment_p2007_06    TABLE        CREATE TABLE payment_p2007_06 (
    CONSTRAINT payment_p2007_06_payment_date_check CHECK (((payment_date >= '2007-06-01 00:00:00'::timestamp without time zone) AND (payment_date < '2007-07-01 00:00:00'::timestamp without time zone)))
)
INHERITS (payment);
 $   DROP TABLE public.payment_p2007_06;
       public         postgres    false    221    3            �            1259    16536    rental_rental_id_seq    SEQUENCE     v   CREATE SEQUENCE rental_rental_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.rental_rental_id_seq;
       public       postgres    false    3            �            1259    16538    rental    TABLE     w  CREATE TABLE rental (
    rental_id integer DEFAULT nextval('rental_rental_id_seq'::regclass) NOT NULL,
    rental_date timestamp without time zone NOT NULL,
    inventory_id integer NOT NULL,
    customer_id smallint NOT NULL,
    return_date timestamp without time zone,
    staff_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.rental;
       public         postgres    false    228    3            �            1259    16543    sales_by_film_category    VIEW     �  CREATE VIEW sales_by_film_category AS
 SELECT c.name AS category,
    sum(p.amount) AS total_sales
   FROM (((((payment p
     JOIN rental r ON ((p.rental_id = r.rental_id)))
     JOIN inventory i ON ((r.inventory_id = i.inventory_id)))
     JOIN film f ON ((i.film_id = f.film_id)))
     JOIN film_category fc ON ((f.film_id = fc.film_id)))
     JOIN category c ON ((fc.category_id = c.category_id)))
  GROUP BY c.name
  ORDER BY (sum(p.amount)) DESC;
 )   DROP VIEW public.sales_by_film_category;
       public       postgres    false    229    229    221    221    216    216    203    203    201    199    199    3            �            1259    16548    staff_staff_id_seq    SEQUENCE     t   CREATE SEQUENCE staff_staff_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.staff_staff_id_seq;
       public       postgres    false    3            �            1259    16550    staff    TABLE     �  CREATE TABLE staff (
    staff_id integer DEFAULT nextval('staff_staff_id_seq'::regclass) NOT NULL,
    first_name character varying(45) NOT NULL,
    last_name character varying(45) NOT NULL,
    address_id smallint NOT NULL,
    email character varying(50),
    store_id smallint NOT NULL,
    active boolean DEFAULT true NOT NULL,
    username character varying(16) NOT NULL,
    password character varying(40),
    last_update timestamp without time zone DEFAULT now() NOT NULL,
    picture bytea
);
    DROP TABLE public.staff;
       public         postgres    false    231    3            �            1259    16559    store_store_id_seq    SEQUENCE     t   CREATE SEQUENCE store_store_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.store_store_id_seq;
       public       postgres    false    3            �            1259    16561    store    TABLE     �   CREATE TABLE store (
    store_id integer DEFAULT nextval('store_store_id_seq'::regclass) NOT NULL,
    manager_staff_id smallint NOT NULL,
    address_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.store;
       public         postgres    false    233    3            �            1259    16566    sales_by_store    VIEW     �  CREATE VIEW sales_by_store AS
 SELECT (((c.city)::text || ','::text) || (cy.country)::text) AS store,
    (((m.first_name)::text || ' '::text) || (m.last_name)::text) AS manager,
    sum(p.amount) AS total_sales
   FROM (((((((payment p
     JOIN rental r ON ((p.rental_id = r.rental_id)))
     JOIN inventory i ON ((r.inventory_id = i.inventory_id)))
     JOIN store s ON ((i.store_id = s.store_id)))
     JOIN address a ON ((s.address_id = a.address_id)))
     JOIN city c ON ((a.city_id = c.city_id)))
     JOIN country cy ON ((c.country_id = cy.country_id)))
     JOIN staff m ON ((s.manager_staff_id = m.staff_id)))
  GROUP BY cy.country, c.city, s.store_id, m.first_name, m.last_name
  ORDER BY cy.country, c.city;
 !   DROP VIEW public.sales_by_store;
       public       postgres    false    232    221    221    229    229    232    216    216    210    210    208    208    208    206    206    234    234    234    232    3            �            1259    16571 
   staff_list    VIEW     �  CREATE VIEW staff_list AS
 SELECT s.staff_id AS id,
    (((s.first_name)::text || ' '::text) || (s.last_name)::text) AS name,
    a.address,
    a.postal_code AS "zip code",
    a.phone,
    city.city,
    country.country,
    s.store_id AS sid
   FROM (((staff s
     JOIN address a ON ((s.address_id = a.address_id)))
     JOIN city ON ((a.city_id = city.city_id)))
     JOIN country ON ((city.country_id = country.country_id)));
    DROP VIEW public.staff_list;
       public       postgres    false    206    206    206    206    206    232    232    232    232    210    210    208    208    232    208    3            U           2604    16509    payment_p2007_01 payment_id    DEFAULT     s   ALTER TABLE ONLY payment_p2007_01 ALTER COLUMN payment_id SET DEFAULT nextval('payment_payment_id_seq'::regclass);
 J   ALTER TABLE public.payment_p2007_01 ALTER COLUMN payment_id DROP DEFAULT;
       public       postgres    false    222    220            W           2604    16514    payment_p2007_02 payment_id    DEFAULT     s   ALTER TABLE ONLY payment_p2007_02 ALTER COLUMN payment_id SET DEFAULT nextval('payment_payment_id_seq'::regclass);
 J   ALTER TABLE public.payment_p2007_02 ALTER COLUMN payment_id DROP DEFAULT;
       public       postgres    false    220    223            Y           2604    16519    payment_p2007_03 payment_id    DEFAULT     s   ALTER TABLE ONLY payment_p2007_03 ALTER COLUMN payment_id SET DEFAULT nextval('payment_payment_id_seq'::regclass);
 J   ALTER TABLE public.payment_p2007_03 ALTER COLUMN payment_id DROP DEFAULT;
       public       postgres    false    220    224            [           2604    16524    payment_p2007_04 payment_id    DEFAULT     s   ALTER TABLE ONLY payment_p2007_04 ALTER COLUMN payment_id SET DEFAULT nextval('payment_payment_id_seq'::regclass);
 J   ALTER TABLE public.payment_p2007_04 ALTER COLUMN payment_id DROP DEFAULT;
       public       postgres    false    220    225            ]           2604    16529    payment_p2007_05 payment_id    DEFAULT     s   ALTER TABLE ONLY payment_p2007_05 ALTER COLUMN payment_id SET DEFAULT nextval('payment_payment_id_seq'::regclass);
 J   ALTER TABLE public.payment_p2007_05 ALTER COLUMN payment_id DROP DEFAULT;
       public       postgres    false    226    220            _           2604    16534    payment_p2007_06 payment_id    DEFAULT     s   ALTER TABLE ONLY payment_p2007_06 ALTER COLUMN payment_id SET DEFAULT nextval('payment_payment_id_seq'::regclass);
 J   ALTER TABLE public.payment_p2007_06 ALTER COLUMN payment_id DROP DEFAULT;
       public       postgres    false    227    220            a          0    16387    actor 
   TABLE DATA               F   COPY actor (actor_id, first_name, last_name, last_update) FROM stdin;
    public       postgres    false    197   Z3      i          0    16443    address 
   TABLE DATA               m   COPY address (address_id, address, address2, district, city_id, postal_code, phone, last_update) FROM stdin;
    public       postgres    false    206   �4      c          0    16409    category 
   TABLE DATA               ;   COPY category (category_id, name, last_update) FROM stdin;
    public       postgres    false    199   �4      k          0    16450    city 
   TABLE DATA               ?   COPY city (city_id, city, country_id, last_update) FROM stdin;
    public       postgres    false    208   ]5      m          0    16457    country 
   TABLE DATA               <   COPY country (country_id, country, last_update) FROM stdin;
    public       postgres    false    210   z5      o          0    16464    customer 
   TABLE DATA               �   COPY customer (customer_id, store_id, first_name, last_name, email, address_id, activebool, create_date, last_update, active) FROM stdin;
    public       postgres    false    212   e9      e          0    16416    film 
   TABLE DATA               �   COPY film (film_id, title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update, special_features, fulltext) FROM stdin;
    public       postgres    false    201   �9      f          0    16428 
   film_actor 
   TABLE DATA               =   COPY film_actor (actor_id, film_id, last_update) FROM stdin;
    public       postgres    false    202   �9      g          0    16432    film_category 
   TABLE DATA               C   COPY film_category (film_id, category_id, last_update) FROM stdin;
    public       postgres    false    203   �9      q          0    16483 	   inventory 
   TABLE DATA               J   COPY inventory (inventory_id, film_id, store_id, last_update) FROM stdin;
    public       postgres    false    216   �9      s          0    16490    language 
   TABLE DATA               ;   COPY language (language_id, name, last_update) FROM stdin;
    public       postgres    false    218   �9      u          0    16502    payment 
   TABLE DATA               ^   COPY payment (payment_id, customer_id, staff_id, rental_id, amount, payment_date) FROM stdin;
    public       postgres    false    221   :      v          0    16506    payment_p2007_01 
   TABLE DATA               g   COPY payment_p2007_01 (payment_id, customer_id, staff_id, rental_id, amount, payment_date) FROM stdin;
    public       postgres    false    222   0:      w          0    16511    payment_p2007_02 
   TABLE DATA               g   COPY payment_p2007_02 (payment_id, customer_id, staff_id, rental_id, amount, payment_date) FROM stdin;
    public       postgres    false    223   M:      x          0    16516    payment_p2007_03 
   TABLE DATA               g   COPY payment_p2007_03 (payment_id, customer_id, staff_id, rental_id, amount, payment_date) FROM stdin;
    public       postgres    false    224   j:      y          0    16521    payment_p2007_04 
   TABLE DATA               g   COPY payment_p2007_04 (payment_id, customer_id, staff_id, rental_id, amount, payment_date) FROM stdin;
    public       postgres    false    225   �:      z          0    16526    payment_p2007_05 
   TABLE DATA               g   COPY payment_p2007_05 (payment_id, customer_id, staff_id, rental_id, amount, payment_date) FROM stdin;
    public       postgres    false    226   �:      {          0    16531    payment_p2007_06 
   TABLE DATA               g   COPY payment_p2007_06 (payment_id, customer_id, staff_id, rental_id, amount, payment_date) FROM stdin;
    public       postgres    false    227   �:      }          0    16538    rental 
   TABLE DATA               p   COPY rental (rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update) FROM stdin;
    public       postgres    false    229   �:                0    16550    staff 
   TABLE DATA               �   COPY staff (staff_id, first_name, last_name, address_id, email, store_id, active, username, password, last_update, picture) FROM stdin;
    public       postgres    false    232   �:      �          0    16561    store 
   TABLE DATA               M   COPY store (store_id, manager_staff_id, address_id, last_update) FROM stdin;
    public       postgres    false    234   ;      �           0    0    actor_actor_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('actor_actor_id_seq', 200, true);
            public       postgres    false    196            �           0    0    address_address_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('address_address_id_seq', 605, true);
            public       postgres    false    205            �           0    0    category_category_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('category_category_id_seq', 16, true);
            public       postgres    false    198            �           0    0    city_city_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('city_city_id_seq', 600, true);
            public       postgres    false    207            �           0    0    country_country_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('country_country_id_seq', 109, true);
            public       postgres    false    209            �           0    0    customer_customer_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('customer_customer_id_seq', 599, true);
            public       postgres    false    211            �           0    0    film_film_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('film_film_id_seq', 1000, true);
            public       postgres    false    200            �           0    0    inventory_inventory_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('inventory_inventory_id_seq', 4581, true);
            public       postgres    false    215            �           0    0    language_language_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('language_language_id_seq', 6, true);
            public       postgres    false    217            �           0    0    payment_payment_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('payment_payment_id_seq', 32098, true);
            public       postgres    false    220            �           0    0    rental_rental_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('rental_rental_id_seq', 16049, true);
            public       postgres    false    228            �           0    0    staff_staff_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('staff_staff_id_seq', 2, true);
            public       postgres    false    231            �           0    0    store_store_id_seq    SEQUENCE SET     9   SELECT pg_catalog.setval('store_store_id_seq', 2, true);
            public       postgres    false    233            i           2606    16585    actor actor_pkey 
   CONSTRAINT     M   ALTER TABLE ONLY actor
    ADD CONSTRAINT actor_pkey PRIMARY KEY (actor_id);
 :   ALTER TABLE ONLY public.actor DROP CONSTRAINT actor_pkey;
       public         postgres    false    197            y           2606    16587    address address_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY address
    ADD CONSTRAINT address_pkey PRIMARY KEY (address_id);
 >   ALTER TABLE ONLY public.address DROP CONSTRAINT address_pkey;
       public         postgres    false    206            l           2606    16589    category category_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY category
    ADD CONSTRAINT category_pkey PRIMARY KEY (category_id);
 @   ALTER TABLE ONLY public.category DROP CONSTRAINT category_pkey;
       public         postgres    false    199            |           2606    16591    city city_pkey 
   CONSTRAINT     J   ALTER TABLE ONLY city
    ADD CONSTRAINT city_pkey PRIMARY KEY (city_id);
 8   ALTER TABLE ONLY public.city DROP CONSTRAINT city_pkey;
       public         postgres    false    208                       2606    16593    country country_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY country
    ADD CONSTRAINT country_pkey PRIMARY KEY (country_id);
 >   ALTER TABLE ONLY public.country DROP CONSTRAINT country_pkey;
       public         postgres    false    210            �           2606    16595    customer customer_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customer_id);
 @   ALTER TABLE ONLY public.customer DROP CONSTRAINT customer_pkey;
       public         postgres    false    212            t           2606    16597    film_actor film_actor_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY film_actor
    ADD CONSTRAINT film_actor_pkey PRIMARY KEY (actor_id, film_id);
 D   ALTER TABLE ONLY public.film_actor DROP CONSTRAINT film_actor_pkey;
       public         postgres    false    202    202            w           2606    16599     film_category film_category_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY film_category
    ADD CONSTRAINT film_category_pkey PRIMARY KEY (film_id, category_id);
 J   ALTER TABLE ONLY public.film_category DROP CONSTRAINT film_category_pkey;
       public         postgres    false    203    203            o           2606    16601    film film_pkey 
   CONSTRAINT     J   ALTER TABLE ONLY film
    ADD CONSTRAINT film_pkey PRIMARY KEY (film_id);
 8   ALTER TABLE ONLY public.film DROP CONSTRAINT film_pkey;
       public         postgres    false    201            �           2606    16603    inventory inventory_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (inventory_id);
 B   ALTER TABLE ONLY public.inventory DROP CONSTRAINT inventory_pkey;
       public         postgres    false    216            �           2606    16605    language language_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY language
    ADD CONSTRAINT language_pkey PRIMARY KEY (language_id);
 @   ALTER TABLE ONLY public.language DROP CONSTRAINT language_pkey;
       public         postgres    false    218            �           2606    16607    payment payment_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);
 >   ALTER TABLE ONLY public.payment DROP CONSTRAINT payment_pkey;
       public         postgres    false    221            �           2606    16609    rental rental_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY rental
    ADD CONSTRAINT rental_pkey PRIMARY KEY (rental_id);
 <   ALTER TABLE ONLY public.rental DROP CONSTRAINT rental_pkey;
       public         postgres    false    229            �           2606    16611    staff staff_pkey 
   CONSTRAINT     M   ALTER TABLE ONLY staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (staff_id);
 :   ALTER TABLE ONLY public.staff DROP CONSTRAINT staff_pkey;
       public         postgres    false    232            �           2606    16613    store store_pkey 
   CONSTRAINT     M   ALTER TABLE ONLY store
    ADD CONSTRAINT store_pkey PRIMARY KEY (store_id);
 :   ALTER TABLE ONLY public.store DROP CONSTRAINT store_pkey;
       public         postgres    false    234            m           1259    16614    film_fulltext_idx    INDEX     >   CREATE INDEX film_fulltext_idx ON film USING gist (fulltext);
 %   DROP INDEX public.film_fulltext_idx;
       public         postgres    false    201            j           1259    16615    idx_actor_last_name    INDEX     C   CREATE INDEX idx_actor_last_name ON actor USING btree (last_name);
 '   DROP INDEX public.idx_actor_last_name;
       public         postgres    false    197            �           1259    16616    idx_fk_address_id    INDEX     E   CREATE INDEX idx_fk_address_id ON customer USING btree (address_id);
 %   DROP INDEX public.idx_fk_address_id;
       public         postgres    false    212            z           1259    16617    idx_fk_city_id    INDEX     >   CREATE INDEX idx_fk_city_id ON address USING btree (city_id);
 "   DROP INDEX public.idx_fk_city_id;
       public         postgres    false    206            }           1259    16618    idx_fk_country_id    INDEX     A   CREATE INDEX idx_fk_country_id ON city USING btree (country_id);
 %   DROP INDEX public.idx_fk_country_id;
       public         postgres    false    208            �           1259    16619    idx_fk_customer_id    INDEX     F   CREATE INDEX idx_fk_customer_id ON payment USING btree (customer_id);
 &   DROP INDEX public.idx_fk_customer_id;
       public         postgres    false    221            u           1259    16620    idx_fk_film_id    INDEX     A   CREATE INDEX idx_fk_film_id ON film_actor USING btree (film_id);
 "   DROP INDEX public.idx_fk_film_id;
       public         postgres    false    202            �           1259    16621    idx_fk_inventory_id    INDEX     G   CREATE INDEX idx_fk_inventory_id ON rental USING btree (inventory_id);
 '   DROP INDEX public.idx_fk_inventory_id;
       public         postgres    false    229            p           1259    16622    idx_fk_language_id    INDEX     C   CREATE INDEX idx_fk_language_id ON film USING btree (language_id);
 &   DROP INDEX public.idx_fk_language_id;
       public         postgres    false    201            q           1259    16623    idx_fk_original_language_id    INDEX     U   CREATE INDEX idx_fk_original_language_id ON film USING btree (original_language_id);
 /   DROP INDEX public.idx_fk_original_language_id;
       public         postgres    false    201            �           1259    16624 #   idx_fk_payment_p2007_01_customer_id    INDEX     `   CREATE INDEX idx_fk_payment_p2007_01_customer_id ON payment_p2007_01 USING btree (customer_id);
 7   DROP INDEX public.idx_fk_payment_p2007_01_customer_id;
       public         postgres    false    222            �           1259    16625     idx_fk_payment_p2007_01_staff_id    INDEX     Z   CREATE INDEX idx_fk_payment_p2007_01_staff_id ON payment_p2007_01 USING btree (staff_id);
 4   DROP INDEX public.idx_fk_payment_p2007_01_staff_id;
       public         postgres    false    222            �           1259    16626 #   idx_fk_payment_p2007_02_customer_id    INDEX     `   CREATE INDEX idx_fk_payment_p2007_02_customer_id ON payment_p2007_02 USING btree (customer_id);
 7   DROP INDEX public.idx_fk_payment_p2007_02_customer_id;
       public         postgres    false    223            �           1259    16627     idx_fk_payment_p2007_02_staff_id    INDEX     Z   CREATE INDEX idx_fk_payment_p2007_02_staff_id ON payment_p2007_02 USING btree (staff_id);
 4   DROP INDEX public.idx_fk_payment_p2007_02_staff_id;
       public         postgres    false    223            �           1259    16628 #   idx_fk_payment_p2007_03_customer_id    INDEX     `   CREATE INDEX idx_fk_payment_p2007_03_customer_id ON payment_p2007_03 USING btree (customer_id);
 7   DROP INDEX public.idx_fk_payment_p2007_03_customer_id;
       public         postgres    false    224            �           1259    16629     idx_fk_payment_p2007_03_staff_id    INDEX     Z   CREATE INDEX idx_fk_payment_p2007_03_staff_id ON payment_p2007_03 USING btree (staff_id);
 4   DROP INDEX public.idx_fk_payment_p2007_03_staff_id;
       public         postgres    false    224            �           1259    16630 #   idx_fk_payment_p2007_04_customer_id    INDEX     `   CREATE INDEX idx_fk_payment_p2007_04_customer_id ON payment_p2007_04 USING btree (customer_id);
 7   DROP INDEX public.idx_fk_payment_p2007_04_customer_id;
       public         postgres    false    225            �           1259    16631     idx_fk_payment_p2007_04_staff_id    INDEX     Z   CREATE INDEX idx_fk_payment_p2007_04_staff_id ON payment_p2007_04 USING btree (staff_id);
 4   DROP INDEX public.idx_fk_payment_p2007_04_staff_id;
       public         postgres    false    225            �           1259    16632 #   idx_fk_payment_p2007_05_customer_id    INDEX     `   CREATE INDEX idx_fk_payment_p2007_05_customer_id ON payment_p2007_05 USING btree (customer_id);
 7   DROP INDEX public.idx_fk_payment_p2007_05_customer_id;
       public         postgres    false    226            �           1259    16633     idx_fk_payment_p2007_05_staff_id    INDEX     Z   CREATE INDEX idx_fk_payment_p2007_05_staff_id ON payment_p2007_05 USING btree (staff_id);
 4   DROP INDEX public.idx_fk_payment_p2007_05_staff_id;
       public         postgres    false    226            �           1259    16634 #   idx_fk_payment_p2007_06_customer_id    INDEX     `   CREATE INDEX idx_fk_payment_p2007_06_customer_id ON payment_p2007_06 USING btree (customer_id);
 7   DROP INDEX public.idx_fk_payment_p2007_06_customer_id;
       public         postgres    false    227            �           1259    16635     idx_fk_payment_p2007_06_staff_id    INDEX     Z   CREATE INDEX idx_fk_payment_p2007_06_staff_id ON payment_p2007_06 USING btree (staff_id);
 4   DROP INDEX public.idx_fk_payment_p2007_06_staff_id;
       public         postgres    false    227            �           1259    16636    idx_fk_staff_id    INDEX     @   CREATE INDEX idx_fk_staff_id ON payment USING btree (staff_id);
 #   DROP INDEX public.idx_fk_staff_id;
       public         postgres    false    221            �           1259    16637    idx_fk_store_id    INDEX     A   CREATE INDEX idx_fk_store_id ON customer USING btree (store_id);
 #   DROP INDEX public.idx_fk_store_id;
       public         postgres    false    212            �           1259    16638    idx_last_name    INDEX     @   CREATE INDEX idx_last_name ON customer USING btree (last_name);
 !   DROP INDEX public.idx_last_name;
       public         postgres    false    212            �           1259    16639    idx_store_id_film_id    INDEX     P   CREATE INDEX idx_store_id_film_id ON inventory USING btree (store_id, film_id);
 (   DROP INDEX public.idx_store_id_film_id;
       public         postgres    false    216    216            r           1259    16640 	   idx_title    INDEX     4   CREATE INDEX idx_title ON film USING btree (title);
    DROP INDEX public.idx_title;
       public         postgres    false    201            �           1259    16641    idx_unq_manager_staff_id    INDEX     V   CREATE UNIQUE INDEX idx_unq_manager_staff_id ON store USING btree (manager_staff_id);
 ,   DROP INDEX public.idx_unq_manager_staff_id;
       public         postgres    false    234            �           1259    16642 3   idx_unq_rental_rental_date_inventory_id_customer_id    INDEX     �   CREATE UNIQUE INDEX idx_unq_rental_rental_date_inventory_id_customer_id ON rental USING btree (rental_date, inventory_id, customer_id);
 G   DROP INDEX public.idx_unq_rental_rental_date_inventory_id_customer_id;
       public         postgres    false    229    229    229            Z           2618    16643    payment payment_insert_p2007_01    RULE     �  CREATE RULE payment_insert_p2007_01 AS
    ON INSERT TO payment
   WHERE ((new.payment_date >= '2007-01-01 00:00:00'::timestamp without time zone) AND (new.payment_date < '2007-02-01 00:00:00'::timestamp without time zone)) DO INSTEAD  INSERT INTO payment_p2007_01 (payment_id, customer_id, staff_id, rental_id, amount, payment_date)
  VALUES (DEFAULT, new.customer_id, new.staff_id, new.rental_id, new.amount, new.payment_date);
 5   DROP RULE payment_insert_p2007_01 ON public.payment;
       public       postgres    false    221    221    221    222    222    222    222    222    221    221    222    221    221    221            [           2618    16644    payment payment_insert_p2007_02    RULE     �  CREATE RULE payment_insert_p2007_02 AS
    ON INSERT TO payment
   WHERE ((new.payment_date >= '2007-02-01 00:00:00'::timestamp without time zone) AND (new.payment_date < '2007-03-01 00:00:00'::timestamp without time zone)) DO INSTEAD  INSERT INTO payment_p2007_02 (payment_id, customer_id, staff_id, rental_id, amount, payment_date)
  VALUES (DEFAULT, new.customer_id, new.staff_id, new.rental_id, new.amount, new.payment_date);
 5   DROP RULE payment_insert_p2007_02 ON public.payment;
       public       postgres    false    221    221    221    223    223    223    223    223    223    221    221    221    221    221            \           2618    16645    payment payment_insert_p2007_03    RULE     �  CREATE RULE payment_insert_p2007_03 AS
    ON INSERT TO payment
   WHERE ((new.payment_date >= '2007-03-01 00:00:00'::timestamp without time zone) AND (new.payment_date < '2007-04-01 00:00:00'::timestamp without time zone)) DO INSTEAD  INSERT INTO payment_p2007_03 (payment_id, customer_id, staff_id, rental_id, amount, payment_date)
  VALUES (DEFAULT, new.customer_id, new.staff_id, new.rental_id, new.amount, new.payment_date);
 5   DROP RULE payment_insert_p2007_03 ON public.payment;
       public       postgres    false    221    224    221    221    221    221    221    221    224    224    224    224    224    221            ]           2618    16646    payment payment_insert_p2007_04    RULE     �  CREATE RULE payment_insert_p2007_04 AS
    ON INSERT TO payment
   WHERE ((new.payment_date >= '2007-04-01 00:00:00'::timestamp without time zone) AND (new.payment_date < '2007-05-01 00:00:00'::timestamp without time zone)) DO INSTEAD  INSERT INTO payment_p2007_04 (payment_id, customer_id, staff_id, rental_id, amount, payment_date)
  VALUES (DEFAULT, new.customer_id, new.staff_id, new.rental_id, new.amount, new.payment_date);
 5   DROP RULE payment_insert_p2007_04 ON public.payment;
       public       postgres    false    221    221    221    225    225    225    225    225    225    221    221    221    221    221            ^           2618    16647    payment payment_insert_p2007_05    RULE     �  CREATE RULE payment_insert_p2007_05 AS
    ON INSERT TO payment
   WHERE ((new.payment_date >= '2007-05-01 00:00:00'::timestamp without time zone) AND (new.payment_date < '2007-06-01 00:00:00'::timestamp without time zone)) DO INSTEAD  INSERT INTO payment_p2007_05 (payment_id, customer_id, staff_id, rental_id, amount, payment_date)
  VALUES (DEFAULT, new.customer_id, new.staff_id, new.rental_id, new.amount, new.payment_date);
 5   DROP RULE payment_insert_p2007_05 ON public.payment;
       public       postgres    false    221    221    221    226    226    226    226    226    226    221    221    221    221    221            _           2618    16648    payment payment_insert_p2007_06    RULE     �  CREATE RULE payment_insert_p2007_06 AS
    ON INSERT TO payment
   WHERE ((new.payment_date >= '2007-06-01 00:00:00'::timestamp without time zone) AND (new.payment_date < '2007-07-01 00:00:00'::timestamp without time zone)) DO INSTEAD  INSERT INTO payment_p2007_06 (payment_id, customer_id, staff_id, rental_id, amount, payment_date)
  VALUES (DEFAULT, new.customer_id, new.staff_id, new.rental_id, new.amount, new.payment_date);
 5   DROP RULE payment_insert_p2007_06 ON public.payment;
       public       postgres    false    221    221    221    221    221    221    227    221    227    227    227    227    227    221            �           2620    16649    film film_fulltext_trigger    TRIGGER     �   CREATE TRIGGER film_fulltext_trigger BEFORE INSERT OR UPDATE ON film FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger('fulltext', 'pg_catalog.english', 'title', 'description');
 3   DROP TRIGGER film_fulltext_trigger ON public.film;
       public       postgres    false    201            �           2620    16650    actor last_updated    TRIGGER     b   CREATE TRIGGER last_updated BEFORE UPDATE ON actor FOR EACH ROW EXECUTE PROCEDURE last_updated();
 +   DROP TRIGGER last_updated ON public.actor;
       public       postgres    false    243    197            �           2620    16651    address last_updated    TRIGGER     d   CREATE TRIGGER last_updated BEFORE UPDATE ON address FOR EACH ROW EXECUTE PROCEDURE last_updated();
 -   DROP TRIGGER last_updated ON public.address;
       public       postgres    false    206    243            �           2620    16652    category last_updated    TRIGGER     e   CREATE TRIGGER last_updated BEFORE UPDATE ON category FOR EACH ROW EXECUTE PROCEDURE last_updated();
 .   DROP TRIGGER last_updated ON public.category;
       public       postgres    false    243    199            �           2620    16653    city last_updated    TRIGGER     a   CREATE TRIGGER last_updated BEFORE UPDATE ON city FOR EACH ROW EXECUTE PROCEDURE last_updated();
 *   DROP TRIGGER last_updated ON public.city;
       public       postgres    false    243    208            �           2620    16654    country last_updated    TRIGGER     d   CREATE TRIGGER last_updated BEFORE UPDATE ON country FOR EACH ROW EXECUTE PROCEDURE last_updated();
 -   DROP TRIGGER last_updated ON public.country;
       public       postgres    false    210    243            �           2620    16655    customer last_updated    TRIGGER     e   CREATE TRIGGER last_updated BEFORE UPDATE ON customer FOR EACH ROW EXECUTE PROCEDURE last_updated();
 .   DROP TRIGGER last_updated ON public.customer;
       public       postgres    false    243    212            �           2620    16656    film last_updated    TRIGGER     a   CREATE TRIGGER last_updated BEFORE UPDATE ON film FOR EACH ROW EXECUTE PROCEDURE last_updated();
 *   DROP TRIGGER last_updated ON public.film;
       public       postgres    false    201    243            �           2620    16657    film_actor last_updated    TRIGGER     g   CREATE TRIGGER last_updated BEFORE UPDATE ON film_actor FOR EACH ROW EXECUTE PROCEDURE last_updated();
 0   DROP TRIGGER last_updated ON public.film_actor;
       public       postgres    false    202    243            �           2620    16658    film_category last_updated    TRIGGER     j   CREATE TRIGGER last_updated BEFORE UPDATE ON film_category FOR EACH ROW EXECUTE PROCEDURE last_updated();
 3   DROP TRIGGER last_updated ON public.film_category;
       public       postgres    false    243    203            �           2620    16659    inventory last_updated    TRIGGER     f   CREATE TRIGGER last_updated BEFORE UPDATE ON inventory FOR EACH ROW EXECUTE PROCEDURE last_updated();
 /   DROP TRIGGER last_updated ON public.inventory;
       public       postgres    false    243    216            �           2620    16660    language last_updated    TRIGGER     e   CREATE TRIGGER last_updated BEFORE UPDATE ON language FOR EACH ROW EXECUTE PROCEDURE last_updated();
 .   DROP TRIGGER last_updated ON public.language;
       public       postgres    false    243    218            �           2620    16661    rental last_updated    TRIGGER     c   CREATE TRIGGER last_updated BEFORE UPDATE ON rental FOR EACH ROW EXECUTE PROCEDURE last_updated();
 ,   DROP TRIGGER last_updated ON public.rental;
       public       postgres    false    229    243            �           2620    16662    staff last_updated    TRIGGER     b   CREATE TRIGGER last_updated BEFORE UPDATE ON staff FOR EACH ROW EXECUTE PROCEDURE last_updated();
 +   DROP TRIGGER last_updated ON public.staff;
       public       postgres    false    243    232            �           2620    16663    store last_updated    TRIGGER     b   CREATE TRIGGER last_updated BEFORE UPDATE ON store FOR EACH ROW EXECUTE PROCEDURE last_updated();
 +   DROP TRIGGER last_updated ON public.store;
       public       postgres    false    234    243            �           2606    16664    address address_city_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY address
    ADD CONSTRAINT address_city_id_fkey FOREIGN KEY (city_id) REFERENCES city(city_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 F   ALTER TABLE ONLY public.address DROP CONSTRAINT address_city_id_fkey;
       public       postgres    false    208    2940    206            �           2606    16669    city city_country_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY city
    ADD CONSTRAINT city_country_id_fkey FOREIGN KEY (country_id) REFERENCES country(country_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 C   ALTER TABLE ONLY public.city DROP CONSTRAINT city_country_id_fkey;
       public       postgres    false    210    2943    208            �           2606    16674 !   customer customer_address_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_address_id_fkey FOREIGN KEY (address_id) REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 K   ALTER TABLE ONLY public.customer DROP CONSTRAINT customer_address_id_fkey;
       public       postgres    false    212    206    2937            �           2606    16679    customer customer_store_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_store_id_fkey FOREIGN KEY (store_id) REFERENCES store(store_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 I   ALTER TABLE ONLY public.customer DROP CONSTRAINT customer_store_id_fkey;
       public       postgres    false    2978    234    212            �           2606    16684 #   film_actor film_actor_actor_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY film_actor
    ADD CONSTRAINT film_actor_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES actor(actor_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.film_actor DROP CONSTRAINT film_actor_actor_id_fkey;
       public       postgres    false    2921    197    202            �           2606    16689 "   film_actor film_actor_film_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY film_actor
    ADD CONSTRAINT film_actor_film_id_fkey FOREIGN KEY (film_id) REFERENCES film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 L   ALTER TABLE ONLY public.film_actor DROP CONSTRAINT film_actor_film_id_fkey;
       public       postgres    false    2927    202    201            �           2606    16694 ,   film_category film_category_category_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY film_category
    ADD CONSTRAINT film_category_category_id_fkey FOREIGN KEY (category_id) REFERENCES category(category_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 V   ALTER TABLE ONLY public.film_category DROP CONSTRAINT film_category_category_id_fkey;
       public       postgres    false    203    2924    199            �           2606    16699 (   film_category film_category_film_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY film_category
    ADD CONSTRAINT film_category_film_id_fkey FOREIGN KEY (film_id) REFERENCES film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 R   ALTER TABLE ONLY public.film_category DROP CONSTRAINT film_category_film_id_fkey;
       public       postgres    false    203    2927    201            �           2606    16704    film film_language_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY film
    ADD CONSTRAINT film_language_id_fkey FOREIGN KEY (language_id) REFERENCES language(language_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 D   ALTER TABLE ONLY public.film DROP CONSTRAINT film_language_id_fkey;
       public       postgres    false    2953    218    201            �           2606    16709 #   film film_original_language_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY film
    ADD CONSTRAINT film_original_language_id_fkey FOREIGN KEY (original_language_id) REFERENCES language(language_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 M   ALTER TABLE ONLY public.film DROP CONSTRAINT film_original_language_id_fkey;
       public       postgres    false    201    2953    218            �           2606    16714     inventory inventory_film_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY inventory
    ADD CONSTRAINT inventory_film_id_fkey FOREIGN KEY (film_id) REFERENCES film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 J   ALTER TABLE ONLY public.inventory DROP CONSTRAINT inventory_film_id_fkey;
       public       postgres    false    201    2927    216            �           2606    16719 !   inventory inventory_store_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY inventory
    ADD CONSTRAINT inventory_store_id_fkey FOREIGN KEY (store_id) REFERENCES store(store_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 K   ALTER TABLE ONLY public.inventory DROP CONSTRAINT inventory_store_id_fkey;
       public       postgres    false    2978    216    234            �           2606    16724     payment payment_customer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment
    ADD CONSTRAINT payment_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 J   ALTER TABLE ONLY public.payment DROP CONSTRAINT payment_customer_id_fkey;
       public       postgres    false    2945    221    212            �           2606    16729 2   payment_p2007_01 payment_p2007_01_customer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_01
    ADD CONSTRAINT payment_p2007_01_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(customer_id);
 \   ALTER TABLE ONLY public.payment_p2007_01 DROP CONSTRAINT payment_p2007_01_customer_id_fkey;
       public       postgres    false    2945    212    222            �           2606    16734 0   payment_p2007_01 payment_p2007_01_rental_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_01
    ADD CONSTRAINT payment_p2007_01_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES rental(rental_id);
 Z   ALTER TABLE ONLY public.payment_p2007_01 DROP CONSTRAINT payment_p2007_01_rental_id_fkey;
       public       postgres    false    2973    222    229            �           2606    16739 /   payment_p2007_01 payment_p2007_01_staff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_01
    ADD CONSTRAINT payment_p2007_01_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(staff_id);
 Y   ALTER TABLE ONLY public.payment_p2007_01 DROP CONSTRAINT payment_p2007_01_staff_id_fkey;
       public       postgres    false    232    2975    222            �           2606    16744 2   payment_p2007_02 payment_p2007_02_customer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_02
    ADD CONSTRAINT payment_p2007_02_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(customer_id);
 \   ALTER TABLE ONLY public.payment_p2007_02 DROP CONSTRAINT payment_p2007_02_customer_id_fkey;
       public       postgres    false    2945    212    223            �           2606    16749 0   payment_p2007_02 payment_p2007_02_rental_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_02
    ADD CONSTRAINT payment_p2007_02_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES rental(rental_id);
 Z   ALTER TABLE ONLY public.payment_p2007_02 DROP CONSTRAINT payment_p2007_02_rental_id_fkey;
       public       postgres    false    229    223    2973            �           2606    16754 /   payment_p2007_02 payment_p2007_02_staff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_02
    ADD CONSTRAINT payment_p2007_02_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(staff_id);
 Y   ALTER TABLE ONLY public.payment_p2007_02 DROP CONSTRAINT payment_p2007_02_staff_id_fkey;
       public       postgres    false    232    223    2975            �           2606    16759 2   payment_p2007_03 payment_p2007_03_customer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_03
    ADD CONSTRAINT payment_p2007_03_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(customer_id);
 \   ALTER TABLE ONLY public.payment_p2007_03 DROP CONSTRAINT payment_p2007_03_customer_id_fkey;
       public       postgres    false    212    2945    224            �           2606    16764 0   payment_p2007_03 payment_p2007_03_rental_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_03
    ADD CONSTRAINT payment_p2007_03_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES rental(rental_id);
 Z   ALTER TABLE ONLY public.payment_p2007_03 DROP CONSTRAINT payment_p2007_03_rental_id_fkey;
       public       postgres    false    224    229    2973            �           2606    16769 /   payment_p2007_03 payment_p2007_03_staff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_03
    ADD CONSTRAINT payment_p2007_03_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(staff_id);
 Y   ALTER TABLE ONLY public.payment_p2007_03 DROP CONSTRAINT payment_p2007_03_staff_id_fkey;
       public       postgres    false    2975    224    232            �           2606    16774 2   payment_p2007_04 payment_p2007_04_customer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_04
    ADD CONSTRAINT payment_p2007_04_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(customer_id);
 \   ALTER TABLE ONLY public.payment_p2007_04 DROP CONSTRAINT payment_p2007_04_customer_id_fkey;
       public       postgres    false    225    212    2945            �           2606    16779 0   payment_p2007_04 payment_p2007_04_rental_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_04
    ADD CONSTRAINT payment_p2007_04_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES rental(rental_id);
 Z   ALTER TABLE ONLY public.payment_p2007_04 DROP CONSTRAINT payment_p2007_04_rental_id_fkey;
       public       postgres    false    2973    229    225            �           2606    16784 /   payment_p2007_04 payment_p2007_04_staff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_04
    ADD CONSTRAINT payment_p2007_04_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(staff_id);
 Y   ALTER TABLE ONLY public.payment_p2007_04 DROP CONSTRAINT payment_p2007_04_staff_id_fkey;
       public       postgres    false    225    232    2975            �           2606    16789 2   payment_p2007_05 payment_p2007_05_customer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_05
    ADD CONSTRAINT payment_p2007_05_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(customer_id);
 \   ALTER TABLE ONLY public.payment_p2007_05 DROP CONSTRAINT payment_p2007_05_customer_id_fkey;
       public       postgres    false    226    212    2945            �           2606    16794 0   payment_p2007_05 payment_p2007_05_rental_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_05
    ADD CONSTRAINT payment_p2007_05_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES rental(rental_id);
 Z   ALTER TABLE ONLY public.payment_p2007_05 DROP CONSTRAINT payment_p2007_05_rental_id_fkey;
       public       postgres    false    226    229    2973            �           2606    16799 /   payment_p2007_05 payment_p2007_05_staff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_05
    ADD CONSTRAINT payment_p2007_05_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(staff_id);
 Y   ALTER TABLE ONLY public.payment_p2007_05 DROP CONSTRAINT payment_p2007_05_staff_id_fkey;
       public       postgres    false    226    2975    232            �           2606    16804 2   payment_p2007_06 payment_p2007_06_customer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_06
    ADD CONSTRAINT payment_p2007_06_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(customer_id);
 \   ALTER TABLE ONLY public.payment_p2007_06 DROP CONSTRAINT payment_p2007_06_customer_id_fkey;
       public       postgres    false    2945    227    212            �           2606    16809 0   payment_p2007_06 payment_p2007_06_rental_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_06
    ADD CONSTRAINT payment_p2007_06_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES rental(rental_id);
 Z   ALTER TABLE ONLY public.payment_p2007_06 DROP CONSTRAINT payment_p2007_06_rental_id_fkey;
       public       postgres    false    2973    229    227            �           2606    16814 /   payment_p2007_06 payment_p2007_06_staff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment_p2007_06
    ADD CONSTRAINT payment_p2007_06_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(staff_id);
 Y   ALTER TABLE ONLY public.payment_p2007_06 DROP CONSTRAINT payment_p2007_06_staff_id_fkey;
       public       postgres    false    2975    232    227            �           2606    16819    payment payment_rental_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment
    ADD CONSTRAINT payment_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES rental(rental_id) ON UPDATE CASCADE ON DELETE SET NULL;
 H   ALTER TABLE ONLY public.payment DROP CONSTRAINT payment_rental_id_fkey;
       public       postgres    false    221    2973    229            �           2606    16824    payment payment_staff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY payment
    ADD CONSTRAINT payment_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 G   ALTER TABLE ONLY public.payment DROP CONSTRAINT payment_staff_id_fkey;
       public       postgres    false    2975    221    232            �           2606    16829    rental rental_customer_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY rental
    ADD CONSTRAINT rental_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 H   ALTER TABLE ONLY public.rental DROP CONSTRAINT rental_customer_id_fkey;
       public       postgres    false    229    212    2945            �           2606    16834    rental rental_inventory_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY rental
    ADD CONSTRAINT rental_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 I   ALTER TABLE ONLY public.rental DROP CONSTRAINT rental_inventory_id_fkey;
       public       postgres    false    216    229    2951            �           2606    16839    rental rental_staff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY rental
    ADD CONSTRAINT rental_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 E   ALTER TABLE ONLY public.rental DROP CONSTRAINT rental_staff_id_fkey;
       public       postgres    false    229    232    2975            �           2606    16844    staff staff_address_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY staff
    ADD CONSTRAINT staff_address_id_fkey FOREIGN KEY (address_id) REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 E   ALTER TABLE ONLY public.staff DROP CONSTRAINT staff_address_id_fkey;
       public       postgres    false    2937    232    206            �           2606    16849    staff staff_store_id_fkey    FK CONSTRAINT     q   ALTER TABLE ONLY staff
    ADD CONSTRAINT staff_store_id_fkey FOREIGN KEY (store_id) REFERENCES store(store_id);
 C   ALTER TABLE ONLY public.staff DROP CONSTRAINT staff_store_id_fkey;
       public       postgres    false    232    2978    234            �           2606    16854    store store_address_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY store
    ADD CONSTRAINT store_address_id_fkey FOREIGN KEY (address_id) REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 E   ALTER TABLE ONLY public.store DROP CONSTRAINT store_address_id_fkey;
       public       postgres    false    2937    234    206            �           2606    16859 !   store store_manager_staff_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY store
    ADD CONSTRAINT store_manager_staff_id_fkey FOREIGN KEY (manager_staff_id) REFERENCES staff(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT;
 K   ALTER TABLE ONLY public.store DROP CONSTRAINT store_manager_staff_id_fkey;
       public       postgres    false    2975    232    234            a     x�u�Kn�0DדS�)�ɧɎ�Y�B�l#E���{z=r�5�,��p�N	MU]�Us��_��ޞ�m{h ����:��dZ��~�Ħ|E��#Z��s�SG����]��d�t�3o{���I]�"������D~�G^7k��7�VtFZI&S��r|�){8�C]㗣�'�4�(�r^��h1���`�',~�,���9���4lh��q+��'{�#�b��wc���R� k���N;<h�K��Vs�CI5�F�`����i��B�������p�8���      i      x������ � �      c   �   x�u�A�0����^ �(ʎ@Ѝnp�)�6�����z�a��I������%�N�Je��*ו*�z��lz���ǁ�9��̳�3����eQ��vnZ�-�`X;�3����]$�|�8���d)q�D�xU���wy�pu�r�֧��@���li�ȼ���}�$�\Tk�      k      x������ � �      m   �  x�}�Ms�6���_�c;�x��#7ٱױ�1m�$��Z�IT$�����w��=a{�4z^�����z�4z�h ��(���LD�(>	q��j���9�&�k4I����
X�ގq(���V�W�k��I&�Va�G�7�8CS��r/��f'M����aӏةy�+r8S#�0�qgv�o\����%�`���
���#���qz�Ǜ�+g-�A�`_��p>`g1=�8�Ș!+�܎vzab�$q���qP�g5ٵC��Ƀچ��~���̝K8?���8��ೝ�9���+k�X쬋�.�����N���-g�<�?h��x��J��M�^�å6��.�u��rIT:����y\y�.���ި���+dj^Õr�}7p�b�,đ��,R�B�%�R�oϋY蹞kO�x�������>���� �/�P��c.
�6\�r��?���k���Z؏8��zv��դh���X
���=e
7x��bd7�����Mء�'�,�+z�>J	_5��Wf��)Ҳ$�r�$+��:���x�ʚ#��V6G��W)�V��k�)�ڱ�o�⌰�knuN��$Ϗπ���=���Z)��qX�b�0eE����KLY�d�|W��_�����J��u~�Ts������8���7��S���㾯
�W��T��VS��%%P��^Up��6y��Q��`'ֹU�h�Cׂ�L�4ɥ���	9e
-�8>y�T��B^�dB��Z<��:�u����!W��ZeTϸ�.���n���2��uC��_o���vˍqu���W4fum�5��/C�hw�~�I\��#�w���9�h
xP�W��Hm�Y\�#��\ME�mT<9��H��M��!���J����2^�kW*Rx2ګ���b��bƌ����7����Y�.;vx�b<�mA1/.���7�ݧ$�zmާ���i{ʈ+��&�C���[�-]�}S|�g��NONN�rD*      o      x������ � �      e      x������ � �      f      x������ � �      g      x������ � �      q      x������ � �      s      x������ � �      u      x������ � �      v      x������ � �      w      x������ � �      x      x������ � �      y      x������ � �      z      x������ � �      {      x������ � �      }      x������ � �            x������ � �      �      x������ � �     