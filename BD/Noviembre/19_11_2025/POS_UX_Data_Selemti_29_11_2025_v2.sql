--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.25
-- Dumped by pg_dump version 9.5.0

-- Started on 2025-11-29 14:40:09

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = selemti, pg_catalog;

--
-- TOC entry 5279 (class 0 OID 25508)
-- Dependencies: 366
-- Data for Name: alert_events; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY alert_events (id, recipe_id, snapshot_at, old_portion_cost, new_portion_cost, delta_pct, created_at, handled, assigned_to, acknowledged_at, resolution_notes, severity) FROM stdin;
\.


--
-- TOC entry 5778 (class 0 OID 0)
-- Dependencies: 367
-- Name: alert_events_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('alert_events_id_seq', 1, false);


--
-- TOC entry 5281 (class 0 OID 25519)
-- Dependencies: 368
-- Data for Name: alert_rules; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY alert_rules (id, recipe_id, category_id, threshold_pct, active, notes, scope, threshold_numeric, threshold_percent, notification_channels) FROM stdin;
\.


--
-- TOC entry 5779 (class 0 OID 0)
-- Dependencies: 369
-- Name: alert_rules_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('alert_rules_id_seq', 1, false);


--
-- TOC entry 5548 (class 0 OID 30534)
-- Dependencies: 698
-- Data for Name: alertas_cortes; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY alertas_cortes (id, postcorte_id, sesion_id, tipo, destinatario_id, leida, creada_en, leida_en) FROM stdin;
\.


--
-- TOC entry 5780 (class 0 OID 0)
-- Dependencies: 697
-- Name: alertas_cortes_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('alertas_cortes_id_seq', 1, false);


--
-- TOC entry 5283 (class 0 OID 25530)
-- Dependencies: 370
-- Data for Name: almacen; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY almacen (id, sucursal_id, nombre, activo) FROM stdin;
\.


--
-- TOC entry 5284 (class 0 OID 25537)
-- Dependencies: 371
-- Data for Name: audit_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY audit_log (id, "timestamp", user_id, accion, entidad, entidad_id, motivo, evidencia_url, payload_json) FROM stdin;
1	2025-11-20 18:16:40	3	USER_PERMISSIONS_UPDATE	user	4	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [], "direct_permissions": []}
2	2025-11-20 18:17:10	3	USER_PERMISSIONS_UPDATE	user	4	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [], "direct_permissions": []}
3	2025-11-20 18:17:21	3	USER_PERMISSIONS_UPDATE	user	4	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
4	2025-11-20 18:17:23	3	USER_PERMISSIONS_UPDATE	user	4	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
5	2025-11-20 18:17:28	3	USER_PERMISSIONS_UPDATE	user	4	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
6	2025-11-20 18:21:28	3	USER_PERMISSIONS_UPDATE	user	5	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": ["cashfund.view", "inventory.lots.view", "inventory.view", "people.view", "reports.view"]}
7	2025-11-20 18:21:55	3	USER_PERMISSIONS_UPDATE	user	5	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": ["cashfund.view", "inventory.lots.view", "inventory.view", "people.view", "reports.view"]}
8	2025-11-20 18:22:01	3	USER_PERMISSIONS_UPDATE	user	5	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
9	2025-11-20 18:22:27	3	USER_PERMISSIONS_UPDATE	user	5	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": ["cashfund.view", "inventory.lots.view", "inventory.view", "people.view", "reports.view"]}
10	2025-11-20 19:16:16	3	USER_PERMISSIONS_UPDATE	user	6	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [], "direct_permissions": []}
11	2025-11-20 19:17:19	3	USER_PERMISSIONS_UPDATE	user	6	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
12	2025-11-21 08:38:37	3	USER_PERMISSIONS_UPDATE	user	4	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": ["cashfund.view", "inventory.lots.view", "inventory.view", "people.view", "reports.view"]}
13	2025-11-21 08:39:03	3	USER_PERMISSIONS_UPDATE	user	5	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": ["cashfund.view", "inventory.lots.view", "inventory.view", "people.view", "reports.view"]}
14	2025-11-21 08:42:14	3	USER_PERMISSIONS_UPDATE	user	7	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": ["cashfund.view", "inventory.lots.view", "inventory.view", "people.view", "reports.view"]}
15	2025-11-21 08:42:50	3	USER_PERMISSIONS_UPDATE	user	8	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": ["cashfund.view", "inventory.lots.view", "inventory.view", "people.view", "reports.view"]}
16	2025-11-21 08:43:34	3	USER_PERMISSIONS_UPDATE	user	9	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": ["cashfund.view", "inventory.lots.view", "inventory.view", "people.view", "reports.view"]}
17	2025-11-21 08:44:23	3	USER_PERMISSIONS_UPDATE	user	10	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": ["cashfund.view", "inventory.lots.view", "inventory.view", "people.view", "reports.view"]}
18	2025-11-21 08:45:27	3	USER_PERMISSIONS_UPDATE	user	11	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": ["cashfund.view", "inventory.lots.view", "inventory.view", "people.view", "reports.view"]}
19	2025-11-21 08:45:41	3	USER_PERMISSIONS_UPDATE	user	6	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
20	2025-11-21 08:45:48	3	USER_PERMISSIONS_UPDATE	user	8	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
21	2025-11-21 08:46:02	3	USER_PERMISSIONS_UPDATE	user	10	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
22	2025-11-21 08:46:04	3	USER_PERMISSIONS_UPDATE	user	10	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
23	2025-11-21 08:46:12	3	USER_PERMISSIONS_UPDATE	user	7	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [], "direct_permissions": []}
24	2025-11-21 08:46:22	3	USER_PERMISSIONS_UPDATE	user	7	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
25	2025-11-21 08:46:29	3	USER_PERMISSIONS_UPDATE	user	9	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
26	2025-11-21 08:46:30	3	USER_PERMISSIONS_UPDATE	user	9	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [6], "direct_permissions": []}
27	2025-11-21 13:48:46	3	USER_PERMISSIONS_UPDATE	user	10	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [], "direct_permissions": []}
28	2025-11-21 13:49:38	3	USER_PERMISSIONS_UPDATE	user	9	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [], "direct_permissions": []}
29	2025-11-21 14:04:37	3	USER_PERMISSIONS_UPDATE	user	7	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [], "direct_permissions": []}
30	2025-11-24 10:37:35	3	USER_PERMISSIONS_UPDATE	user	8	Actualización de accesos desde panel de administración	\N	{"assigned_roles": [], "direct_permissions": []}
\.


--
-- TOC entry 5285 (class 0 OID 25544)
-- Dependencies: 372
-- Data for Name: audit_log_global; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY audit_log_global (id, schema_name, table_name, operation, record_id, old_data, new_data, changed_by_user_id, changed_at, ip_address, user_agent) FROM stdin;
\.


--
-- TOC entry 5781 (class 0 OID 0)
-- Dependencies: 373
-- Name: audit_log_global_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('audit_log_global_id_seq', 1, false);


--
-- TOC entry 5782 (class 0 OID 0)
-- Dependencies: 374
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('audit_log_id_seq', 30, true);


--
-- TOC entry 5288 (class 0 OID 25556)
-- Dependencies: 375
-- Data for Name: auditoria; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

COPY auditoria (id, quien, que, payload, creado_en) FROM stdin;
1	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-17T09:06:03.217", "dah_id": 126, "operation": "ASIGNAR"}	2025-09-17 08:06:04.081128-06
2	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-17T09:22:58.68", "dah_id": 127, "operation": "ASIGNAR"}	2025-09-17 08:22:58.686625-06
3	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-18T08:55:08.491", "dah_id": 130, "operation": "ASIGNAR"}	2025-09-18 07:55:08.545545-06
4	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-18T09:38:33.973", "dah_id": 131, "operation": "ASIGNAR"}	2025-09-18 08:38:34.748483-06
5	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-19T08:34:20.654", "dah_id": 134, "operation": "ASIGNAR"}	2025-09-19 07:34:21.424031-06
6	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-19T09:05:06.502", "dah_id": 135, "operation": "ASIGNAR"}	2025-09-19 08:05:06.546538-06
7	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-20T09:01:59.5", "dah_id": 138, "operation": "ASIGNAR"}	2025-09-20 08:02:00.219905-06
8	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-20T09:06:11.135", "dah_id": 139, "operation": "ASIGNAR"}	2025-09-20 08:06:12.507865-06
9	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:23:37.943", "dah_id": 142, "operation": "ASIGNAR"}	2025-09-22 07:23:40.164587-06
10	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:42:23.967", "dah_id": 143, "operation": "ASIGNAR"}	2025-09-22 07:42:24.379279-06
11	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:54:42.608", "dah_id": 146, "operation": "ASIGNAR"}	2025-09-22 07:54:43.01876-06
12	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:55:26.437", "dah_id": 147, "operation": "ASIGNAR"}	2025-09-22 07:55:26.463681-06
13	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T15:58:41.388", "dah_id": 148, "operation": "ASIGNAR"}	2025-09-22 14:58:44.147496-06
14	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-23T09:05:49.234", "dah_id": 151, "operation": "ASIGNAR"}	2025-09-23 08:05:50.31703-06
15	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-23T09:12:22.319", "dah_id": 152, "operation": "ASIGNAR"}	2025-09-23 08:12:22.383953-06
16	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-24T08:55:07.788", "dah_id": 155, "operation": "ASIGNAR"}	2025-09-24 07:55:07.848467-06
17	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-24T09:36:29.527", "dah_id": 156, "operation": "ASIGNAR"}	2025-09-24 08:36:30.21109-06
18	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-25T09:02:41.923", "dah_id": 159, "operation": "ASIGNAR"}	2025-09-25 08:02:42.676315-06
19	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-25T09:34:12.819", "dah_id": 160, "operation": "ASIGNAR"}	2025-09-25 08:34:14.59031-06
20	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-26T08:46:01.273", "dah_id": 163, "operation": "ASIGNAR"}	2025-09-26 07:46:01.310139-06
21	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-26T08:51:34.061", "dah_id": 164, "operation": "ASIGNAR"}	2025-09-26 07:51:34.273578-06
22	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-27T08:34:04.289", "dah_id": 167, "operation": "ASIGNAR"}	2025-09-27 07:34:05.109531-06
23	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-27T09:06:22.867", "dah_id": 168, "operation": "ASIGNAR"}	2025-09-27 08:06:24.105709-06
24	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-29T09:01:23.765", "dah_id": 171, "operation": "ASIGNAR"}	2025-09-29 08:01:23.827279-06
25	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-29T09:13:41.633", "dah_id": 172, "operation": "ASIGNAR"}	2025-09-29 08:13:42.556641-06
26	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-30T07:34:22.236", "dah_id": 177, "operation": "ASIGNAR"}	2025-09-30 06:34:22.295356-06
27	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-30T09:02:39.518", "dah_id": 178, "operation": "ASIGNAR"}	2025-09-30 08:02:39.594419-06
28	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-01T07:32:59.659", "dah_id": 184, "operation": "ASIGNAR"}	2025-10-01 06:32:59.763091-06
29	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-01T07:55:41.608", "dah_id": 185, "operation": "ASIGNAR"}	2025-10-01 06:55:42.45592-06
30	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-01T09:16:09.183", "dah_id": 186, "operation": "ASIGNAR"}	2025-10-01 08:16:10.61867-06
31	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-02T07:53:37.516", "dah_id": 189, "operation": "ASIGNAR"}	2025-10-02 06:53:37.537881-06
32	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-02T08:40:27.388", "dah_id": 190, "operation": "ASIGNAR"}	2025-10-02 07:40:27.395912-06
33	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-02T08:45:53.634", "dah_id": 192, "operation": "ASIGNAR"}	2025-10-02 07:45:54.688896-06
34	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-03T07:22:54.163", "dah_id": 196, "operation": "ASIGNAR"}	2025-10-03 06:22:54.235856-06
35	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-03T08:54:37.023", "dah_id": 197, "operation": "ASIGNAR"}	2025-10-03 07:54:37.094581-06
36	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-03T09:30:34.68", "dah_id": 198, "operation": "ASIGNAR"}	2025-10-03 08:30:35.753797-06
37	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-04T08:37:46.98", "dah_id": 202, "operation": "ASIGNAR"}	2025-10-04 07:37:48.614896-06
38	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-04T08:39:49.896", "dah_id": 203, "operation": "ASIGNAR"}	2025-10-04 07:39:50.938951-06
39	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-06T07:58:10.641", "dah_id": 206, "operation": "ASIGNAR"}	2025-10-06 06:58:10.890961-06
40	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-06T08:19:02.596", "dah_id": 207, "operation": "ASIGNAR"}	2025-10-06 07:19:03.292037-06
41	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-07T07:29:05.145", "dah_id": 212, "operation": "ASIGNAR"}	2025-10-07 06:29:05.297092-06
42	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-07T08:50:28.769", "dah_id": 214, "operation": "ASIGNAR"}	2025-10-07 07:50:28.797539-06
43	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-08T08:34:05.623", "dah_id": 218, "operation": "ASIGNAR"}	2025-10-08 07:34:06.872535-06
44	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-08T09:58:21.955", "dah_id": 219, "operation": "ASIGNAR"}	2025-10-08 08:58:23.297741-06
45	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-09T08:35:26.563", "dah_id": 222, "operation": "ASIGNAR"}	2025-10-09 07:35:27.204894-06
46	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-09T09:28:19.78", "dah_id": 223, "operation": "ASIGNAR"}	2025-10-09 08:28:21.068893-06
47	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-10T07:26:30.415", "dah_id": 228, "operation": "ASIGNAR"}	2025-10-10 06:26:30.557316-06
48	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-10T08:42:13.371", "dah_id": 229, "operation": "ASIGNAR"}	2025-10-10 07:42:15.822091-06
49	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-11T08:27:08.465", "dah_id": 234, "operation": "ASIGNAR"}	2025-10-11 07:27:10.31438-06
50	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-11T08:28:34.703", "dah_id": 235, "operation": "ASIGNAR"}	2025-10-11 07:28:37.111777-06
51	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-13T07:19:16.121", "dah_id": 238, "operation": "ASIGNAR"}	2025-10-13 06:19:16.258862-06
52	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-13T08:55:19.487", "dah_id": 239, "operation": "ASIGNAR"}	2025-10-13 07:55:19.518505-06
53	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-14T07:14:29.338", "dah_id": 244, "operation": "ASIGNAR"}	2025-10-14 06:14:29.514346-06
54	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-14T08:27:04.537", "dah_id": 245, "operation": "ASIGNAR"}	2025-10-14 07:27:05.84751-06
55	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-15T07:36:32.551", "dah_id": 250, "operation": "ASIGNAR"}	2025-10-15 06:36:32.674744-06
56	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-15T08:17:38.126", "dah_id": 252, "operation": "ASIGNAR"}	2025-10-15 07:17:38.405685-06
57	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-16T07:06:23.065", "dah_id": 256, "operation": "ASIGNAR"}	2025-10-16 06:06:23.103373-06
58	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-16T07:07:00.96", "dah_id": 258, "operation": "ASIGNAR"}	2025-10-16 06:07:00.991373-06
59	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-16T09:03:55.529", "dah_id": 260, "operation": "ASIGNAR"}	2025-10-16 08:03:55.646781-06
60	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-17T08:47:04.893", "dah_id": 263, "operation": "ASIGNAR"}	2025-10-17 07:47:06.451915-06
61	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-18T07:57:40.291", "dah_id": 268, "operation": "ASIGNAR"}	2025-10-18 06:57:40.121727-06
62	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-20T08:50:42.114", "dah_id": 271, "operation": "ASIGNAR"}	2025-10-20 07:50:42.262013-06
63	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-21T08:03:32.316", "dah_id": 275, "operation": "ASIGNAR"}	2025-10-21 08:03:33.225142-06
64	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-22T08:07:17.347", "dah_id": 280, "operation": "ASIGNAR"}	2025-10-22 07:07:18.357403-06
65	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-23T08:46:48.664", "dah_id": 283, "operation": "ASIGNAR"}	2025-10-23 07:46:49.545493-06
66	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-24T07:46:29.323", "dah_id": 287, "operation": "ASIGNAR"}	2025-10-24 07:46:29.34105-06
67	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-25T08:19:50.827", "dah_id": 292, "operation": "ASIGNAR"}	2025-10-25 07:19:51.524247-06
68	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-27T08:05:39.203", "dah_id": 295, "operation": "ASIGNAR"}	2025-10-27 08:05:39.785984-06
69	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-28T08:02:53.052", "dah_id": 300, "operation": "ASIGNAR"}	2025-10-28 08:02:53.095579-06
70	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-29T07:35:07.677", "dah_id": 304, "operation": "ASIGNAR"}	2025-10-29 07:35:07.38462-06
71	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-30T07:28:49.2", "dah_id": 307, "operation": "ASIGNAR"}	2025-10-30 07:28:49.364087-06
72	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-31T08:34:39.643", "dah_id": 311, "operation": "ASIGNAR"}	2025-10-31 08:34:40.271255-06
73	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-03T08:01:00.232", "dah_id": 315, "operation": "ASIGNAR"}	2025-11-03 08:01:00.23551-06
74	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-04T06:56:16.696", "dah_id": 322, "operation": "ASIGNAR"}	2025-11-04 06:56:16.768307-06
75	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-04T07:34:25.306", "dah_id": 323, "operation": "ASIGNAR"}	2025-11-04 07:34:25.707977-06
76	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-05T07:49:53.526", "dah_id": 328, "operation": "ASIGNAR"}	2025-11-05 07:49:54.14574-06
77	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-05T08:18:56.19", "dah_id": 329, "operation": "ASIGNAR"}	2025-11-05 08:18:56.240872-06
78	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-06T06:42:10.377", "dah_id": 332, "operation": "ASIGNAR"}	2025-11-06 06:42:10.479132-06
79	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-06T07:58:01.229", "dah_id": 333, "operation": "ASIGNAR"}	2025-11-06 07:58:01.348696-06
80	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-07T06:38:54.435", "dah_id": 342, "operation": "ASIGNAR"}	2025-11-07 06:38:54.520624-06
81	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-07T07:52:30.879", "dah_id": 344, "operation": "ASIGNAR"}	2025-11-07 07:52:31.640422-06
82	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-08T07:24:40.261", "dah_id": 348, "operation": "ASIGNAR"}	2025-11-08 07:24:41.92378-06
83	12	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-08T08:00:31.893", "dah_id": 349, "operation": "ASIGNAR"}	2025-11-08 08:00:31.946036-06
84	14	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-08T13:51:13.1", "dah_id": 350, "operation": "ASIGNAR"}	2025-11-08 13:51:13.283927-06
85	11	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-08T15:32:04.991", "dah_id": 353, "operation": "ASIGNAR"}	2025-11-08 15:32:05.297032-06
86	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-15T06:00:50.176", "dah_id": 1, "operation": "ASIGNAR"}	2025-11-10 11:04:02.915961-06
87	7	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-15T12:21:24.808", "dah_id": 2, "operation": "ASIGNAR"}	2025-11-10 11:04:02.91784-06
88	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-15T13:04:45.032", "dah_id": 5, "operation": "ASIGNAR"}	2025-11-10 11:04:02.920075-06
89	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-15T13:33:57.629", "dah_id": 7, "operation": "ASIGNAR"}	2025-11-10 11:04:02.921343-06
90	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-15T13:40:59.187", "dah_id": 9, "operation": "ASIGNAR"}	2025-11-10 11:04:02.922532-06
91	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-15T14:06:24.506", "dah_id": 10, "operation": "ASIGNAR"}	2025-11-10 11:04:02.923113-06
92	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-16T09:30:40.619", "dah_id": 13, "operation": "ASIGNAR"}	2025-11-10 11:04:02.924934-06
93	7	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-16T09:43:10.427", "dah_id": 14, "operation": "ASIGNAR"}	2025-11-10 11:04:02.925483-06
94	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-16T17:22:52.894", "dah_id": 17, "operation": "ASIGNAR"}	2025-11-10 11:04:02.927127-06
95	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-18T08:24:07.202", "dah_id": 18, "operation": "ASIGNAR"}	2025-11-10 11:04:02.927674-06
96	7	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-18T08:25:00.513", "dah_id": 19, "operation": "ASIGNAR"}	2025-11-10 11:04:02.928248-06
97	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-19T09:05:22.407", "dah_id": 22, "operation": "ASIGNAR"}	2025-11-10 11:04:02.929916-06
98	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-19T10:42:04.823", "dah_id": 23, "operation": "ASIGNAR"}	2025-11-10 11:04:02.930457-06
99	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-20T09:10:26.782", "dah_id": 26, "operation": "ASIGNAR"}	2025-11-10 11:04:02.932177-06
100	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-20T10:39:52.787", "dah_id": 27, "operation": "ASIGNAR"}	2025-11-10 11:04:02.932734-06
101	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-21T20:27:05.941", "dah_id": 30, "operation": "ASIGNAR"}	2025-11-10 11:04:02.934451-06
102	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-22T09:26:16.929", "dah_id": 32, "operation": "ASIGNAR"}	2025-11-10 11:04:02.935582-06
103	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-22T21:08:20.303", "dah_id": 34, "operation": "ASIGNAR"}	2025-11-10 11:04:02.936713-06
104	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-23T08:43:41.756", "dah_id": 36, "operation": "ASIGNAR"}	2025-11-10 11:04:02.937833-06
105	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-23T09:09:43.686", "dah_id": 37, "operation": "ASIGNAR"}	2025-11-10 11:04:02.938372-06
106	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-25T08:45:08.838", "dah_id": 40, "operation": "ASIGNAR"}	2025-11-10 11:04:02.940025-06
107	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-25T09:46:51.706", "dah_id": 41, "operation": "ASIGNAR"}	2025-11-10 11:04:02.940577-06
108	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-25T19:35:31.6", "dah_id": 44, "operation": "ASIGNAR"}	2025-11-10 11:04:02.942213-06
109	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-26T09:02:04.471", "dah_id": 46, "operation": "ASIGNAR"}	2025-11-10 11:04:02.943306-06
110	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-26T09:09:33.3", "dah_id": 47, "operation": "ASIGNAR"}	2025-11-10 11:04:02.943854-06
111	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-27T08:17:57.989", "dah_id": 50, "operation": "ASIGNAR"}	2025-11-10 11:04:02.94549-06
112	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-27T09:35:12.936", "dah_id": 51, "operation": "ASIGNAR"}	2025-11-10 11:04:02.946039-06
113	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-27T22:25:47.329", "dah_id": 54, "operation": "ASIGNAR"}	2025-11-10 11:04:02.947688-06
114	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-27T22:29:33.86", "dah_id": 56, "operation": "ASIGNAR"}	2025-11-10 11:04:02.948804-06
115	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-28T09:04:58.814", "dah_id": 58, "operation": "ASIGNAR"}	2025-11-10 11:04:02.949899-06
116	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-28T09:20:06.363", "dah_id": 59, "operation": "ASIGNAR"}	2025-11-10 11:04:02.95045-06
117	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-29T09:01:51.929", "dah_id": 62, "operation": "ASIGNAR"}	2025-11-10 11:04:02.952143-06
118	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-29T09:14:15.466", "dah_id": 63, "operation": "ASIGNAR"}	2025-11-10 11:04:02.952711-06
119	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-29T18:22:53.823", "dah_id": 66, "operation": "ASIGNAR"}	2025-11-10 11:04:02.954375-06
120	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-30T08:43:09.865", "dah_id": 67, "operation": "ASIGNAR"}	2025-11-10 11:04:02.95492-06
121	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-08-30T08:44:48.293", "dah_id": 69, "operation": "ASIGNAR"}	2025-11-10 11:04:02.956031-06
122	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-01T09:07:21.137", "dah_id": 72, "operation": "ASIGNAR"}	2025-11-10 11:04:02.957704-06
123	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-01T09:33:04.071", "dah_id": 73, "operation": "ASIGNAR"}	2025-11-10 11:04:02.958267-06
124	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-02T08:35:42.857", "dah_id": 76, "operation": "ASIGNAR"}	2025-11-10 11:04:02.959915-06
125	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-02T09:35:26.167", "dah_id": 77, "operation": "ASIGNAR"}	2025-11-10 11:04:02.960464-06
126	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-03T09:04:43.604", "dah_id": 80, "operation": "ASIGNAR"}	2025-11-10 11:04:02.962142-06
127	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-03T09:34:38.012", "dah_id": 81, "operation": "ASIGNAR"}	2025-11-10 11:04:02.962705-06
128	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-04T09:02:18.87", "dah_id": 84, "operation": "ASIGNAR"}	2025-11-10 11:04:02.964381-06
129	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-04T09:38:52.01", "dah_id": 85, "operation": "ASIGNAR"}	2025-11-10 11:04:02.964923-06
130	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-05T09:15:26.78", "dah_id": 88, "operation": "ASIGNAR"}	2025-11-10 11:04:02.966597-06
131	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-05T09:20:33.59", "dah_id": 89, "operation": "ASIGNAR"}	2025-11-10 11:04:02.967152-06
132	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-06T08:41:36.151", "dah_id": 92, "operation": "ASIGNAR"}	2025-11-10 11:04:02.968844-06
133	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-06T08:58:47.721", "dah_id": 93, "operation": "ASIGNAR"}	2025-11-10 11:04:02.969411-06
134	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-06T17:20:23.894", "dah_id": 96, "operation": "ASIGNAR"}	2025-11-10 11:04:02.971124-06
135	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-08T09:11:57.063", "dah_id": 98, "operation": "ASIGNAR"}	2025-11-10 11:04:02.972344-06
136	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-08T09:41:00.913", "dah_id": 99, "operation": "ASIGNAR"}	2025-11-10 11:04:02.972896-06
137	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-09T09:03:39.915", "dah_id": 102, "operation": "ASIGNAR"}	2025-11-10 11:04:02.974565-06
138	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-09T09:04:20.914", "dah_id": 103, "operation": "ASIGNAR"}	2025-11-10 11:04:02.975119-06
139	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-10T09:17:40.042", "dah_id": 106, "operation": "ASIGNAR"}	2025-11-10 11:04:02.976786-06
140	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-10T09:28:22.54", "dah_id": 107, "operation": "ASIGNAR"}	2025-11-10 11:04:02.977338-06
141	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-11T08:30:54.864", "dah_id": 110, "operation": "ASIGNAR"}	2025-11-10 11:04:02.978992-06
142	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-11T09:39:15.809", "dah_id": 111, "operation": "ASIGNAR"}	2025-11-10 11:04:02.979536-06
143	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-12T08:32:34.41", "dah_id": 114, "operation": "ASIGNAR"}	2025-11-10 11:04:02.981214-06
144	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-12T09:24:03.805", "dah_id": 115, "operation": "ASIGNAR"}	2025-11-10 11:04:02.981773-06
145	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-13T09:01:16.098", "dah_id": 118, "operation": "ASIGNAR"}	2025-11-10 11:04:02.98345-06
146	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-13T09:31:48.56", "dah_id": 119, "operation": "ASIGNAR"}	2025-11-10 11:04:02.983997-06
147	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-15T08:03:44.29", "dah_id": 122, "operation": "ASIGNAR"}	2025-11-10 11:04:02.985677-06
148	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-15T08:05:26.937", "dah_id": 123, "operation": "ASIGNAR"}	2025-11-10 11:04:02.986242-06
149	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-17T09:06:03.217", "dah_id": 126, "operation": "ASIGNAR"}	2025-11-10 11:04:02.987904-06
150	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-17T09:22:58.68", "dah_id": 127, "operation": "ASIGNAR"}	2025-11-10 11:04:02.988458-06
151	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-18T08:55:08.491", "dah_id": 130, "operation": "ASIGNAR"}	2025-11-10 11:04:02.990109-06
152	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-18T09:38:33.973", "dah_id": 131, "operation": "ASIGNAR"}	2025-11-10 11:04:02.990656-06
153	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-19T08:34:20.654", "dah_id": 134, "operation": "ASIGNAR"}	2025-11-10 11:04:02.992304-06
154	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-19T09:05:06.502", "dah_id": 135, "operation": "ASIGNAR"}	2025-11-10 11:04:02.992868-06
155	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-20T09:01:59.5", "dah_id": 138, "operation": "ASIGNAR"}	2025-11-10 11:04:02.994569-06
156	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-20T09:06:11.135", "dah_id": 139, "operation": "ASIGNAR"}	2025-11-10 11:04:02.995111-06
157	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:23:37.943", "dah_id": 142, "operation": "ASIGNAR"}	2025-11-10 11:04:02.996757-06
158	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:42:23.967", "dah_id": 143, "operation": "ASIGNAR"}	2025-11-10 11:04:02.997321-06
159	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:54:42.608", "dah_id": 146, "operation": "ASIGNAR"}	2025-11-10 11:04:02.998969-06
160	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:55:26.437", "dah_id": 147, "operation": "ASIGNAR"}	2025-11-10 11:04:02.999514-06
161	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T15:58:41.388", "dah_id": 148, "operation": "ASIGNAR"}	2025-11-10 11:04:03.000072-06
162	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-23T09:05:49.234", "dah_id": 151, "operation": "ASIGNAR"}	2025-11-10 11:04:03.001743-06
163	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-23T09:12:22.319", "dah_id": 152, "operation": "ASIGNAR"}	2025-11-10 11:04:03.002298-06
164	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-24T08:55:07.788", "dah_id": 155, "operation": "ASIGNAR"}	2025-11-10 11:04:03.003968-06
165	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-24T09:36:29.527", "dah_id": 156, "operation": "ASIGNAR"}	2025-11-10 11:04:03.004561-06
166	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-25T09:02:41.923", "dah_id": 159, "operation": "ASIGNAR"}	2025-11-10 11:04:03.006275-06
167	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-25T09:34:12.819", "dah_id": 160, "operation": "ASIGNAR"}	2025-11-10 11:04:03.006868-06
168	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-26T08:46:01.273", "dah_id": 163, "operation": "ASIGNAR"}	2025-11-10 11:04:03.008539-06
169	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-26T08:51:34.061", "dah_id": 164, "operation": "ASIGNAR"}	2025-11-10 11:04:03.009085-06
170	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-27T08:34:04.289", "dah_id": 167, "operation": "ASIGNAR"}	2025-11-10 11:04:03.010747-06
171	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-27T09:06:22.867", "dah_id": 168, "operation": "ASIGNAR"}	2025-11-10 11:04:03.011294-06
172	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-29T09:01:23.765", "dah_id": 171, "operation": "ASIGNAR"}	2025-11-10 11:04:03.01293-06
173	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-29T09:13:41.633", "dah_id": 172, "operation": "ASIGNAR"}	2025-11-10 11:04:03.013474-06
174	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-30T07:34:22.236", "dah_id": 177, "operation": "ASIGNAR"}	2025-11-10 11:04:03.016186-06
175	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-30T09:02:39.518", "dah_id": 178, "operation": "ASIGNAR"}	2025-11-10 11:04:03.016732-06
176	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-30T09:31:01.736", "dah_id": 179, "operation": "ASIGNAR"}	2025-11-10 11:04:03.0173-06
177	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-01T07:32:59.659", "dah_id": 184, "operation": "ASIGNAR"}	2025-11-10 11:04:03.020066-06
178	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-01T07:55:41.608", "dah_id": 185, "operation": "ASIGNAR"}	2025-11-10 11:04:03.020919-06
179	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-01T09:16:09.183", "dah_id": 186, "operation": "ASIGNAR"}	2025-11-10 11:04:03.021469-06
180	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-02T07:53:37.516", "dah_id": 189, "operation": "ASIGNAR"}	2025-11-10 11:04:03.02347-06
181	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-02T08:40:27.388", "dah_id": 190, "operation": "ASIGNAR"}	2025-11-10 11:04:03.02403-06
182	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-02T08:45:53.634", "dah_id": 192, "operation": "ASIGNAR"}	2025-11-10 11:04:03.025165-06
183	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-03T07:22:54.163", "dah_id": 196, "operation": "ASIGNAR"}	2025-11-10 11:04:03.027392-06
184	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-03T08:54:37.023", "dah_id": 197, "operation": "ASIGNAR"}	2025-11-10 11:04:03.027947-06
185	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-03T09:30:34.68", "dah_id": 198, "operation": "ASIGNAR"}	2025-11-10 11:04:03.028503-06
186	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-04T08:37:46.98", "dah_id": 202, "operation": "ASIGNAR"}	2025-11-10 11:04:03.030736-06
187	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-04T08:39:49.896", "dah_id": 203, "operation": "ASIGNAR"}	2025-11-10 11:04:03.031288-06
188	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-06T07:58:10.641", "dah_id": 206, "operation": "ASIGNAR"}	2025-11-10 11:04:03.032948-06
189	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-06T08:19:02.596", "dah_id": 207, "operation": "ASIGNAR"}	2025-11-10 11:04:03.033506-06
190	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-06T08:26:44.277", "dah_id": 208, "operation": "ASIGNAR"}	2025-11-10 11:04:03.034086-06
191	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-07T07:29:05.145", "dah_id": 212, "operation": "ASIGNAR"}	2025-11-10 11:04:03.036343-06
192	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-07T08:50:02.803", "dah_id": 213, "operation": "ASIGNAR"}	2025-11-10 11:04:03.03694-06
193	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-07T08:50:28.769", "dah_id": 214, "operation": "ASIGNAR"}	2025-11-10 11:04:03.037505-06
194	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-08T08:34:05.623", "dah_id": 218, "operation": "ASIGNAR"}	2025-11-10 11:04:03.039779-06
195	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-08T09:58:21.955", "dah_id": 219, "operation": "ASIGNAR"}	2025-11-10 11:04:03.040336-06
196	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-09T08:35:26.563", "dah_id": 222, "operation": "ASIGNAR"}	2025-11-10 11:04:03.042024-06
197	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-09T09:28:19.78", "dah_id": 223, "operation": "ASIGNAR"}	2025-11-10 11:04:03.042599-06
198	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-09T11:17:14.532", "dah_id": 224, "operation": "ASIGNAR"}	2025-11-10 11:04:03.043164-06
199	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-10T07:26:30.415", "dah_id": 228, "operation": "ASIGNAR"}	2025-11-10 11:04:03.045507-06
200	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-10T08:42:13.371", "dah_id": 229, "operation": "ASIGNAR"}	2025-11-10 11:04:03.046069-06
201	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-10T09:32:39.661", "dah_id": 230, "operation": "ASIGNAR"}	2025-11-10 11:04:03.04661-06
202	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-11T08:27:08.465", "dah_id": 234, "operation": "ASIGNAR"}	2025-11-10 11:04:03.048813-06
203	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-11T08:28:34.703", "dah_id": 235, "operation": "ASIGNAR"}	2025-11-10 11:04:03.049359-06
204	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-13T07:19:16.121", "dah_id": 238, "operation": "ASIGNAR"}	2025-11-10 11:04:03.051018-06
205	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-13T08:55:19.487", "dah_id": 239, "operation": "ASIGNAR"}	2025-11-10 11:04:03.051581-06
206	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-13T09:06:33.203", "dah_id": 240, "operation": "ASIGNAR"}	2025-11-10 11:04:03.052124-06
207	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-14T07:14:29.338", "dah_id": 244, "operation": "ASIGNAR"}	2025-11-10 11:04:03.054297-06
208	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-14T08:27:04.537", "dah_id": 245, "operation": "ASIGNAR"}	2025-11-10 11:04:03.054855-06
209	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-14T08:59:01.679", "dah_id": 246, "operation": "ASIGNAR"}	2025-11-10 11:04:03.055389-06
210	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-15T07:36:32.551", "dah_id": 250, "operation": "ASIGNAR"}	2025-11-10 11:04:03.057585-06
211	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-15T08:16:52.894", "dah_id": 251, "operation": "ASIGNAR"}	2025-11-10 11:04:03.058161-06
212	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-15T08:17:38.126", "dah_id": 252, "operation": "ASIGNAR"}	2025-11-10 11:04:03.058707-06
213	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-16T07:06:23.065", "dah_id": 256, "operation": "ASIGNAR"}	2025-11-10 11:04:03.060929-06
214	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-16T07:07:00.96", "dah_id": 258, "operation": "ASIGNAR"}	2025-11-10 11:04:03.062015-06
215	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-16T09:02:43.681", "dah_id": 259, "operation": "ASIGNAR"}	2025-11-10 11:04:03.062558-06
216	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-16T09:03:55.529", "dah_id": 260, "operation": "ASIGNAR"}	2025-11-10 11:04:03.063087-06
217	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-17T08:47:04.893", "dah_id": 263, "operation": "ASIGNAR"}	2025-11-10 11:04:03.064732-06
218	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-17T09:09:49.867", "dah_id": 264, "operation": "ASIGNAR"}	2025-11-10 11:04:03.065308-06
219	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-18T07:55:35.428", "dah_id": 267, "operation": "ASIGNAR"}	2025-11-10 11:04:03.066931-06
220	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-18T07:57:40.291", "dah_id": 268, "operation": "ASIGNAR"}	2025-11-10 11:04:03.067472-06
221	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-20T08:50:42.114", "dah_id": 271, "operation": "ASIGNAR"}	2025-11-10 11:04:03.069104-06
222	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-20T09:05:20.415", "dah_id": 272, "operation": "ASIGNAR"}	2025-11-10 11:04:03.069656-06
223	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-21T08:03:32.316", "dah_id": 275, "operation": "ASIGNAR"}	2025-11-10 11:04:03.071346-06
224	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-21T09:08:10.002", "dah_id": 276, "operation": "ASIGNAR"}	2025-11-10 11:04:03.07188-06
225	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-22T07:03:35.378", "dah_id": 279, "operation": "ASIGNAR"}	2025-11-10 11:04:03.073532-06
226	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-22T08:07:17.347", "dah_id": 280, "operation": "ASIGNAR"}	2025-11-10 11:04:03.074076-06
227	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-23T08:46:48.664", "dah_id": 283, "operation": "ASIGNAR"}	2025-11-10 11:04:03.075721-06
228	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-23T08:11:07.696", "dah_id": 284, "operation": "ASIGNAR"}	2025-11-10 11:04:03.076273-06
229	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-24T07:46:29.323", "dah_id": 287, "operation": "ASIGNAR"}	2025-11-10 11:04:03.077934-06
230	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-24T09:09:40.99", "dah_id": 288, "operation": "ASIGNAR"}	2025-11-10 11:04:03.078487-06
231	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-25T07:18:02.074", "dah_id": 291, "operation": "ASIGNAR"}	2025-11-10 11:04:03.080108-06
232	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-25T08:19:50.827", "dah_id": 292, "operation": "ASIGNAR"}	2025-11-10 11:04:03.080641-06
233	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-27T08:05:39.203", "dah_id": 295, "operation": "ASIGNAR"}	2025-11-10 11:04:03.082316-06
234	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-27T08:26:04.685", "dah_id": 296, "operation": "ASIGNAR"}	2025-11-10 11:04:03.082858-06
235	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-28T07:53:05.069", "dah_id": 299, "operation": "ASIGNAR"}	2025-11-10 11:04:03.084487-06
236	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-28T08:02:53.052", "dah_id": 300, "operation": "ASIGNAR"}	2025-11-10 11:04:03.08503-06
237	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-29T07:29:41.836", "dah_id": 303, "operation": "ASIGNAR"}	2025-11-10 11:04:03.086681-06
238	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-29T07:35:07.677", "dah_id": 304, "operation": "ASIGNAR"}	2025-11-10 11:04:03.087224-06
239	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-30T07:28:49.2", "dah_id": 307, "operation": "ASIGNAR"}	2025-11-10 11:04:03.088873-06
240	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-30T07:31:05.995", "dah_id": 308, "operation": "ASIGNAR"}	2025-11-10 11:04:03.089404-06
241	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-31T08:34:39.643", "dah_id": 311, "operation": "ASIGNAR"}	2025-11-10 11:04:03.091028-06
242	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-31T08:57:00.221", "dah_id": 312, "operation": "ASIGNAR"}	2025-11-10 11:04:03.091566-06
243	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-03T08:01:00.232", "dah_id": 315, "operation": "ASIGNAR"}	2025-11-10 11:04:03.093198-06
244	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-03T08:09:31.024", "dah_id": 316, "operation": "ASIGNAR"}	2025-11-10 11:04:03.093736-06
245	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-03T11:01:13.351", "dah_id": 318, "operation": "ASIGNAR"}	2025-11-10 11:04:03.09486-06
246	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-04T06:56:16.696", "dah_id": 322, "operation": "ASIGNAR"}	2025-11-10 11:04:03.097063-06
247	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-04T07:34:25.306", "dah_id": 323, "operation": "ASIGNAR"}	2025-11-10 11:04:03.097642-06
248	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-04T08:22:36.49", "dah_id": 324, "operation": "ASIGNAR"}	2025-11-10 11:04:03.098175-06
249	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-05T07:49:53.526", "dah_id": 328, "operation": "ASIGNAR"}	2025-11-10 11:04:03.100378-06
250	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-05T08:18:56.19", "dah_id": 329, "operation": "ASIGNAR"}	2025-11-10 11:04:03.100913-06
251	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-06T06:42:10.377", "dah_id": 332, "operation": "ASIGNAR"}	2025-11-10 11:04:03.102525-06
252	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-06T07:58:01.229", "dah_id": 333, "operation": "ASIGNAR"}	2025-11-10 11:04:03.103074-06
253	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-06T08:17:17.669", "dah_id": 334, "operation": "ASIGNAR"}	2025-11-10 11:04:03.103607-06
254	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-06T19:26:17.653", "dah_id": 338, "operation": "ASIGNAR"}	2025-11-10 11:04:03.105821-06
255	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-06T19:40:32.531", "dah_id": 340, "operation": "ASIGNAR"}	2025-11-10 11:04:03.106897-06
256	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-07T06:38:54.435", "dah_id": 342, "operation": "ASIGNAR"}	2025-11-10 11:04:03.107999-06
257	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-07T07:49:48.594", "dah_id": 343, "operation": "ASIGNAR"}	2025-11-10 11:04:03.108556-06
258	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-07T07:52:30.879", "dah_id": 344, "operation": "ASIGNAR"}	2025-11-10 11:04:03.109088-06
259	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-08T07:24:40.261", "dah_id": 348, "operation": "ASIGNAR"}	2025-11-10 11:04:03.111299-06
260	12	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-08T08:00:31.893", "dah_id": 349, "operation": "ASIGNAR"}	2025-11-10 11:04:03.11185-06
261	14	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-08T13:51:13.1", "dah_id": 350, "operation": "ASIGNAR"}	2025-11-10 11:04:03.112406-06
262	11	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-08T15:32:04.991", "dah_id": 353, "operation": "ASIGNAR"}	2025-11-10 11:04:03.114051-06
\.


