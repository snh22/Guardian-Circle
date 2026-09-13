--
-- PostgreSQL database dump
--

\restrict vZNJmPCKqp5UpPOOcDuQZrY3yf2K2PfjQ8hpICfg3No7ZeLZaIxiKlTjXATqs5a

-- Dumped from database version 16.15 (Homebrew)
-- Dumped by pg_dump version 16.15 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alerts; Type: TABLE; Schema: public; Owner: snehahankare2007
--

CREATE TABLE public.alerts (
    alert_id integer NOT NULL,
    user_id integer NOT NULL,
    risk_level character varying(20) NOT NULL,
    reason character varying(500) NOT NULL,
    status character varying(30) NOT NULL,
    "timestamp" timestamp without time zone NOT NULL
);


ALTER TABLE public.alerts OWNER TO snehahankare2007;

--
-- Name: alerts_alert_id_seq; Type: SEQUENCE; Schema: public; Owner: snehahankare2007
--

CREATE SEQUENCE public.alerts_alert_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alerts_alert_id_seq OWNER TO snehahankare2007;

--
-- Name: alerts_alert_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: snehahankare2007
--

ALTER SEQUENCE public.alerts_alert_id_seq OWNED BY public.alerts.alert_id;


--
-- Name: elderly_profiles; Type: TABLE; Schema: public; Owner: snehahankare2007
--

CREATE TABLE public.elderly_profiles (
    profile_id integer NOT NULL,
    user_id integer NOT NULL,
    caretaker_id integer NOT NULL
);


ALTER TABLE public.elderly_profiles OWNER TO snehahankare2007;

--
-- Name: elderly_profiles_profile_id_seq; Type: SEQUENCE; Schema: public; Owner: snehahankare2007
--

CREATE SEQUENCE public.elderly_profiles_profile_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.elderly_profiles_profile_id_seq OWNER TO snehahankare2007;

--
-- Name: elderly_profiles_profile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: snehahankare2007
--

ALTER SEQUENCE public.elderly_profiles_profile_id_seq OWNED BY public.elderly_profiles.profile_id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: snehahankare2007
--

CREATE TABLE public.events (
    event_id integer NOT NULL,
    user_id integer NOT NULL,
    event_type character varying(50) NOT NULL,
    risk_level character varying(20) NOT NULL,
    "timestamp" timestamp without time zone NOT NULL
);


ALTER TABLE public.events OWNER TO snehahankare2007;

--
-- Name: events_event_id_seq; Type: SEQUENCE; Schema: public; Owner: snehahankare2007
--

CREATE SEQUENCE public.events_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.events_event_id_seq OWNER TO snehahankare2007;

--
-- Name: events_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: snehahankare2007
--

ALTER SEQUENCE public.events_event_id_seq OWNED BY public.events.event_id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: snehahankare2007
--

CREATE TABLE public.locations (
    location_id integer NOT NULL,
    user_id integer NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    "timestamp" timestamp without time zone NOT NULL
);


ALTER TABLE public.locations OWNER TO snehahankare2007;

--
-- Name: locations_location_id_seq; Type: SEQUENCE; Schema: public; Owner: snehahankare2007
--

CREATE SEQUENCE public.locations_location_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.locations_location_id_seq OWNER TO snehahankare2007;

--
-- Name: locations_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: snehahankare2007
--

ALTER SEQUENCE public.locations_location_id_seq OWNED BY public.locations.location_id;


--
-- Name: safe_zones; Type: TABLE; Schema: public; Owner: snehahankare2007
--

CREATE TABLE public.safe_zones (
    zone_id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(100) NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    radius double precision NOT NULL
);


ALTER TABLE public.safe_zones OWNER TO snehahankare2007;

--
-- Name: safe_zones_zone_id_seq; Type: SEQUENCE; Schema: public; Owner: snehahankare2007
--

CREATE SEQUENCE public.safe_zones_zone_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.safe_zones_zone_id_seq OWNER TO snehahankare2007;

--
-- Name: safe_zones_zone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: snehahankare2007
--

ALTER SEQUENCE public.safe_zones_zone_id_seq OWNED BY public.safe_zones.zone_id;


--
-- Name: trips; Type: TABLE; Schema: public; Owner: snehahankare2007
--

CREATE TABLE public.trips (
    trip_id integer NOT NULL,
    user_id integer NOT NULL,
    destination character varying(200) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    status character varying(30) NOT NULL
);