--
-- TOC entry 5783 (class 0 OID 0)
-- Dependencies: 376
-- Name: auditoria_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('auditoria_id_seq', 79, true);


--
-- TOC entry 5290 (class 0 OID 25565)
-- Dependencies: 377
-- Data for Name: bodega; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY bodega (id, sucursal_id, codigo, nombre) FROM stdin;
\.


--
-- TOC entry 5784 (class 0 OID 0)
-- Dependencies: 378
-- Name: bodega_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('bodega_id_seq', 1, false);


--
-- TOC entry 5292 (class 0 OID 25573)
-- Dependencies: 379
-- Data for Name: cache; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cache (key, value, expiration) FROM stdin;
\.


--
-- TOC entry 5293 (class 0 OID 25579)
-- Dependencies: 380
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cache_locks (key, owner, expiration) FROM stdin;
\.


--
-- TOC entry 5294 (class 0 OID 25585)
-- Dependencies: 381
-- Data for Name: caja_fondo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY caja_fondo (id, sucursal_id, fecha, monto_inicial, moneda, estado, creado_por, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5295 (class 0 OID 25592)
-- Dependencies: 382
-- Data for Name: caja_fondo_adj; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY caja_fondo_adj (id, mov_id, tipo, archivo_url, observaciones, created_at) FROM stdin;
\.


--
-- TOC entry 5785 (class 0 OID 0)
-- Dependencies: 383
-- Name: caja_fondo_adj_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_adj_id_seq', 1, false);


--
-- TOC entry 5297 (class 0 OID 25601)
-- Dependencies: 384
-- Data for Name: caja_fondo_arqueo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY caja_fondo_arqueo (id, fondo_id, fecha_cierre, efectivo_contado, diferencia, observaciones, cerrado_por) FROM stdin;
\.


--
-- TOC entry 5786 (class 0 OID 0)
-- Dependencies: 385
-- Name: caja_fondo_arqueo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_arqueo_id_seq', 1, false);


--
-- TOC entry 5787 (class 0 OID 0)
-- Dependencies: 386
-- Name: caja_fondo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_id_seq', 1, false);


--
-- TOC entry 5300 (class 0 OID 25612)
-- Dependencies: 387
-- Data for Name: caja_fondo_mov; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY caja_fondo_mov (id, fondo_id, fecha_hora, tipo, concepto, proveedor_id, monto, metodo, requiere_comprobante, estatus, creado_por, aprobado_por, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5788 (class 0 OID 0)
-- Dependencies: 388
-- Name: caja_fondo_mov_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_mov_id_seq', 1, false);


--
-- TOC entry 5302 (class 0 OID 25626)
-- Dependencies: 389
-- Data for Name: caja_fondo_usuario; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY caja_fondo_usuario (fondo_id, user_id, rol) FROM stdin;
\.


--
-- TOC entry 5303 (class 0 OID 25629)
-- Dependencies: 390
-- Data for Name: cash_fund_arqueos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cash_fund_arqueos (id, cash_fund_id, monto_esperado, monto_contado, diferencia, observaciones, created_by_user_id, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5789 (class 0 OID 0)
-- Dependencies: 391
-- Name: cash_fund_arqueos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_fund_arqueos_id_seq', 1, false);


--
-- TOC entry 5305 (class 0 OID 25637)
-- Dependencies: 392
-- Data for Name: cash_fund_movement_audit_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cash_fund_movement_audit_log (id, movement_id, action, field_changed, old_value, new_value, observaciones, changed_by_user_id, created_at) FROM stdin;
\.


--
-- TOC entry 5790 (class 0 OID 0)
-- Dependencies: 393
-- Name: cash_fund_movement_audit_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_fund_movement_audit_log_id_seq', 1, false);


--
-- TOC entry 5307 (class 0 OID 25646)
-- Dependencies: 394
-- Data for Name: cash_fund_movements; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cash_fund_movements (id, cash_fund_id, tipo, concepto, proveedor_id, monto, metodo, estatus, requiere_comprobante, tiene_comprobante, adjunto_path, created_by_user_id, approved_by_user_id, approved_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5791 (class 0 OID 0)
-- Dependencies: 395
-- Name: cash_fund_movements_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_fund_movements_id_seq', 1, false);


--
-- TOC entry 5309 (class 0 OID 25660)
-- Dependencies: 396
-- Data for Name: cash_funds; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cash_funds (id, sucursal_id, fecha, monto_inicial, moneda, estado, responsable_user_id, created_by_user_id, closed_at, created_at, updated_at, descripcion) FROM stdin;
\.


--
-- TOC entry 5792 (class 0 OID 0)
-- Dependencies: 397
-- Name: cash_funds_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_funds_id_seq', 1, false);


--
-- TOC entry 5311 (class 0 OID 25671)
-- Dependencies: 398
-- Data for Name: cat_almacenes; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cat_almacenes (id, clave, nombre, sucursal_id, activo, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5793 (class 0 OID 0)
-- Dependencies: 399
-- Name: cat_almacenes_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_almacenes_id_seq', 2, true);


--
-- TOC entry 5313 (class 0 OID 25677)
-- Dependencies: 400
-- Data for Name: cat_proveedores; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cat_proveedores (id, rfc, nombre, telefono, email, activo, created_at, updated_at, razon_social, tipo_comprobante, uso_cfdi, metodo_pago, forma_pago, regimen_fiscal, contacto_nombre, contacto_email, contacto_telefono, direccion, ciudad, estado, pais, cp, notas) FROM stdin;
1	XAXX010101000-U1	URBANO CASTILLO CENTRAL DE ABASTOS	\N	\N	t	2025-11-02 20:23:53	2025-11-02 20:23:53	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2	AFA8807024B1	Abarrotes Fasti S.A. de C.V.	\N	\N	t	2025-11-02 20:24:42	2025-11-02 20:24:42	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
3	NWM9709244W4	Sam''s Club México.	\N	\N	t	2025-11-02 20:24:55	2025-11-02 20:24:55	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
4	CCA8805089W1	Costco de México	\N	\N	t	2025-11-02 20:25:06	2025-11-02 20:25:06	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5	CCO670202HB7	Coca-Cola Femsa Veracruz	\N	\N	t	2025-11-02 20:25:17	2025-11-02 20:25:17	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6	DCO100916H51	Distribuidora Comercial Oriental	\N	\N	t	2025-11-02 20:25:37	2025-11-02 20:25:37	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7	BIM4601016X8	Grupo Bimbo	\N	\N	t	2025-11-02 20:25:47	2025-11-02 20:25:47	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8	CHE8507029B1	Chedraui Veracruz filial	\N	\N	t	2025-11-02 20:25:59	2025-11-02 20:25:59	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9	LJO9201012B1	Quesos La Joya Liz S.A. de C.V.	\N	\N	t	2025-11-02 20:26:08	2025-11-02 20:26:08	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
10	XAXX010101000-MP	MATERIAS PRIMAS LA AZTECA	\N	\N	t	2025-11-02 20:26:21	2025-11-02 20:26:21	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
11	XAXX010101000-CP	COAPEXPAN CARNES FRIAS	\N	\N	t	2025-11-02 20:26:34	2025-11-02 20:26:34	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
12	OFS000526912	EL BODEGON DE SEMILLAS, S.A. DE C.V.	\N	\N	t	2025-11-02 20:26:45	2025-11-02 20:26:45	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
13	XAXX010101000-FC	FERCAS	\N	\N	t	2025-11-02 20:26:59	2025-11-02 20:26:59	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
14	XAXX010101000-FR	FRUTA	\N	\N	t	2025-11-02 20:27:10	2025-11-02 20:27:10	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
15	XAXX010101000-PK	PANADERIA KAREN	\N	\N	t	2025-11-02 20:27:22	2025-11-02 20:27:22	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
16	XAXX010101000-GN	GENERICO	\N	\N	t	2025-11-02 20:27:41	2025-11-02 20:27:41	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
17	XAXX010101000-SL	SAN LUIS	\N	\N	t	2025-11-02 20:27:54	2025-11-02 20:27:54	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
18	XAXX010101000-PE	POLLERIA EL DORADO	\N	\N	t	2025-11-02 20:28:10	2025-11-02 20:28:10	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
19	XAXX010101000-QV	QUESOS Y ABARROTES VERONICA	\N	\N	t	2025-11-02 20:28:22	2025-11-02 20:28:22	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
20	XAXX010101000-VD	VERDURAS	\N	\N	t	2025-11-02 20:28:32	2025-11-02 20:28:32	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- TOC entry 5794 (class 0 OID 0)
-- Dependencies: 401
-- Name: cat_proveedores_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_proveedores_id_seq', 20, true);


--
-- TOC entry 5315 (class 0 OID 25686)
-- Dependencies: 402
-- Data for Name: cat_sucursales; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cat_sucursales (id, clave, nombre, ubicacion, activo, created_at, updated_at, pos_location) FROM stdin;
1	PRINCIPAL	Sucursal Principal	Ubicacion Principal	t	2025-11-02 12:35:41	2025-11-02 12:35:41	PRINCIPAL
2	NB	Sucursal NB	Ubicacion NB	t	2025-11-02 12:35:41	2025-11-02 12:35:41	NB
3	TORRE	Sucursal Torre	Ubicacion Torre	t	2025-11-02 12:35:41	2025-11-02 12:35:41	TORRE
4	SUCURS	Sucursal Entrada	\N	t	2025-11-02 20:19:40	2025-11-02 20:19:40	ENTRADA
5	SUCURS1	Sucursal Selemti	Pruebas	t	2025-11-02 20:19:57	2025-11-02 20:19:57	SelemTI
\.


--
-- TOC entry 5795 (class 0 OID 0)
-- Dependencies: 403
-- Name: cat_sucursales_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_sucursales_id_seq', 5, true);


--
-- TOC entry 5317 (class 0 OID 25692)
-- Dependencies: 404
-- Data for Name: cat_unidades; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cat_unidades (id, created_at, updated_at, clave, nombre, activo, categoria) FROM stdin;
1	2025-11-02 20:38:36	2025-11-02 20:38:36	KG	Kilogramo	t	BASE
2	2025-11-02 20:38:36	2025-11-02 20:38:36	L	Litro	t	BASE
3	2025-11-02 20:38:36	2025-11-02 20:38:36	PZ	Pieza	t	BASE
4	2025-11-02 20:38:36	2025-11-02 20:38:36	G	Gramo	t	COCINA
5	2025-11-02 20:38:36	2025-11-02 20:38:36	MG	Miligramo	t	COCINA
6	2025-11-02 20:38:36	2025-11-02 20:38:36	ML	Mililitro	t	COCINA
7	2025-11-02 20:38:36	2025-11-02 20:38:36	TAZA	Taza	t	COCINA
8	2025-11-02 20:38:36	2025-11-02 20:38:36	CUCH	Cucharada	t	COCINA
9	2025-11-02 20:38:36	2025-11-02 20:38:36	CUCHT	Cucharadita	t	COCINA
10	2025-11-02 20:38:36	2025-11-02 20:38:36	PIZCA	Pizca	t	COCINA
11	2025-11-02 20:38:36	2025-11-02 20:38:36	VASO	Vaso	t	COCINA
12	2025-11-02 20:38:36	2025-11-02 20:38:36	CAJA	Caja	t	COMPRA
13	2025-11-02 20:38:36	2025-11-02 20:38:36	COSTAL	Costal	t	COMPRA
14	2025-11-02 20:38:36	2025-11-02 20:38:36	BOTELLA	Botella	t	COMPRA
15	2025-11-02 20:38:36	2025-11-02 20:38:36	GARRAFA	Garrafón	t	COMPRA
16	2025-11-02 20:38:36	2025-11-02 20:38:36	PAQUETE	Paquete	t	COMPRA
17	2025-11-02 20:38:36	2025-11-02 20:38:36	CHAROLA	Charola	t	COMPRA
18	2025-11-02 20:38:36	2025-11-02 20:38:36	BOLSA	Bolsa	t	COMPRA
19	2025-11-02 20:38:36	2025-11-02 20:38:36	BOTE	Bote	t	COMPRA
20	2025-11-02 20:38:36	2025-11-02 20:38:36	LATA	Lata	t	COMPRA
21	2025-11-02 20:38:36	2025-11-02 20:38:36	FRASCO	Frasco	t	COMPRA
22	2025-11-02 20:38:36	2025-11-02 20:38:36	PORCION	Porción	t	PORCION
23	2025-11-02 20:38:36	2025-11-02 20:38:36	RACION	Ración	t	PORCION
24	2025-11-02 20:38:36	2025-11-02 20:38:36	REBANADA	Rebanada	t	PORCION
25	2025-11-02 20:38:36	2025-11-02 20:38:36	PLATO	Plato	t	PORCION
26	2025-11-02 20:38:36	2025-11-02 20:38:36	ORDEN	Orden	t	PORCION
\.


--
-- TOC entry 5796 (class 0 OID 0)
-- Dependencies: 405
-- Name: cat_unidades_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_unidades_id_seq', 26, true);


--
-- TOC entry 5319 (class 0 OID 25698)
-- Dependencies: 406
-- Data for Name: cat_uom_conversion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cat_uom_conversion (id, origen_id, destino_id, factor, created_at, updated_at, is_exact, scope, notes) FROM stdin;
1	4	1	0.001000	2025-11-02 20:53:00	2025-11-02 20:53:00	t	global	Conversión estándar: 1 gramo = 0.001 kg
2	5	1	0.000001	2025-11-02 20:53:00	2025-11-02 20:53:00	t	global	Conversión estándar: 1 miligramo = 0.000001 kg
3	10	1	0.000500	2025-11-02 20:53:00	2025-11-02 20:53:00	f	global	Aproximado: 1 pizca ≈ 0.5 gramos (0.0005 kg)
4	6	2	0.001000	2025-11-02 20:53:00	2025-11-02 20:53:00	t	global	Conversión estándar: 1 mililitro = 0.001 litros
5	7	2	0.240000	2025-11-02 20:53:00	2025-11-02 20:53:00	t	global	Taza estándar: 1 taza = 240 ml = 0.240 litros
6	8	2	0.015000	2025-11-02 20:53:00	2025-11-02 20:53:00	t	global	Cucharada estándar: 1 cucharada = 15 ml = 0.015 litros
7	9	2	0.005000	2025-11-02 20:53:00	2025-11-02 20:53:00	t	global	Cucharadita estándar: 1 cucharadita = 5 ml = 0.005 litros
8	11	2	0.250000	2025-11-02 20:53:00	2025-11-02 20:53:00	t	global	Vaso estándar: 1 vaso = 250 ml = 0.250 litros
9	1	4	1000.000000	2025-11-02 20:53:00	2025-11-02 20:53:00	t	global	Conversión inversa: 1 kg = 1000 gramos
10	2	6	1000.000000	2025-11-02 20:53:00	2025-11-02 20:53:00	t	global	Conversión inversa: 1 litro = 1000 mililitros
\.


--
-- TOC entry 5797 (class 0 OID 0)
-- Dependencies: 407
-- Name: cat_uom_conversion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_uom_conversion_id_seq', 10, true);


--
-- TOC entry 5321 (class 0 OID 25708)
-- Dependencies: 408
-- Data for Name: conciliacion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY conciliacion (id, postcorte_id, conciliado_por, conciliado_en, estatus, notas) FROM stdin;
\.


--
-- TOC entry 5798 (class 0 OID 0)
-- Dependencies: 409
-- Name: conciliacion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('conciliacion_id_seq', 1, false);


--
-- TOC entry 5799 (class 0 OID 0)
-- Dependencies: 412
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('conversiones_unidad_id_seq', 1, false);


--
-- TOC entry 5323 (class 0 OID 25723)
-- Dependencies: 411
-- Data for Name: conversiones_unidad_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY conversiones_unidad_legacy (id, unidad_origen_id, unidad_destino_id, factor_conversion, formula_directa, precision_estimada, activo, created_at) FROM stdin;
\.


--
-- TOC entry 5325 (class 0 OID 25736)
-- Dependencies: 413
-- Data for Name: cost_layer; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cost_layer (id, item_id, batch_id, ts_in, qty_in, qty_left, unit_cost, sucursal_id, source_ref, source_id) FROM stdin;
\.


--
-- TOC entry 5800 (class 0 OID 0)
-- Dependencies: 414
-- Name: cost_layer_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cost_layer_id_seq', 1, false);


--
-- TOC entry 5327 (class 0 OID 25744)
-- Dependencies: 415
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- TOC entry 5801 (class 0 OID 0)
-- Dependencies: 416
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('failed_jobs_id_seq', 1, false);


--
-- TOC entry 5329 (class 0 OID 25753)
-- Dependencies: 417
-- Data for Name: formas_pago; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

COPY formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) FROM stdin;
1	CASH	CASH	\N	\N	\N	\N	t	100	2025-09-17 07:40:57.876762-06
2	CREDIT	CREDIT	\N	\N	\N	\N	t	100	2025-09-17 07:40:57.876762-06
3	DEBIT	DEBIT	\N	\N	\N	\N	t	100	2025-09-17 07:40:57.876762-06
4	TRANSFER	TRANSFER	\N	\N	\N	\N	t	100	2025-09-17 07:40:57.876762-06
5	REFUND	REFUND	\N	\N	\N	\N	t	100	2025-09-17 07:40:57.876762-06
6	PAY_OUT	PAY_OUT	\N	\N	\N	\N	t	100	2025-09-17 07:40:57.876762-06
7	CASH_DROP	CASH_DROP	\N	\N	\N	\N	t	100	2025-09-17 07:40:57.876762-06
8	CREDIT_CARD	CREDIT_CARD	CREDIT	VISA	\N	\N	t	100	2025-09-17 08:06:09.509102-06
9	CASH	CASH	CREDIT	CASH	\N	\N	t	100	2025-09-17 08:10:09.104336-06
343	DEBIT_CARD	DEBIT_CARD	CREDIT	MASTER CARD	\N	\N	t	100	2025-09-17 14:35:19.713525-06
1117	CREDIT_CARD	CREDIT_CARD	CREDIT	MASTER CARD	\N	\N	t	100	2025-09-19 10:43:16.717348-06
1591	REFUND	REFUND	DEBIT	CASH	\N	\N	t	100	2025-09-20 15:43:46.046399-06
1592	VOID_TRANS	VOID_TRANS	DEBIT	CASH	\N	\N	t	100	2025-09-20 15:43:46.046399-06
1675	DEBIT_CARD	DEBIT_CARD	CREDIT	VISA	\N	\N	t	100	2025-09-22 09:04:31.673494-06
12351	CUSTOM:tranferencia	CUSTOM_PAYMENT	CREDIT	CUSTOM PAYMENT	Tranferencia	1	t	100	2025-10-20 10:37:17.050812-06
17997	CREDIT_CARD	CREDIT_CARD	CREDIT	AMEX	\N	\N	t	100	2025-11-08 09:37:14.67681-06
19034	CUSTOM:tranferencia	CUSTOM_PAYMENT	CREDIT	CUSTOM PAYMENT	Tranferencia	PAMELA U.	t	100	2025-11-10 11:04:39.773392-06
21022	CUSTOM:tranferencia	CUSTOM_PAYMENT	CREDIT	CUSTOM PAYMENT	Tranferencia	MAEL GARCIA SANCHEZ	t	100	2025-11-10 11:04:40.982901-06
22749	PAY_OUT	PAY_OUT	DEBIT	CASH	\N	\N	t	100	2025-11-21 16:39:59.070768-06
\.


--
-- TOC entry 5802 (class 0 OID 0)
-- Dependencies: 418
-- Name: formas_pago_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('formas_pago_id_seq', 29143, true);


--
-- TOC entry 5331 (class 0 OID 25764)
-- Dependencies: 419
-- Data for Name: hist_cost_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY hist_cost_insumo (id, item_id, fecha_efectiva, costo_wac, costo_peps, costo_ueps, costo_std, algoritmo_principal, valid_from, valid_to, sys_from, sys_to, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5803 (class 0 OID 0)
-- Dependencies: 420
-- Name: hist_cost_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('hist_cost_insumo_id_seq', 1, false);


--
-- TOC entry 5333 (class 0 OID 25777)
-- Dependencies: 421
-- Data for Name: hist_cost_receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY hist_cost_receta (id, receta_version_id, fecha_calculo, costo_total, costo_porcion, algoritmo_utilizado, valid_from, valid_to, sys_from, sys_to) FROM stdin;
\.


--
-- TOC entry 5804 (class 0 OID 0)
-- Dependencies: 422
-- Name: hist_cost_receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('hist_cost_receta_id_seq', 1, false);


--
-- TOC entry 5335 (class 0 OID 25788)
-- Dependencies: 423
-- Data for Name: historial_costos_item; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY historial_costos_item (id, item_id, fecha_efectiva, fecha_registro, costo_anterior, costo_nuevo, tipo_cambio, referencia_id, referencia_tipo, usuario_id, valid_from, valid_to, sys_from, sys_to, costo_wac, costo_peps, costo_ueps, costo_estandar, algoritmo_principal, version_datos, recalculado, fuente_datos, metadata_calculo, created_at) FROM stdin;
\.


--
-- TOC entry 5805 (class 0 OID 0)
-- Dependencies: 424
-- Name: historial_costos_item_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('historial_costos_item_id_seq', 1, false);


--
-- TOC entry 5337 (class 0 OID 25805)
-- Dependencies: 425
-- Data for Name: historial_costos_receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY historial_costos_receta (id, receta_version_id, fecha_calculo, costo_total, costo_porcion, algoritmo_utilizado, version_datos, metadata_calculo, created_at, valid_from, valid_to, sys_from, sys_to) FROM stdin;
\.


--
-- TOC entry 5806 (class 0 OID 0)
-- Dependencies: 426
-- Name: historial_costos_receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('historial_costos_receta_id_seq', 1, false);


--
-- TOC entry 5339 (class 0 OID 25816)
-- Dependencies: 427
-- Data for Name: insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY insumo (id, sku, nombre, um_id, perecible, merma_pct, activo, meta, codigo, categoria_codigo, subcategoria_codigo, consecutivo, codigo_alterno) FROM stdin;
\.


--
-- TOC entry 5807 (class 0 OID 0)
-- Dependencies: 428
-- Name: insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('insumo_id_seq', 1, false);


--
-- TOC entry 5341 (class 0 OID 25827)
-- Dependencies: 429
-- Data for Name: insumo_presentacion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY insumo_presentacion (id, item_id, proveedor_id, um_compra_id, factor_a_um, costo_ultimo, activo, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5808 (class 0 OID 0)
-- Dependencies: 430
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('insumo_presentacion_id_seq', 1, false);


--
-- TOC entry 5343 (class 0 OID 25837)
-- Dependencies: 431
-- Data for Name: insumo_proveedor_presentacion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY insumo_proveedor_presentacion (id, item_id, proveedor_id, uom_compra_id, cantidad_en_uom_compra, uom_base_id, factor_a_base, precio_compra, moneda, activo, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5809 (class 0 OID 0)
-- Dependencies: 432
-- Name: insumo_proveedor_presentacion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('insumo_proveedor_presentacion_id_seq', 1, false);


--
-- TOC entry 5345 (class 0 OID 25851)
-- Dependencies: 433
-- Data for Name: inv_consumo_pos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inv_consumo_pos (id, ticket_id, ticket_item_id, sucursal_id, terminal_id, estado, created_at, requiere_reproceso, procesado, fecha_proceso, revertido) FROM stdin;
\.


--
-- TOC entry 5346 (class 0 OID 25859)
-- Dependencies: 434
-- Data for Name: inv_consumo_pos_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inv_consumo_pos_det (id, consumo_id, mp_id, uom_id, cantidad, factor, origen, requiere_reproceso, procesado, fecha_proceso, revertido) FROM stdin;
\.


--
-- TOC entry 5810 (class 0 OID 0)
-- Dependencies: 435
-- Name: inv_consumo_pos_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_consumo_pos_det_id_seq', 1, false);


--
-- TOC entry 5811 (class 0 OID 0)
-- Dependencies: 436
-- Name: inv_consumo_pos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_consumo_pos_id_seq', 1, false);


--
-- TOC entry 5349 (class 0 OID 25870)
-- Dependencies: 437
-- Data for Name: inv_consumo_pos_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inv_consumo_pos_log (id, ticket_id, accion, registrado_en, payload) FROM stdin;
\.


--
-- TOC entry 5812 (class 0 OID 0)
-- Dependencies: 438
-- Name: inv_consumo_pos_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_consumo_pos_log_id_seq', 1, false);


--
-- TOC entry 5351 (class 0 OID 25879)
-- Dependencies: 439
-- Data for Name: inv_stock_policy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inv_stock_policy (id, item_id, sucursal_id, min_qty, max_qty, reorder_qty, activo, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5813 (class 0 OID 0)
-- Dependencies: 440
-- Name: inv_stock_policy_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_stock_policy_id_seq', 1, false);


--
-- TOC entry 5353 (class 0 OID 25888)
-- Dependencies: 441
-- Data for Name: inventory_batch; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inventory_batch (id, item_id, lote_proveedor, fecha_recepcion, fecha_caducidad, temperatura_recepcion, documento_url, cantidad_original, cantidad_actual, estado, ubicacion_id, created_at, updated_at, unit_cost) FROM stdin;
\.


--
-- TOC entry 5814 (class 0 OID 0)
-- Dependencies: 442
-- Name: inventory_batch_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_batch_id_seq', 1, false);


--
-- TOC entry 5355 (class 0 OID 25904)
-- Dependencies: 443
-- Data for Name: inventory_count_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inventory_count_lines (id, inventory_count_id, item_id, inventory_batch_id, qty_teorica, qty_contada, qty_variacion, uom, motivo, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5815 (class 0 OID 0)
-- Dependencies: 444
-- Name: inventory_count_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_count_lines_id_seq', 1, false);


--
-- TOC entry 5357 (class 0 OID 25915)
-- Dependencies: 445
-- Data for Name: inventory_counts; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inventory_counts (id, folio, sucursal_id, almacen_id, programado_para, iniciado_en, cerrado_en, estado, creado_por, cerrado_por, notas, total_items, total_variacion, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5816 (class 0 OID 0)
-- Dependencies: 446
-- Name: inventory_counts_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_counts_id_seq', 1, false);


--
-- TOC entry 5359 (class 0 OID 25926)
-- Dependencies: 447
-- Data for Name: inventory_snapshot; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inventory_snapshot (snapshot_date, branch_id, item_id, teorico_qty, fisico_qty, teorico_cost, valor_teorico, variance_qty, variance_cost, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5360 (class 0 OID 25935)
-- Dependencies: 448
-- Data for Name: inventory_wastes; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inventory_wastes (id, production_order_id, item_id, inventory_batch_id, qty, uom, motivo, sucursal_id, almacen_id, user_id, ref_tipo, ref_id, registrado_en, meta, notas, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5817 (class 0 OID 0)
-- Dependencies: 449
-- Name: inventory_wastes_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_wastes_id_seq', 1, false);


--
-- TOC entry 5362 (class 0 OID 25944)
-- Dependencies: 450
-- Data for Name: item_categories; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY item_categories (id, nombre, slug, codigo, descripcion, activo, prefijo, created_at, updated_at) FROM stdin;
7	Abarrotes	\N	CAT-0007	Productos de abarrotes y despensa	t	\N	2025-11-03 10:45:00	2025-11-03 10:45:00
8	Lácteos	\N	CAT-0008	Productos lácteos y derivados	t	\N	2025-11-03 10:45:00	2025-11-03 10:45:00
9	Abarrotes	\N	CAT-0009	Productos de abarrotes y despensa	t	\N	2025-11-03 10:48:23	2025-11-03 10:48:23
10	Lácteos	\N	CAT-0010	Productos lácteos y derivados	t	\N	2025-11-03 10:48:23	2025-11-03 10:48:23
11	CAT-ABARR	cat-abarr	CAT-ABARR	\N	t	\N	2025-11-05 03:29:35	2025-11-05 03:29:35
12	CAT-LACT	cat-lact	CAT-LACT	\N	t	\N	2025-11-05 03:29:35	2025-11-05 03:29:35
\.


--
-- TOC entry 5818 (class 0 OID 0)
-- Dependencies: 451
-- Name: item_categories_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('item_categories_id_seq', 12, true);


--
-- TOC entry 5364 (class 0 OID 25953)
-- Dependencies: 452
-- Data for Name: item_category_counters; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY item_category_counters (category_id, last_val, updated_at) FROM stdin;
11	4	2025-11-10 17:16:51
12	8	2025-11-10 17:16:51
\.


--
-- TOC entry 5365 (class 0 OID 25957)
-- Dependencies: 453
-- Data for Name: item_vendor; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY item_vendor (item_id, vendor_id, presentacion, unidad_presentacion_id, factor_a_canonica, costo_ultimo, moneda, lead_time_dias, codigo_proveedor, activo, created_at, preferente, vendor_sku, vendor_descripcion, currency_code, lead_time_days, min_order_qty, pack_qty, pack_uom) FROM stdin;
\.


--
-- TOC entry 5366 (class 0 OID 25969)
-- Dependencies: 454
-- Data for Name: item_vendor_prices; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY item_vendor_prices (id, item_id, vendor_id, price, currency_code, pack_qty, pack_uom, notes, source, effective_from, effective_to, created_by, created_at) FROM stdin;
\.


--
-- TOC entry 5819 (class 0 OID 0)
-- Dependencies: 455
-- Name: item_vendor_prices_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('item_vendor_prices_id_seq', 1, false);


--
-- TOC entry 5368 (class 0 OID 25981)
-- Dependencies: 456
-- Data for Name: items; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY items (id, nombre, descripcion, categoria_id, unidad_medida, perishable, temperatura_min, temperatura_max, costo_promedio, activo, created_at, updated_at, unidad_medida_id, factor_conversion, unidad_compra_id, factor_compra, tipo, unidad_salida_id, category_id, item_code, es_producible, es_consumible_operativo, es_empaque_to_go) FROM stdin;
LECHE-MEMBERS-01	Leche Deslactosada Member's Mark	Leche deslactosada reducida en lactosa	CAT-LACT	L	t	2	8	220.00	t	2025-11-03 10:48:23.476701	2025-11-03 14:26:39	2	1.000000	12	12.000000	MATERIA_PRIMA	\N	12	C-00005	f	f	f
LECHE-MEM-01	Leche Deslactosada Member's Mark	Leche deslactosada reducida en lactosa	CAT-LACT	L	t	2	8	220.00	t	2025-11-03 10:44:59.528047	2025-11-03 14:26:39	2	1.000000	\N	1.000000	MATERIA_PRIMA	\N	12	C-00006	f	f	f
LECHE-NUTRI-01	Producto Lácteo Nutri Deslactosada	Producto lácteo deslactosado sabor natural	CAT-LACT	L	t	2	8	280.00	t	2025-11-03 10:48:23.476701	2025-11-03 14:26:39	2	1.000000	12	18.000000	MATERIA_PRIMA	\N	12	C-00007	f	f	f
ACEITE-NUTRIOLI-01	Aceite de Soya Nutrioli	Aceite vegetal de soya 100% puro	CAT-ABARR	L	f	\N	\N	150.00	t	2025-11-03 10:48:23.476701	2025-11-03 14:26:39	2	1.000000	16	2.838000	MATERIA_PRIMA	\N	11	C-00003	f	f	f
ACEITE-NUT-01	Aceite de Soya Nutrioli	Aceite vegetal de soya 100% puro	CAT-ABARR	L	f	\N	\N	150.00	t	2025-11-03 10:44:59.528047	2025-11-03 14:26:39	2	1.000000	\N	1.000000	MATERIA_PRIMA	\N	11	C-00004	f	f	f
LECHE-NUT-01	Producto Lácteo Nutri Deslactosada	Producto lácteo deslactosado sabor natural	CAT-LACT	L	t	2	8	280.00	t	2025-11-03 10:44:59.528047	2025-11-03 14:26:39	2	1.000000	\N	1.000000	MATERIA_PRIMA	\N	12	C-00008	f	f	f
\.


--
-- TOC entry 5369 (class 0 OID 26004)
-- Dependencies: 457
-- Data for Name: job_batches; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- TOC entry 5370 (class 0 OID 26010)
-- Dependencies: 458
-- Data for Name: job_recalc_queue; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY job_recalc_queue (id, scope_type, scope_from, scope_to, item_id, receta_id, sucursal_id, reason, created_ts, status, result) FROM stdin;
\.


--
-- TOC entry 5820 (class 0 OID 0)
-- Dependencies: 459
-- Name: job_recalc_queue_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('job_recalc_queue_id_seq', 1, false);


--
-- TOC entry 5372 (class 0 OID 26022)
-- Dependencies: 460
-- Data for Name: jobs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- TOC entry 5821 (class 0 OID 0)
-- Dependencies: 461
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('jobs_id_seq', 1, false);


--
-- TOC entry 5374 (class 0 OID 26030)
-- Dependencies: 462
-- Data for Name: labor_roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY labor_roles (id, clave, nombre, rate_per_hour, activo, descripcion, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5822 (class 0 OID 0)
-- Dependencies: 463
-- Name: labor_roles_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('labor_roles_id_seq', 1, false);


--
-- TOC entry 5376 (class 0 OID 26040)
-- Dependencies: 464
-- Data for Name: lote; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY lote (id, item_id, proveedor_id, codigo, caducidad, estado, creado_ts) FROM stdin;
\.


--
-- TOC entry 5823 (class 0 OID 0)
-- Dependencies: 465
-- Name: lote_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('lote_id_seq', 1, false);


--
-- TOC entry 5378 (class 0 OID 26050)
-- Dependencies: 466
-- Data for Name: menu_engineering_snapshots; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY menu_engineering_snapshots (id, menu_item_id, period_start, period_end, units_sold, net_sales, food_cost, contribution, avg_price, avg_cost, margin_pct, popularity_index, classification, metadata, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5824 (class 0 OID 0)
-- Dependencies: 467
-- Name: menu_engineering_snapshots_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('menu_engineering_snapshots_id_seq', 1, false);


--
-- TOC entry 5380 (class 0 OID 26066)
-- Dependencies: 468
-- Data for Name: menu_item_sync_map; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY menu_item_sync_map (id, menu_item_id, pos_identifier, channel, metadata, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5825 (class 0 OID 0)
-- Dependencies: 469
-- Name: menu_item_sync_map_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('menu_item_sync_map_id_seq', 1, false);


--
-- TOC entry 5382 (class 0 OID 26075)
-- Dependencies: 470
-- Data for Name: menu_items; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY menu_items (id, recipe_id, plu, name, category, active, metadata, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5826 (class 0 OID 0)
-- Dependencies: 471
-- Name: menu_items_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('menu_items_id_seq', 1, false);


--
-- TOC entry 5384 (class 0 OID 26084)
-- Dependencies: 472
-- Data for Name: merma; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY merma (id, ts, tipo, item_id, batch_id, op_id, qty, um_id, usuario_id, motivo, meta, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5827 (class 0 OID 0)
-- Dependencies: 473
-- Name: merma_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('merma_id_seq', 1, false);


--
-- TOC entry 5386 (class 0 OID 26095)
-- Dependencies: 474
-- Data for Name: migrations; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY migrations (id, migration, batch) FROM stdin;
1	0001_01_01_000000_create_users_table	1
2	0001_01_01_000001_create_cache_table	1
3	0001_01_01_000002_create_jobs_table	1
4	2025_01_12_000000_add_preferente_to_selemti_item_vendor	1
5	2025_01_23_100000_create_cash_funds_table	1
6	2025_01_23_100001_create_cash_fund_movements_table	1
7	2025_01_23_100002_create_cash_fund_arqueos_table	1
8	2025_01_23_110000_create_cash_fund_movement_audit_log_table	1
9	2025_09_26_090415_create_cat_unidades_table	1
10	2025_09_26_090657_create_cat_unidades_table	1
11	2025_09_26_205955_create_permission_tables	1
12	2025_10_18_000001_create_cat_sucursales_table	1
13	2025_10_18_000002_create_cat_almacenes_table	1
14	2025_10_18_000003_create_cat_proveedores_table	1
15	2025_10_18_000004_create_cat_uom_conversion_table	1
16	2025_10_18_000005_create_inv_stock_policy_table	1
17	2025_10_19_000001_update_cat_unidades_structure	1
18	2025_10_21_100100_alter_cat_proveedores_add_fields	1
19	2025_10_21_100200_alter_item_vendor_add_vendor_sku	1
20	2025_10_21_123344_add_preferente_to_selemti_item_vendor	1
21	2025_10_21_180000_create_item_categories	1
22	2025_10_21_180100_backfill_item_categories	1
23	2025_10_21_180200_ensure_items_id_autoincrement	1
24	2025_10_21_190100_alter_items_add_item_code	1
25	2025_10_21_190200_item_code_trigger_and_counter	1
26	2025_10_21_190300_backfill_item_codes	1
27	2025_10_21_200000_create_item_vendor_prices	1
28	2025_10_21_200100_fn_item_cost_at	1
29	2025_10_21_200200_recipe_versioning_and_history	1
30	2025_10_21_200300_fn_recipe_cost_at	1
31	2025_10_21_200400_sp_snapshot_recipe_cost	1
32	2025_10_21_200500_alert_rules_and_events	1
33	2025_10_21_200500_create_item_last_price_views	1
34	2025_10_21_200600_trg_on_price_change_alerts	1
35	2025_10_23_154901_add_descripcion_to_cash_funds_table	1
\.


--
-- TOC entry 5828 (class 0 OID 0)
-- Dependencies: 475
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('migrations_id_seq', 79, true);


--
-- TOC entry 5388 (class 0 OID 26100)
-- Dependencies: 476
-- Data for Name: model_has_permissions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY model_has_permissions (permission_id, model_type, model_id) FROM stdin;
\.


--
-- TOC entry 5389 (class 0 OID 26103)
-- Dependencies: 477
-- Data for Name: model_has_roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY model_has_roles (role_id, model_type, model_id) FROM stdin;
1	App\\Models\\User	3
6	App\\Models\\User	4
6	App\\Models\\User	5
6	App\\Models\\User	6
6	App\\Models\\User	8
6	App\\Models\\User	10
6	App\\Models\\User	7
6	App\\Models\\User	9
\.


--
-- TOC entry 5390 (class 0 OID 26106)
-- Dependencies: 478
-- Data for Name: modificadores_pos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) FROM stdin;
\.


--
-- TOC entry 5829 (class 0 OID 0)
-- Dependencies: 479
-- Name: modificadores_pos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('modificadores_pos_id_seq', 1, false);


--
-- TOC entry 5392 (class 0 OID 26114)
-- Dependencies: 480
-- Data for Name: mov_inv; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY mov_inv (id, ts, item_id, lote_id, cantidad, qty_original, uom_original_id, costo_unit, tipo, ref_tipo, ref_id, sucursal_id, usuario_id, created_at) FROM stdin;
\.


--
-- TOC entry 5830 (class 0 OID 0)
-- Dependencies: 481
-- Name: mov_inv_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('mov_inv_id_seq', 1, false);


--
-- TOC entry 5399 (class 0 OID 26170)
-- Dependencies: 487
-- Data for Name: op_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY op_cab (id, sucursal_id, receta_version_id, cantidad_objetivo, um_salida_id, estado, ts_apertura, ts_cierre, usuario_abre, usuario_cierra, lote_salida_id, meta, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5831 (class 0 OID 0)
-- Dependencies: 488
-- Name: op_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_cab_id_seq', 1, false);


--
-- TOC entry 5401 (class 0 OID 26182)
-- Dependencies: 489
-- Data for Name: op_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY op_insumo (id, op_id, item_id, qty_teorica, qty_real, um_id, batch_id, meta, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5832 (class 0 OID 0)
-- Dependencies: 490
-- Name: op_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_insumo_id_seq', 1, false);


--
-- TOC entry 5403 (class 0 OID 26192)
-- Dependencies: 491
-- Data for Name: op_produccion_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY op_produccion_cab (id, receta_version_id, cantidad_planeada, cantidad_real, fecha_produccion, estado, lote_resultado, usuario_responsable, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5833 (class 0 OID 0)
-- Dependencies: 492
-- Name: op_produccion_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_produccion_cab_id_seq', 1, false);


--
-- TOC entry 5405 (class 0 OID 26202)
-- Dependencies: 493
-- Data for Name: op_yield; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY op_yield (op_id, cantidad_real, merma_real, evidencia_url, meta) FROM stdin;
\.


--
-- TOC entry 5406 (class 0 OID 26209)
-- Dependencies: 494
-- Data for Name: overhead_definitions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY overhead_definitions (id, clave, nombre, tipo, tasa, activo, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5834 (class 0 OID 0)
-- Dependencies: 495
-- Name: overhead_definitions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('overhead_definitions_id_seq', 1, false);


--
-- TOC entry 5408 (class 0 OID 26220)
-- Dependencies: 496
-- Data for Name: param_sucursal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY param_sucursal (id, sucursal_id, consumo, tolerancia_precorte_pct, tolerancia_corte_abs, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5835 (class 0 OID 0)
-- Dependencies: 497
-- Name: param_sucursal_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('param_sucursal_id_seq', 1, false);


--
-- TOC entry 5410 (class 0 OID 26233)
-- Dependencies: 498
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY password_reset_tokens (email, token, created_at) FROM stdin;
\.


--
-- TOC entry 5411 (class 0 OID 26239)
-- Dependencies: 499
-- Data for Name: perdida_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY perdida_log (id, ts, item_id, lote_id, sucursal_id, clase, motivo, qty_canonica, qty_original, uom_original_id, evidencia_url, usuario_id, ref_tipo, ref_id, created_at) FROM stdin;
\.


--
-- TOC entry 5836 (class 0 OID 0)
-- Dependencies: 500
-- Name: perdida_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('perdida_log_id_seq', 1, false);


--
-- TOC entry 5413 (class 0 OID 26250)
-- Dependencies: 501
-- Data for Name: permissions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY permissions (id, name, guard_name, created_at, updated_at) FROM stdin;
1	inventory.view	web	2025-11-02 12:31:12	2025-11-02 12:31:12
2	inventory.items.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
3	inventory.prices.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
4	inventory.receivings.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
5	inventory.receptions.validate	web	2025-11-02 12:31:13	2025-11-02 12:31:13
6	inventory.receptions.override_tolerance	web	2025-11-02 12:31:13	2025-11-02 12:31:13
7	inventory.receptions.post	web	2025-11-02 12:31:13	2025-11-02 12:31:13
8	inventory.counts.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
9	inventory.moves.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
10	inventory.lots.view	web	2025-11-02 12:31:13	2025-11-02 12:31:13
11	inventory.transfers.approve	web	2025-11-02 12:31:13	2025-11-02 12:31:13
12	inventory.transfers.ship	web	2025-11-02 12:31:13	2025-11-02 12:31:13
13	inventory.transfers.receive	web	2025-11-02 12:31:13	2025-11-02 12:31:13
14	inventory.transfers.post	web	2025-11-02 12:31:13	2025-11-02 12:31:13
15	recipes.view	web	2025-11-02 12:31:13	2025-11-02 12:31:13
16	recipes.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
17	recipes.costs.view	web	2025-11-02 12:31:13	2025-11-02 12:31:13
18	recipes.production.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
19	production.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
20	purchasing.view	web	2025-11-02 12:31:13	2025-11-02 12:31:13
21	purchasing.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
22	menu.engineering.view	web	2025-11-02 12:31:13	2025-11-02 12:31:13
23	menu.engineering.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
24	reports.view	web	2025-11-02 12:31:13	2025-11-02 12:31:13
25	reports.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
26	alerts.view	web	2025-11-02 12:31:13	2025-11-02 12:31:13
27	alerts.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
28	alerts.assign	web	2025-11-02 12:31:13	2025-11-02 12:31:13
29	audit.view	web	2025-11-02 12:31:13	2025-11-02 12:31:13
30	vendors.view	web	2025-11-02 12:31:13	2025-11-02 12:31:13
31	vendors.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
32	pos.sync.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
33	cashfund.view	web	2025-11-02 12:31:13	2025-11-02 12:31:13
34	cashfund.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
35	people.view	web	2025-11-02 12:31:13	2025-11-02 12:31:13
36	people.users.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
37	people.roles.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
38	people.permissions.manage	web	2025-11-02 12:31:13	2025-11-02 12:31:13
39	admin.access	web	2025-11-02 12:31:13	2025-11-02 12:31:13
40	can_view_recipe_dashboard	web	2025-11-02 12:31:13	2025-11-02 12:31:13
41	can_reprocess_sales	web	2025-11-02 12:31:13	2025-11-02 12:31:13
42	can_edit_production_order	web	2025-11-02 12:31:13	2025-11-02 12:31:13
43	can_manage_purchasing	web	2025-11-02 12:31:13	2025-11-02 12:31:13
44	can_modify_recipe	web	2025-11-02 12:31:13	2025-11-02 12:31:13
45	kitchen.view_kds	web	2025-11-02 12:31:13	2025-11-02 12:31:13
\.


--
-- TOC entry 5837 (class 0 OID 0)
-- Dependencies: 502
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('permissions_id_seq', 45, true);


--
-- TOC entry 5415 (class 0 OID 26258)
-- Dependencies: 503
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, expires_at, created_at, updated_at) FROM stdin;
170	App\\Models\\User	8	browser-dashboard	252d4348f34aa3d946026d690114d9616a4ca5fc25b2a161bc6e397a567df4bc	["*"]	2025-11-28 06:35:54	\N	2025-11-28 06:35:54	2025-11-28 06:35:54
171	App\\Models\\User	9	browser-dashboard	019033939a7665a67061bc83d44020c1d8ef5dab2a1c098217dda084ec8ea86d	["*"]	2025-11-28 15:42:39	\N	2025-11-28 15:42:39	2025-11-28 15:42:39
149	App\\Models\\User	3	browser-dashboard	ac9d1b7b20164adef5af7e1c03f1eff8590cb399674c8367eef1b2e0b5a9e50f	["*"]	2025-11-24 10:37:04	\N	2025-11-24 10:37:04	2025-11-24 10:37:04
172	App\\Models\\User	5	browser-dashboard	d2ac01226aacc940df7053cda706d01ac14a999fb352844c46fba9b744364f4a	["*"]	2025-11-28 16:31:57	\N	2025-11-28 16:31:57	2025-11-28 16:31:57
174	App\\Models\\User	6	browser-dashboard	b51a4c080e2defee7fae3db7986e28b3811719a4a6fb8a4b5f78f19f2d145613	["*"]	2025-11-28 18:49:34	\N	2025-11-28 18:49:34	2025-11-28 18:49:34
160	App\\Models\\User	7	browser-dashboard	d8b6dfe26f0ce7544d1700c2caa2f8cafbe663d32b51ac4cc72540a1986c8dd0	["*"]	2025-11-25 18:34:06	\N	2025-11-25 18:34:06	2025-11-25 18:34:06
175	App\\Models\\User	4	browser-dashboard	d9b8f1025699c1ef1ffac20b272bef7b06984cad370a526f91f0fa2c062e06aa	["*"]	2025-11-29 13:30:09	\N	2025-11-29 13:30:09	2025-11-29 13:30:09
\.


--
-- TOC entry 5838 (class 0 OID 0)
-- Dependencies: 504
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('personal_access_tokens_id_seq', 175, true);


--
-- TOC entry 5417 (class 0 OID 26266)
-- Dependencies: 505
-- Data for Name: pos_map; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_map (pos_system, plu, tipo, receta_id, receta_version_id, valid_from, valid_to, sys_from, sys_to, meta, vigente_desde, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5418 (class 0 OID 26276)
-- Dependencies: 506
-- Data for Name: pos_modifiers_map; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_modifiers_map (id, pos_modifier_code, name, effect, linked_recipe_id, linked_recipe_version_id, delta_qty_canonical, canonical_uom_id, delta_cost, active, valid_from, valid_to, notes, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5419 (class 0 OID 26288)
-- Dependencies: 507
-- Data for Name: pos_reprocess_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_reprocess_log (id, ticket_id, user_id, reprocessed_at, motivo, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5839 (class 0 OID 0)
-- Dependencies: 508
-- Name: pos_reprocess_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_reprocess_log_id_seq', 1, false);


--
-- TOC entry 5421 (class 0 OID 26299)
-- Dependencies: 509
-- Data for Name: pos_reverse_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_reverse_log (id, ticket_id, user_id, reversed_at, motivo, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5840 (class 0 OID 0)
-- Dependencies: 510
-- Name: pos_reverse_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_reverse_log_id_seq', 1, false);


--
-- TOC entry 5423 (class 0 OID 26310)
-- Dependencies: 511
-- Data for Name: pos_sync_batches; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_sync_batches (id, source_system, status, started_at, finished_at, rows_processed, rows_successful, rows_failed, metadata, errors, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5841 (class 0 OID 0)
-- Dependencies: 512
-- Name: pos_sync_batches_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_sync_batches_id_seq', 1, false);


--
-- TOC entry 5425 (class 0 OID 26322)
-- Dependencies: 513
-- Data for Name: pos_sync_logs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_sync_logs (id, batch_id, external_id, action, status, payload, message, created_at) FROM stdin;
\.


--
-- TOC entry 5842 (class 0 OID 0)
-- Dependencies: 514
-- Name: pos_sync_logs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_sync_logs_id_seq', 1, false);


--
-- TOC entry 5427 (class 0 OID 26331)
-- Dependencies: 515
-- Data for Name: postcorte; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

COPY postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas, sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias, validado, validado_por, validado_en, requiere_aprobacion, aprobado_por, aprobado_en, motivo_irregular, rechazado, motivo_rechazo) FROM stdin;
1	5	2390.80	2440.00	49.20	EN_CONTRA	3676.00	3676.00	0.00	CUADRA	2025-09-19 17:40:17.932454-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-19 17:40:36.381355-06	f	\N	\N	\N	f	\N
2	6	5146.80	7662.00	2515.20	A_FAVOR	6477.00	6517.00	40.00	A_FAVOR	2025-09-19 17:42:11.002586-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N	\N	f	\N
4	8	5170.80	7208.00	2037.20	EN_CONTRA	2581.00	2581.00	0.00	CUADRA	2025-09-20 16:20:42.259148-06	1	Parte del faltante estaba en caja 101 $282, con $180.00 faltante en efectivo	0.00	0.00	0.00	CUADRA	t	1	2025-09-20 16:49:37.436832-06	f	\N	\N	\N	f	\N
28	132	4391.00	4981.00	590.00	EN_CONTRA	5007.00	4870.00	-137.00	EN_CONTRA	2025-11-06 19:16:42.383809-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-06 19:17:25.275447-06	f	\N	\N	\N	f	\N
5	7	8132.80	10915.00	2782.20	A_FAVOR	6063.00	6105.00	42.00	A_FAVOR	2025-09-20 16:36:02.768915-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-20 16:54:42.308064-06	f	\N	\N	\N	f	\N
7	12	10312.40	8463.00	-1849.40	EN_CONTRA	7311.00	7247.00	-64.00	EN_CONTRA	2025-09-22 18:13:37.154518-06	1	SE TOMARON $4,552 Hay una diferencia de $372.6	0.00	0.00	0.00	CUADRA	t	1	2025-09-22 18:15:15.987446-06	f	\N	\N	\N	f	\N
8	14	4209.00	6012.00	1803.00	EN_CONTRA	3021.00	3085.00	64.00	A_FAVOR	2025-09-23 18:21:40.19596-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-23 18:22:11.906841-06	f	\N	\N	\N	f	\N
9	15	8149.00	11819.00	3670.00	A_FAVOR	8138.80	8138.80	0.00	CUADRA	2025-09-23 18:22:23.718303-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-23 18:22:27.722591-06	f	\N	\N	\N	f	\N
10	18	8631.00	8672.00	41.00	EN_CONTRA	9706.00	9826.00	120.00	A_FAVOR	2025-09-25 17:48:06.736863-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-25 17:48:13.046387-06	f	\N	\N	\N	f	\N
11	19	4266.60	6911.50	2644.90	A_FAVOR	3913.00	3888.00	-25.00	EN_CONTRA	2025-09-25 18:07:18.831377-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-25 18:07:22.038903-06	f	\N	\N	\N	f	\N
12	21	3345.00	6053.00	2708.00	A_FAVOR	2536.00	2448.00	-88.00	EN_CONTRA	2025-09-26 18:19:22.954022-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-26 18:19:30.14417-06	f	\N	\N	\N	f	\N
13	20	6701.80	9258.00	2556.20	A_FAVOR	7110.80	7065.80	-45.00	EN_CONTRA	2025-09-26 18:31:26.738896-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-26 18:31:31.758857-06	f	\N	\N	\N	f	\N
14	22	12107.00	14768.00	2661.00	A_FAVOR	7408.00	7408.00	0.00	CUADRA	2025-09-27 16:02:41.578846-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-27 16:03:18.130218-06	f	\N	\N	\N	f	\N
15	23	8141.00	10541.00	2400.00	EN_CONTRA	5523.20	5523.20	0.00	CUADRA	2025-09-27 16:21:00.177925-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-27 16:21:40.921717-06	f	\N	\N	\N	f	\N
16	24	8911.00	8661.00	-250.00	EN_CONTRA	8077.00	8019.00	-58.00	EN_CONTRA	2025-09-29 17:43:33.16515-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-29 17:43:37.798515-06	f	\N	\N	\N	f	\N
17	28	8937.80	12232.00	3294.20	A_FAVOR	9262.00	9232.00	-30.00	EN_CONTRA	2025-09-30 17:34:47.438661-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-09-30 17:34:50.462961-06	f	\N	\N	\N	f	\N
18	32	6755.00	5912.00	-843.00	EN_CONTRA	9230.00	9182.00	-48.00	EN_CONTRA	2025-10-01 18:24:37.116734-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-10-01 18:24:39.948505-06	f	\N	\N	\N	f	\N
19	36	3481.00	5913.00	2432.00	EN_CONTRA	3406.00	3474.00	68.00	A_FAVOR	2025-10-02 18:17:19.725233-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-10-02 18:17:25.740326-06	f	\N	\N	\N	f	\N
20	35	10325.80	12508.00	2182.20	EN_CONTRA	11662.00	11408.00	-254.00	EN_CONTRA	2025-10-02 18:34:33.257465-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-10-02 18:36:15.801037-06	f	\N	\N	\N	f	\N
22	39	2350.00	4697.00	2347.00	EN_CONTRA	1904.00	3436.00	1532.00	A_FAVOR	2025-10-03 17:56:23.112019-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-10-03 17:56:39.158723-06	f	\N	\N	\N	f	\N
23	38	6087.00	5371.00	-716.00	EN_CONTRA	9312.20	9093.00	-219.20	EN_CONTRA	2025-10-03 18:13:48.415782-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-10-03 18:13:50.761456-06	f	\N	\N	\N	f	\N
29	140	5741.80	7687.00	1945.20	EN_CONTRA	4779.00	4772.00	-7.00	EN_CONTRA	2025-11-07 17:25:22.471378-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-07 17:25:26.740572-06	f	\N	\N	\N	f	\N
24	43	8775.00	11448.00	2673.00	A_FAVOR	10732.80	10728.80	-4.00	EN_CONTRA	2025-10-06 18:12:48.777878-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-10-06 18:15:01.575493-06	f	\N	\N	\N	f	\N
30	142	10434.60	13115.00	2680.40	A_FAVOR	6544.80	6544.80	0.00	CUADRA	2025-11-08 15:21:53.032318-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-08 15:21:56.753385-06	f	\N	\N	\N	f	\N
26	130	5970.00	8478.00	2508.00	A_FAVOR	6530.00	6444.00	-86.00	EN_CONTRA	2025-11-06 18:58:48.488242-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-06 18:59:39.456175-06	f	\N	\N	\N	f	\N
31	141	8280.40	10042.00	1761.60	EN_CONTRA	5597.80	5473.00	-124.80	EN_CONTRA	2025-11-08 15:41:46.032918-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-08 15:43:00.694978-06	f	\N	\N	\N	f	\N
34	157	0.00	1.00	1.00	A_FAVOR	0.00	2.00	2.00	A_FAVOR	2025-11-10 22:52:22.312999-06	1		0.00	1.00	1.00	A_FAVOR	f	\N	\N	f	\N	\N	\N	f	\N
35	163	10068.00	1500.00	-8568.00	EN_CONTRA	1687.60	2.00	-1685.60	EN_CONTRA	2025-11-10 22:53:17.836064-06	1		0.00	1.00	1.00	A_FAVOR	t	1	2025-11-10 23:18:12.472064-06	t	\N	\N	\N	f	\N
32	162	6524.20	9109.50	2585.30	A_FAVOR	5026.00	5864.80	838.80	A_FAVOR	2025-11-10 22:39:11.05109-06	1	eertertet	0.00	0.00	0.00	CUADRA	t	1	2025-11-10 23:18:34.913789-06	f	\N	\N	\N	f	\N
36	169	2354.00	5372.00	3018.00	A_FAVOR	2291.60	2291.60	0.00	CUADRA	2025-11-12 17:53:51.032848-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N	\N	f	\N
37	171	3212.00	4652.50	1440.50	EN_CONTRA	4097.00	4017.00	-80.00	EN_CONTRA	2025-11-13 18:06:47.699125-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-13 18:08:15.132374-06	f	\N	\N	\N	f	\N
38	172	6705.20	9100.00	2394.80	A_FAVOR	9330.40	9185.40	-145.00	EN_CONTRA	2025-11-13 18:08:24.16528-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N	\N	f	\N
39	170	173.00	1500.00	1327.00	A_FAVOR	100.00	0.00	-100.00	EN_CONTRA	2025-11-13 18:17:21.805988-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N	\N	f	\N
40	173	245.00	1246.00	1001.00	A_FAVOR	332.00	332.00	0.00	CUADRA	2025-11-14 17:50:36.931955-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-14 17:50:52.93141-06	f	\N	\N		f	\N
41	179	9785.00	12295.50	2510.50	A_FAVOR	5126.00	5111.00	-15.00	EN_CONTRA	2025-11-15 15:50:11.469435-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N		f	\N
42	178	7790.00	8276.00	486.00	A_FAVOR	6700.00	6700.00	0.00	CUADRA	2025-11-15 16:23:28.900656-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N		f	\N
43	177	12977.90	14827.00	1849.10	A_FAVOR	8520.60	8183.60	-337.00	EN_CONTRA	2025-11-15 16:23:42.187364-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N		f	\N
44	182	3305.00	5805.00	2500.00	A_FAVOR	3419.00	3419.00	0.00	CUADRA	2025-11-18 18:58:30.645719-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N		f	\N
45	183	7807.00	10286.00	2479.00	EN_CONTRA	4363.00	4390.00	27.00	A_FAVOR	2025-11-18 18:58:34.739011-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-18 18:59:10.459222-06	f	\N	\N		f	\N
46	185	4766.80	8052.00	3285.20	A_FAVOR	7089.00	54876.80	47787.80	A_FAVOR	2025-11-19 18:52:48.965309-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N		f	\N
47	187	6772.00	9276.00	2504.00	A_FAVOR	3905.00	659.26	-3245.74	EN_CONTRA	2025-11-19 18:59:05.182309-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-19 18:59:29.796219-06	f	\N	\N		f	\N
48	192	4944.00	7448.00	2504.00	A_FAVOR	4246.00	4246.00	0.00	CUADRA	2025-11-20 15:48:23.609361-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-20 15:49:33.129393-06	f	\N	\N		f	\N
49	191	4269.80	7042.00	2772.20	A_FAVOR	4278.00	4297.00	19.00	A_FAVOR	2025-11-20 18:08:26.997121-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N		f	\N
50	190	6108.80	7285.50	1176.70	A_FAVOR	6464.80	6438.80	-26.00	EN_CONTRA	2025-11-20 18:24:35.71813-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N		f	\N
52	189	6407.00	8931.00	2524.00	A_FAVOR	4393.00	4393.00	0.00	CUADRA	2025-11-20 19:26:41.673159-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-20 19:43:38.358665-06	f	\N	\N		f	\N
54	194	4966.00	7466.00	2500.00	CUADRA	4709.00	4709.00	0.00	CUADRA	2025-11-21 15:49:33.088251-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-21 15:49:50.224749-06	f	\N	\N		f	\N
55	197	3278.00	2501.00	-777.00	EN_CONTRA	3880.80	3855.80	-25.00	EN_CONTRA	2025-11-21 16:49:12.564943-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-21 16:54:09.799943-06	f	\N	\N		f	\N
56	196	4281.80	5578.50	1296.70	EN_CONTRA	7183.80	7183.80	0.00	CUADRA	2025-11-21 17:09:49.519339-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-21 17:11:09.445198-06	f	\N	\N		f	\N
57	195	4684.00	7185.00	2501.00	A_FAVOR	4034.00	4034.00	0.00	CUADRA	2025-11-21 18:53:07.707148-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-21 18:55:22.863413-06	f	\N	\N		f	\N
58	198	9583.00	12548.00	2965.00	A_FAVOR	4032.00	4032.00	0.00	CUADRA	2025-11-22 15:39:07.908131-06	1	El efectivo sobrante se debe a un excedente de CAMBIO que se me entregó. Se entrega dicho sobrante a José Huesca	0.00	0.00	0.00	CUADRA	t	1	2025-11-22 15:40:16.839005-06	f	\N	\N		f	\N
60	199	9004.20	11496.00	2491.80	EN_CONTRA	6038.00	6033.00	-5.00	EN_CONTRA	2025-11-22 15:52:38.266231-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-22 15:56:11.118462-06	f	\N	\N		f	\N
59	201	9958.00	12459.00	2501.00	A_FAVOR	5364.00	5364.00	0.00	CUADRA	2025-11-22 15:47:26.295739-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-22 16:05:24.031661-06	f	\N	\N		f	\N
61	200	9812.00	12301.00	2489.00	EN_CONTRA	6491.00	6490.00	-1.00	EN_CONTRA	2025-11-22 17:11:43.835614-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-22 17:11:46.478503-06	f	\N	\N		f	\N
62	209	271.00	1281.00	1010.00	A_FAVOR	69.00	69.00	0.00	CUADRA	2025-11-24 11:31:25.662227-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-24 11:31:41.884403-06	f	\N	\N		f	\N
63	205	6129.60	8629.00	2499.40	EN_CONTRA	4139.00	4139.00	0.00	CUADRA	2025-11-24 15:56:04.269888-06	1	los $.60 de diferencia se deben a un descuento de colaborador pero ya se repusieron	0.00	0.00	0.00	CUADRA	t	1	2025-11-24 15:57:01.773369-06	f	\N	\N		f	\N
64	207	5446.00	8736.00	3290.00	A_FAVOR	3633.40	3633.40	0.00	CUADRA	2025-11-24 17:47:56.092948-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-24 17:47:58.79428-06	f	\N	\N		f	\N
65	208	6415.20	8908.00	2492.80	EN_CONTRA	6763.00	6703.00	-60.00	EN_CONTRA	2025-11-24 17:59:08.981007-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-24 17:59:13.571727-06	f	\N	\N		f	\N
66	206	6411.00	8910.00	2499.00	EN_CONTRA	4952.00	4952.00	0.00	CUADRA	2025-11-24 18:42:26.20924-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-24 18:53:34.065876-06	f	\N	\N		f	\N
67	214	274.00	1284.00	1010.00	A_FAVOR	55.00	55.00	0.00	CUADRA	2025-11-25 11:16:03.557056-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-25 11:16:16.849945-06	f	\N	\N		f	\N
68	211	4640.00	7141.00	2501.00	A_FAVOR	4086.80	4086.80	0.00	CUADRA	2025-11-25 15:54:03.504246-06	1	ventas crédito: terminal banorte, ventas débito: terminal mercado libre	0.00	0.00	0.00	CUADRA	t	1	2025-11-25 15:54:56.817957-06	f	\N	\N		f	\N
70	210	6631.60	5274.50	-1357.10	EN_CONTRA	7151.60	7129.40	-22.20	EN_CONTRA	2025-11-25 18:24:04.949301-06	1	Faltante en la caja 101 y la otra parte en los gastos del dia, corte completo.	0.00	0.00	0.00	CUADRA	t	1	2025-11-25 18:25:25.178165-06	f	\N	\N		f	\N
69	213	3291.00	6708.00	3417.00	A_FAVOR	3648.00	3648.00	0.00	CUADRA	2025-11-25 18:06:10.016411-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-25 18:25:30.325521-06	f	\N	\N		f	\N
71	212	6622.00	9121.00	2499.00	EN_CONTRA	5702.00	5667.00	-35.00	EN_CONTRA	2025-11-25 18:44:50.24008-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-25 18:48:41.09128-06	f	\N	\N		f	\N
72	215	136.00	1137.00	1001.00	A_FAVOR	140.00	0.00	-140.00	EN_CONTRA	2025-11-26 11:44:24.788731-06	1		0.00	0.00	0.00	CUADRA	f	\N	\N	f	\N	\N		f	\N
73	248	4817.00	7317.00	2500.00	CUADRA	4588.00	4588.00	0.00	CUADRA	2025-11-26 15:52:01.993521-06	1	todo bien	0.00	0.00	0.00	CUADRA	t	1	2025-11-26 15:52:17.098078-06	f	\N	\N		f	\N
74	250	4068.80	7674.00	3605.20	A_FAVOR	4502.00	4502.01	0.01	A_FAVOR	2025-11-26 17:42:37.644171-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-26 17:50:40.402622-06	f	\N	\N		f	\N
75	249	4318.20	6823.50	2505.30	A_FAVOR	6964.00	6963.00	-1.00	EN_CONTRA	2025-11-26 18:33:43.241788-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-26 18:33:46.052679-06	f	\N	\N		f	\N
76	251	6342.00	8840.00	2498.00	EN_CONTRA	4792.00	4807.00	15.00	A_FAVOR	2025-11-26 19:10:08.054075-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-26 19:18:41.247189-06	f	\N	\N		f	\N
77	252	301.00	1308.00	1007.00	A_FAVOR	239.00	239.00	0.00	CUADRA	2025-11-27 11:32:15.684242-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-27 11:32:22.295376-06	f	\N	\N		f	\N
78	253	4432.80	6934.00	2501.20	A_FAVOR	3774.00	3774.00	0.00	CUADRA	2025-11-27 15:52:32.975541-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-27 15:52:51.106337-06	f	\N	\N		f	\N
79	256	6559.00	9062.00	2503.00	A_FAVOR	5107.00	5097.00	-10.00	EN_CONTRA	2025-11-27 18:49:26.279811-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-27 19:00:50.604889-06	f	\N	\N		f	\N
80	254	6995.40	8276.50	1281.10	EN_CONTRA	9105.60	8808.05	-297.55	EN_CONTRA	2025-11-27 19:19:06.340224-06	1	FALTANTE EN BOLSA DE CAMBIO EN MODENDAS DE $5.00	0.00	0.00	0.00	CUADRA	t	1	2025-11-27 19:19:29.552833-06	f	\N	\N		f	\N
81	255	3032.00	5759.00	2727.00	A_FAVOR	4001.00	3901.00	-100.00	EN_CONTRA	2025-11-27 19:19:34.65227-06	1	FALTANTE DE TARJETAS EN EFECTIVO Y EL RESTO DE LA CAJA 102	0.00	0.00	0.00	CUADRA	t	1	2025-11-27 19:20:03.229604-06	f	\N	\N		f	\N
82	257	102.00	3107.00	3005.00	A_FAVOR	334.00	334.00	0.00	CUADRA	2025-11-28 11:12:55.050038-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-28 11:12:58.51437-06	f	\N	\N		f	\N
83	260	3467.00	5970.00	2503.00	A_FAVOR	3586.00	3584.00	-2.00	EN_CONTRA	2025-11-28 15:46:16.64641-06	1	Dos de los tres pesos que sobran en efectivo son lo que falta en tarjeta de débito, debido a un error de Alexis al registrar una venta pagada en ambos medios. El otro peso seguro es error de Isabella.	0.00	0.00	0.00	CUADRA	t	1	2025-11-28 15:47:38.029358-06	f	\N	\N		f	\N
84	259	3767.00	2500.00	-1267.00	EN_CONTRA	4217.00	4069.00	-148.00	EN_CONTRA	2025-11-28 16:48:25.366082-06	1	SE EXCEDIERON LOS GASTOS EN EFECTIVO DEL DIA	0.00	0.00	0.00	CUADRA	t	1	2025-11-28 16:48:47.65307-06	f	\N	\N		f	\N
85	261	5405.00	7860.00	2455.00	EN_CONTRA	4179.00	4134.00	-45.00	EN_CONTRA	2025-11-28 18:53:14.457152-06	1		0.00	0.00	0.00	CUADRA	t	1	2025-11-28 19:21:44.543959-06	f	\N	\N		f	\N
\.


--
-- TOC entry 5843 (class 0 OID 0)
-- Dependencies: 516
-- Name: postcorte_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('postcorte_id_seq', 85, true);


--
-- TOC entry 5429 (class 0 OID 26356)
-- Dependencies: 517
-- Data for Name: precorte; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

COPY precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) FROM stdin;
118	200	12301.00	6490.00	ENVIADO	2025-11-22 16:22:23.67679-06	6	192.168.1.198	\N
74	162	9109.50	5864.80	ENVIADO	2025-11-10 18:35:12.649877-06	6	100.98.146.92	\N
98	183	10286.00	4390.00	ENVIADO	2025-11-18 18:39:13.476144-06	\N	\N	\N
79	157	1.00	3.00	ENVIADO	2025-11-10 22:17:11.390027-06	1	100.98.146.92	\N
99	181	0.00	0.00	PENDIENTE	2025-11-18 18:59:31.483768-06	6	100.98.146.92	\N
83	163	1500.00	3.00	ENVIADO	2025-11-10 22:51:23.443542-06	8	100.98.146.92	\N
100	180	0.00	0.00	PENDIENTE	2025-11-18 18:59:35.376683-06	14	100.98.146.92	\N
84	166	5338.00	3103.00	ENVIADO	2025-11-11 17:39:04.573748-06	\N	\N	\N
85	165	5819.00	8162.00	ENVIADO	2025-11-11 17:56:00.688632-06	\N	\N	\N
112	196	5578.50	7183.80	ENVIADO	2025-11-21 13:50:50.236587-06	6	192.168.1.49	\N
86	169	5372.00	2291.60	ENVIADO	2025-11-12 17:32:44.8299-06	\N	\N	\N
101	186	8392.00	4646.60	ENVIADO	2025-11-19 17:31:06.500869-06	\N	\N	\N
87	168	10401.00	8319.50	ENVIADO	2025-11-12 17:54:42.372025-06	6	100.98.146.92	\N
88	171	4652.50	4017.00	ENVIADO	2025-11-13 17:34:47.87078-06	\N	\N	\N
2	6	7662.00	6517.00	ENVIADO	2025-09-19 17:18:47.744592-06	\N	\N	\N
1	5	2440.00	3676.00	ENVIADO	2025-09-19 16:09:32.076298-06	\N	\N	\N
32	142	13115.00	6544.80	ENVIADO	2025-11-08 15:06:58.630641-06	\N	\N	\N
4	8	7208.00	2581.00	ENVIADO	2025-09-20 16:01:22.84404-06	\N	\N	\N
3	7	10915.00	6105.00	ENVIADO	2025-09-20 15:56:57.42353-06	\N	\N	\N
5	12	8463.00	7247.00	ENVIADO	2025-09-22 18:03:03.666758-06	\N	\N	\N
33	141	10042.00	5473.00	ENVIADO	2025-11-08 15:28:14.857632-06	\N	\N	\N
6	15	11819.00	8138.80	ENVIADO	2025-09-23 17:56:42.176694-06	\N	\N	\N
7	14	6012.00	3085.00	ENVIADO	2025-09-23 18:13:35.737952-06	\N	\N	\N
8	18	8672.00	9826.00	ENVIADO	2025-09-25 17:46:08.310003-06	\N	\N	\N
9	19	6911.50	3888.00	ENVIADO	2025-09-25 18:03:21.011982-06	\N	\N	\N
10	20	9258.00	7065.80	ENVIADO	2025-09-26 16:59:23.355418-06	\N	\N	\N
11	21	6053.00	2448.00	ENVIADO	2025-09-26 17:52:24.021418-06	\N	\N	\N
12	22	14768.00	7408.00	ENVIADO	2025-09-27 15:57:35.438419-06	\N	\N	\N
13	23	10541.00	5523.20	ENVIADO	2025-09-27 16:09:01.378508-06	\N	\N	\N
14	24	8661.00	8019.00	ENVIADO	2025-09-29 17:30:31.600467-06	\N	\N	\N
89	172	9100.00	9185.40	ENVIADO	2025-11-13 17:45:14.052988-06	\N	\N	\N
16	28	12232.00	9232.00	ENVIADO	2025-09-30 17:24:35.214393-06	\N	\N	\N
102	185	8052.00	54876.80	ENVIADO	2025-11-19 17:55:06.556077-06	\N	\N	\N
18	32	5912.00	9182.00	ENVIADO	2025-10-01 17:45:43.373671-06	\N	\N	\N
21	36	5913.00	3474.00	ENVIADO	2025-10-02 18:07:04.667897-06	\N	\N	\N
20	35	12508.00	11408.00	ENVIADO	2025-10-02 17:39:44.010517-06	\N	\N	\N
23	38	5371.00	9093.00	ENVIADO	2025-10-03 17:47:41.401247-06	\N	\N	\N
22	39	4697.00	3436.00	ENVIADO	2025-10-03 16:56:35.072466-06	\N	\N	\N
24	43	11448.00	10728.80	ENVIADO	2025-10-06 17:57:13.844652-06	\N	\N	\N
90	170	1500.00	0.00	ENVIADO	2025-11-13 18:10:35.93993-06	14	100.98.146.92	\N
28	130	8478.00	6444.00	ENVIADO	2025-11-06 18:49:50.153395-06	\N	\N	\N
27	132	4981.00	4870.00	ENVIADO	2025-11-06 18:49:28.206893-06	\N	\N	\N
91	173	1246.00	332.00	ENVIADO	2025-11-14 10:42:20.527266-06	\N	\N	nada
31	140	7687.00	4772.00	ENVIADO	2025-11-07 17:10:46.939857-06	\N	\N	\N
110	195	7185.00	4034.00	ENVIADO	2025-11-21 13:50:44.606938-06	7	192.168.1.49	\N
92	175	2637.00	2841.00	ENVIADO	2025-11-14 11:53:34.7624-06	8	100.98.146.92	\N
103	187	9276.00	659.26	ENVIADO	2025-11-19 18:34:12.883728-06	\N	\N	EN UNA VENTA DE MISCELANEA DE UN MONTO DE 10$  INGRESÉ AL SISTEMA Y COBRE CON 20$ Y LA CAJA NO ABRIÓ NI ARROJÓ TICKET
93	174	4176.00	8910.50	ENVIADO	2025-11-14 16:47:18.669892-06	\N	\N	\N
104	188	0.00	0.00	PENDIENTE	2025-11-20 13:17:48.526888-06	14	100.98.146.92	\N
94	178	8276.00	6700.00	ENVIADO	2025-11-15 15:25:56.062255-06	\N	\N	\N
95	179	12295.50	5111.00	ENVIADO	2025-11-15 15:28:40.831066-06	\N	\N	\N
113	204	0.00	0.00	PENDIENTE	2025-11-22 12:22:45.145255-06	1	100.98.146.92	\N
96	177	14827.00	8183.60	ENVIADO	2025-11-15 15:45:41.102272-06	\N	\N	\N
105	192	7448.00	4246.00	ENVIADO	2025-11-20 15:29:06.199835-06	10	192.168.1.49	sistema lento
97	182	5805.00	3419.00	ENVIADO	2025-11-18 17:59:41.643156-06	\N	\N	\N
106	191	7042.00	4297.00	ENVIADO	2025-11-20 17:45:30.917148-06	\N	\N	EXCEDENTE DE LA CAJA 2
107	190	7285.50	6438.80	ENVIADO	2025-11-20 18:11:00.203497-06	\N	\N	\N
114	203	1539.00	0.00	ENVIADO	2025-11-22 13:08:38.684694-06	13	100.98.146.92	\N
108	189	8931.00	4393.00	ENVIADO	2025-11-20 19:04:41.413947-06	\N	\N	Se anularon 3 tickets, dos por error en la orden y uno tenemos duda.
109	194	7466.00	4709.00	ENVIADO	2025-11-21 13:50:30.482511-06	10	192.168.1.49	Gustavo anuló una compra de prueba
111	197	2501.00	3855.80	ENVIADO	2025-11-21 13:50:47.899232-06	8	192.168.1.49	\N
119	208	8908.00	6703.00	ENVIADO	2025-11-24 10:38:13.219114-06	6	192.168.1.210	\N
115	198	12548.00	4032.00	ENVIADO	2025-11-22 15:23:46.912607-06	10	192.168.1.209	ventas débito terminal de mercado libre y ventas de crédito terminal banorte
120	209	1281.00	69.00	ENVIADO	2025-11-24 10:39:41.081755-06	14	192.168.1.210	\N
117	201	12459.00	5364.00	ENVIADO	2025-11-22 15:36:39.663756-06	7	192.168.1.196	\N
116	199	11496.00	6033.00	ENVIADO	2025-11-22 15:32:18.458683-06	8	192.168.1.198	\N
126	213	6708.00	3648.00	ENVIADO	2025-11-25 17:54:11.112349-06	8	192.168.1.198	\N
121	205	8629.00	4139.00	ENVIADO	2025-11-24 15:52:41.315806-06	10	192.168.1.209	\N
123	206	8910.00	4952.00	ENVIADO	2025-11-24 18:38:16.861148-06	11	192.168.1.196	\N
122	207	8736.00	3633.40	ENVIADO	2025-11-24 17:28:13.255978-06	8	192.168.1.198	\N
125	211	7141.00	4086.80	ENVIADO	2025-11-25 15:50:26.206187-06	10	192.168.1.209	tarjetas de crédito terminal banorte, ventas débito terminal mercado libre
124	214	1284.00	55.00	ENVIADO	2025-11-25 11:03:43.879957-06	14	192.168.1.210	\N
127	210	5274.50	7129.40	ENVIADO	2025-11-25 18:08:36.257929-06	6	192.168.1.198	\N
128	212	9121.00	5667.00	ENVIADO	2025-11-25 18:34:31.336175-06	7	192.168.1.196	\N
129	215	1137.00	0.00	ENVIADO	2025-11-26 11:41:44.629059-06	14	192.168.1.210	\N
130	248	7317.00	4588.00	ENVIADO	2025-11-26 15:47:47.39398-06	10	192.168.1.209	\N
131	250	7674.00	4502.01	ENVIADO	2025-11-26 17:27:16.980686-06	8	192.168.1.198	\N
132	249	6823.50	6963.00	ENVIADO	2025-11-26 18:02:53.182344-06	6	192.168.1.198	\N
134	252	1308.00	239.00	ENVIADO	2025-11-27 11:01:46.785992-06	14	192.168.1.210	\N
135	253	6934.00	3774.00	ENVIADO	2025-11-27 15:45:49.095154-06	10	192.168.1.209	\N
136	255	5759.00	3901.00	ENVIADO	2025-11-27 17:55:47.559763-06	8	192.168.1.198	\N
133	251	8840.00	4807.00	ENVIADO	2025-11-26 19:00:09.140765-06	11	192.168.1.196	Durante un cobro con tarjeta la terminal se apagó, por lo que no tenemos la certeza si el dinero de dicha transacción se cobró correctamente ya que después la terminal no imprimió el ticket de esa transacción. El producto era unas papas o unas malangas. El producto sí se ingresó al sistema.
137	254	8276.50	8808.05	ENVIADO	2025-11-27 18:14:23.315552-06	6	192.168.1.198	\N
138	256	9062.00	5097.00	ENVIADO	2025-11-27 18:42:51.750821-06	11	192.168.1.196	\N
139	257	3107.00	334.00	ENVIADO	2025-11-28 11:00:49.371758-06	14	192.168.1.210	\N
140	260	5970.00	3584.00	ENVIADO	2025-11-28 15:42:47.661903-06	10	192.168.1.209	\N
141	259	2500.00	4069.00	ENVIADO	2025-11-28 16:36:03.347512-06	8	192.168.1.198	\N
142	258	1810.00	6659.60	ENVIADO	2025-11-28 16:57:44.015801-06	6	192.168.1.198	\N
143	261	7860.00	4134.00	ENVIADO	2025-11-28 18:50:00.185123-06	11	192.168.1.196	\N
\.


--
-- TOC entry 5430 (class 0 OID 26367)
-- Dependencies: 518
-- Data for Name: precorte_efectivo; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

COPY precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) FROM stdin;
1	2	1000.00	7	7000.00
2	2	100.00	6	600.00
3	2	50.00	1	50.00
4	2	10.00	1	10.00
5	2	2.00	1	2.00
6	1	200.00	8	1600.00
7	1	100.00	8	800.00
8	1	20.00	2	40.00
9	4	500.00	6	3000.00
10	4	200.00	4	800.00
11	4	100.00	20	2000.00
12	4	50.00	10	500.00
13	4	20.00	16	320.00
14	4	5.00	73	365.00
15	4	10.00	8	80.00
16	4	1.00	2	2.00
17	4	0.50	2	1.00
18	4	2.00	70	140.00
19	3	200.00	22	4400.00
20	3	100.00	36	3600.00
21	3	50.00	6	300.00
22	3	20.00	3	60.00
23	3	10.00	104	1040.00
24	3	5.00	235	1175.00
25	3	2.00	85	170.00
26	3	1.00	170	170.00
27	5	500.00	2	1000.00
28	5	200.00	4	800.00
29	5	100.00	32	3200.00
30	5	50.00	7	350.00
31	5	10.00	128	1280.00
32	5	5.00	202	1010.00
33	5	2.00	230	460.00
34	5	1.00	363	363.00
35	6	1000.00	4	4000.00
36	6	500.00	2	1000.00
37	6	200.00	9	1800.00
38	6	100.00	30	3000.00
39	6	50.00	26	1300.00
40	6	20.00	7	140.00
41	6	10.00	14	140.00
42	6	5.00	74	370.00
43	6	2.00	17	34.00
44	6	1.00	32	32.00
45	6	0.50	6	3.00
46	7	500.00	4	2000.00
47	7	200.00	6	1200.00
48	7	100.00	11	1100.00
49	7	50.00	22	1100.00
50	7	20.00	3	60.00
51	7	10.00	7	70.00
52	7	5.00	84	420.00
53	7	2.00	19	38.00
54	7	1.00	24	24.00
55	8	1000.00	8	8000.00
56	8	500.00	1	500.00
57	8	100.00	1	100.00
58	8	20.00	1	20.00
59	8	50.00	1	50.00
60	8	2.00	1	2.00
61	9	500.00	1	500.00
62	9	200.00	10	2000.00
63	9	100.00	17	1700.00
64	9	50.00	49	2450.00
65	9	5.00	12	60.00
66	9	10.00	9	90.00
67	9	2.00	1	2.00
68	9	1.00	105	105.00
69	9	0.50	9	4.50
70	10	500.00	3	1500.00
71	10	200.00	2	400.00
72	10	100.00	28	2800.00
73	10	50.00	56	2800.00
74	10	20.00	4	80.00
75	10	5.00	137	685.00
76	10	2.00	146	292.00
77	10	1.00	101	101.00
78	10	10.00	60	600.00
79	11	1000.00	1	1000.00
80	11	500.00	2	1000.00
81	11	200.00	5	1000.00
82	11	100.00	4	400.00
83	11	50.00	36	1800.00
84	11	20.00	3	60.00
85	11	2.00	35	70.00
86	11	10.00	13	130.00
87	11	1.00	63	63.00
88	11	5.00	106	530.00
89	12	1000.00	2	2000.00
90	12	500.00	19	9500.00
91	12	200.00	11	2200.00
92	12	100.00	10	1000.00
93	12	50.00	1	50.00
94	12	1.00	3	3.00
95	12	5.00	1	5.00
96	12	10.00	1	10.00
97	13	500.00	4	2000.00
98	13	200.00	18	3600.00
99	13	100.00	23	2300.00
100	13	50.00	52	2600.00
101	13	5.00	2	10.00
102	13	1.00	31	31.00
103	14	500.00	2	1000.00
104	14	200.00	16	3200.00
105	14	100.00	25	2500.00
106	14	50.00	12	600.00
107	14	20.00	5	100.00
108	14	10.00	34	340.00
109	14	5.00	106	530.00
110	14	1.00	205	205.00
111	14	2.00	93	186.00
112	16	500.00	1	500.00
113	16	5.00	119	595.00
114	16	10.00	5	50.00
115	16	2.00	100	200.00
116	16	1.00	387	387.00
117	16	200.00	25	5000.00
118	16	100.00	37	3700.00
119	16	50.00	32	1600.00
120	16	20.00	10	200.00
129	18	500.00	3	1500.00
130	18	200.00	4	800.00
131	18	100.00	9	900.00
132	18	50.00	24	1200.00
133	18	20.00	8	160.00
134	18	1.00	284	284.00
135	18	2.00	124	248.00
136	18	10.00	34	340.00
137	18	5.00	96	480.00
138	21	500.00	2	1000.00
139	21	200.00	1	200.00
140	21	100.00	21	2100.00
141	21	50.00	46	2300.00
142	21	5.00	46	230.00
143	21	2.00	1	2.00
144	21	1.00	71	71.00
145	21	10.00	1	10.00
146	20	500.00	9	4500.00
147	20	200.00	7	1400.00
148	20	100.00	38	3800.00
149	20	50.00	37	1850.00
150	20	20.00	27	540.00
151	20	2.00	53	106.00
152	20	5.00	53	265.00
153	20	1.00	47	47.00
154	23	500.00	1	500.00
155	23	200.00	2	400.00
156	23	100.00	2	200.00
157	23	50.00	55	2750.00
158	23	20.00	28	560.00
159	23	1.00	344	344.00
160	23	2.00	131	262.00
161	23	5.00	19	95.00
162	23	10.00	26	260.00
163	22	500.00	2	1000.00
164	22	200.00	1	200.00
165	22	100.00	8	800.00
166	22	50.00	48	2400.00
167	22	20.00	2	40.00
168	22	10.00	5	50.00
169	22	5.00	9	45.00
170	22	2.00	1	2.00
171	22	1.00	160	160.00
172	24	500.00	5	2500.00
173	24	200.00	14	2800.00
174	24	100.00	3	300.00
175	24	50.00	3	150.00
176	24	1000.00	5	5000.00
177	24	20.00	2	40.00
178	24	2.00	123	246.00
179	24	10.00	3	30.00
180	24	5.00	44	220.00
181	24	1.00	162	162.00
192	28	500.00	5	2500.00
193	28	200.00	15	3000.00
194	28	100.00	20	2000.00
195	28	50.00	8	400.00
196	28	20.00	12	240.00
197	28	0.50	6	3.00
198	28	10.00	18	180.00
199	28	5.00	25	125.00
200	28	2.00	4	8.00
201	28	1.00	22	22.00
202	27	500.00	3	1500.00
203	27	200.00	2	400.00
204	27	100.00	16	1600.00
205	27	50.00	7	350.00
206	27	20.00	9	180.00
207	27	10.00	44	440.00
208	27	5.00	75	375.00
209	27	2.00	14	28.00
210	27	1.00	108	108.00
221	31	500.00	3	1500.00
222	31	200.00	3	600.00
223	31	100.00	16	1600.00
224	31	50.00	7	350.00
225	31	20.00	103	2060.00
226	31	10.00	86	860.00
227	31	5.00	39	195.00
228	31	1.00	2	2.00
229	31	2.00	260	520.00
230	32	500.00	11	5500.00
231	32	200.00	15	3000.00
232	32	100.00	30	3000.00
233	32	50.00	17	850.00
234	32	20.00	15	300.00
235	32	10.00	27	270.00
236	32	2.00	95	190.00
237	32	1.00	5	5.00
238	33	500.00	3	1500.00
239	33	200.00	9	1800.00
240	33	100.00	29	2900.00
241	33	50.00	17	850.00
242	33	20.00	50	1000.00
243	33	10.00	50	500.00
244	33	5.00	230	1150.00
245	33	1.00	150	150.00
246	33	2.00	94	188.00
247	33	0.50	8	4.00
248	74	1.00	9109	9109.00
249	74	0.50	1	0.50
250	79	1.00	1	1.00
251	83	1000.00	1	1000.00
252	83	500.00	1	500.00
253	84	200.00	8	1600.00
254	84	100.00	14	1400.00
255	84	50.00	32	1600.00
256	84	20.00	1	20.00
257	84	10.00	5	50.00
258	84	5.00	96	480.00
259	84	2.00	82	164.00
260	84	1.00	24	24.00
261	85	200.00	6	1200.00
262	85	100.00	21	2100.00
263	85	50.00	19	950.00
264	85	20.00	45	900.00
265	85	10.00	18	180.00
266	85	5.00	78	390.00
267	85	2.00	30	60.00
268	85	1.00	36	36.00
269	85	0.50	6	3.00
270	86	500.00	2	1000.00
271	86	200.00	7	1400.00
272	86	100.00	6	600.00
273	86	50.00	34	1700.00
274	86	20.00	5	100.00
275	86	10.00	7	70.00
276	86	5.00	71	355.00
277	86	2.00	61	122.00
278	86	1.00	25	25.00
279	87	500.00	8	4000.00
280	87	200.00	13	2600.00
281	87	100.00	17	1700.00
282	87	50.00	29	1450.00
283	87	10.00	5	50.00
284	87	5.00	85	425.00
285	87	2.00	61	122.00
286	87	1.00	49	49.00
287	87	0.50	10	5.00
288	88	500.00	1	500.00
289	88	200.00	6	1200.00
290	88	100.00	6	600.00
291	88	50.00	42	2100.00
292	88	20.00	7	140.00
293	88	5.00	22	110.00
294	88	1.00	2	2.00
295	88	0.50	1	0.50
296	89	500.00	5	2500.00
297	89	200.00	7	1400.00
298	89	100.00	33	3300.00
299	89	50.00	32	1600.00
300	89	20.00	1	20.00
301	89	10.00	5	50.00
302	89	5.00	16	80.00
303	89	2.00	71	142.00
304	89	1.00	8	8.00
305	90	1000.00	1	1000.00
306	90	500.00	1	500.00
307	91	500.00	1	500.00
308	91	200.00	2	400.00
309	91	50.00	1	50.00
310	91	10.00	3	30.00
311	91	5.00	27	135.00
312	91	2.00	26	52.00
313	91	1.00	78	78.00
314	91	0.50	2	1.00
315	92	500.00	1	500.00
316	92	200.00	3	600.00
317	92	100.00	1	100.00
318	92	50.00	22	1100.00
319	92	20.00	8	160.00
320	92	10.00	4	40.00
321	92	5.00	12	60.00
322	92	1.00	77	77.00
323	93	200.00	2	400.00
324	93	100.00	10	1000.00
325	93	50.00	20	1000.00
326	93	20.00	9	180.00
327	93	10.00	77	770.00
328	93	5.00	54	270.00
329	93	2.00	128	256.00
330	93	1.00	299	299.00
331	93	0.50	2	1.00
332	94	500.00	1	500.00
333	94	200.00	7	1400.00
334	94	100.00	31	3100.00
335	94	50.00	19	950.00
336	94	20.00	89	1780.00
337	94	10.00	43	430.00
338	94	5.00	14	70.00
339	94	2.00	1	2.00
340	94	1.00	44	44.00
341	95	500.00	12	6000.00
342	95	200.00	12	2400.00
343	95	50.00	12	600.00
344	95	20.00	3	60.00
345	95	10.00	11	110.00
346	95	100.00	28	2800.00
347	95	5.00	37	185.00
348	95	2.00	33	66.00
349	95	1.00	74	74.00
350	95	0.50	1	0.50
351	96	200.00	16	3200.00
352	96	100.00	48	4800.00
353	96	50.00	40	2000.00
354	96	20.00	157	3140.00
355	96	10.00	153	1530.00
356	96	5.00	1	5.00
357	96	2.00	6	12.00
358	96	0.50	2	1.00
359	96	1.00	139	139.00
360	97	50.00	33	1650.00
361	97	1000.00	1	1000.00
362	97	10.00	9	90.00
363	97	5.00	2	10.00
364	97	1.00	55	55.00
365	97	100.00	15	1500.00
366	97	20.00	75	1500.00
367	98	200.00	18	3600.00
368	98	500.00	5	2500.00
369	98	100.00	21	2100.00
370	98	50.00	33	1650.00
371	98	20.00	10	200.00
372	98	10.00	13	130.00
373	98	5.00	9	45.00
374	98	2.00	17	34.00
375	98	1.00	27	27.00
376	101	500.00	5	2500.00
377	101	200.00	7	1400.00
378	101	100.00	18	1800.00
379	101	50.00	17	850.00
380	101	20.00	10	200.00
381	101	10.00	150	1500.00
382	101	5.00	19	95.00
383	101	1.00	17	17.00
384	101	2.00	15	30.00
385	102	200.00	3	600.00
386	102	100.00	7	700.00
387	102	50.00	65	3250.00
388	102	20.00	45	900.00
389	102	500.00	3	1500.00
390	102	10.00	62	620.00
391	102	5.00	44	220.00
392	102	2.00	79	158.00
393	102	1.00	104	104.00
394	103	500.00	8	4000.00
395	103	200.00	5	1000.00
396	103	100.00	13	1300.00
397	103	50.00	22	1100.00
398	103	20.00	42	840.00
399	103	10.00	56	560.00
400	103	5.00	76	380.00
401	103	2.00	34	68.00
402	103	1.00	28	28.00
403	105	500.00	4	2000.00
404	105	200.00	4	800.00
405	105	100.00	31	3100.00
406	105	50.00	14	700.00
407	105	20.00	1	20.00
408	105	10.00	28	280.00
409	105	5.00	94	470.00
410	105	2.00	3	6.00
411	105	1.00	71	71.00
412	105	0.50	2	1.00
413	106	500.00	4	2000.00
414	106	200.00	17	3400.00
415	106	100.00	7	700.00
416	106	50.00	8	400.00
417	106	10.00	8	80.00
418	106	20.00	2	40.00
419	106	5.00	26	130.00
420	106	2.00	62	124.00
421	106	1.00	168	168.00
422	107	500.00	2	1000.00
423	107	200.00	6	1200.00
424	107	100.00	31	3100.00
425	107	50.00	18	900.00
426	107	20.00	7	140.00
427	107	10.00	74	740.00
428	107	5.00	1	5.00
429	107	0.50	5	2.50
430	107	2.00	55	110.00
431	107	1.00	88	88.00
432	108	2.00	34	68.00
433	108	5.00	72	360.00
434	108	1.00	43	43.00
435	108	10.00	45	450.00
436	108	20.00	18	360.00
437	108	50.00	31	1550.00
438	108	100.00	8	800.00
439	108	200.00	14	2800.00
440	108	500.00	5	2500.00
441	109	500.00	4	2000.00
442	109	200.00	4	800.00
443	109	100.00	25	2500.00
444	109	50.00	37	1850.00
445	109	20.00	1	20.00
446	109	10.00	5	50.00
447	109	5.00	39	195.00
448	109	1.00	51	51.00
449	111	500.00	1	500.00
450	111	100.00	12	1200.00
451	111	50.00	15	750.00
452	111	5.00	4	20.00
453	111	10.00	1	10.00
454	111	1.00	13	13.00
455	111	2.00	4	8.00
456	112	100.00	34	3400.00
457	112	50.00	27	1350.00
458	112	20.00	1	20.00
459	112	10.00	2	20.00
460	112	5.00	102	510.00
461	112	2.00	57	114.00
462	112	1.00	161	161.00
463	112	0.50	7	3.50
464	110	1.00	53	53.00
465	110	2.00	36	72.00
466	110	5.00	56	280.00
467	110	10.00	64	640.00
468	110	20.00	17	340.00
469	110	50.00	30	1500.00
470	110	100.00	22	2200.00
471	110	200.00	3	600.00
472	110	500.00	3	1500.00
473	114	1000.00	1	1000.00
474	114	1.00	539	539.00
475	115	500.00	3	1500.00
476	115	200.00	22	4400.00
477	115	100.00	45	4500.00
478	115	50.00	40	2000.00
479	115	5.00	26	130.00
480	115	1.00	18	18.00
481	117	0.50	2	1.00
482	117	1.00	54	54.00
483	117	2.00	57	114.00
484	117	5.00	58	290.00
485	117	10.00	22	220.00
486	117	20.00	9	180.00
487	117	50.00	38	1900.00
488	117	100.00	4	400.00
489	117	200.00	9	1800.00
490	117	500.00	13	6500.00
491	117	1000.00	1	1000.00
492	116	500.00	8	4000.00
493	116	200.00	10	2000.00
494	116	100.00	35	3500.00
495	116	50.00	15	750.00
496	116	20.00	25	500.00
497	116	10.00	36	360.00
498	116	5.00	33	165.00
499	116	2.00	61	122.00
500	116	1.00	98	98.00
501	116	0.50	2	1.00
502	118	500.00	9	4500.00
503	118	200.00	13	2600.00
504	118	100.00	24	2400.00
505	118	50.00	35	1750.00
506	118	20.00	47	940.00
507	118	10.00	2	20.00
508	118	2.00	21	42.00
509	118	1.00	46	46.00
510	118	0.50	6	3.00
511	120	500.00	2	1000.00
512	120	20.00	1	20.00
513	120	10.00	13	130.00
514	120	2.00	22	44.00
515	120	1.00	86	86.00
516	120	0.50	2	1.00
517	121	500.00	6	3000.00
518	121	200.00	4	800.00
519	121	100.00	27	2700.00
520	121	50.00	28	1400.00
521	121	20.00	9	180.00
522	121	10.00	25	250.00
523	121	5.00	20	100.00
524	121	2.00	39	78.00
525	121	1.00	119	119.00
526	121	0.50	4	2.00
527	122	1000.00	1	1000.00
528	122	500.00	10	5000.00
529	122	200.00	2	400.00
530	122	100.00	1	100.00
531	122	50.00	30	1500.00
532	122	20.00	8	160.00
533	122	10.00	3	30.00
534	122	5.00	103	515.00
535	122	2.00	1	2.00
536	122	1.00	29	29.00
537	119	1000.00	2	2000.00
538	119	500.00	6	3000.00
539	119	200.00	2	400.00
540	119	100.00	10	1000.00
541	119	50.00	23	1150.00
542	119	20.00	43	860.00
543	119	10.00	33	330.00
544	119	5.00	1	5.00
545	119	2.00	35	70.00
546	119	1.00	88	88.00
547	119	0.50	10	5.00
548	123	500.00	9	4500.00
549	123	200.00	4	800.00
550	123	100.00	16	1600.00
551	123	50.00	25	1250.00
552	123	20.00	23	460.00
553	123	10.00	9	90.00
554	123	5.00	29	145.00
555	123	2.00	21	42.00
556	123	1.00	23	23.00
557	124	500.00	1	500.00
558	124	50.00	6	300.00
559	124	20.00	8	160.00
560	124	10.00	21	210.00
561	124	2.00	17	34.00
562	124	1.00	79	79.00
563	124	0.50	2	1.00
564	125	500.00	3	1500.00
565	125	200.00	7	1400.00
566	125	100.00	21	2100.00
567	125	50.00	40	2000.00
568	125	10.00	6	60.00
569	125	5.00	4	20.00
570	125	1.00	61	61.00
571	126	500.00	1	500.00
572	126	200.00	2	400.00
573	126	100.00	29	2900.00
574	126	50.00	37	1850.00
575	126	20.00	29	580.00
576	126	10.00	1	10.00
577	126	5.00	41	205.00
578	126	2.00	80	160.00
579	126	1.00	103	103.00
580	127	200.00	7	1400.00
581	127	100.00	12	1200.00
582	127	50.00	24	1200.00
583	127	10.00	70	700.00
584	127	20.00	1	20.00
585	127	0.50	21	10.50
586	127	1.00	44	44.00
587	127	2.00	100	200.00
588	127	5.00	100	500.00
589	128	1.00	56	56.00
590	128	2.00	95	190.00
591	128	5.00	51	255.00
592	128	10.00	43	430.00
593	128	20.00	12	240.00
594	128	50.00	29	1450.00
595	128	100.00	35	3500.00
596	128	200.00	5	1000.00
597	128	500.00	4	2000.00
598	129	500.00	1	500.00
599	129	200.00	1	200.00
600	129	20.00	6	120.00
601	129	50.00	1	50.00
602	129	10.00	17	170.00
603	129	2.00	8	16.00
604	129	1.00	80	80.00
605	129	0.50	2	1.00
606	130	500.00	2	1000.00
607	130	200.00	10	2000.00
608	130	100.00	16	1600.00
609	130	50.00	28	1400.00
610	130	20.00	9	180.00
611	130	10.00	26	260.00
612	130	5.00	118	590.00
613	130	2.00	82	164.00
614	130	1.00	122	122.00
615	130	0.50	2	1.00
616	131	500.00	5	2500.00
617	131	200.00	7	1400.00
618	131	100.00	11	1100.00
619	131	50.00	32	1600.00
620	131	20.00	2	40.00
621	131	10.00	31	310.00
622	131	5.00	104	520.00
623	131	2.00	77	154.00
624	131	1.00	49	49.00
625	131	0.50	2	1.00
626	132	100.00	16	1600.00
627	132	50.00	32	1600.00
628	132	20.00	69	1380.00
629	132	500.00	1	500.00
630	132	10.00	62	620.00
631	132	5.00	212	1060.00
632	132	2.00	26	52.00
633	132	1.00	11	11.00
634	132	0.50	1	0.50
635	133	500.00	4	2000.00
636	133	200.00	11	2200.00
637	133	100.00	15	1500.00
638	133	50.00	38	1900.00
639	133	20.00	7	140.00
640	133	10.00	67	670.00
641	133	5.00	49	245.00
642	133	2.00	60	120.00
643	133	1.00	65	65.00
644	134	500.00	1	500.00
645	134	200.00	2	400.00
646	134	100.00	1	100.00
647	134	50.00	1	50.00
648	134	20.00	4	80.00
649	134	10.00	9	90.00
650	134	5.00	1	5.00
651	134	2.00	4	8.00
652	134	1.00	74	74.00
653	134	0.50	2	1.00
654	135	500.00	4	2000.00
655	135	200.00	6	1200.00
656	135	100.00	11	1100.00
657	135	50.00	21	1050.00
658	135	20.00	26	520.00
659	135	10.00	24	240.00
660	135	5.00	116	580.00
661	135	2.00	59	118.00
662	135	1.00	125	125.00
663	135	0.50	2	1.00
664	136	1000.00	1	1000.00
665	136	500.00	1	500.00
666	136	100.00	19	1900.00
667	136	50.00	23	1150.00
668	136	20.00	9	180.00
669	136	10.00	23	230.00
670	136	5.00	110	550.00
671	136	2.00	78	156.00
672	136	1.00	93	93.00
673	137	200.00	5	1000.00
674	137	100.00	24	2400.00
675	137	50.00	43	2150.00
676	137	20.00	103	2060.00
677	137	10.00	36	360.00
678	137	5.00	30	150.00
679	137	2.00	5	10.00
680	137	0.50	1	0.50
681	137	1.00	146	146.00
682	138	500.00	4	2000.00
683	138	200.00	4	800.00
684	138	100.00	35	3500.00
685	138	50.00	36	1800.00
686	138	20.00	7	140.00
687	138	10.00	52	520.00
688	138	5.00	45	225.00
689	138	2.00	23	46.00
690	138	1.00	31	31.00
691	139	1.00	104	104.00
692	139	2.00	4	8.00
693	139	5.00	13	65.00
694	139	10.00	9	90.00
695	139	20.00	7	140.00
696	139	200.00	1	200.00
697	139	500.00	5	2500.00
698	140	500.00	2	1000.00
699	140	200.00	8	1600.00
700	140	100.00	14	1400.00
701	140	50.00	9	450.00
702	140	20.00	18	360.00
703	140	10.00	45	450.00
704	140	5.00	100	500.00
705	140	2.00	44	88.00
706	140	1.00	122	122.00
707	141	50.00	29	1450.00
708	141	10.00	4	40.00
709	141	5.00	108	540.00
710	141	2.00	61	122.00
711	141	1.00	108	108.00
712	141	100.00	2	200.00
713	141	20.00	2	40.00
714	142	500.00	1	500.00
715	142	5.00	228	1140.00
716	142	2.00	6	12.00
717	142	10.00	11	110.00
718	142	1.00	48	48.00
719	143	500.00	2	1000.00
720	143	200.00	12	2400.00
721	143	100.00	16	1600.00
722	143	50.00	32	1600.00
723	143	20.00	8	160.00
724	143	10.00	47	470.00
725	143	5.00	72	360.00
726	143	2.00	88	176.00
727	143	1.00	94	94.00
\.


--
-- TOC entry 5844 (class 0 OID 0)
-- Dependencies: 519
-- Name: precorte_efectivo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('precorte_efectivo_id_seq', 727, true);


--
-- TOC entry 5845 (class 0 OID 0)
-- Dependencies: 520
-- Name: precorte_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('precorte_id_seq', 143, true);


--
-- TOC entry 5433 (class 0 OID 26375)
-- Dependencies: 521
-- Data for Name: precorte_otros; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

COPY precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) FROM stdin;
1	2	CREDITO	5711.00	\N	\N		2025-09-19 17:21:55.001189-06
2	2	DEBITO	806.00	\N	\N		2025-09-19 17:21:55.001189-06
3	1	CREDITO	3416.00	\N	\N		2025-09-19 17:40:11.568475-06
4	1	DEBITO	260.00	\N	\N		2025-09-19 17:40:11.568475-06
5	4	CREDITO	1077.00	\N	\N		2025-09-20 16:08:21.380278-06
6	4	DEBITO	1504.00	\N	\N		2025-09-20 16:08:21.380278-06
7	3	CREDITO	1550.00	\N	\N		2025-09-20 16:28:07.566137-06
8	3	DEBITO	4555.00	\N	\N		2025-09-20 16:28:07.566137-06
9	5	CREDITO	1891.00	\N	\N		2025-09-22 18:12:34.803104-06
10	5	DEBITO	5356.00	\N	\N		2025-09-22 18:12:34.803104-06
11	6	CREDITO	1956.00	\N	\N		2025-09-23 18:06:12.730547-06
12	6	DEBITO	6182.80	\N	\N		2025-09-23 18:06:12.730547-06
13	7	CREDITO	701.00	\N	\N		2025-09-23 18:20:10.001467-06
14	7	DEBITO	2384.00	\N	\N		2025-09-23 18:20:10.001467-06
15	8	CREDITO	2316.00	\N	\N		2025-09-25 17:47:55.732764-06
16	8	DEBITO	7510.00	\N	\N		2025-09-25 17:47:55.732764-06
17	9	CREDITO	1151.00	\N	\N		2025-09-25 18:06:21.200563-06
18	9	DEBITO	2737.00	\N	\N		2025-09-25 18:06:21.200563-06
19	10	CREDITO	1336.00	\N	\N		2025-09-26 17:49:04.176735-06
20	10	DEBITO	5729.80	\N	\N		2025-09-26 17:49:04.176735-06
21	11	CREDITO	1048.00	\N	\N		2025-09-26 18:11:52.023796-06
22	11	DEBITO	1400.00	\N	\N		2025-09-26 18:11:52.023796-06
23	12	CREDITO	2247.00	\N	\N		2025-09-27 16:01:16.834449-06
24	12	DEBITO	5161.00	\N	\N		2025-09-27 16:01:16.834449-06
25	13	CREDITO	1748.00	\N	\N		2025-09-27 16:20:14.495049-06
26	13	DEBITO	3775.20	\N	\N		2025-09-27 16:20:14.495049-06
27	14	CREDITO	1987.00	\N	\N		2025-09-29 17:42:35.006548-06
28	14	DEBITO	6032.00	\N	\N		2025-09-29 17:42:35.006548-06
29	16	CREDITO	2644.00	\N	\N		2025-09-30 17:34:12.321052-06
30	16	DEBITO	6588.00	\N	\N		2025-09-30 17:34:12.321052-06
33	18	CREDITO	2622.00	\N	\N		2025-10-01 17:53:11.127489-06
34	18	DEBITO	6560.00	\N	\N		2025-10-01 17:53:11.127489-06
35	21	CREDITO	3474.00	\N	\N		2025-10-02 18:17:02.202864-06
36	20	CREDITO	2792.00	\N	\N		2025-10-02 18:34:03.277333-06
37	20	DEBITO	8616.00	\N	\N		2025-10-02 18:34:03.277333-06
38	23	CREDITO	2307.00	\N	\N		2025-10-03 17:54:08.653655-06
39	23	DEBITO	6786.00	\N	\N		2025-10-03 17:54:08.653655-06
40	22	CREDITO	1892.00	\N	\N		2025-10-03 17:54:26.741336-06
41	22	DEBITO	1544.00	\N	\N		2025-10-03 17:54:26.741336-06
42	24	CREDITO	2879.00	\N	\N		2025-10-06 18:11:37.018112-06
43	24	DEBITO	7849.80	\N	\N		2025-10-06 18:11:37.018112-06
46	28	CREDITO	2161.00	\N	\N		2025-11-06 18:56:45.30236-06
47	28	DEBITO	4283.00	\N	\N		2025-11-06 18:56:45.30236-06
48	27	CREDITO	922.00	\N	\N		2025-11-06 19:07:39.909335-06
49	27	DEBITO	3948.00	\N	\N		2025-11-06 19:07:39.909335-06
52	31	CREDITO	1050.00	\N	\N		2025-11-07 17:18:28.346567-06
53	31	DEBITO	3722.00	\N	\N		2025-11-07 17:18:28.346567-06
54	32	CREDITO	1857.00	\N	\N		2025-11-08 15:21:19.121478-06
55	32	DEBITO	4687.80	\N	\N		2025-11-08 15:21:19.121478-06
56	33	CREDITO	1330.00	\N	\N		2025-11-08 15:41:07.05459-06
57	33	DEBITO	4143.00	\N	\N		2025-11-08 15:41:07.05459-06
58	74	CREDITO	1426.00	\N	\N		2025-11-10 18:40:13.221745-06
59	74	DEBITO	4438.80	\N	\N		2025-11-10 18:40:13.221745-06
60	79	CREDITO	1.00	\N	\N		2025-11-10 22:17:52.628948-06
61	79	DEBITO	1.00	\N	\N		2025-11-10 22:17:52.628948-06
62	79	TRANSFER	1.00	\N	\N		2025-11-10 22:17:52.628948-06
63	83	CREDITO	1.00	\N	\N		2025-11-10 22:53:13.22135-06
64	83	DEBITO	1.00	\N	\N		2025-11-10 22:53:13.22135-06
65	83	TRANSFER	1.00	\N	\N		2025-11-10 22:53:13.22135-06
66	84	CREDITO	944.00	\N	\N		2025-11-11 17:43:39.330208-06
67	84	DEBITO	2159.00	\N	\N		2025-11-11 17:43:39.330208-06
68	85	CREDITO	2543.00	\N	\N		2025-11-11 18:00:19.105404-06
69	85	DEBITO	5619.00	\N	\N		2025-11-11 18:00:19.105404-06
70	86	CREDITO	2010.00	\N	\N		2025-11-12 17:40:44.151932-06
71	86	DEBITO	281.60	\N	\N		2025-11-12 17:40:44.151932-06
72	87	CREDITO	2702.50	\N	\N		2025-11-12 18:17:57.614822-06
73	87	DEBITO	5617.00	\N	\N		2025-11-12 18:17:57.614822-06
74	88	CREDITO	1131.00	\N	\N		2025-11-13 17:37:20.903102-06
75	88	DEBITO	2886.00	\N	\N		2025-11-13 17:37:20.903102-06
76	89	CREDITO	2751.20	\N	\N		2025-11-13 17:48:30.090908-06
77	89	DEBITO	6434.20	\N	\N		2025-11-13 17:48:30.090908-06
78	91	DEBITO	332.00	\N	\N	nada	2025-11-14 10:53:56.91234-06
79	92	CREDITO	639.00	\N	\N		2025-11-14 16:22:36.756769-06
80	92	DEBITO	2202.00	\N	\N		2025-11-14 16:22:36.756769-06
81	93	CREDITO	3240.00	\N	\N		2025-11-14 16:52:59.281603-06
82	93	DEBITO	5670.50	\N	\N		2025-11-14 16:52:59.281603-06
83	94	CREDITO	2005.00	\N	\N		2025-11-15 15:30:13.792723-06
84	94	DEBITO	4695.00	\N	\N		2025-11-15 15:30:13.792723-06
85	95	CREDITO	835.00	\N	\N		2025-11-15 15:45:36.013858-06
86	95	DEBITO	4276.00	\N	\N		2025-11-15 15:45:36.013858-06
87	96	CREDITO	1958.00	\N	\N		2025-11-15 15:58:42.314042-06
88	96	DEBITO	6225.60	\N	\N		2025-11-15 15:58:42.314042-06
89	97	CREDITO	1334.00	\N	\N		2025-11-18 18:08:32.446246-06
90	97	DEBITO	2085.00	\N	\N		2025-11-18 18:08:32.446246-06
91	98	CREDITO	774.00	\N	\N		2025-11-18 18:54:48.658064-06
92	98	DEBITO	3616.00	\N	\N		2025-11-18 18:54:48.658064-06
93	101	CREDITO	931.60	\N	\N		2025-11-19 17:36:46.012812-06
94	101	DEBITO	3715.00	\N	\N		2025-11-19 17:36:46.012812-06
95	102	CREDITO	1780.00	\N	\N		2025-11-19 18:01:10.697947-06
96	102	DEBITO	53096.80	\N	\N		2025-11-19 18:01:10.697947-06
97	103	CREDITO	656.00	\N	\N	EN UNA VENTA DE MISCELANEA DE UN MONTO DE 10$  INGRESÉ AL SISTEMA Y COBRE CON 20$ Y LA CAJA NO ABRIÓ NI ARROJÓ TICKET	2025-11-19 18:50:57.003272-06
98	103	DEBITO	3.26	\N	\N	EN UNA VENTA DE MISCELANEA DE UN MONTO DE 10$  INGRESÉ AL SISTEMA Y COBRE CON 20$ Y LA CAJA NO ABRIÓ NI ARROJÓ TICKET	2025-11-19 18:50:57.003272-06
99	105	CREDITO	670.00	\N	\N	sistema lento	2025-11-20 15:41:09.170671-06
100	105	DEBITO	3576.00	\N	\N	sistema lento	2025-11-20 15:41:09.170671-06
101	106	CREDITO	1356.00	\N	\N	EXCEDENTE DE LA CAJA 2	2025-11-20 18:07:07.46622-06
102	106	DEBITO	2941.00	\N	\N	EXCEDENTE DE LA CAJA 2	2025-11-20 18:07:07.46622-06
103	107	CREDITO	1040.80	\N	\N		2025-11-20 18:19:35.388949-06
104	107	DEBITO	5398.00	\N	\N		2025-11-20 18:19:35.388949-06
105	108	CREDITO	994.00	\N	\N	Se anularon 3 tickets, dos por error en la orden y uno tenemos duda.	2025-11-20 19:24:02.439143-06
106	108	DEBITO	3399.00	\N	\N	Se anularon 3 tickets, dos por error en la orden y uno tenemos duda.	2025-11-20 19:24:02.439143-06
107	109	CREDITO	1295.00	\N	\N	Gustavo anuló una compra de prueba	2025-11-21 15:47:22.078226-06
108	109	DEBITO	3414.00	\N	\N	Gustavo anuló una compra de prueba	2025-11-21 15:47:22.078226-06
109	111	CREDITO	933.00	\N	\N		2025-11-21 16:48:25.939086-06
110	111	DEBITO	2922.80	\N	\N		2025-11-21 16:48:25.939086-06
111	112	CREDITO	1404.80	\N	\N		2025-11-21 17:08:38.365128-06
112	112	DEBITO	5779.00	\N	\N		2025-11-21 17:08:38.365128-06
113	110	CREDITO	590.00	\N	\N		2025-11-21 18:51:22.75158-06
114	110	DEBITO	3444.00	\N	\N		2025-11-21 18:51:22.75158-06
115	115	CREDITO	858.00	\N	\N	ventas débito terminal de mercado libre y ventas de crédito terminal banorte	2025-11-22 15:35:24.892144-06
116	115	DEBITO	3174.00	\N	\N	ventas débito terminal de mercado libre y ventas de crédito terminal banorte	2025-11-22 15:35:24.892144-06
117	117	CREDITO	1919.00	\N	\N		2025-11-22 15:45:14.698016-06
118	117	DEBITO	3445.00	\N	\N		2025-11-22 15:45:14.698016-06
119	116	CREDITO	1516.00	\N	\N		2025-11-22 15:49:24.695782-06
120	116	DEBITO	4517.00	\N	\N		2025-11-22 15:49:24.695782-06
121	118	CREDITO	4393.80	\N	\N		2025-11-22 16:26:49.69647-06
122	118	DEBITO	2096.20	\N	\N		2025-11-22 16:26:49.69647-06
123	120	CREDITO	39.00	\N	\N		2025-11-24 11:30:54.43018-06
124	120	DEBITO	30.00	\N	\N		2025-11-24 11:30:54.43018-06
125	121	CREDITO	779.00	\N	\N		2025-11-24 15:54:25.902176-06
126	121	DEBITO	3360.00	\N	\N		2025-11-24 15:54:25.902176-06
127	122	CREDITO	1097.40	\N	\N		2025-11-24 17:33:30.534192-06
128	122	DEBITO	2536.00	\N	\N		2025-11-24 17:33:30.534192-06
129	119	CREDITO	1982.00	\N	\N		2025-11-24 17:58:34.086512-06
130	119	DEBITO	4721.00	\N	\N		2025-11-24 17:58:34.086512-06
131	123	CREDITO	1007.00	\N	\N		2025-11-24 18:41:16.238146-06
132	123	DEBITO	3945.00	\N	\N		2025-11-24 18:41:16.238146-06
133	124	CREDITO	55.00	\N	\N		2025-11-25 11:12:40.391278-06
134	125	CREDITO	743.00	\N	\N	tarjetas de crédito terminal banorte, ventas débito terminal mercado libre	2025-11-25 15:52:46.209929-06
135	125	DEBITO	3343.80	\N	\N	tarjetas de crédito terminal banorte, ventas débito terminal mercado libre	2025-11-25 15:52:46.209929-06
136	126	CREDITO	335.00	\N	\N		2025-11-25 18:05:13.166514-06
137	126	DEBITO	3313.00	\N	\N		2025-11-25 18:05:13.166514-06
138	127	CREDITO	2719.00	\N	\N		2025-11-25 18:20:30.610051-06
139	127	DEBITO	4410.40	\N	\N		2025-11-25 18:20:30.610051-06
140	128	CREDITO	1335.00	\N	\N		2025-11-25 18:44:41.849861-06
141	128	DEBITO	4332.00	\N	\N		2025-11-25 18:44:41.849861-06
142	130	CREDITO	1074.00	\N	\N		2025-11-26 15:50:18.852035-06
143	130	DEBITO	3514.00	\N	\N		2025-11-26 15:50:18.852035-06
144	131	DEBITO	4502.01	\N	\N		2025-11-26 17:39:59.628731-06
145	132	DEBITO	6963.00	\N	\N		2025-11-26 18:15:59.156979-06
146	133	CREDITO	1365.00	\N	\N	Durante un cobro con tarjeta la terminal se apagó, por lo que no tenemos la certeza si el dinero de dicha transacción se cobró correctamente ya que después la terminal no imprimió el ticket de esa transacción. El producto era unas papas o unas malangas. El producto sí se ingresó al sistema.	2025-11-26 19:08:37.208346-06
147	133	DEBITO	3442.00	\N	\N	Durante un cobro con tarjeta la terminal se apagó, por lo que no tenemos la certeza si el dinero de dicha transacción se cobró correctamente ya que después la terminal no imprimió el ticket de esa transacción. El producto era unas papas o unas malangas. El producto sí se ingresó al sistema.	2025-11-26 19:08:37.208346-06
148	134	CREDITO	96.00	\N	\N		2025-11-27 11:31:33.931928-06
149	134	DEBITO	143.00	\N	\N		2025-11-27 11:31:33.931928-06
150	135	CREDITO	588.00	\N	\N		2025-11-27 15:48:20.131232-06
151	135	DEBITO	3186.00	\N	\N		2025-11-27 15:48:20.131232-06
152	136	CREDITO	914.00	\N	\N		2025-11-27 18:05:39.846524-06
153	136	DEBITO	2987.00	\N	\N		2025-11-27 18:05:39.846524-06
154	137	CREDITO	8808.05	\N	\N		2025-11-27 18:26:17.193426-06
155	138	CREDITO	1124.00	\N	\N		2025-11-27 18:47:20.704094-06
156	138	DEBITO	3973.00	\N	\N		2025-11-27 18:47:20.704094-06
157	139	CREDITO	13.00	\N	\N		2025-11-28 11:11:12.706693-06
158	139	DEBITO	321.00	\N	\N		2025-11-28 11:11:12.706693-06
159	140	CREDITO	877.00	\N	\N		2025-11-28 15:45:00.05154-06
160	140	DEBITO	2707.00	\N	\N		2025-11-28 15:45:00.05154-06
161	141	DEBITO	4069.00	\N	\N		2025-11-28 16:45:54.590351-06
162	142	CREDITO	1480.00	\N	\N		2025-11-28 17:02:02.248927-06
163	142	DEBITO	5179.60	\N	\N		2025-11-28 17:02:02.248927-06
164	143	CREDITO	1032.00	\N	\N		2025-11-28 18:51:58.358426-06
165	143	DEBITO	3102.00	\N	\N		2025-11-28 18:51:58.358426-06
\.


--
-- TOC entry 5846 (class 0 OID 0)
-- Dependencies: 522
-- Name: precorte_otros_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('precorte_otros_id_seq', 165, true);


--
-- TOC entry 5435 (class 0 OID 26385)
-- Dependencies: 523
-- Data for Name: prod_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY prod_cab (id, sol_id, fecha_programada, estado, creada_por, aprobada_por, created_at) FROM stdin;
\.


--
-- TOC entry 5847 (class 0 OID 0)
-- Dependencies: 524
-- Name: prod_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('prod_cab_id_seq', 1, false);


--
-- TOC entry 5437 (class 0 OID 26392)
-- Dependencies: 525
-- Data for Name: prod_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY prod_det (id, prod_id, sr_id, cantidad, rendimiento, created_at) FROM stdin;
\.


--
-- TOC entry 5848 (class 0 OID 0)
-- Dependencies: 526
-- Name: prod_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('prod_det_id_seq', 1, false);


--
-- TOC entry 5439 (class 0 OID 26398)
-- Dependencies: 527
-- Data for Name: production_order_inputs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY production_order_inputs (id, production_order_id, item_id, inventory_batch_id, qty, uom, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5849 (class 0 OID 0)
-- Dependencies: 528
-- Name: production_order_inputs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('production_order_inputs_id_seq', 1, false);


--
-- TOC entry 5441 (class 0 OID 26406)
-- Dependencies: 529
-- Data for Name: production_order_outputs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY production_order_outputs (id, production_order_id, item_id, inventory_batch_id, lote_producido, fecha_caducidad, qty, uom, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5850 (class 0 OID 0)
-- Dependencies: 530
-- Name: production_order_outputs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('production_order_outputs_id_seq', 1, false);


--
-- TOC entry 5443 (class 0 OID 26414)
-- Dependencies: 531
-- Data for Name: production_orders; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY production_orders (id, folio, recipe_id, item_id, qty_programada, qty_producida, qty_merma, uom_base, sucursal_id, almacen_id, programado_para, iniciado_en, cerrado_en, estado, creado_por, aprobado_por, notas, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5851 (class 0 OID 0)
-- Dependencies: 532
-- Name: production_orders_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('production_orders_id_seq', 1, false);


--
-- TOC entry 5445 (class 0 OID 26426)
-- Dependencies: 533
-- Data for Name: proveedor; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY proveedor (id, nombre, rfc, activo) FROM stdin;
\.


--
-- TOC entry 5446 (class 0 OID 26433)
-- Dependencies: 534
-- Data for Name: purchase_documents; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_documents (id, request_id, quote_id, order_id, tipo, file_url, uploaded_by, notas, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5852 (class 0 OID 0)
-- Dependencies: 535
-- Name: purchase_documents_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_documents_id_seq', 1, false);


--
-- TOC entry 5448 (class 0 OID 26441)
-- Dependencies: 536
-- Data for Name: purchase_order_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_order_lines (id, order_id, request_line_id, item_id, qty, uom, precio_unitario, descuento, impuestos, total, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5853 (class 0 OID 0)
-- Dependencies: 537
-- Name: purchase_order_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_order_lines_id_seq', 1, false);


--
-- TOC entry 5450 (class 0 OID 26451)
-- Dependencies: 538
-- Data for Name: purchase_orders; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_orders (id, folio, quote_id, vendor_id, sucursal_id, estado, fecha_promesa, subtotal, descuento, impuestos, total, creado_por, aprobado_por, aprobado_en, notas, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5854 (class 0 OID 0)
-- Dependencies: 539
-- Name: purchase_orders_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_orders_id_seq', 1, false);


--
-- TOC entry 5452 (class 0 OID 26464)
-- Dependencies: 540
-- Data for Name: purchase_request_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_request_lines (id, request_id, item_id, qty, uom, fecha_requerida, preferred_vendor_id, last_price, estado, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5855 (class 0 OID 0)
-- Dependencies: 541
-- Name: purchase_request_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_request_lines_id_seq', 1, false);


--
-- TOC entry 5454 (class 0 OID 26473)
-- Dependencies: 542
-- Data for Name: purchase_requests; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_requests (id, folio, sucursal_id, created_by, requested_by, requested_at, estado, importe_estimado, notas, meta, created_at, updated_at, fecha_requerida, almacen_destino_id, justificacion, urgente, origen_suggestion_id) FROM stdin;
\.


--
-- TOC entry 5856 (class 0 OID 0)
-- Dependencies: 543
-- Name: purchase_requests_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_requests_id_seq', 1, false);


--
-- TOC entry 5456 (class 0 OID 26485)
-- Dependencies: 544
-- Data for Name: purchase_suggestion_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_suggestion_lines (id, suggestion_id, item_id, stock_actual, stock_min, stock_max, reorder_point, consumo_promedio_diario, dias_cobertura_actual, demanda_proyectada, qty_sugerida, qty_ajustada, uom, costo_unitario_estimado, costo_total_linea, proveedor_sugerido_id, ultimo_precio_compra, fecha_ultima_compra, notas, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5857 (class 0 OID 0)
-- Dependencies: 545
-- Name: purchase_suggestion_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_suggestion_lines_id_seq', 1, false);


--
-- TOC entry 5458 (class 0 OID 26497)
-- Dependencies: 546
-- Data for Name: purchase_suggestions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_suggestions (id, folio, sucursal_id, almacen_id, estado, prioridad, origen, total_items, total_estimado, sugerido_en, sugerido_por_user_id, revisado_por_user_id, revisado_en, convertido_a_request_id, convertido_en, dias_analisis, consumo_promedio_calculado, notas, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5858 (class 0 OID 0)
-- Dependencies: 547
-- Name: purchase_suggestions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_suggestions_id_seq', 1, false);


--
-- TOC entry 5460 (class 0 OID 26513)
-- Dependencies: 548
-- Data for Name: purchase_vendor_quote_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_vendor_quote_lines (id, quote_id, request_line_id, item_id, qty_oferta, uom_oferta, precio_unitario, pack_size, pack_uom, monto_total, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5859 (class 0 OID 0)
-- Dependencies: 549
-- Name: purchase_vendor_quote_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_vendor_quote_lines_id_seq', 1, false);


--
-- TOC entry 5462 (class 0 OID 26522)
-- Dependencies: 550
-- Data for Name: purchase_vendor_quotes; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_vendor_quotes (id, request_id, vendor_id, folio_proveedor, estado, enviada_en, recibida_en, subtotal, descuento, impuestos, total, capturada_por, aprobada_por, aprobada_en, notas, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5860 (class 0 OID 0)
-- Dependencies: 551
-- Name: purchase_vendor_quotes_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_vendor_quotes_id_seq', 1, false);


--
-- TOC entry 5464 (class 0 OID 26536)
-- Dependencies: 552
-- Data for Name: recalc_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recalc_log (id, job_id, step, started_ts, ended_ts, ok, details) FROM stdin;
\.


--
-- TOC entry 5861 (class 0 OID 0)
-- Dependencies: 553
-- Name: recalc_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recalc_log_id_seq', 1, false);


--
-- TOC entry 5466 (class 0 OID 26544)
-- Dependencies: 554
-- Data for Name: recepcion_adjuntos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recepcion_adjuntos (id, recepcion_id, tipo, file_url, notas, uploaded_by, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5862 (class 0 OID 0)
-- Dependencies: 555
-- Name: recepcion_adjuntos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recepcion_adjuntos_id_seq', 1, false);


--
-- TOC entry 5468 (class 0 OID 26552)
-- Dependencies: 556
-- Data for Name: recepcion_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recepcion_cab (id, sucursal_id, proveedor_id, oc_ref, ts, usuario_id, meta, almacen_id, numero_recepcion, fecha_recepcion, estado, total_presentaciones, total_canonico, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5863 (class 0 OID 0)
-- Dependencies: 557
-- Name: recepcion_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recepcion_cab_id_seq', 1, false);


--
-- TOC entry 5470 (class 0 OID 26563)
-- Dependencies: 558
-- Data for Name: recepcion_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recepcion_det (id, recepcion_id, item_id, bodega_id, qty, um_id, costo_unit, batch_id, temperatura, doc_url, meta, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5864 (class 0 OID 0)
-- Dependencies: 559
-- Name: recepcion_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recepcion_det_id_seq', 1, false);


--
-- TOC entry 5472 (class 0 OID 26573)
-- Dependencies: 560
-- Data for Name: receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta (id, codigo, nombre, porciones, pvp_objetivo, activo, meta) FROM stdin;
\.


--
-- TOC entry 5395 (class 0 OID 26131)
-- Dependencies: 483
-- Data for Name: receta_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5396 (class 0 OID 26145)
-- Dependencies: 484
-- Data for Name: receta_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta_det (id, receta_version_id, item_id, cantidad, unidad_medida, merma_porcentaje, instrucciones_especificas, orden, created_at) FROM stdin;
\.


--
-- TOC entry 5865 (class 0 OID 0)
-- Dependencies: 561
-- Name: receta_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_det_id_seq', 1, false);


--
-- TOC entry 5866 (class 0 OID 0)
-- Dependencies: 562
-- Name: receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_id_seq', 1, false);


--
-- TOC entry 5475 (class 0 OID 26585)
-- Dependencies: 563
-- Data for Name: receta_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta_insumo (id, receta_version_id, item_id, cantidad) FROM stdin;
\.


--
-- TOC entry 5867 (class 0 OID 0)
-- Dependencies: 564
-- Name: receta_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_insumo_id_seq', 1, false);


--
-- TOC entry 5477 (class 0 OID 26590)
-- Dependencies: 565
-- Data for Name: receta_shadow; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta_shadow (id, codigo_plato_pos, nombre_plato, estado, confianza, total_ventas_analizadas, fecha_primer_venta, fecha_ultima_venta, frecuencia_dias, ingredientes_inferidos, usuario_validador, fecha_validacion, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5868 (class 0 OID 0)
-- Dependencies: 566
-- Name: receta_shadow_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_shadow_id_seq', 1, false);


--
-- TOC entry 5397 (class 0 OID 26156)
-- Dependencies: 485
-- Data for Name: receta_version; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) FROM stdin;
\.


--
-- TOC entry 5869 (class 0 OID 0)
-- Dependencies: 567
-- Name: receta_version_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_version_id_seq', 1, false);


--
-- TOC entry 5480 (class 0 OID 26607)
-- Dependencies: 568
-- Data for Name: recipe_cost_history; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_cost_history (id, recipe_id, recipe_version_id, snapshot_at, currency_code, batch_cost, portion_cost, batch_size, yield_portions, notes, created_at) FROM stdin;
\.


--
-- TOC entry 5870 (class 0 OID 0)
-- Dependencies: 569
-- Name: recipe_cost_history_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_cost_history_id_seq', 1, false);


--
-- TOC entry 5482 (class 0 OID 26617)
-- Dependencies: 570
-- Data for Name: recipe_cost_snapshots; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_cost_snapshots (id, recipe_id, snapshot_date, cost_total, cost_per_portion, portions, cost_breakdown, reason, created_by_user_id, created_at) FROM stdin;
\.


--
-- TOC entry 5871 (class 0 OID 0)
-- Dependencies: 571
-- Name: recipe_cost_snapshots_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_cost_snapshots_id_seq', 1, false);


--
-- TOC entry 5484 (class 0 OID 26630)
-- Dependencies: 572
-- Data for Name: recipe_extended_cost_history; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_extended_cost_history (id, recipe_id, snapshot_at, mp_batch_cost, labor_batch_cost, overhead_batch_cost, total_batch_cost, portion_cost, yield_portions, breakdown, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5872 (class 0 OID 0)
-- Dependencies: 573
-- Name: recipe_extended_cost_history_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_extended_cost_history_id_seq', 1, false);


--
-- TOC entry 5486 (class 0 OID 26645)
-- Dependencies: 574
-- Data for Name: recipe_labor_steps; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_labor_steps (id, recipe_id, labor_role_id, nombre, duracion_minutos, costo_manual, orden, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5873 (class 0 OID 0)
-- Dependencies: 575
-- Name: recipe_labor_steps_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_labor_steps_id_seq', 1, false);


--
-- TOC entry 5488 (class 0 OID 26655)
-- Dependencies: 576
-- Data for Name: recipe_overhead_allocations; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_overhead_allocations (id, recipe_id, overhead_id, valor, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5874 (class 0 OID 0)
-- Dependencies: 577
-- Name: recipe_overhead_allocations_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_overhead_allocations_id_seq', 1, false);


--
-- TOC entry 5490 (class 0 OID 26663)
-- Dependencies: 578
-- Data for Name: recipe_version_items; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_version_items (id, recipe_version_id, item_id, qty, uom_receta) FROM stdin;
\.


--
-- TOC entry 5875 (class 0 OID 0)
-- Dependencies: 579
-- Name: recipe_version_items_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_version_items_id_seq', 1, false);


--
-- TOC entry 5492 (class 0 OID 26668)
-- Dependencies: 580
-- Data for Name: recipe_versions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_versions (id, recipe_id, version_no, notes, valid_from, valid_to, created_at) FROM stdin;
\.


--
-- TOC entry 5876 (class 0 OID 0)
-- Dependencies: 581
-- Name: recipe_versions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_versions_id_seq', 1, false);


--
-- TOC entry 5494 (class 0 OID 26678)
-- Dependencies: 582
-- Data for Name: replenishment_suggestions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY replenishment_suggestions (id, folio, tipo, prioridad, origen, item_id, sucursal_id, almacen_id, stock_actual, stock_min, stock_max, qty_sugerida, qty_aprobada, uom, consumo_promedio_diario, dias_stock_restante, fecha_agotamiento_estimada, estado, purchase_request_id, production_order_id, sugerido_en, revisado_en, revisado_por, convertido_en, caduca_en, motivo, motivo_rechazo, notas, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5877 (class 0 OID 0)
-- Dependencies: 583
-- Name: replenishment_suggestions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('replenishment_suggestions_id_seq', 1, false);


--
-- TOC entry 5496 (class 0 OID 26690)
-- Dependencies: 584
-- Data for Name: report_definitions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY report_definitions (id, name, slug, category, config, is_system, created_by, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5878 (class 0 OID 0)
-- Dependencies: 585
-- Name: report_definitions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('report_definitions_id_seq', 1, false);


--
-- TOC entry 5498 (class 0 OID 26699)
-- Dependencies: 586
-- Data for Name: report_favorites; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY report_favorites (id, user_id, report_key, meta, created_at, updated_at) FROM stdin;
9	3	merma_promedio	{"range": "custom", "title": "Merma Promedio"}	2025-11-04 20:43:07-06	2025-11-04 20:43:07-06
\.


--
-- TOC entry 5879 (class 0 OID 0)
-- Dependencies: 587
-- Name: report_favorites_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('report_favorites_id_seq', 9, true);


--
-- TOC entry 5500 (class 0 OID 26707)
-- Dependencies: 588
-- Data for Name: report_runs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY report_runs (id, report_id, requested_by, status, filters, result_meta, storage_path, queued_at, started_at, finished_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5880 (class 0 OID 0)
-- Dependencies: 589
-- Name: report_runs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('report_runs_id_seq', 1, false);


--
-- TOC entry 5502 (class 0 OID 26716)
-- Dependencies: 590
-- Data for Name: rol; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY rol (id, codigo, nombre) FROM stdin;
\.


--
-- TOC entry 5881 (class 0 OID 0)
-- Dependencies: 591
-- Name: rol_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('rol_id_seq', 1, false);


--
-- TOC entry 5504 (class 0 OID 26724)
-- Dependencies: 592
-- Data for Name: role_has_permissions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY role_has_permissions (permission_id, role_id) FROM stdin;
1	1
2	1
3	1
4	1
5	1
6	1
7	1
8	1
9	1
10	1
11	1
12	1
13	1
14	1
15	1
16	1
17	1
18	1
19	1
20	1
21	1
22	1
23	1
24	1
25	1
26	1
27	1
28	1
29	1
30	1
31	1
32	1
33	1
34	1
35	1
36	1
37	1
38	1
39	1
40	1
41	1
42	1
43	1
44	1
45	1
1	2
2	2
3	2
4	2
8	2
9	2
10	2
15	2
16	2
17	2
18	2
19	2
20	2
21	2
22	2
23	2
24	2
25	2
26	2
27	2
28	2
30	2
31	2
32	2
33	2
34	2
35	2
36	2
37	2
1	3
2	3
3	3
4	3
8	3
9	3
10	3
15	3
17	3
18	3
19	3
24	3
26	3
27	3
30	3
35	3
1	4
4	4
3	4
20	4
21	4
30	4
31	4
35	4
1	5
10	5
15	5
16	5
17	5
18	5
19	5
26	5
35	5
1	6
10	6
24	6
33	6
35	6
1	7
10	7
15	7
24	7
26	7
30	7
35	7
\.


--
-- TOC entry 5505 (class 0 OID 26727)
-- Dependencies: 593
-- Data for Name: roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY roles (id, name, guard_name, created_at, updated_at, display_name, description, color) FROM stdin;
1	Super Admin	web	2025-11-02 12:31:13	2025-11-02 12:31:13	\N	\N	\N
2	Ops Manager	web	2025-11-02 12:31:13	2025-11-02 12:31:13	\N	\N	\N
3	inventario.manager	web	2025-11-02 12:31:14	2025-11-02 12:31:14	\N	\N	\N
4	purchasing	web	2025-11-02 12:31:14	2025-11-02 12:31:14	\N	\N	\N
5	kitchen	web	2025-11-02 12:31:14	2025-11-02 12:31:14	\N	\N	\N
6	cashier	web	2025-11-02 12:31:14	2025-11-02 12:31:14	\N	\N	\N
7	viewer	web	2025-11-02 12:31:14	2025-11-02 12:31:14	\N	\N	\N
\.


--
-- TOC entry 5882 (class 0 OID 0)
-- Dependencies: 594
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('roles_id_seq', 7, true);


--
-- TOC entry 5883 (class 0 OID 0)
-- Dependencies: 595
-- Name: seq_cat_codigo; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('seq_cat_codigo', 1, false);


--
-- TOC entry 5508 (class 0 OID 26737)
-- Dependencies: 596
-- Data for Name: sesion_cajon; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

COPY sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id, skipped_precorte) FROM stdin;
1	PRINCIPAL	101	101	6	2025-09-17 08:06:04.081128-06	2025-09-17 18:40:36.846-06	LISTO_PARA_CORTE	2500.00	11978.40	128	f
2	PRINCIPAL	102	102	13	2025-09-17 08:22:58.686625-06	2025-09-17 18:58:35.293-06	LISTO_PARA_CORTE	2500.00	6855.60	129	f
3	PRINCIPAL	101	101	6	2025-09-18 07:55:08.545545-06	2025-09-18 19:04:31.893-06	LISTO_PARA_CORTE	2500.00	12431.80	132	f
4	PRINCIPAL	102	102	13	2025-09-18 08:38:34.748483-06	2025-09-18 19:25:14.389-06	LISTO_PARA_CORTE	2500.00	6562.20	133	f
25	PRINCIPAL	102	102	13	2025-09-29 08:13:42.556641-06	2025-09-29 19:06:29.323-06	LISTO_PARA_CORTE	2500.00	7317.00	175	f
26	ENTRADA	401	Terminal 401	8	2025-09-29 13:50:03.517437-06	2025-09-30 07:34:02.682-06	LISTO_PARA_CORTE	0.00	85.00	176	f
10	PRINCIPAL	102	102	13	2025-09-22 07:42:24.379279-06	2025-09-22 08:44:43.447-06	LISTO_PARA_CORTE	2500.00	2500.00	144	f
9	PRINCIPAL	101	101	6	2025-09-22 07:23:40.164587-06	2025-09-22 08:45:33.192-06	LISTO_PARA_CORTE	2500.00	2500.00	145	f
27	ENTRADA	401	Terminal 401	8	2025-09-30 06:34:22.295356-06	2025-09-30 11:29:54.720725-06	LISTO_PARA_CORTE	1000.00	1121.00	\N	t
11	PRINCIPAL	102	102	13	2025-09-22 07:54:43.01876-06	2025-09-22 19:32:00.981-06	LISTO_PARA_CORTE	2500.00	6630.00	150	f
29	ENTRADA	401	Terminal 401	8	2025-09-30 09:31:01.736-06	2025-09-30 11:29:54.720725-06	LISTO_PARA_CORTE	1001.00	1121.00	179	t
16	PRINCIPAL	101	101	6	2025-09-24 07:55:07.848467-06	2025-09-24 18:18:57.576-06	LISTO_PARA_CORTE	2500.00	10189.00	157	f
17	PRINCIPAL	102	102	8	2025-09-24 08:36:30.21109-06	2025-09-24 18:53:59.454-06	LISTO_PARA_CORTE	2500.00	6477.40	158	f
30	PRINCIPAL	102	102	8	2025-09-30 08:31:02.987154-06	2025-09-30 12:29:54.681-06	LISTO_PARA_CORTE	2500.00	4078.00	180	f
40	PRINCIPAL	101	101	6	2025-10-04 07:37:48.614896-06	2025-10-04 16:00:10.487-06	LISTO_PARA_CORTE	2500.00	16045.00	204	f
41	PRINCIPAL	102	102	8	2025-10-04 07:39:50.938951-06	2025-10-04 16:07:54.937-06	LISTO_PARA_CORTE	2500.00	11230.20	205	f
31	ENTRADA	401	Terminal 401	8	2025-10-01 06:32:59.763091-06	2025-10-02 07:50:54.355-06	LISTO_PARA_CORTE	1000.00	1000.00	188	f
33	PRINCIPAL	102	102	13	2025-10-01 08:16:10.61867-06	2025-10-02 08:45:35.013-06	LISTO_PARA_CORTE	2500.00	5084.00	191	f
34	ENTRADA	401	Terminal 401	8	2025-10-02 06:53:37.537881-06	2025-10-02 12:23:35.95-06	LISTO_PARA_CORTE	1000.00	1150.00	193	f
50	PRINCIPAL	101	101	6	2025-10-08 07:34:06.872535-06	2025-10-08 18:53:09.901-06	LISTO_PARA_CORTE	2500.00	3714.20	220	f
42	ENTRADA	401	Terminal 401	8	2025-10-06 06:58:10.890961-06	2025-10-06 11:17:26.862837-06	LISTO_PARA_CORTE	1000.00	1070.00	\N	t
37	ENTRADA	401	Terminal 401	8	2025-10-03 06:22:54.235856-06	2025-10-03 12:21:38.593-06	LISTO_PARA_CORTE	1000.00	1300.00	199	f
44	ENTRADA	401	Terminal 401	8	2025-10-06 08:26:44.277-06	2025-10-06 11:17:26.862837-06	LISTO_PARA_CORTE	1070.00	1070.00	208	t
51	PRINCIPAL	102	102	13	2025-10-08 08:58:23.297741-06	2025-10-08 18:56:04.039-06	LISTO_PARA_CORTE	2500.00	2650.00	221	f
45	PRINCIPAL	102	102	8	2025-10-06 07:26:45.279096-06	2025-10-06 12:17:26.712-06	LISTO_PARA_CORTE	2500.00	4443.40	209	f
48	PRINCIPAL	102	102	8	2025-10-07 07:50:03.753591-06	2025-10-07 12:23:48.722-06	LISTO_PARA_CORTE	2500.00	4397.00	215	f
46	ENTRADA	401	Terminal 401	8	2025-10-07 06:29:05.297092-06	2025-10-07 11:23:48.96552-06	LISTO_PARA_CORTE	1000.00	1270.00	\N	t
47	ENTRADA	401	Terminal 401	8	2025-10-07 08:50:02.803-06	2025-10-07 11:23:48.96552-06	LISTO_PARA_CORTE	1055.00	1270.00	213	t
49	PRINCIPAL	101	101	6	2025-10-07 07:50:28.797539-06	2025-10-07 18:35:06.164-06	LISTO_PARA_CORTE	2500.00	10537.60	216	f
53	PRINCIPAL	102	102	8	2025-10-09 08:28:21.068893-06	2025-10-09 12:26:12.523-06	LISTO_PARA_CORTE	2500.00	3642.00	225	f
54	PRINCIPAL	102	102	8	2025-10-09 11:17:14.532-06	2025-10-09 12:26:12.523-06	LISTO_PARA_CORTE	3642.00	3642.00	224	f
55	ENTRADA	401	Terminal 401	8	2025-10-09 10:17:14.748923-06	2025-10-09 11:26:12.654384-06	LISTO_PARA_CORTE	1000.00	1004.00	\N	t
52	PRINCIPAL	101	101	6	2025-10-09 07:35:27.204894-06	2025-10-09 18:40:51.165-06	LISTO_PARA_CORTE	2500.00	12017.00	226	f
59	PRINCIPAL	102	102	8	2025-10-10 08:32:40.331227-06	2025-10-10 10:53:05.497-06	LISTO_PARA_CORTE	2500.00	3785.00	231	f
56	ENTRADA	401	Terminal 401	8	2025-10-10 06:26:30.557316-06	2025-10-10 09:53:05.651058-06	LISTO_PARA_CORTE	1000.00	1168.00	\N	t
58	ENTRADA	401	Terminal 401	8	2025-10-10 09:32:39.661-06	2025-10-10 09:53:05.651058-06	LISTO_PARA_CORTE	1168.00	1168.00	230	t
57	PRINCIPAL	101	101	6	2025-10-10 07:42:15.822091-06	2025-10-10 17:46:02.907-06	LISTO_PARA_CORTE	2500.00	8551.20	232	f
60	PRINCIPAL	102	102	8	2025-10-11 07:27:10.31438-06	2025-10-11 16:20:46.121-06	LISTO_PARA_CORTE	2500.00	16128.00	236	f
61	PRINCIPAL	101	101	6	2025-10-11 07:28:37.111777-06	2025-10-11 16:31:39.055-06	LISTO_PARA_CORTE	2500.00	14646.00	237	f
65	PRINCIPAL	102	102	8	2025-10-13 08:06:33.330098-06	2025-10-13 12:20:17.589-06	LISTO_PARA_CORTE	2500.00	5847.00	241	f
62	ENTRADA	401	Terminal 401	8	2025-10-13 06:19:16.258862-06	2025-10-13 11:20:17.739527-06	LISTO_PARA_CORTE	1000.00	1187.00	\N	t
64	ENTRADA	401	Terminal 401	8	2025-10-13 09:06:33.203-06	2025-10-13 11:20:17.739527-06	LISTO_PARA_CORTE	1083.00	1187.00	240	t
63	PRINCIPAL	101	101	6	2025-10-13 07:55:19.518505-06	2025-10-13 18:45:36.27-06	LISTO_PARA_CORTE	2500.00	8064.20	243	f
69	PRINCIPAL	101	101	6	2025-10-14 07:59:01.739723-06	2025-10-14 18:47:54.514-06	LISTO_PARA_CORTE	2500.00	7946.80	248	f
67	PRINCIPAL	102	102	6	2025-10-14 07:27:05.84751-06	2025-10-14 18:54:21.56-06	LISTO_PARA_CORTE	2500.00	8240.00	249	f
66	ENTRADA	401	Terminal 401	8	2025-10-14 06:14:29.514346-06	2025-10-14 12:29:58.618-06	LISTO_PARA_CORTE	1000.00	1220.60	247	f
68	PRINCIPAL	102	102	6	2025-10-14 08:59:01.679-06	2025-10-14 18:54:21.56-06	LISTO_PARA_CORTE	2500.00	8240.00	246	f
72	PRINCIPAL	101	101	8	2025-10-15 07:16:53.811492-06	2025-10-15 12:19:45.211-06	LISTO_PARA_CORTE	2500.00	5400.40	253	f
70	ENTRADA	401	Terminal 401	8	2025-10-15 06:36:32.674744-06	2025-10-15 11:19:45.385882-06	LISTO_PARA_CORTE	1000.00	1271.00	\N	t
6	PRINCIPAL	101	101	6	2025-09-19 08:05:06.546538-06	2025-09-19 17:32:08.086-06	CERRADA	2500.00	7646.80	136	f
8	PRINCIPAL	102	102	8	2025-09-20 08:06:12.507865-06	2025-09-20 17:09:08.011-06	CERRADA	2500.00	7670.80	140	f
7	PRINCIPAL	101	101	6	2025-09-20 08:02:00.219905-06	2025-09-20 17:28:32.719-06	CERRADA	2500.00	10567.80	141	f
12	PRINCIPAL	101	101	6	2025-09-22 07:55:26.463681-06	2025-09-22 19:17:27.465-06	CERRADA	2500.00	12812.40	149	f
14	PRINCIPAL	102	102	8	2025-09-23 08:05:50.31703-06	2025-09-23 19:20:21.37-06	CERRADA	2500.00	6634.00	154	f
15	PRINCIPAL	101	101	6	2025-09-23 08:12:22.383953-06	2025-09-23 19:06:39.067-06	CERRADA	2500.00	10491.00	153	f
18	PRINCIPAL	101	101	6	2025-09-25 08:02:42.676315-06	2025-09-25 18:17:49.372-06	CERRADA	2500.00	11131.00	161	f
19	PRINCIPAL	102	102	13	2025-09-25 08:34:14.59031-06	2025-09-25 19:06:31.864-06	CERRADA	2500.00	6766.60	162	f
21	PRINCIPAL	102	102	13	2025-09-26 07:51:34.273578-06	2025-09-26 19:12:01.605-06	CERRADA	2500.00	5845.00	166	f
20	PRINCIPAL	101	101	6	2025-09-26 07:46:01.310139-06	2025-09-26 18:49:26.925-06	CERRADA	2500.00	9153.80	165	f
22	PRINCIPAL	101	101	6	2025-09-27 07:34:05.109531-06	2025-09-27 17:01:50.172-06	CERRADA	2500.00	14607.00	169	f
23	PRINCIPAL	102	102	8	2025-09-27 08:06:24.105709-06	2025-09-27 17:20:26.501-06	CERRADA	2500.00	10576.00	170	f
24	PRINCIPAL	101	101	6	2025-09-29 08:01:23.827279-06	2025-09-29 18:43:17.06-06	CERRADA	2500.00	11353.00	174	f
28	PRINCIPAL	101	101	6	2025-09-30 08:02:39.594419-06	2025-09-30 18:34:37.968-06	CERRADA	2500.00	11307.80	181	f
32	PRINCIPAL	101	101	6	2025-10-01 06:55:42.45592-06	2025-10-01 18:53:33.939-06	CERRADA	2500.00	9239.00	187	f
36	PRINCIPAL	102	102	13	2025-10-02 07:45:54.688896-06	2025-10-02 19:35:23.257-06	CERRADA	2500.00	5981.00	195	f
35	PRINCIPAL	101	101	6	2025-10-02 07:40:27.395912-06	2025-10-02 19:34:28.113-06	CERRADA	2500.00	12735.80	194	f
39	PRINCIPAL	102	102	13	2025-10-03 08:30:35.753797-06	2025-10-03 18:54:52.529-06	CERRADA	2500.00	4735.00	201	f
38	PRINCIPAL	101	101	6	2025-10-03 07:54:37.094581-06	2025-10-03 18:54:35.126-06	CERRADA	2500.00	8444.00	200	f
43	PRINCIPAL	101	101	6	2025-10-06 07:19:03.292037-06	2025-10-06 19:11:58.854-06	CERRADA	2500.00	11255.00	210	f
71	ENTRADA	401	Terminal 401	8	2025-10-15 08:16:52.894-06	2025-10-15 11:19:45.385882-06	LISTO_PARA_CORTE	1020.00	1271.00	251	t
73	PRINCIPAL	102	102	6	2025-10-15 07:17:38.405685-06	2025-10-15 18:22:18.748-06	LISTO_PARA_CORTE	2500.00	7751.00	254	f
74	ENTRADA	401	Terminal 401	8	2025-10-16 06:06:23.103373-06	2025-10-16 07:06:27.364-06	LISTO_PARA_CORTE	500.00	500.00	257	f
78	PRINCIPAL	101	101	6	2025-10-16 08:03:55.646781-06	2025-10-16 18:42:31.452-06	LISTO_PARA_CORTE	2500.00	7140.80	261	f
77	PRINCIPAL	102	102	8	2025-10-16 08:02:43.794352-06	2025-10-16 19:02:46.819-06	LISTO_PARA_CORTE	2500.00	8295.00	262	f
81	PRINCIPAL	101	101	6	2025-10-17 08:09:49.931669-06	2025-10-17 17:55:33.029-06	LISTO_PARA_CORTE	2500.00	4823.20	265	f
79	PRINCIPAL	102	102	6	2025-10-17 07:47:06.451915-06	2025-10-17 16:55:32.974294-06	LISTO_PARA_CORTE	2500.00	8582.00	\N	t
80	PRINCIPAL	102	102	6	2025-10-17 09:09:49.867-06	2025-10-17 16:55:32.974294-06	LISTO_PARA_CORTE	2564.00	8582.00	264	t
84	PRINCIPAL	102	102	6	2025-10-18 06:57:40.121727-06	2025-10-18 16:09:18.045-06	LISTO_PARA_CORTE	2500.00	10786.00	269	f
83	PRINCIPAL	101	101	8	2025-10-18 06:55:35.815537-06	2025-10-18 16:09:26.857-06	LISTO_PARA_CORTE	2500.00	10858.40	270	f
87	PRINCIPAL	101	101	6	2025-10-20 08:05:20.47362-06	2025-10-20 18:32:10.853-06	LISTO_PARA_CORTE	2500.00	7058.00	273	f
85	PRINCIPAL	102	102	6	2025-10-20 07:50:42.262013-06	2025-10-20 18:54:04.541-06	LISTO_PARA_CORTE	2500.00	7739.00	274	f
86	PRINCIPAL	102	102	6	2025-10-20 09:05:20.415-06	2025-10-20 18:54:04.541-06	LISTO_PARA_CORTE	2500.00	7739.00	272	f
88	PRINCIPAL	101	101	6	2025-10-21 08:03:33.225142-06	2025-10-21 17:18:47.237-06	LISTO_PARA_CORTE	2500.00	5927.60	277	f
90	PRINCIPAL	102	102	8	2025-10-21 08:08:11.225768-06	2025-10-21 18:46:50.73-06	LISTO_PARA_CORTE	2500.00	8040.00	278	f
92	PRINCIPAL	101	101	8	2025-10-22 07:03:35.377218-06	2025-10-22 17:00:43.27-06	LISTO_PARA_CORTE	2500.00	6199.00	281	f
93	PRINCIPAL	102	102	6	2025-10-22 07:07:18.357403-06	2025-10-22 18:40:02.655-06	LISTO_PARA_CORTE	2500.00	7817.00	282	f
96	PRINCIPAL	101	101	6	2025-10-23 08:11:08.580936-06	2025-10-23 18:08:19.57-06	LISTO_PARA_CORTE	2500.00	6237.00	285	f
94	PRINCIPAL	102	102	6	2025-10-23 07:46:49.545493-06	2025-10-23 19:14:01.32-06	LISTO_PARA_CORTE	2500.00	7874.00	286	f
95	PRINCIPAL	102	102	6	2025-10-23 08:11:07.696-06	2025-10-23 19:14:01.32-06	LISTO_PARA_CORTE	2500.00	7874.00	284	f
97	PRINCIPAL	101	101	6	2025-10-24 07:46:29.34105-06	2025-10-24 16:12:42.358-06	LISTO_PARA_CORTE	2500.00	5911.00	289	f
99	PRINCIPAL	102	102	8	2025-10-24 08:09:42.411768-06	2025-10-24 17:31:34.441-06	LISTO_PARA_CORTE	2500.00	7602.00	290	f
101	PRINCIPAL	101	101	8	2025-10-25 07:18:03.623768-06	2025-10-25 16:15:22.281-06	LISTO_PARA_CORTE	2500.00	6254.00	293	f
102	PRINCIPAL	102	102	6	2025-10-25 07:19:51.524247-06	2025-10-25 17:20:46.98-06	LISTO_PARA_CORTE	2500.00	10285.00	294	f
103	PRINCIPAL	101	101	6	2025-10-27 08:05:39.785984-06	2025-10-27 17:54:32.954-06	LISTO_PARA_CORTE	2500.00	7665.00	297	f
104	PRINCIPAL	101	101	6	2025-10-27 08:26:04.685-06	2025-10-27 17:54:32.954-06	LISTO_PARA_CORTE	2565.00	7665.00	296	f
105	PRINCIPAL	102	102	6	2025-10-27 08:26:04.680608-06	2025-10-27 17:55:49.552-06	LISTO_PARA_CORTE	2500.00	7814.00	298	f
107	PRINCIPAL	102	102	8	2025-10-28 07:53:05.598979-06	2025-10-28 17:15:52.249-06	LISTO_PARA_CORTE	2500.00	6889.00	301	f
108	PRINCIPAL	101	101	6	2025-10-28 08:02:53.095579-06	2025-10-28 17:42:08.403-06	LISTO_PARA_CORTE	2500.00	4811.00	302	f
110	PRINCIPAL	101	101	8	2025-10-29 07:29:41.830574-06	2025-10-29 17:56:48.243-06	LISTO_PARA_CORTE	2500.00	6105.00	305	f
111	PRINCIPAL	102	102	6	2025-10-29 07:35:07.38462-06	2025-10-29 17:59:59.173-06	LISTO_PARA_CORTE	2500.00	7442.00	306	f
114	PRINCIPAL	101	101	8	2025-10-30 07:31:06.875328-06	2025-10-30 16:54:59.993-06	LISTO_PARA_CORTE	2500.00	3413.00	309	f
112	PRINCIPAL	102	102	6	2025-10-30 07:28:49.364087-06	2025-10-30 17:40:10.786-06	LISTO_PARA_CORTE	2500.00	10769.00	310	f
117	PRINCIPAL	101	101	8	2025-10-31 08:57:00.330315-06	2025-10-31 15:19:29.884-06	LISTO_PARA_CORTE	2500.00	3407.00	313	f
115	PRINCIPAL	102	102	6	2025-10-31 08:34:40.271255-06	2025-10-31 15:31:19.368-06	LISTO_PARA_CORTE	2500.00	2996.00	314	f
120	PRINCIPAL	101	101	8	2025-11-03 08:09:31.61643-06	2025-11-03 10:52:17.079-06	LISTO_PARA_CORTE	2500.00	2751.00	317	f
122	PRINCIPAL	101	101	8	2025-11-03 11:01:14.137814-06	2025-11-03 17:44:08.151-06	LISTO_PARA_CORTE	2500.00	5349.00	319	f
118	PRINCIPAL	102	102	6	2025-11-03 08:01:00.23551-06	2025-11-03 18:01:56.164-06	LISTO_PARA_CORTE	2500.00	12119.00	320	f
75	ENTRADA	401	Terminal 401	8	2025-10-16 06:07:00.991373-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1000.00	1233.00	321	f
76	ENTRADA	401	Terminal 401	8	2025-10-16 09:02:43.681-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1210.00	1233.00	259	f
82	ENTRADA	401	Terminal 401	14	2025-10-18 07:55:35.428-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1223.00	1233.00	267	f
98	ENTRADA	401	Terminal 401	8	2025-10-24 09:09:40.99-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1223.00	1233.00	288	f
106	ENTRADA	401	Terminal 401	14	2025-10-28 07:53:05.069-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1223.00	1233.00	299	f
100	ENTRADA	401	Terminal 401	14	2025-10-25 07:18:02.074-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1223.00	1233.00	291	f
91	ENTRADA	401	Terminal 401	14	2025-10-22 07:03:35.378-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1223.00	1233.00	279	f
89	ENTRADA	401	Terminal 401	14	2025-10-21 09:08:10.002-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1223.00	1233.00	276	f
121	ENTRADA	401	Terminal 401	14	2025-11-03 11:01:13.351-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1223.00	1233.00	318	f
119	ENTRADA	401	Terminal 401	14	2025-11-03 08:09:31.024-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1223.00	1233.00	316	f
116	ENTRADA	401	Terminal 401	14	2025-10-31 08:57:00.221-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1223.00	1233.00	312	f
113	ENTRADA	401	Terminal 401	14	2025-10-30 07:31:05.995-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1223.00	1233.00	308	f
109	ENTRADA	401	Terminal 401	14	2025-10-29 07:29:41.836-06	2025-11-04 06:56:00.835-06	LISTO_PARA_CORTE	1223.00	1233.00	303	f
126	PRINCIPAL	101	101	8	2025-11-04 08:22:37.071416-06	2025-11-04 11:27:33.078-06	LISTO_PARA_CORTE	2500.00	3577.00	325	f
123	ENTRADA	401	Terminal 401	8	2025-11-04 06:56:16.768307-06	2025-11-04 11:27:33.139638-06	LISTO_PARA_CORTE	1000.00	1153.00	\N	t
124	PRINCIPAL	102	102	6	2025-11-04 07:34:25.707977-06	2025-11-04 17:41:20.479-06	LISTO_PARA_CORTE	2500.00	8895.00	327	f
128	PRINCIPAL	101	101	8	2025-11-05 08:18:56.240872-06	2025-11-05 17:30:49.352-06	LISTO_PARA_CORTE	2500.00	6051.00	330	f
127	PRINCIPAL	102	102	6	2025-11-05 07:49:54.14574-06	2025-11-05 18:01:10.727-06	LISTO_PARA_CORTE	2500.00	8831.00	331	f
134	PRINCIPAL	101	101	1	2025-11-06 19:26:19.386931-06	2025-11-06 19:26:31.035-06	LISTO_PARA_CORTE	500.00	500.00	339	f
136	PRINCIPAL	102	102	1	2025-11-06 19:40:32.565217-06	2025-11-06 19:42:45.661-06	LISTO_PARA_CORTE	500.00	500.00	341	f
137	ENTRADA	401	Terminal 401	14	2025-11-07 06:38:54.520624-06	2025-11-07 11:30:24.518752-06	LISTO_PARA_CORTE	1000.00	1193.00	\N	t
138	ENTRADA	401	Terminal 401	14	2025-11-07 07:49:48.594-06	2025-11-07 11:30:24.518752-06	LISTO_PARA_CORTE	1110.00	1193.00	343	t
131	ENTRADA	401	Terminal 401	14	2025-11-06 08:17:17.669-06	2025-11-06 11:30:48.730565-06	LISTO_PARA_CORTE	1111.00	1241.00	334	t
129	ENTRADA	401	Terminal 401	14	2025-11-06 06:42:10.479132-06	2025-11-06 11:30:48.730565-06	LISTO_PARA_CORTE	1000.00	1241.00	\N	t
125	ENTRADA	401	Terminal 401	14	2025-11-04 08:22:36.49-06	2025-11-04 11:27:33.139638-06	LISTO_PARA_CORTE	1053.00	1153.00	324	t
143	ENTRADA	401	401	14	2025-11-08 13:51:13.283927-06	2025-11-08 13:52:16.148-06	LISTO_PARA_CORTE	0.00	0.00	351	f
132	PRINCIPAL	101	101	8	2025-11-06 08:17:18.639824-06	2025-11-07 11:30:24.46-06	CERRADA	2500.00	4579.00	335	t
140	PRINCIPAL	102	102	6	2025-11-07 07:52:31.640422-06	2025-11-07 17:18:39.393-06	CERRADA	2500.00	8171.80	347	f
142	PRINCIPAL	101	101	12	2025-11-08 08:00:31.946036-06	2025-11-08 15:21:41.397-06	CERRADA	2500.00	12934.60	352	f
130	PRINCIPAL	102	102	6	2025-11-06 07:58:01.348696-06	2025-11-06 18:58:10.705-06	CERRADA	2500.00	8289.00	336	f
144	NB	301	301	11	2025-11-08 15:32:05.297032-06	2025-11-08 15:33:49.596-06	LISTO_PARA_CORTE	0.00	0.00	354	f
147	NB	201	201	7	2025-11-10 12:16:48.742458-06	\N	ACTIVA	0.00	\N	\N	f
139	PRINCIPAL	101	101	8	2025-11-07 07:49:48.602515-06	2025-08-19 18:47:00.868-06	LISTO_PARA_CORTE	2500.00	0.00	345	f
150	TORRE	1090	201	12	2025-11-10 12:16:48.742458-06	\N	ACTIVA	0.00	\N	\N	f
151		1091	Terminal 1091	14	2025-11-10 12:16:48.742458-06	\N	ACTIVA	0.00	\N	\N	f
154	PRINCIPAL	102	102	6	2025-11-10 12:25:08.289269-06	2025-11-10 12:29:52.551-06	LISTO_PARA_CORTE	0.00	0.00	376	f
187	TORRE	301	301	7	2025-11-19 07:52:51.534478-06	2025-11-19 18:52:06.816375-06	CERRADA	2500.00	9272.00	\N	f
188	ENTRADA	401	401	14	2025-11-20 06:41:02.09411-06	2025-11-20 11:11:28.378719-06	EN_CORTE	1000.00	1339.00	\N	t
190	PRINCIPAL	102	102	6	2025-11-20 08:08:35.438467-06	2025-11-20 18:19:51.227789-06	CERRADA	2500.00	8582.80	\N	f
163	PRINCIPAL	101	101	8	2025-11-10 12:53:50.1331-06	2025-11-10 18:30:59.84277-06	CERRADA	2500.00	12559.00	\N	t
149	ENTRADA	401	401	11	2025-11-10 12:16:48.742458-06	2025-11-11 06:25:14.311503-06	LISTO_PARA_CORTE	0.00	0.00	\N	t
166	PRINCIPAL	101	101	8	2025-11-11 08:01:02.023075-06	2025-11-11 17:43:58.973914-06	LISTO_PARA_CORTE	2500.00	5249.00	\N	f
169	PRINCIPAL	101	101	8	2025-11-12 07:11:40.936705-06	2025-11-12 17:40:55.045824-06	CERRADA	2500.00	4854.00	\N	f
194	NB	2486	Terminal 2486	10	2025-11-21 07:34:28.932663-06	2025-11-21 15:47:56.061913-06	CERRADA	2500.00	7466.00	\N	f
172	PRINCIPAL	102	102	6	2025-11-13 07:47:44.939994-06	2025-11-13 17:49:19.128722-06	CERRADA	2500.00	9060.20	\N	f
175	PRINCIPAL	101	101	8	2025-11-14 08:50:38.766515-06	2025-11-14 16:22:57.344325-06	LISTO_PARA_CORTE	2500.00	5122.00	\N	f
148	NB	301	301	8	2025-11-10 12:16:48.742458-06	2025-11-14 19:07:57.82748-06	LISTO_PARA_CORTE	0.00	0.00	\N	t
195	TORRE	301	301	7	2025-11-21 07:52:59.58142-06	2025-11-21 18:36:05.157676-06	CERRADA	2500.00	7184.00	\N	f
178	PRINCIPAL	101	101	8	2025-11-15 07:35:22.67816-06	2025-11-15 15:30:33.9917-06	CERRADA	2500.00	10290.00	\N	f
181	PRINCIPAL	102	102	6	2025-11-18 07:33:43.927176-06	2025-11-18 18:11:24.788657-06	EN_CORTE	2500.00	10412.40	\N	t
184	ENTRADA	401	401	14	2025-11-19 06:42:43.019548-06	2025-11-19 11:10:59.326699-06	LISTO_PARA_CORTE	1000.00	1137.00	\N	t
204	PRINCIPAL	103	103	1	2025-11-22 11:30:48.497202-06	2025-11-22 12:28:50.616929-06	LISTO_PARA_CORTE	0.00	163.00	\N	f
201	TORRE	301	301	7	2025-11-22 08:00:15.755941-06	2025-11-22 15:45:35.440531-06	CERRADA	2500.00	12458.00	\N	f
207	PRINCIPAL	101	101	8	2025-11-24 08:06:40.295532-06	2025-11-24 17:38:54.090391-06	CERRADA	2500.00	7946.00	\N	f
212	TORRE	301	301	7	2025-11-25 07:45:58.131409-06	2025-11-25 18:38:22.213306-06	CERRADA	2500.00	9122.00	\N	f
250	PRINCIPAL	101	101	8	2025-11-26 07:59:54.167438-06	2025-11-26 17:40:28.213822-06	CERRADA	2500.00	6500.80	\N	f
254	PRINCIPAL	102	102	6	2025-11-27 07:37:35.500301-06	2025-11-27 18:27:05.375989-06	CERRADA	2500.00	9333.40	\N	f
257	ENTRADA	401	401	14	2025-11-28 06:35:31.103671-06	2025-11-28 11:11:22.714464-06	CERRADA	1000.00	1102.00	\N	f
260	NB	2486	Terminal 2486	10	2025-11-28 07:55:20.152751-06	2025-11-28 15:45:25.519601-06	CERRADA	2500.00	5967.00	\N	f
264	PRINCIPAL	101	101	12	2025-11-29 07:21:21.905099-06	\N	ACTIVA	2500.00	\N	\N	f
267	PRINCIPAL	103	103	8	2025-11-29 08:02:08.940724-06	2025-11-29 12:02:34.450541-06	LISTO_PARA_CORTE	2500.00	5229.20	\N	t
145	PRINCIPAL	101	101	1	2025-11-10 12:16:48.742458-06	2025-11-10 12:19:18.654-06	LISTO_PARA_CORTE	85.00	85.00	370	f
152	PRINCIPAL	101	101	1	2025-11-10 12:19:12.965-06	2025-11-10 12:19:18.654-06	LISTO_PARA_CORTE	85.00	85.00	369	f
153		9939	Terminal 9939	1	2025-11-10 12:19:16.746187-06	2025-11-10 12:19:22.379803-06	LISTO_PARA_CORTE	500.00	500.00	\N	t
155	PRINCIPAL	101	101	1	2025-11-10 12:28:50.897-06	2025-11-10 12:28:56.144-06	LISTO_PARA_CORTE	85.00	85.00	374	f
156		9939	Terminal 9939	1	2025-11-10 12:28:54.714192-06	2025-11-10 12:28:59.893332-06	LISTO_PARA_CORTE	500.01	500.01	\N	t
252	ENTRADA	401	401	14	2025-11-27 06:25:39.424729-06	2025-11-27 11:31:40.059473-06	CERRADA	1000.00	1301.00	\N	f
185	PRINCIPAL	102	102	6	2025-11-19 07:41:05.141989-06	2025-11-19 18:01:28.911556-06	CERRADA	2500.00	7203.80	\N	f
164	ENTRADA	401	401	14	2025-11-11 06:25:29.942946-06	2025-11-11 10:57:15.265902-06	LISTO_PARA_CORTE	1000.00	1206.00	\N	t
167	ENTRADA	401	401	14	2025-11-12 06:43:10.330404-06	2025-11-12 11:22:56.580125-06	LISTO_PARA_CORTE	1000.00	1166.00	\N	t
170	ENTRADA	401	401	14	2025-11-13 06:37:38.104561-06	2025-11-13 18:16:30.066036-06	CERRADA	1000.00	1173.00	\N	f
191	PRINCIPAL	101	101	8	2025-11-20 08:09:04.101543-06	2025-11-20 18:07:53.084176-06	CERRADA	2500.00	6682.80	\N	f
255	PRINCIPAL	101	101	8	2025-11-27 07:39:58.823732-06	2025-11-27 18:05:58.518024-06	CERRADA	2500.00	5532.00	\N	f
173	ENTRADA	401	401	14	2025-11-14 06:37:32.685627-06	2025-11-14 10:54:08.358692-06	CERRADA	1000.00	1245.00	\N	f
176	TORRE	301	301	1	2025-11-14 19:23:24.648234-06	2025-11-14 22:42:47.958992-06	LISTO_PARA_CORTE	0.00	0.00	\N	t
189	TORRE	301	301	11	2025-11-20 07:59:40.283971-06	2025-11-20 19:24:27.578682-06	CERRADA	2500.00	8907.00	\N	f
179	TORRE	301	301	7	2025-11-15 07:52:13.240405-06	2025-11-15 15:46:03.109048-06	CERRADA	2500.00	12285.00	\N	f
182	PRINCIPAL	101	101	8	2025-11-18 07:36:55.72195-06	2025-11-18 18:08:43.831626-06	CERRADA	2500.00	5805.00	\N	f
258	PRINCIPAL	102	102	6	2025-11-28 07:34:49.506067-06	2025-11-28 17:02:24.714425-06	LISTO_PARA_CORTE	2500.00	8295.00	\N	f
196	PRINCIPAL	102	102	6	2025-11-21 08:05:20.362371-06	2025-11-21 17:08:53.14208-06	CERRADA	2500.00	6048.80	\N	f
202		689	Terminal 689	1	2025-11-22 08:36:47.453197-06	2025-11-22 09:19:34.788107-06	LISTO_PARA_CORTE	0.00	0.00	\N	t
261	TORRE	301	301	11	2025-11-28 07:56:23.205696-06	2025-11-28 18:52:16.394616-06	CERRADA	2500.00	7905.00	\N	f
198	NB	2486	Terminal 2486	10	2025-11-22 07:34:59.044344-06	2025-11-22 15:36:02.302335-06	CERRADA	2500.00	12083.00	\N	f
265	NB	2486	Terminal 2486	10	2025-11-29 07:30:18.975517-06	\N	ACTIVA	2500.00	\N	\N	f
200	PRINCIPAL	102	102	6	2025-11-22 07:57:46.152561-06	2025-11-22 16:27:49.987177-06	CERRADA	2500.00	12180.00	\N	f
205	NB	2486	Terminal 2486	10	2025-11-24 07:48:50.633815-06	2025-11-24 15:54:58.739458-06	CERRADA	2500.00	8629.60	\N	f
208	PRINCIPAL	102	102	6	2025-11-24 08:06:47.514895-06	2025-11-24 17:58:47.83015-06	CERRADA	2500.00	8810.20	\N	f
210	PRINCIPAL	102	102	6	2025-11-25 07:39:36.101519-06	2025-11-25 18:20:47.340548-06	CERRADA	2500.00	9131.60	\N	f
213	PRINCIPAL	101	101	8	2025-11-25 07:55:17.083507-06	2025-11-25 18:05:34.562147-06	CERRADA	2500.00	5791.00	\N	f
215	ENTRADA	401	401	14	2025-11-26 06:58:58.870972-06	2025-11-26 11:44:04.317972-06	CERRADA	1000.00	1136.00	\N	f
248	NB	2486	Terminal 2486	10	2025-11-26 07:56:36.163751-06	2025-11-26 15:50:57.433852-06	CERRADA	2500.00	7317.00	\N	f
251	TORRE	301	301	11	2025-11-26 08:04:13.353324-06	2025-11-26 19:09:02.737264-06	CERRADA	2500.00	8842.00	\N	f
146	PRINCIPAL	102	102	6	2025-11-10 12:16:48.742458-06	2025-11-10 12:21:27.421-06	LISTO_PARA_CORTE	0.00	0.00	371	f
186	PRINCIPAL	101	101	8	2025-11-19 07:42:05.314924-06	2025-11-20 08:08:48.941869-06	LISTO_PARA_CORTE	2500.00	7149.00	\N	f
5	PRINCIPAL	102	102	8	2025-09-19 07:34:21.424031-06	2025-09-19 18:23:02.095-06	CERRADA	2500.00	4890.80	137	f
141	PRINCIPAL	102	102	6	2025-11-08 07:24:41.92378-06	2025-11-08 15:41:19.782-06	CERRADA	2500.00	10780.40	355	f
192	NB	2486	Terminal 2486	10	2025-11-20 08:24:34.712523-06	2025-11-20 15:41:50.528792-06	CERRADA	2500.00	7444.00	\N	f
193	ENTRADA	401	401	14	2025-11-21 06:14:13.751127-06	2025-11-21 11:21:47.910062-06	LISTO_PARA_CORTE	1000.00	1271.00	\N	t
157		9939	Terminal 9939	1	2025-11-10 12:39:38.239407-06	2025-11-10 22:19:41.320417-06	CERRADA	1.00	1.00	\N	f
162	PRINCIPAL	102	102	6	2025-11-10 12:45:21.068868-06	2025-11-10 22:39:11.05109-06	CERRADA	2500.00	9024.20	\N	t
165	PRINCIPAL	102	102	6	2025-11-11 07:46:15.905335-06	2025-11-11 18:00:33.81794-06	LISTO_PARA_CORTE	2500.00	10151.20	\N	f
168	PRINCIPAL	102	102	6	2025-11-12 07:10:52.966461-06	2025-11-12 18:18:15.301459-06	LISTO_PARA_CORTE	2500.00	10422.60	\N	f
197	PRINCIPAL	101	101	8	2025-11-21 08:06:09.355965-06	2025-11-21 16:48:55.369657-06	CERRADA	2500.00	2032.00	\N	f
203		689	Terminal 689	13	2025-11-22 10:25:12.623085-06	\N	ACTIVA	1000.00	\N	\N	f
171	PRINCIPAL	101	101	8	2025-11-13 07:46:58.937786-06	2025-11-13 17:37:35.355348-06	CERRADA	2500.00	5712.00	\N	f
174	PRINCIPAL	102	102	6	2025-11-14 08:01:32.959503-06	2025-11-14 16:53:12.651184-06	LISTO_PARA_CORTE	2500.00	7088.00	\N	f
199	PRINCIPAL	101	101	8	2025-11-22 07:50:13.771823-06	2025-11-22 15:50:30.224131-06	CERRADA	2500.00	11486.20	\N	f
177	PRINCIPAL	102	102	6	2025-11-15 07:34:54.771088-06	2025-11-15 15:58:59.304428-06	CERRADA	2500.00	15284.90	\N	f
183	TORRE	301	301	11	2025-11-18 08:01:54.836818-06	2025-11-18 18:55:25.835784-06	CERRADA	2500.00	10262.00	\N	f
180	ENTRADA	401	401	14	2025-11-18 06:15:12.400601-06	2025-11-18 11:16:00.605121-06	EN_CORTE	1000.00	1169.00	\N	t
209	ENTRADA	401	401	14	2025-11-24 10:39:23.038133-06	2025-11-24 11:29:31.144942-06	CERRADA	1000.00	1271.00	\N	f
206	TORRE	301	301	11	2025-11-24 07:57:11.653374-06	2025-11-24 18:41:50.075682-06	CERRADA	2500.00	8911.00	\N	f
214	ENTRADA	401	401	14	2025-11-25 08:10:33.335475-06	2025-11-25 11:15:22.007454-06	CERRADA	1000.00	1274.00	\N	f
211	NB	2486	Terminal 2486	10	2025-11-25 07:45:06.701843-06	2025-11-25 15:53:18.104805-06	CERRADA	2500.00	7140.00	\N	f
249	PRINCIPAL	102	102	6	2025-11-26 07:58:50.871626-06	2025-11-26 18:16:42.658616-06	CERRADA	2500.00	6703.20	\N	f
253	NB	2486	Terminal 2486	10	2025-11-27 07:24:01.817759-06	2025-11-27 15:50:21.003145-06	CERRADA	2500.00	6932.80	\N	f
256	TORRE	301	301	11	2025-11-27 07:51:53.892936-06	2025-11-27 18:47:39.74986-06	CERRADA	2500.00	9059.00	\N	f
259	PRINCIPAL	101	101	8	2025-11-28 07:35:48.958334-06	2025-11-28 16:46:19.002102-06	CERRADA	2500.00	6199.00	\N	f
262	PRINCIPAL	102	102	6	2025-11-29 07:19:36.055268-06	2025-11-29 07:19:46.947775-06	LISTO_PARA_CORTE	2500.00	2500.00	\N	t
263	PRINCIPAL	102	102	6	2025-11-29 07:20:25.543101-06	\N	ACTIVA	2500.00	\N	\N	f
266	TORRE	301	301	7	2025-11-29 07:58:49.400435-06	\N	ACTIVA	2500.00	\N	\N	f
\.


--
-- TOC entry 5884 (class 0 OID 0)
-- Dependencies: 597
-- Name: sesion_cajon_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('sesion_cajon_id_seq', 267, true);


--
-- TOC entry 5510 (class 0 OID 26750)
-- Dependencies: 598
-- Data for Name: sessions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY sessions (id, user_id, ip_address, user_agent, payload, last_activity) FROM stdin;
hfMl3vsYY1yeiwz46DTGDAm67uxffliXrAGDtHAv	8	192.168.1.210	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	YTo1OntzOjY6Il90b2tlbiI7czo0MDoiUW1yYkhwdm93Rkc0QngwUjgwRHpzNmhON0VuOTFCQjN1cVNIRkJ1dSI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjQ3OiJodHRwOi8vMTkyLjE2OC4xLjIzNS90ZXJyZW5hMi9zZXNzaW9uL2FwaS10b2tlbiI7czo1OiJyb3V0ZSI7czoyNjoic2Vzc2lvbi5hcGktdG9rZW4uZ2VuZXJhdGUiO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX1zOjUwOiJsb2dpbl93ZWJfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aTo4O30=	1764333354
yu4a0KM3C67O4LP6eoBRHJYIUImLJ2E3Els1hta3	5	192.168.1.198	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiTU5nOU1yV3c1ZWdGNkZIT2hZY0JwMDNNT2F0M0l1cjM4YTdUUmREZyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDE6Imh0dHA6Ly8xOTIuMTY4LjEuMjM1L3RlcnJlbmEyL2NhamEvY29ydGVzIjtzOjU6InJvdXRlIjtzOjExOiJjYWphLmNvcnRlcyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjU7fQ==	1764288860
GYZBY79fnKjLX1yDxa0Qf31f1XXsQm8Kg90CKrzu	\N	192.168.1.196	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	YTozOntzOjY6Il90b2tlbiI7czo0MDoiWVNYdzE3RHVFQUdKSWVqdHpiVkZaQkZmb2RFYURqS2g4T2NLSGcyQiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzU6Imh0dHA6Ly8xOTIuMTY4LjEuMjM1L3RlcnJlbmEyL2xvZ2luIjtzOjU6InJvdXRlIjtzOjU6ImxvZ2luIjt9fQ==	1764291654
0KNHzYqWwBAkROFgt8c1oiCfEFZ5JUOkWPCMeUfB	5	192.168.1.198	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiMzFXZ2VxemtXMFEzNUN3RFVNZUROVUFuTVVaVFJOWmEwMjh0a0thRyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDE6Imh0dHA6Ly8xOTIuMTY4LjEuMjM1L3RlcnJlbmEyL2NhamEvY29ydGVzIjtzOjU6InJvdXRlIjtzOjExOiJjYWphLmNvcnRlcyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjU7fQ==	1764369308
9JBSYgPAW9wGTZpAgppuLCC52bkhbiYRnQnlN9i5	8	192.168.1.210	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	YTo1OntzOjY6Il90b2tlbiI7czo0MDoicGwyQlB6U3NPWmxHRHdkOGc1RG9JbWhsQW9kcmtzWmFyYk14WWpSbSI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjQxOiJodHRwOi8vMTkyLjE2OC4xLjIzNS90ZXJyZW5hMi9jYWphL2NvcnRlcyI7czo1OiJyb3V0ZSI7czoxMToiY2FqYS5jb3J0ZXMiO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX1zOjUwOiJsb2dpbl93ZWJfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aTo4O30=	1764349247
MCX68X4yi7S1SX7ZwxZv484KJ9MkIYJZ0d9augxD	9	192.168.1.209	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	YTo0OntzOjY6Il90b2tlbiI7czo0MDoicTkzTXF2OFhKUkZDdHdUQkdRZTVsNlJSUkNaZnVyOWVPOERQNTEwZyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDE6Imh0dHA6Ly8xOTIuMTY4LjEuMjM1L3RlcnJlbmEyL2NhamEvY29ydGVzIjtzOjU6InJvdXRlIjtzOjExOiJjYWphLmNvcnRlcyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjk7fQ==	1764366160
ymKnNuoz5SCt1YwYeUfwslUt2BdwZ4lNLX06HOn9	5	192.168.1.198	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiMllib1JJcU1tMWZ4eFRORlE3dXNYRUJwZFlTak02cXNJRzAwRXg0aSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDE6Imh0dHA6Ly8xOTIuMTY4LjEuMjM1L3RlcnJlbmEyL2NhamEvY29ydGVzIjtzOjU6InJvdXRlIjtzOjExOiJjYWphLmNvcnRlcyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjU7fQ==	1764287687
S0YprkRKYIwJKGYUanc2fuCNU39fuj8jgdxeoBjT	4	192.168.1.198	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiWkFHczY1M3oxbXlQM3pXR284MlFBMmFJc1N6T1BXczFxaG1haHBFbSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDE6Imh0dHA6Ly8xOTIuMTY4LjEuMjM1L3RlcnJlbmEyL2NhamEvY29ydGVzIjtzOjU6InJvdXRlIjtzOjExOiJjYWphLmNvcnRlcyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjQ7fQ==	1764370656
3A4KU5wFTWESd3eWsAa5LeuDkwf7LqXE9fYjeWU9	\N	192.168.1.196	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	YTozOntzOjY6Il90b2tlbiI7czo0MDoiR2Nob051eUVwd0d2Y3hXUVE5ejFySkZCMGU4TTRsUWlRWVlZc3Q5ZiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MzU6Imh0dHA6Ly8xOTIuMTY4LjEuMjM1L3RlcnJlbmEyL2xvZ2luIjtzOjU6InJvdXRlIjtzOjU6ImxvZ2luIjt9fQ==	1764379307
1FFPtXBgiwgORWkInqlMWe44aXO7UqsElTfEcS4t	4	192.168.1.198	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiUW82eTR2SHpJRGt4NFY5d29SWVNybXlOUERMdHhxeklBNUF1ajNmZSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjc4OiJodHRwOi8vMTkyLjE2OC4xLjIzNS90ZXJyZW5hMi9jYWphL2NvcnRlcy9oaXN0b3JpY28/Y2FqZXJvX3VzdWFyaW9faWQ9JmRhdGVfZmlsdGVyPWxhc3Rfd2VlayZkYXRlX2ZpbHRlcl9yYWRpbz1sYXN0X3dlZWsmZGlmZXJlbmNpYV9tYXg9JmRpZmVyZW5jaWFfbWluPSZlc3RhdHVzPSZmZWNoYV9maW49MjAyNS0xMS0yOSZmZWNoYV9pbmljaW89MjAyNS0xMS0wMSZvcmRlcj1kZXNjJnBlcl9wYWdlPTIwJnNlYXJjaD0mc29ydD1hcGVydHVyYV90cyZ0ZXJtaW5hbF9pZD0mdmVyZWRpY3RvPSI7czo1OiJyb3V0ZSI7czoxNDoiY2FqYS5oaXN0b3JpY28iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX1zOjUwOiJsb2dpbl93ZWJfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aTo0O30=	1764444669
Fhb5PJTQT21icZMDvFkJGGQqU3m4XU26Jba0pgrC	\N	100.98.146.92	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	YTozOntzOjY6Il90b2tlbiI7czo0MDoiRnYyaWRkcVRqQVFqMFV0QVRYUnhHYjY2MVRieWV5Um9TekNmazgzNCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mzc6Imh0dHA6Ly8xMDAuMTI2LjEyNC4xMDEvdGVycmVuYTIvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1764447055
\.


--
-- TOC entry 5511 (class 0 OID 26756)
-- Dependencies: 599
-- Data for Name: sol_prod_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY sol_prod_cab (id, sucursal_id, fecha, estado, solicitada_por, autorizada_por, observaciones, created_at) FROM stdin;
\.


--
-- TOC entry 5885 (class 0 OID 0)
-- Dependencies: 600
-- Name: sol_prod_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('sol_prod_cab_id_seq', 1, false);


--
-- TOC entry 5513 (class 0 OID 26767)
-- Dependencies: 601
-- Data for Name: sol_prod_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY sol_prod_det (id, sol_id, plu, cantidad, cantidad_autorizada, created_at) FROM stdin;
\.


--
-- TOC entry 5886 (class 0 OID 0)
-- Dependencies: 602
-- Name: sol_prod_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('sol_prod_det_id_seq', 1, false);


--
-- TOC entry 5515 (class 0 OID 26773)
-- Dependencies: 603
-- Data for Name: stock_policy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY stock_policy (id, item_id, sucursal_id, almacen_id, min_qty, max_qty, reorder_lote, activo, created_at) FROM stdin;
\.


--
-- TOC entry 5887 (class 0 OID 0)
-- Dependencies: 604
-- Name: stock_policy_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('stock_policy_id_seq', 1, false);


--
-- TOC entry 5517 (class 0 OID 26785)
-- Dependencies: 605
-- Data for Name: sucursal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY sucursal (id, nombre, activo) FROM stdin;
\.


--
-- TOC entry 5518 (class 0 OID 26792)
-- Dependencies: 606
-- Data for Name: sucursal_almacen_terminal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY sucursal_almacen_terminal (id, sucursal_id, almacen_id, terminal_id, location, descripcion, activo, created_at) FROM stdin;
\.


--
-- TOC entry 5888 (class 0 OID 0)
-- Dependencies: 607
-- Name: sucursal_almacen_terminal_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('sucursal_almacen_terminal_id_seq', 1, false);


--
-- TOC entry 5520 (class 0 OID 26802)
-- Dependencies: 608
-- Data for Name: ticket_det_consumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY ticket_det_consumo (id, ticket_id, ticket_det_id, item_id, lote_id, qty_canonica, qty_original, uom_original_id, sucursal_id, ref_tipo, ref_id, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5889 (class 0 OID 0)
-- Dependencies: 609
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_det_consumo_id_seq', 1, false);


--
-- TOC entry 5522 (class 0 OID 26813)
-- Dependencies: 610
-- Data for Name: ticket_item_modifiers; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY ticket_item_modifiers (id, ticket_id, ticket_item_id, sucursal_id, terminal_id, procesado, fecha_proceso, pos_code, recipe_version_id, precio_extra, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5890 (class 0 OID 0)
-- Dependencies: 611
-- Name: ticket_item_modifiers_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_item_modifiers_id_seq', 1, false);


--
-- TOC entry 5524 (class 0 OID 26820)
-- Dependencies: 612
-- Data for Name: ticket_venta_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY ticket_venta_cab (id, numero_ticket, fecha_venta, sucursal_id, terminal_id, total_venta, estado, created_at) FROM stdin;
\.


--
-- TOC entry 5891 (class 0 OID 0)
-- Dependencies: 613
-- Name: ticket_venta_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_venta_cab_id_seq', 1, false);


--
-- TOC entry 5526 (class 0 OID 26830)
-- Dependencies: 614
-- Data for Name: ticket_venta_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY ticket_venta_det (id, ticket_id, item_id, cantidad, precio_unitario, subtotal, receta_version_id, created_at, receta_shadow_id, reprocesado, version_reproceso, modificadores_aplicados) FROM stdin;
\.


--
-- TOC entry 5892 (class 0 OID 0)
-- Dependencies: 615
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_venta_det_id_seq', 1, false);


--
-- TOC entry 5528 (class 0 OID 26842)
-- Dependencies: 616
-- Data for Name: transfer_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY transfer_cab (id, origen_almacen_id, destino_almacen_id, estado, creada_por, despachada_por, recibida_por, guia, created_at) FROM stdin;
\.


--
-- TOC entry 5893 (class 0 OID 0)
-- Dependencies: 617
-- Name: transfer_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('transfer_cab_id_seq', 1, false);


--
-- TOC entry 5530 (class 0 OID 26849)
-- Dependencies: 618
-- Data for Name: transfer_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY transfer_det (id, transfer_id, item_id, cantidad, cantidad_despachada, cantidad_recibida, created_at) FROM stdin;
\.


--
-- TOC entry 5894 (class 0 OID 0)
-- Dependencies: 619
-- Name: transfer_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('transfer_det_id_seq', 1, false);


--
-- TOC entry 5532 (class 0 OID 26855)
-- Dependencies: 620
-- Data for Name: traspaso_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY traspaso_cab (id, from_bodega_id, to_bodega_id, ts, usuario_id, meta, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5895 (class 0 OID 0)
-- Dependencies: 621
-- Name: traspaso_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('traspaso_cab_id_seq', 1, false);


--
-- TOC entry 5534 (class 0 OID 26866)
-- Dependencies: 622
-- Data for Name: traspaso_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY traspaso_det (id, traspaso_id, item_id, batch_id, qty, um_id, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5896 (class 0 OID 0)
-- Dependencies: 623
-- Name: traspaso_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('traspaso_det_id_seq', 1, false);


--
-- TOC entry 5897 (class 0 OID 0)
-- Dependencies: 626
-- Name: unidad_medida_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('unidad_medida_id_seq', 1, false);


--
-- TOC entry 5536 (class 0 OID 26878)
-- Dependencies: 625
-- Data for Name: unidad_medida_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY unidad_medida_legacy (id, codigo, nombre, tipo, es_base, factor_a_base, decimales) FROM stdin;
\.


--
-- TOC entry 5898 (class 0 OID 0)
-- Dependencies: 629
-- Name: unidades_medida_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('unidades_medida_id_seq', 1, false);


--
-- TOC entry 5538 (class 0 OID 26895)
-- Dependencies: 628
-- Data for Name: unidades_medida_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY unidades_medida_legacy (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) FROM stdin;
\.


--
-- TOC entry 5899 (class 0 OID 0)
-- Dependencies: 632
-- Name: uom_conversion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('uom_conversion_id_seq', 1, false);


--
-- TOC entry 5540 (class 0 OID 26912)
-- Dependencies: 631
-- Data for Name: uom_conversion_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY uom_conversion_legacy (id, origen_id, destino_id, factor) FROM stdin;
\.


--
-- TOC entry 5542 (class 0 OID 26919)
-- Dependencies: 633
-- Data for Name: user_roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY user_roles (user_id, role_id, assigned_at, assigned_by) FROM stdin;
\.


--
-- TOC entry 5543 (class 0 OID 26924)
-- Dependencies: 634
-- Data for Name: users; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY users (id, username, password_hash, email, nombre_completo, sucursal_id, activo, fecha_ultimo_login, intentos_login, bloqueado_hasta, created_at, updated_at, remember_token) FROM stdin;
3	soporte	$2y$12$ooLJw7RQYdTPJmuISfour.jHXJVXbSsMJqkXHA//UbHRK3FSXsaF6	soporte@terrena.com	Usuario Soporte	SUR	t	\N	0	\N	2025-11-02 12:34:50.954274	2025-11-02 20:03:09	\N
6	aldo	$2y$12$HjsBPavbDdGhIJu4IIDjmuaE7QaU2clpm38B2YnzS5AcaOeLjotA6	aldo@terrena.com.mx	Aldo Martinez	SUR	t	\N	0	\N	2025-11-20 19:16:16	2025-11-20 19:16:16	\N
4	eumir	$2y$12$831sz60gQlTO7u5bi0N/euDLuyCOPVpLl5O.ikz8tDSz.JNcUVXd6	eumir@terrena.com.mx	Jose Eumir Rodriguez Rranco	SUR	t	\N	0	\N	2025-11-20 18:16:40	2025-11-21 08:38:37	\N
5	jose	$2y$12$tdsdNWkW8KAXhgCB4sMEWOtETawANjz/A1BqfjsjhqXdAvQ5./PN6	jose@terrena.com.mx	Jose Huesca	SUR	t	\N	0	\N	2025-11-20 18:21:28	2025-11-21 08:39:03	\N
11	jonathan	$2y$12$yqVJ3a.S0KZEblQRG973zuMa6KDtnLWt5vW4VcIc8oOGvuYeTFUQK	jonathan@terrena.com.mx	Jonathan Garcia	SUR	t	\N	0	\N	2025-11-21 08:45:27	2025-11-21 08:45:27	\N
10	alexis	$2y$12$Q7Wzdl4bbOO6TVQWhtHeN.ZIUq6uM/rgsaKWIfWyk2Uc1qrJScOOS	alexis@terrena.com.mx	Alexis Ramirez	SUR	t	\N	0	\N	2025-11-21 08:44:23	2025-11-21 13:48:46	\N
9	isabella	$2y$12$xDNNPVitRSKM69lgJH/zJOIyubbqXr2mZlftcXq/DWU8buQ6y.LF6	isabella@terrena.com.mx	Isabella Fernandez	SUR	t	\N	0	\N	2025-11-21 08:43:34	2025-11-21 13:49:38	\N
7	david	$2y$12$izXvnW4B36E2BhLglcSOseAvy2Cp6b6FkuikSzFxFniPAbwhEInUW	david@terrena.com.mx	David Martinez	SUR	t	\N	0	\N	2025-11-21 08:42:14	2025-11-21 14:04:37	\N
8	alejandro	$2y$12$trbLLWcAo4utP4u4WUwzgen//e0GMgLHL3fD2qL3XgDt1tL9LX5HC	alejandro@terrena.com.mx	Alejandro Fernandez	SUR	t	\N	0	\N	2025-11-21 08:42:50	2025-11-24 10:37:35	\N
\.


--
-- TOC entry 5900 (class 0 OID 0)
-- Dependencies: 635
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('users_id_seq', 11, true);


--
-- TOC entry 5545 (class 0 OID 26942)
-- Dependencies: 636
-- Data for Name: usuario; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY usuario (id, username, nombre, email, rol_id, activo, password_hash, floreant_user_id, meta, created_at) FROM stdin;
\.


--
-- TOC entry 5901 (class 0 OID 0)
-- Dependencies: 637
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('usuario_id_seq', 1, false);


-- Completed on 2025-11-29 14:40:55

--
-- PostgreSQL database dump complete
--