ALTER TABLE public.trips OWNER TO snehahankare2007;

--
-- Name: trips_trip_id_seq; Type: SEQUENCE; Schema: public; Owner: snehahankare2007
--

CREATE SEQUENCE public.trips_trip_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.trips_trip_id_seq OWNER TO snehahankare2007;

--
-- Name: trips_trip_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: snehahankare2007
--

ALTER SEQUENCE public.trips_trip_id_seq OWNED BY public.trips.trip_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: snehahankare2007
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    password character varying(255) NOT NULL,
    role character varying(30) NOT NULL
);


ALTER TABLE public.users OWNER TO snehahankare2007;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: snehahankare2007
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO snehahankare2007;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: snehahankare2007
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: alerts alert_id; Type: DEFAULT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.alerts ALTER COLUMN alert_id SET DEFAULT nextval('public.alerts_alert_id_seq'::regclass);


--
-- Name: elderly_profiles profile_id; Type: DEFAULT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.elderly_profiles ALTER COLUMN profile_id SET DEFAULT nextval('public.elderly_profiles_profile_id_seq'::regclass);


--
-- Name: events event_id; Type: DEFAULT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.events ALTER COLUMN event_id SET DEFAULT nextval('public.events_event_id_seq'::regclass);


--
-- Name: locations location_id; Type: DEFAULT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.locations ALTER COLUMN location_id SET DEFAULT nextval('public.locations_location_id_seq'::regclass);


--
-- Name: safe_zones zone_id; Type: DEFAULT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.safe_zones ALTER COLUMN zone_id SET DEFAULT nextval('public.safe_zones_zone_id_seq'::regclass);


--
-- Name: trips trip_id; Type: DEFAULT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.trips ALTER COLUMN trip_id SET DEFAULT nextval('public.trips_trip_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (alert_id);


--
-- Name: elderly_profiles elderly_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.elderly_profiles
    ADD CONSTRAINT elderly_profiles_pkey PRIMARY KEY (profile_id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (event_id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (location_id);


--
-- Name: safe_zones safe_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.safe_zones
    ADD CONSTRAINT safe_zones_pkey PRIMARY KEY (zone_id);


--
-- Name: trips trips_pkey; Type: CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_pkey PRIMARY KEY (trip_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: ix_alerts_alert_id; Type: INDEX; Schema: public; Owner: snehahankare2007
--

CREATE INDEX ix_alerts_alert_id ON public.alerts USING btree (alert_id);


--
-- Name: ix_elderly_profiles_profile_id; Type: INDEX; Schema: public; Owner: snehahankare2007
--

CREATE INDEX ix_elderly_profiles_profile_id ON public.elderly_profiles USING btree (profile_id);


--
-- Name: ix_events_event_id; Type: INDEX; Schema: public; Owner: snehahankare2007
--

CREATE INDEX ix_events_event_id ON public.events USING btree (event_id);


--
-- Name: ix_locations_location_id; Type: INDEX; Schema: public; Owner: snehahankare2007
--

CREATE INDEX ix_locations_location_id ON public.locations USING btree (location_id);


--
-- Name: ix_safe_zones_zone_id; Type: INDEX; Schema: public; Owner: snehahankare2007
--

CREATE INDEX ix_safe_zones_zone_id ON public.safe_zones USING btree (zone_id);


--
-- Name: ix_trips_trip_id; Type: INDEX; Schema: public; Owner: snehahankare2007
--

CREATE INDEX ix_trips_trip_id ON public.trips USING btree (trip_id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: snehahankare2007
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_user_id; Type: INDEX; Schema: public; Owner: snehahankare2007
--

CREATE INDEX ix_users_user_id ON public.users USING btree (user_id);


--
-- Name: alerts alerts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: elderly_profiles elderly_profiles_caretaker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.elderly_profiles
    ADD CONSTRAINT elderly_profiles_caretaker_id_fkey FOREIGN KEY (caretaker_id) REFERENCES public.users(user_id);


--
-- Name: elderly_profiles elderly_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.elderly_profiles
    ADD CONSTRAINT elderly_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: events events_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: locations locations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: safe_zones safe_zones_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.safe_zones
    ADD CONSTRAINT safe_zones_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: trips trips_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: snehahankare2007
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- PostgreSQL database dump complete
--

\unrestrict vZNJmPCKqp5UpPOOcDuQZrY3yf2K2PfjQ8hpICfg3No7ZeLZaIxiKlTjXATqs5a

