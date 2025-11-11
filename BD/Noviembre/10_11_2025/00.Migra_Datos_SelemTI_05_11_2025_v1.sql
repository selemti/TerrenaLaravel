--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.0
-- Dumped by pg_dump version 9.5.0

-- Started on 2025-11-10 17:11:22

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = selemti, pg_catalog;

--
-- TOC entry 4989 (class 0 OID 152303)
-- Dependencies: 189
-- Data for Name: alert_events; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY alert_events (id, recipe_id, snapshot_at, old_portion_cost, new_portion_cost, delta_pct, created_at, handled, assigned_to, acknowledged_at, resolution_notes, severity) FROM stdin;
\.


--
-- TOC entry 5447 (class 0 OID 0)
-- Dependencies: 190
-- Name: alert_events_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('alert_events_id_seq', 1, false);


--
-- TOC entry 4991 (class 0 OID 152314)
-- Dependencies: 191
-- Data for Name: alert_rules; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY alert_rules (id, recipe_id, category_id, threshold_pct, active, notes, scope, threshold_numeric, threshold_percent, notification_channels) FROM stdin;
\.


--
-- TOC entry 5448 (class 0 OID 0)
-- Dependencies: 192
-- Name: alert_rules_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('alert_rules_id_seq', 1, false);


--
-- TOC entry 4993 (class 0 OID 152325)
-- Dependencies: 193
-- Data for Name: almacen; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY almacen (id, sucursal_id, nombre, activo) FROM stdin;
\.


--
-- TOC entry 4994 (class 0 OID 152332)
-- Dependencies: 194
-- Data for Name: audit_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY audit_log (id, "timestamp", user_id, accion, entidad, entidad_id, motivo, evidencia_url, payload_json) FROM stdin;
\.


--
-- TOC entry 4995 (class 0 OID 152339)
-- Dependencies: 195
-- Data for Name: audit_log_global; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY audit_log_global (id, schema_name, table_name, operation, record_id, old_data, new_data, changed_by_user_id, changed_at, ip_address, user_agent) FROM stdin;
\.


--
-- TOC entry 5449 (class 0 OID 0)
-- Dependencies: 196
-- Name: audit_log_global_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('audit_log_global_id_seq', 1, false);


--
-- TOC entry 5450 (class 0 OID 0)
-- Dependencies: 197
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('audit_log_id_seq', 1, false);


--
-- TOC entry 4998 (class 0 OID 152351)
-- Dependencies: 198
-- Data for Name: auditoria; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

COPY auditoria (id, quien, que, payload, creado_en) FROM stdin;
1	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-17T09:06:03.217", "dah_id": 126, "operation": "ASIGNAR"}	2025-09-17 09:06:04.081128-05
2	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-17T09:22:58.68", "dah_id": 127, "operation": "ASIGNAR"}	2025-09-17 09:22:58.686625-05
3	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-18T08:55:08.491", "dah_id": 130, "operation": "ASIGNAR"}	2025-09-18 08:55:08.545545-05
4	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-18T09:38:33.973", "dah_id": 131, "operation": "ASIGNAR"}	2025-09-18 09:38:34.748483-05
5	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-19T08:34:20.654", "dah_id": 134, "operation": "ASIGNAR"}	2025-09-19 08:34:21.424031-05
6	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-19T09:05:06.502", "dah_id": 135, "operation": "ASIGNAR"}	2025-09-19 09:05:06.546538-05
7	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-20T09:01:59.5", "dah_id": 138, "operation": "ASIGNAR"}	2025-09-20 09:02:00.219905-05
8	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-20T09:06:11.135", "dah_id": 139, "operation": "ASIGNAR"}	2025-09-20 09:06:12.507865-05
9	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:23:37.943", "dah_id": 142, "operation": "ASIGNAR"}	2025-09-22 08:23:40.164587-05
10	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:42:23.967", "dah_id": 143, "operation": "ASIGNAR"}	2025-09-22 08:42:24.379279-05
11	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:54:42.608", "dah_id": 146, "operation": "ASIGNAR"}	2025-09-22 08:54:43.01876-05
12	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T08:55:26.437", "dah_id": 147, "operation": "ASIGNAR"}	2025-09-22 08:55:26.463681-05
13	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-22T15:58:41.388", "dah_id": 148, "operation": "ASIGNAR"}	2025-09-22 15:58:44.147496-05
14	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-23T09:05:49.234", "dah_id": 151, "operation": "ASIGNAR"}	2025-09-23 09:05:50.31703-05
15	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-23T09:12:22.319", "dah_id": 152, "operation": "ASIGNAR"}	2025-09-23 09:12:22.383953-05
16	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-24T08:55:07.788", "dah_id": 155, "operation": "ASIGNAR"}	2025-09-24 08:55:07.848467-05
17	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-24T09:36:29.527", "dah_id": 156, "operation": "ASIGNAR"}	2025-09-24 09:36:30.21109-05
18	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-25T09:02:41.923", "dah_id": 159, "operation": "ASIGNAR"}	2025-09-25 09:02:42.676315-05
19	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-25T09:34:12.819", "dah_id": 160, "operation": "ASIGNAR"}	2025-09-25 09:34:14.59031-05
20	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-26T08:46:01.273", "dah_id": 163, "operation": "ASIGNAR"}	2025-09-26 08:46:01.310139-05
21	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-26T08:51:34.061", "dah_id": 164, "operation": "ASIGNAR"}	2025-09-26 08:51:34.273578-05
22	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-27T08:34:04.289", "dah_id": 167, "operation": "ASIGNAR"}	2025-09-27 08:34:05.109531-05
23	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-27T09:06:22.867", "dah_id": 168, "operation": "ASIGNAR"}	2025-09-27 09:06:24.105709-05
24	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-29T09:01:23.765", "dah_id": 171, "operation": "ASIGNAR"}	2025-09-29 09:01:23.827279-05
25	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-29T09:13:41.633", "dah_id": 172, "operation": "ASIGNAR"}	2025-09-29 09:13:42.556641-05
26	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-30T07:34:22.236", "dah_id": 177, "operation": "ASIGNAR"}	2025-09-30 07:34:22.295356-05
27	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-09-30T09:02:39.518", "dah_id": 178, "operation": "ASIGNAR"}	2025-09-30 09:02:39.594419-05
28	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-01T07:32:59.659", "dah_id": 184, "operation": "ASIGNAR"}	2025-10-01 07:32:59.763091-05
29	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-01T07:55:41.608", "dah_id": 185, "operation": "ASIGNAR"}	2025-10-01 07:55:42.45592-05
30	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-01T09:16:09.183", "dah_id": 186, "operation": "ASIGNAR"}	2025-10-01 09:16:10.61867-05
31	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-02T07:53:37.516", "dah_id": 189, "operation": "ASIGNAR"}	2025-10-02 07:53:37.537881-05
32	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-02T08:40:27.388", "dah_id": 190, "operation": "ASIGNAR"}	2025-10-02 08:40:27.395912-05
33	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-02T08:45:53.634", "dah_id": 192, "operation": "ASIGNAR"}	2025-10-02 08:45:54.688896-05
34	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-03T07:22:54.163", "dah_id": 196, "operation": "ASIGNAR"}	2025-10-03 07:22:54.235856-05
35	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-03T08:54:37.023", "dah_id": 197, "operation": "ASIGNAR"}	2025-10-03 08:54:37.094581-05
36	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-03T09:30:34.68", "dah_id": 198, "operation": "ASIGNAR"}	2025-10-03 09:30:35.753797-05
37	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-04T08:37:46.98", "dah_id": 202, "operation": "ASIGNAR"}	2025-10-04 08:37:48.614896-05
38	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-04T08:39:49.896", "dah_id": 203, "operation": "ASIGNAR"}	2025-10-04 08:39:50.938951-05
39	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-06T07:58:10.641", "dah_id": 206, "operation": "ASIGNAR"}	2025-10-06 07:58:10.890961-05
40	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-06T08:19:02.596", "dah_id": 207, "operation": "ASIGNAR"}	2025-10-06 08:19:03.292037-05
41	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-07T07:29:05.145", "dah_id": 212, "operation": "ASIGNAR"}	2025-10-07 07:29:05.297092-05
42	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-07T08:50:28.769", "dah_id": 214, "operation": "ASIGNAR"}	2025-10-07 08:50:28.797539-05
43	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-08T08:34:05.623", "dah_id": 218, "operation": "ASIGNAR"}	2025-10-08 08:34:06.872535-05
44	13	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-08T09:58:21.955", "dah_id": 219, "operation": "ASIGNAR"}	2025-10-08 09:58:23.297741-05
45	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-09T08:35:26.563", "dah_id": 222, "operation": "ASIGNAR"}	2025-10-09 08:35:27.204894-05
46	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-09T09:28:19.78", "dah_id": 223, "operation": "ASIGNAR"}	2025-10-09 09:28:21.068893-05
47	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-10T07:26:30.415", "dah_id": 228, "operation": "ASIGNAR"}	2025-10-10 07:26:30.557316-05
48	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-10T08:42:13.371", "dah_id": 229, "operation": "ASIGNAR"}	2025-10-10 08:42:15.822091-05
49	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-11T08:27:08.465", "dah_id": 234, "operation": "ASIGNAR"}	2025-10-11 08:27:10.31438-05
50	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-11T08:28:34.703", "dah_id": 235, "operation": "ASIGNAR"}	2025-10-11 08:28:37.111777-05
51	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-13T07:19:16.121", "dah_id": 238, "operation": "ASIGNAR"}	2025-10-13 07:19:16.258862-05
52	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-13T08:55:19.487", "dah_id": 239, "operation": "ASIGNAR"}	2025-10-13 08:55:19.518505-05
53	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-14T07:14:29.338", "dah_id": 244, "operation": "ASIGNAR"}	2025-10-14 07:14:29.514346-05
54	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-14T08:27:04.537", "dah_id": 245, "operation": "ASIGNAR"}	2025-10-14 08:27:05.84751-05
55	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-15T07:36:32.551", "dah_id": 250, "operation": "ASIGNAR"}	2025-10-15 07:36:32.674744-05
56	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-15T08:17:38.126", "dah_id": 252, "operation": "ASIGNAR"}	2025-10-15 08:17:38.405685-05
57	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-16T07:06:23.065", "dah_id": 256, "operation": "ASIGNAR"}	2025-10-16 07:06:23.103373-05
58	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-16T07:07:00.96", "dah_id": 258, "operation": "ASIGNAR"}	2025-10-16 07:07:00.991373-05
59	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-16T09:03:55.529", "dah_id": 260, "operation": "ASIGNAR"}	2025-10-16 09:03:55.646781-05
60	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-17T08:47:04.893", "dah_id": 263, "operation": "ASIGNAR"}	2025-10-17 08:47:06.451915-05
61	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-18T07:57:40.291", "dah_id": 268, "operation": "ASIGNAR"}	2025-10-18 07:57:40.121727-05
62	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-20T08:50:42.114", "dah_id": 271, "operation": "ASIGNAR"}	2025-10-20 08:50:42.262013-05
63	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-21T08:03:32.316", "dah_id": 275, "operation": "ASIGNAR"}	2025-10-21 09:03:33.225142-05
64	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-22T08:07:17.347", "dah_id": 280, "operation": "ASIGNAR"}	2025-10-22 08:07:18.357403-05
65	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-23T08:46:48.664", "dah_id": 283, "operation": "ASIGNAR"}	2025-10-23 08:46:49.545493-05
66	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-24T07:46:29.323", "dah_id": 287, "operation": "ASIGNAR"}	2025-10-24 08:46:29.34105-05
67	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-25T08:19:50.827", "dah_id": 292, "operation": "ASIGNAR"}	2025-10-25 08:19:51.524247-05
68	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-27T08:05:39.203", "dah_id": 295, "operation": "ASIGNAR"}	2025-10-27 08:05:39.785984-06
69	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-28T08:02:53.052", "dah_id": 300, "operation": "ASIGNAR"}	2025-10-28 08:02:53.095579-06
70	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-29T07:35:07.677", "dah_id": 304, "operation": "ASIGNAR"}	2025-10-29 07:35:07.38462-06
71	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-30T07:28:49.2", "dah_id": 307, "operation": "ASIGNAR"}	2025-10-30 07:28:49.364087-06
72	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-10-31T08:34:39.643", "dah_id": 311, "operation": "ASIGNAR"}	2025-10-31 08:34:40.271255-06
73	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-03T08:01:00.232", "dah_id": 315, "operation": "ASIGNAR"}	2025-11-03 08:01:00.23551-06
74	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-04T06:56:16.696", "dah_id": 322, "operation": "ASIGNAR"}	2025-11-04 06:56:16.768307-06
75	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-04T07:34:25.306", "dah_id": 323, "operation": "ASIGNAR"}	2025-11-04 07:34:25.707977-06
78	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-06T01:42:44.637", "dah_id": 333, "operation": "ASIGNAR"}	2025-11-06 01:42:44.643023-06
79	1	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-10T11:35:07.731", "dah_id": 335, "operation": "ASIGNAR"}	2025-11-10 11:35:07.732585-06
76	6	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-05T07:49:53.526", "dah_id": 328, "operation": "ASIGNAR"}	2025-11-05 07:49:54.14574-06
77	8	NO_SE_PUDO_RESOLVER_TERMINAL	{"time": "2025-11-05T08:18:56.19", "dah_id": 329, "operation": "ASIGNAR"}	2025-11-05 08:18:56.240872-06
\.


--
-- TOC entry 5451 (class 0 OID 0)
-- Dependencies: 199
-- Name: auditoria_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('auditoria_id_seq', 79, true);


--
-- TOC entry 5000 (class 0 OID 152360)
-- Dependencies: 200
-- Data for Name: bodega; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY bodega (id, sucursal_id, codigo, nombre) FROM stdin;
\.


--
-- TOC entry 5452 (class 0 OID 0)
-- Dependencies: 201
-- Name: bodega_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('bodega_id_seq', 1, false);


--
-- TOC entry 5002 (class 0 OID 152368)
-- Dependencies: 202
-- Data for Name: cache; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cache (key, value, expiration) FROM stdin;
\.


--
-- TOC entry 5003 (class 0 OID 152374)
-- Dependencies: 203
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cache_locks (key, owner, expiration) FROM stdin;
\.


--
-- TOC entry 5004 (class 0 OID 152380)
-- Dependencies: 204
-- Data for Name: caja_fondo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY caja_fondo (id, sucursal_id, fecha, monto_inicial, moneda, estado, creado_por, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5005 (class 0 OID 152387)
-- Dependencies: 205
-- Data for Name: caja_fondo_adj; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY caja_fondo_adj (id, mov_id, tipo, archivo_url, observaciones, created_at) FROM stdin;
\.


--
-- TOC entry 5453 (class 0 OID 0)
-- Dependencies: 206
-- Name: caja_fondo_adj_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_adj_id_seq', 1, false);


--
-- TOC entry 5007 (class 0 OID 152396)
-- Dependencies: 207
-- Data for Name: caja_fondo_arqueo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY caja_fondo_arqueo (id, fondo_id, fecha_cierre, efectivo_contado, diferencia, observaciones, cerrado_por) FROM stdin;
\.


--
-- TOC entry 5454 (class 0 OID 0)
-- Dependencies: 208
-- Name: caja_fondo_arqueo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_arqueo_id_seq', 1, false);


--
-- TOC entry 5455 (class 0 OID 0)
-- Dependencies: 209
-- Name: caja_fondo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_id_seq', 1, false);


--
-- TOC entry 5010 (class 0 OID 152407)
-- Dependencies: 210
-- Data for Name: caja_fondo_mov; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY caja_fondo_mov (id, fondo_id, fecha_hora, tipo, concepto, proveedor_id, monto, metodo, requiere_comprobante, estatus, creado_por, aprobado_por, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5456 (class 0 OID 0)
-- Dependencies: 211
-- Name: caja_fondo_mov_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('caja_fondo_mov_id_seq', 1, false);


--
-- TOC entry 5012 (class 0 OID 152421)
-- Dependencies: 212
-- Data for Name: caja_fondo_usuario; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY caja_fondo_usuario (fondo_id, user_id, rol) FROM stdin;
\.


--
-- TOC entry 5013 (class 0 OID 152424)
-- Dependencies: 213
-- Data for Name: cash_fund_arqueos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cash_fund_arqueos (id, cash_fund_id, monto_esperado, monto_contado, diferencia, observaciones, created_by_user_id, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5457 (class 0 OID 0)
-- Dependencies: 214
-- Name: cash_fund_arqueos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_fund_arqueos_id_seq', 1, false);


--
-- TOC entry 5015 (class 0 OID 152432)
-- Dependencies: 215
-- Data for Name: cash_fund_movement_audit_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cash_fund_movement_audit_log (id, movement_id, action, field_changed, old_value, new_value, observaciones, changed_by_user_id, created_at) FROM stdin;
\.


--
-- TOC entry 5458 (class 0 OID 0)
-- Dependencies: 216
-- Name: cash_fund_movement_audit_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_fund_movement_audit_log_id_seq', 1, false);


--
-- TOC entry 5017 (class 0 OID 152441)
-- Dependencies: 217
-- Data for Name: cash_fund_movements; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cash_fund_movements (id, cash_fund_id, tipo, concepto, proveedor_id, monto, metodo, estatus, requiere_comprobante, tiene_comprobante, adjunto_path, created_by_user_id, approved_by_user_id, approved_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5459 (class 0 OID 0)
-- Dependencies: 218
-- Name: cash_fund_movements_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_fund_movements_id_seq', 1, false);


--
-- TOC entry 5019 (class 0 OID 152455)
-- Dependencies: 219
-- Data for Name: cash_funds; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cash_funds (id, sucursal_id, fecha, monto_inicial, moneda, estado, responsable_user_id, created_by_user_id, closed_at, created_at, updated_at, descripcion) FROM stdin;
\.


--
-- TOC entry 5460 (class 0 OID 0)
-- Dependencies: 220
-- Name: cash_funds_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cash_funds_id_seq', 1, false);


--
-- TOC entry 5021 (class 0 OID 152466)
-- Dependencies: 221
-- Data for Name: cat_almacenes; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cat_almacenes (id, clave, nombre, sucursal_id, activo, created_at, updated_at) FROM stdin;
1	COC	COCINA PRINCIPAL	1	t	2025-11-02 20:20:49	2025-11-02 20:20:49
2	GENERAL	GENERAL	\N	t	2025-11-02 20:21:05	2025-11-02 20:21:05
\.


--
-- TOC entry 5461 (class 0 OID 0)
-- Dependencies: 222
-- Name: cat_almacenes_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_almacenes_id_seq', 2, true);


--
-- TOC entry 5023 (class 0 OID 152472)
-- Dependencies: 223
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
-- TOC entry 5462 (class 0 OID 0)
-- Dependencies: 224
-- Name: cat_proveedores_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_proveedores_id_seq', 20, true);


--
-- TOC entry 5025 (class 0 OID 152481)
-- Dependencies: 225
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
-- TOC entry 5463 (class 0 OID 0)
-- Dependencies: 226
-- Name: cat_sucursales_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_sucursales_id_seq', 5, true);


--
-- TOC entry 5027 (class 0 OID 152487)
-- Dependencies: 227
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
-- TOC entry 5464 (class 0 OID 0)
-- Dependencies: 228
-- Name: cat_unidades_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_unidades_id_seq', 26, true);


--
-- TOC entry 5029 (class 0 OID 152493)
-- Dependencies: 229
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
-- TOC entry 5465 (class 0 OID 0)
-- Dependencies: 230
-- Name: cat_uom_conversion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cat_uom_conversion_id_seq', 10, true);


--
-- TOC entry 5031 (class 0 OID 152503)
-- Dependencies: 231
-- Data for Name: conciliacion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY conciliacion (id, postcorte_id, conciliado_por, conciliado_en, estatus, notas) FROM stdin;
\.


--
-- TOC entry 5466 (class 0 OID 0)
-- Dependencies: 232
-- Name: conciliacion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('conciliacion_id_seq', 1, false);


--
-- TOC entry 5467 (class 0 OID 0)
-- Dependencies: 235
-- Name: conversiones_unidad_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('conversiones_unidad_id_seq', 1, false);


--
-- TOC entry 5033 (class 0 OID 152518)
-- Dependencies: 234
-- Data for Name: conversiones_unidad_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY conversiones_unidad_legacy (id, unidad_origen_id, unidad_destino_id, factor_conversion, formula_directa, precision_estimada, activo, created_at) FROM stdin;
\.


--
-- TOC entry 5035 (class 0 OID 152531)
-- Dependencies: 236
-- Data for Name: cost_layer; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY cost_layer (id, item_id, batch_id, ts_in, qty_in, qty_left, unit_cost, sucursal_id, source_ref, source_id) FROM stdin;
\.


--
-- TOC entry 5468 (class 0 OID 0)
-- Dependencies: 237
-- Name: cost_layer_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('cost_layer_id_seq', 1, false);


--
-- TOC entry 5037 (class 0 OID 152539)
-- Dependencies: 238
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- TOC entry 5469 (class 0 OID 0)
-- Dependencies: 239
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('failed_jobs_id_seq', 1, false);


--
-- TOC entry 5039 (class 0 OID 152548)
-- Dependencies: 240
-- Data for Name: formas_pago; Type: TABLE DATA; Schema: selemti; Owner: floreant
--

COPY formas_pago (id, codigo, payment_type, transaction_type, payment_sub_type, custom_name, custom_ref, activo, prioridad, creado_en) FROM stdin;
1	CASH	CASH	\N	\N	\N	\N	t	100	2025-09-17 08:40:57.876762-05
2	CREDIT	CREDIT	\N	\N	\N	\N	t	100	2025-09-17 08:40:57.876762-05
3	DEBIT	DEBIT	\N	\N	\N	\N	t	100	2025-09-17 08:40:57.876762-05
4	TRANSFER	TRANSFER	\N	\N	\N	\N	t	100	2025-09-17 08:40:57.876762-05
5	REFUND	REFUND	\N	\N	\N	\N	t	100	2025-09-17 08:40:57.876762-05
6	PAY_OUT	PAY_OUT	\N	\N	\N	\N	t	100	2025-09-17 08:40:57.876762-05
7	CASH_DROP	CASH_DROP	\N	\N	\N	\N	t	100	2025-09-17 08:40:57.876762-05
8	CREDIT_CARD	CREDIT_CARD	CREDIT	VISA	\N	\N	t	100	2025-09-17 09:06:09.509102-05
9	CASH	CASH	CREDIT	CASH	\N	\N	t	100	2025-09-17 09:10:09.104336-05
343	DEBIT_CARD	DEBIT_CARD	CREDIT	MASTER CARD	\N	\N	t	100	2025-09-17 15:35:19.713525-05
1117	CREDIT_CARD	CREDIT_CARD	CREDIT	MASTER CARD	\N	\N	t	100	2025-09-19 11:43:16.717348-05
1591	REFUND	REFUND	DEBIT	CASH	\N	\N	t	100	2025-09-20 16:43:46.046399-05
1592	VOID_TRANS	VOID_TRANS	DEBIT	CASH	\N	\N	t	100	2025-09-20 16:43:46.046399-05
1675	DEBIT_CARD	DEBIT_CARD	CREDIT	VISA	\N	\N	t	100	2025-09-22 10:04:31.673494-05
12351	CUSTOM:tranferencia	CUSTOM_PAYMENT	CREDIT	CUSTOM PAYMENT	Tranferencia	1	t	100	2025-10-20 11:37:17.050812-05
17081	CASH_DROP	CASH_DROP	CREDIT	CASH	\N	\N	t	100	2025-11-06 01:47:09.796061-06
17082	PAY_OUT	PAY_OUT	DEBIT	CASH	\N	\N	t	100	2025-11-06 01:47:59.87732-06
17084	CREDIT_CARD	CREDIT_CARD	CREDIT	AMEX	\N	\N	t	100	2025-11-06 02:03:41.284259-06
17092	CUSTOM:tranferencia	CUSTOM_PAYMENT	CREDIT	CUSTOM PAYMENT	Tranferencia	55	t	100	2025-11-06 02:06:47.914872-06
\.


--
-- TOC entry 5470 (class 0 OID 0)
-- Dependencies: 241
-- Name: formas_pago_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: floreant
--

SELECT pg_catalog.setval('formas_pago_id_seq', 17095, true);


--
-- TOC entry 5041 (class 0 OID 152559)
-- Dependencies: 242
-- Data for Name: hist_cost_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY hist_cost_insumo (id, item_id, fecha_efectiva, costo_wac, costo_peps, costo_ueps, costo_std, algoritmo_principal, valid_from, valid_to, sys_from, sys_to, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5471 (class 0 OID 0)
-- Dependencies: 243
-- Name: hist_cost_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('hist_cost_insumo_id_seq', 1, false);


--
-- TOC entry 5043 (class 0 OID 152572)
-- Dependencies: 244
-- Data for Name: hist_cost_receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY hist_cost_receta (id, receta_version_id, fecha_calculo, costo_total, costo_porcion, algoritmo_utilizado, valid_from, valid_to, sys_from, sys_to) FROM stdin;
\.


--
-- TOC entry 5472 (class 0 OID 0)
-- Dependencies: 245
-- Name: hist_cost_receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('hist_cost_receta_id_seq', 1, false);


--
-- TOC entry 5045 (class 0 OID 152583)
-- Dependencies: 246
-- Data for Name: historial_costos_item; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY historial_costos_item (id, item_id, fecha_efectiva, fecha_registro, costo_anterior, costo_nuevo, tipo_cambio, referencia_id, referencia_tipo, usuario_id, valid_from, valid_to, sys_from, sys_to, costo_wac, costo_peps, costo_ueps, costo_estandar, algoritmo_principal, version_datos, recalculado, fuente_datos, metadata_calculo, created_at) FROM stdin;
\.


--
-- TOC entry 5473 (class 0 OID 0)
-- Dependencies: 247
-- Name: historial_costos_item_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('historial_costos_item_id_seq', 1, false);


--
-- TOC entry 5047 (class 0 OID 152600)
-- Dependencies: 248
-- Data for Name: historial_costos_receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY historial_costos_receta (id, receta_version_id, fecha_calculo, costo_total, costo_porcion, algoritmo_utilizado, version_datos, metadata_calculo, created_at, valid_from, valid_to, sys_from, sys_to) FROM stdin;
\.


--
-- TOC entry 5474 (class 0 OID 0)
-- Dependencies: 249
-- Name: historial_costos_receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('historial_costos_receta_id_seq', 1, false);


--
-- TOC entry 5049 (class 0 OID 152611)
-- Dependencies: 250
-- Data for Name: insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY insumo (id, sku, nombre, um_id, perecible, merma_pct, activo, meta, codigo, categoria_codigo, subcategoria_codigo, consecutivo, codigo_alterno) FROM stdin;
\.


--
-- TOC entry 5475 (class 0 OID 0)
-- Dependencies: 251
-- Name: insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('insumo_id_seq', 1, false);


--
-- TOC entry 5051 (class 0 OID 152622)
-- Dependencies: 252
-- Data for Name: insumo_presentacion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY insumo_presentacion (id, item_id, proveedor_id, um_compra_id, factor_a_um, costo_ultimo, activo, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5476 (class 0 OID 0)
-- Dependencies: 253
-- Name: insumo_presentacion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('insumo_presentacion_id_seq', 1, false);


--
-- TOC entry 5053 (class 0 OID 152632)
-- Dependencies: 254
-- Data for Name: insumo_proveedor_presentacion; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY insumo_proveedor_presentacion (id, item_id, proveedor_id, uom_compra_id, cantidad_en_uom_compra, uom_base_id, factor_a_base, precio_compra, moneda, activo, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5477 (class 0 OID 0)
-- Dependencies: 255
-- Name: insumo_proveedor_presentacion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('insumo_proveedor_presentacion_id_seq', 1, false);


--
-- TOC entry 5055 (class 0 OID 152646)
-- Dependencies: 256
-- Data for Name: inv_consumo_pos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inv_consumo_pos (id, ticket_id, ticket_item_id, sucursal_id, terminal_id, estado, created_at, requiere_reproceso, procesado, fecha_proceso, revertido) FROM stdin;
\.


--
-- TOC entry 5056 (class 0 OID 152653)
-- Dependencies: 257
-- Data for Name: inv_consumo_pos_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inv_consumo_pos_det (id, consumo_id, mp_id, uom_id, cantidad, factor, origen, requiere_reproceso, procesado, fecha_proceso, revertido) FROM stdin;
\.


--
-- TOC entry 5478 (class 0 OID 0)
-- Dependencies: 258
-- Name: inv_consumo_pos_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_consumo_pos_det_id_seq', 1, false);


--
-- TOC entry 5479 (class 0 OID 0)
-- Dependencies: 259
-- Name: inv_consumo_pos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_consumo_pos_id_seq', 1, false);


--
-- TOC entry 5059 (class 0 OID 152663)
-- Dependencies: 260
-- Data for Name: inv_consumo_pos_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inv_consumo_pos_log (id, ticket_id, accion, registrado_en, payload) FROM stdin;
\.


--
-- TOC entry 5480 (class 0 OID 0)
-- Dependencies: 261
-- Name: inv_consumo_pos_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_consumo_pos_log_id_seq', 1, false);


--
-- TOC entry 5061 (class 0 OID 152672)
-- Dependencies: 262
-- Data for Name: inv_stock_policy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inv_stock_policy (id, item_id, sucursal_id, min_qty, max_qty, reorder_qty, activo, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5481 (class 0 OID 0)
-- Dependencies: 263
-- Name: inv_stock_policy_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inv_stock_policy_id_seq', 1, false);


--
-- TOC entry 5063 (class 0 OID 152681)
-- Dependencies: 264
-- Data for Name: inventory_batch; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inventory_batch (id, item_id, lote_proveedor, fecha_recepcion, fecha_caducidad, temperatura_recepcion, documento_url, cantidad_original, cantidad_actual, estado, ubicacion_id, created_at, updated_at, unit_cost) FROM stdin;
\.


--
-- TOC entry 5482 (class 0 OID 0)
-- Dependencies: 265
-- Name: inventory_batch_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_batch_id_seq', 1, false);


--
-- TOC entry 5065 (class 0 OID 152697)
-- Dependencies: 266
-- Data for Name: inventory_count_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inventory_count_lines (id, inventory_count_id, item_id, inventory_batch_id, qty_teorica, qty_contada, qty_variacion, uom, motivo, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5483 (class 0 OID 0)
-- Dependencies: 267
-- Name: inventory_count_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_count_lines_id_seq', 1, false);


--
-- TOC entry 5067 (class 0 OID 152708)
-- Dependencies: 268
-- Data for Name: inventory_counts; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inventory_counts (id, folio, sucursal_id, almacen_id, programado_para, iniciado_en, cerrado_en, estado, creado_por, cerrado_por, notas, total_items, total_variacion, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5484 (class 0 OID 0)
-- Dependencies: 269
-- Name: inventory_counts_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_counts_id_seq', 1, false);


--
-- TOC entry 5069 (class 0 OID 152719)
-- Dependencies: 270
-- Data for Name: inventory_snapshot; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inventory_snapshot (snapshot_date, branch_id, item_id, teorico_qty, fisico_qty, teorico_cost, valor_teorico, variance_qty, variance_cost, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5070 (class 0 OID 152728)
-- Dependencies: 271
-- Data for Name: inventory_wastes; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY inventory_wastes (id, production_order_id, item_id, inventory_batch_id, qty, uom, motivo, sucursal_id, almacen_id, user_id, ref_tipo, ref_id, registrado_en, meta, notas, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5485 (class 0 OID 0)
-- Dependencies: 272
-- Name: inventory_wastes_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('inventory_wastes_id_seq', 1, false);


--
-- TOC entry 5072 (class 0 OID 152737)
-- Dependencies: 273
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
-- TOC entry 5486 (class 0 OID 0)
-- Dependencies: 274
-- Name: item_categories_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('item_categories_id_seq', 12, true);


--
-- TOC entry 5074 (class 0 OID 152746)
-- Dependencies: 275
-- Data for Name: item_category_counters; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY item_category_counters (category_id, last_val, updated_at) FROM stdin;
12	4	2025-11-05 03:29:35
11	2	2025-11-05 03:29:35
\.


--
-- TOC entry 5075 (class 0 OID 152750)
-- Dependencies: 276
-- Data for Name: item_vendor; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY item_vendor (item_id, vendor_id, presentacion, unidad_presentacion_id, factor_a_canonica, costo_ultimo, moneda, lead_time_dias, codigo_proveedor, activo, created_at, preferente, vendor_sku, vendor_descripcion, currency_code, lead_time_days, min_order_qty, pack_qty, pack_uom) FROM stdin;
\.


--
-- TOC entry 5076 (class 0 OID 152762)
-- Dependencies: 277
-- Data for Name: item_vendor_prices; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY item_vendor_prices (id, item_id, vendor_id, price, currency_code, pack_qty, pack_uom, notes, source, effective_from, effective_to, created_by, created_at) FROM stdin;
\.


--
-- TOC entry 5487 (class 0 OID 0)
-- Dependencies: 278
-- Name: item_vendor_prices_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('item_vendor_prices_id_seq', 1, false);


--
-- TOC entry 5078 (class 0 OID 152774)
-- Dependencies: 279
-- Data for Name: items; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY items (id, nombre, descripcion, categoria_id, unidad_medida, perishable, temperatura_min, temperatura_max, costo_promedio, activo, created_at, updated_at, unidad_medida_id, factor_conversion, unidad_compra_id, factor_compra, tipo, unidad_salida_id, category_id, item_code, es_producible, es_consumible_operativo, es_empaque_to_go) FROM stdin;
LECHE-MEMBERS-01	Leche Deslactosada Member's Mark	Leche deslactosada reducida en lactosa	CAT-LACT	L	t	2	8	220.00	t	2025-11-03 10:48:23.476701	2025-11-03 14:26:39	2	1.000000	12	12.000000	MATERIA_PRIMA	\N	12	\N	f	f	f
LECHE-MEM-01	Leche Deslactosada Member's Mark	Leche deslactosada reducida en lactosa	CAT-LACT	L	t	2	8	220.00	t	2025-11-03 10:44:59.528047	2025-11-03 14:26:39	2	1.000000	\N	1.000000	MATERIA_PRIMA	\N	12	\N	f	f	f
LECHE-NUTRI-01	Producto Lácteo Nutri Deslactosada	Producto lácteo deslactosado sabor natural	CAT-LACT	L	t	2	8	280.00	t	2025-11-03 10:48:23.476701	2025-11-03 14:26:39	2	1.000000	12	18.000000	MATERIA_PRIMA	\N	12	\N	f	f	f
ACEITE-NUTRIOLI-01	Aceite de Soya Nutrioli	Aceite vegetal de soya 100% puro	CAT-ABARR	L	f	\N	\N	150.00	t	2025-11-03 10:48:23.476701	2025-11-03 14:26:39	2	1.000000	16	2.838000	MATERIA_PRIMA	\N	11	\N	f	f	f
ACEITE-NUT-01	Aceite de Soya Nutrioli	Aceite vegetal de soya 100% puro	CAT-ABARR	L	f	\N	\N	150.00	t	2025-11-03 10:44:59.528047	2025-11-03 14:26:39	2	1.000000	\N	1.000000	MATERIA_PRIMA	\N	11	\N	f	f	f
LECHE-NUT-01	Producto Lácteo Nutri Deslactosada	Producto lácteo deslactosado sabor natural	CAT-LACT	L	t	2	8	280.00	t	2025-11-03 10:44:59.528047	2025-11-03 14:26:39	2	1.000000	\N	1.000000	MATERIA_PRIMA	\N	12	\N	f	f	f
\.


--
-- TOC entry 5079 (class 0 OID 152797)
-- Dependencies: 280
-- Data for Name: job_batches; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- TOC entry 5080 (class 0 OID 152803)
-- Dependencies: 281
-- Data for Name: job_recalc_queue; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY job_recalc_queue (id, scope_type, scope_from, scope_to, item_id, receta_id, sucursal_id, reason, created_ts, status, result) FROM stdin;
\.


--
-- TOC entry 5488 (class 0 OID 0)
-- Dependencies: 282
-- Name: job_recalc_queue_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('job_recalc_queue_id_seq', 1, false);


--
-- TOC entry 5082 (class 0 OID 152815)
-- Dependencies: 283
-- Data for Name: jobs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- TOC entry 5489 (class 0 OID 0)
-- Dependencies: 284
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('jobs_id_seq', 1, false);


--
-- TOC entry 5084 (class 0 OID 152823)
-- Dependencies: 285
-- Data for Name: labor_roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY labor_roles (id, clave, nombre, rate_per_hour, activo, descripcion, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5490 (class 0 OID 0)
-- Dependencies: 286
-- Name: labor_roles_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('labor_roles_id_seq', 1, false);


--
-- TOC entry 5086 (class 0 OID 152833)
-- Dependencies: 287
-- Data for Name: lote; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY lote (id, item_id, proveedor_id, codigo, caducidad, estado, creado_ts) FROM stdin;
\.


--
-- TOC entry 5491 (class 0 OID 0)
-- Dependencies: 288
-- Name: lote_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('lote_id_seq', 1, false);


--
-- TOC entry 5088 (class 0 OID 152843)
-- Dependencies: 289
-- Data for Name: menu_engineering_snapshots; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY menu_engineering_snapshots (id, menu_item_id, period_start, period_end, units_sold, net_sales, food_cost, contribution, avg_price, avg_cost, margin_pct, popularity_index, classification, metadata, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5492 (class 0 OID 0)
-- Dependencies: 290
-- Name: menu_engineering_snapshots_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('menu_engineering_snapshots_id_seq', 1, false);


--
-- TOC entry 5090 (class 0 OID 152859)
-- Dependencies: 291
-- Data for Name: menu_item_sync_map; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY menu_item_sync_map (id, menu_item_id, pos_identifier, channel, metadata, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5493 (class 0 OID 0)
-- Dependencies: 292
-- Name: menu_item_sync_map_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('menu_item_sync_map_id_seq', 1, false);


--
-- TOC entry 5092 (class 0 OID 152868)
-- Dependencies: 293
-- Data for Name: menu_items; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY menu_items (id, recipe_id, plu, name, category, active, metadata, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5494 (class 0 OID 0)
-- Dependencies: 294
-- Name: menu_items_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('menu_items_id_seq', 1, false);


--
-- TOC entry 5094 (class 0 OID 152877)
-- Dependencies: 295
-- Data for Name: merma; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY merma (id, ts, tipo, item_id, batch_id, op_id, qty, um_id, usuario_id, motivo, meta, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5495 (class 0 OID 0)
-- Dependencies: 296
-- Name: merma_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('merma_id_seq', 1, false);


--
-- TOC entry 5096 (class 0 OID 152888)
-- Dependencies: 297
-- Data for Name: migrations; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY migrations (id, migration, batch) FROM stdin;
1	2025_11_01_132623_add_pos_location_to_cat_sucursales_table	1
2	2025_11_03_194200_fix_items_inconsistencies	2
4	2025_11_03_194400_fix_all_item_id_types	3
5	2025_11_03_202400_clean_item_descriptions	4
6	0001_01_01_000000_create_users_table	5
7	0001_01_01_000001_create_cache_table	5
8	0001_01_01_000002_create_jobs_table	5
9	2025_01_12_000000_add_preferente_to_selemti_item_vendor	5
10	2025_12_01_120000_create_report_favorites_table	6
11	2025_01_23_100000_create_cash_funds_table	7
12	2025_01_23_100001_create_cash_fund_movements_table	7
13	2025_01_23_100002_create_cash_fund_arqueos_table	7
14	2025_01_23_110000_create_cash_fund_movement_audit_log_table	7
15	2025_09_26_090415_create_cat_unidades_table	7
16	2025_09_26_090657_create_cat_unidades_table	7
17	2025_09_26_205955_create_permission_tables	7
18	2025_10_18_000001_create_cat_sucursales_table	7
19	2025_10_18_000002_create_cat_almacenes_table	7
20	2025_10_18_000003_create_cat_proveedores_table	7
21	2025_10_18_000004_create_cat_uom_conversion_table	7
22	2025_10_18_000005_create_inv_stock_policy_table	7
23	2025_10_19_000001_update_cat_unidades_structure	7
24	2025_10_21_100100_alter_cat_proveedores_add_fields	7
25	2025_10_21_100200_alter_item_vendor_add_vendor_sku	7
26	2025_10_21_123344_add_preferente_to_selemti_item_vendor	7
27	2025_10_21_180000_create_item_categories	7
28	2025_10_21_180100_backfill_item_categories	7
29	2025_10_21_180200_ensure_items_id_autoincrement	7
30	2025_10_21_190100_alter_items_add_item_code	7
31	2025_10_21_190200_item_code_trigger_and_counter	7
32	2025_10_21_190300_backfill_item_codes	7
33	2025_10_21_200000_create_item_vendor_prices	7
34	2025_10_21_200100_fn_item_cost_at	7
35	2025_10_21_200200_recipe_versioning_and_history	7
36	2025_10_21_200300_fn_recipe_cost_at	7
37	2025_10_21_200400_sp_snapshot_recipe_cost	7
38	2025_10_21_200500_alert_rules_and_events	7
39	2025_10_21_200500_create_item_last_price_views	7
40	2025_10_21_200600_trg_on_price_change_alerts	7
41	2025_10_23_154901_add_descripcion_to_cash_funds_table	7
42	2025_10_24_000000_add_almacen_id_to_recepcion_cab	7
43	2025_10_24_014612_add_numero_recepcion_to_recepcion_cab_table	7
44	2025_10_24_015559_add_fecha_recepcion_to_recepcion_cab_table	7
45	2025_10_24_020818_add_missing_inventory_fields_to_recepcion_cab_table	7
46	2025_10_24_100000_create_replenishment_suggestions_table	7
47	2025_10_24_120000_create_purchase_suggestions_table	7
48	2025_10_24_120101_create_purchase_suggestion_lines_table	7
49	2025_10_24_120102_alter_purchase_requests_add_fields	7
50	2025_10_26_000002_add_operational_flags_to_items	7
51	2025_10_26_000004_add_unit_cost_to_inventory_batch	7
52	2025_10_26_000005_create_pos_map_table	7
53	2025_10_26_000006_create_ticket_item_modifiers_table	7
54	2025_10_27_100239_create_pos_reverse_log_table	7
55	2025_10_27_100252_create_pos_reprocess_log_table	7
56	2025_10_27_110252_add_flags_to_inv_consumo_pos_and_det	7
57	2025_10_27_153528_create_personal_access_tokens_table	7
58	2025_10_28_000001_update_inv_consumo_flags	7
59	2025_10_28_000002_drop_public_ticket_trigger	7
60	2025_10_28_000003_add_display_fields_to_roles_table	7
61	2025_10_28_000010_create_audit_log_table	7
62	2025_10_28_200000_add_indexes_to_audit_log_table	7
63	2025_10_28_200001_add_foreign_key_to_audit_log_table	7
64	2025_10_30_000000_add_remember_token_to_selemti_users	7
65	2025_10_30_120000_add_code_columns_to_insumo	7
66	2025_11_03_194300_fix_item_id_data_types	7
67	2025_11_04_000900_create_additional_sales_report_views	7
68	2025_11_06_120000_refresh_sales_report_views	7
69	2025_11_15_000000_create_inventory_receiving_tables	7
70	2025_11_15_010000_create_inventory_counts_tables	7
71	2025_11_15_020000_create_production_tables	7
72	2025_11_15_030000_create_pos_consumption_tables	7
73	2025_11_15_050000_create_purchasing_tables	7
74	2025_11_15_060000_create_costing_extension_tables	7
75	2025_11_15_070000_create_pos_sync_tables	8
76	2025_11_15_080000_create_menu_engineering_tables	8
77	2025_11_15_090000_extend_alert_tables	8
79	2025_11_15_100000_create_reporting_tables	9
\.


--
-- TOC entry 5496 (class 0 OID 0)
-- Dependencies: 298
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('migrations_id_seq', 79, true);


--
-- TOC entry 5098 (class 0 OID 152893)
-- Dependencies: 299
-- Data for Name: model_has_permissions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY model_has_permissions (permission_id, model_type, model_id) FROM stdin;
\.


--
-- TOC entry 5099 (class 0 OID 152896)
-- Dependencies: 300
-- Data for Name: model_has_roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY model_has_roles (role_id, model_type, model_id) FROM stdin;
1	App\\Models\\User	3
\.


--
-- TOC entry 5100 (class 0 OID 152899)
-- Dependencies: 301
-- Data for Name: modificadores_pos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY modificadores_pos (id, codigo_pos, nombre, tipo, precio_extra, receta_modificador_id, activo) FROM stdin;
\.


--
-- TOC entry 5497 (class 0 OID 0)
-- Dependencies: 302
-- Name: modificadores_pos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('modificadores_pos_id_seq', 1, false);


--
-- TOC entry 5102 (class 0 OID 152907)
-- Dependencies: 303
-- Data for Name: mov_inv; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY mov_inv (id, ts, item_id, lote_id, cantidad, qty_original, uom_original_id, costo_unit, tipo, ref_tipo, ref_id, sucursal_id, usuario_id, created_at) FROM stdin;
\.


--
-- TOC entry 5498 (class 0 OID 0)
-- Dependencies: 304
-- Name: mov_inv_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('mov_inv_id_seq', 1, false);


--
-- TOC entry 5107 (class 0 OID 152996)
-- Dependencies: 311
-- Data for Name: op_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY op_cab (id, sucursal_id, receta_version_id, cantidad_objetivo, um_salida_id, estado, ts_apertura, ts_cierre, usuario_abre, usuario_cierra, lote_salida_id, meta, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5499 (class 0 OID 0)
-- Dependencies: 312
-- Name: op_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_cab_id_seq', 1, false);


--
-- TOC entry 5109 (class 0 OID 153008)
-- Dependencies: 313
-- Data for Name: op_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY op_insumo (id, op_id, item_id, qty_teorica, qty_real, um_id, batch_id, meta, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5500 (class 0 OID 0)
-- Dependencies: 314
-- Name: op_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_insumo_id_seq', 1, false);


--
-- TOC entry 5111 (class 0 OID 153018)
-- Dependencies: 315
-- Data for Name: op_produccion_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY op_produccion_cab (id, receta_version_id, cantidad_planeada, cantidad_real, fecha_produccion, estado, lote_resultado, usuario_responsable, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5501 (class 0 OID 0)
-- Dependencies: 316
-- Name: op_produccion_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('op_produccion_cab_id_seq', 1, false);


--
-- TOC entry 5113 (class 0 OID 153028)
-- Dependencies: 317
-- Data for Name: op_yield; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY op_yield (op_id, cantidad_real, merma_real, evidencia_url, meta) FROM stdin;
\.


--
-- TOC entry 5114 (class 0 OID 153035)
-- Dependencies: 318
-- Data for Name: overhead_definitions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY overhead_definitions (id, clave, nombre, tipo, tasa, activo, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5502 (class 0 OID 0)
-- Dependencies: 319
-- Name: overhead_definitions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('overhead_definitions_id_seq', 1, false);


--
-- TOC entry 5116 (class 0 OID 153046)
-- Dependencies: 320
-- Data for Name: param_sucursal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY param_sucursal (id, sucursal_id, consumo, tolerancia_precorte_pct, tolerancia_corte_abs, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5503 (class 0 OID 0)
-- Dependencies: 321
-- Name: param_sucursal_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('param_sucursal_id_seq', 1, false);


--
-- TOC entry 5118 (class 0 OID 153059)
-- Dependencies: 322
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY password_reset_tokens (email, token, created_at) FROM stdin;
\.


--
-- TOC entry 5119 (class 0 OID 153065)
-- Dependencies: 323
-- Data for Name: perdida_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY perdida_log (id, ts, item_id, lote_id, sucursal_id, clase, motivo, qty_canonica, qty_original, uom_original_id, evidencia_url, usuario_id, ref_tipo, ref_id, created_at) FROM stdin;
\.


--
-- TOC entry 5504 (class 0 OID 0)
-- Dependencies: 324
-- Name: perdida_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('perdida_log_id_seq', 1, false);


--
-- TOC entry 5121 (class 0 OID 153076)
-- Dependencies: 325
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
-- TOC entry 5505 (class 0 OID 0)
-- Dependencies: 326
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('permissions_id_seq', 45, true);


--
-- TOC entry 5123 (class 0 OID 153084)
-- Dependencies: 327
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, expires_at, created_at, updated_at) FROM stdin;
99	App\\Models\\User	3	browser-dashboard	6446ecbd18331cdeec2f10a6895680591a47703c8e1862b4d2e3443eb72752db	["*"]	2025-11-10 15:07:54	\N	2025-11-10 15:07:53	2025-11-10 15:07:54
\.


--
-- TOC entry 5506 (class 0 OID 0)
-- Dependencies: 328
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('personal_access_tokens_id_seq', 99, true);


--
-- TOC entry 5125 (class 0 OID 153092)
-- Dependencies: 329
-- Data for Name: pos_map; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_map (pos_system, plu, tipo, receta_id, receta_version_id, valid_from, valid_to, sys_from, sys_to, meta, vigente_desde, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5126 (class 0 OID 153102)
-- Dependencies: 330
-- Data for Name: pos_modifiers_map; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_modifiers_map (id, pos_modifier_code, name, effect, linked_recipe_id, linked_recipe_version_id, delta_qty_canonical, canonical_uom_id, delta_cost, active, valid_from, valid_to, notes, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5127 (class 0 OID 153114)
-- Dependencies: 331
-- Data for Name: pos_reprocess_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_reprocess_log (id, ticket_id, user_id, reprocessed_at, motivo, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5507 (class 0 OID 0)
-- Dependencies: 332
-- Name: pos_reprocess_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_reprocess_log_id_seq', 1, false);


--
-- TOC entry 5129 (class 0 OID 153125)
-- Dependencies: 333
-- Data for Name: pos_reverse_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_reverse_log (id, ticket_id, user_id, reversed_at, motivo, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5508 (class 0 OID 0)
-- Dependencies: 334
-- Name: pos_reverse_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_reverse_log_id_seq', 1, false);


--
-- TOC entry 5131 (class 0 OID 153136)
-- Dependencies: 335
-- Data for Name: pos_sync_batches; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_sync_batches (id, source_system, status, started_at, finished_at, rows_processed, rows_successful, rows_failed, metadata, errors, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5509 (class 0 OID 0)
-- Dependencies: 336
-- Name: pos_sync_batches_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_sync_batches_id_seq', 1, false);


--
-- TOC entry 5133 (class 0 OID 153148)
-- Dependencies: 337
-- Data for Name: pos_sync_logs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY pos_sync_logs (id, batch_id, external_id, action, status, payload, message, created_at) FROM stdin;
\.


--
-- TOC entry 5510 (class 0 OID 0)
-- Dependencies: 338
-- Name: pos_sync_logs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('pos_sync_logs_id_seq', 1, false);


--
-- TOC entry 5135 (class 0 OID 153211)
-- Dependencies: 347
-- Data for Name: prod_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY prod_cab (id, sol_id, fecha_programada, estado, creada_por, aprobada_por, created_at) FROM stdin;
\.


--
-- TOC entry 5511 (class 0 OID 0)
-- Dependencies: 348
-- Name: prod_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('prod_cab_id_seq', 1, false);


--
-- TOC entry 5137 (class 0 OID 153218)
-- Dependencies: 349
-- Data for Name: prod_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY prod_det (id, prod_id, sr_id, cantidad, rendimiento, created_at) FROM stdin;
\.


--
-- TOC entry 5512 (class 0 OID 0)
-- Dependencies: 350
-- Name: prod_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('prod_det_id_seq', 1, false);


--
-- TOC entry 5139 (class 0 OID 153224)
-- Dependencies: 351
-- Data for Name: production_order_inputs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY production_order_inputs (id, production_order_id, item_id, inventory_batch_id, qty, uom, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5513 (class 0 OID 0)
-- Dependencies: 352
-- Name: production_order_inputs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('production_order_inputs_id_seq', 1, false);


--
-- TOC entry 5141 (class 0 OID 153232)
-- Dependencies: 353
-- Data for Name: production_order_outputs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY production_order_outputs (id, production_order_id, item_id, inventory_batch_id, lote_producido, fecha_caducidad, qty, uom, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5514 (class 0 OID 0)
-- Dependencies: 354
-- Name: production_order_outputs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('production_order_outputs_id_seq', 1, false);


--
-- TOC entry 5143 (class 0 OID 153240)
-- Dependencies: 355
-- Data for Name: production_orders; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY production_orders (id, folio, recipe_id, item_id, qty_programada, qty_producida, qty_merma, uom_base, sucursal_id, almacen_id, programado_para, iniciado_en, cerrado_en, estado, creado_por, aprobado_por, notas, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5515 (class 0 OID 0)
-- Dependencies: 356
-- Name: production_orders_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('production_orders_id_seq', 1, false);


--
-- TOC entry 5145 (class 0 OID 153252)
-- Dependencies: 357
-- Data for Name: proveedor; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY proveedor (id, nombre, rfc, activo) FROM stdin;
\.


--
-- TOC entry 5146 (class 0 OID 153259)
-- Dependencies: 358
-- Data for Name: purchase_documents; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_documents (id, request_id, quote_id, order_id, tipo, file_url, uploaded_by, notas, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5516 (class 0 OID 0)
-- Dependencies: 359
-- Name: purchase_documents_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_documents_id_seq', 1, false);


--
-- TOC entry 5148 (class 0 OID 153267)
-- Dependencies: 360
-- Data for Name: purchase_order_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_order_lines (id, order_id, request_line_id, item_id, qty, uom, precio_unitario, descuento, impuestos, total, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5517 (class 0 OID 0)
-- Dependencies: 361
-- Name: purchase_order_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_order_lines_id_seq', 1, false);


--
-- TOC entry 5150 (class 0 OID 153277)
-- Dependencies: 362
-- Data for Name: purchase_orders; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_orders (id, folio, quote_id, vendor_id, sucursal_id, estado, fecha_promesa, subtotal, descuento, impuestos, total, creado_por, aprobado_por, aprobado_en, notas, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5518 (class 0 OID 0)
-- Dependencies: 363
-- Name: purchase_orders_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_orders_id_seq', 1, false);


--
-- TOC entry 5152 (class 0 OID 153290)
-- Dependencies: 364
-- Data for Name: purchase_request_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_request_lines (id, request_id, item_id, qty, uom, fecha_requerida, preferred_vendor_id, last_price, estado, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5519 (class 0 OID 0)
-- Dependencies: 365
-- Name: purchase_request_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_request_lines_id_seq', 1, false);


--
-- TOC entry 5154 (class 0 OID 153299)
-- Dependencies: 366
-- Data for Name: purchase_requests; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_requests (id, folio, sucursal_id, created_by, requested_by, requested_at, estado, importe_estimado, notas, meta, created_at, updated_at, fecha_requerida, almacen_destino_id, justificacion, urgente, origen_suggestion_id) FROM stdin;
\.


--
-- TOC entry 5520 (class 0 OID 0)
-- Dependencies: 367
-- Name: purchase_requests_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_requests_id_seq', 1, false);


--
-- TOC entry 5156 (class 0 OID 153311)
-- Dependencies: 368
-- Data for Name: purchase_suggestion_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_suggestion_lines (id, suggestion_id, item_id, stock_actual, stock_min, stock_max, reorder_point, consumo_promedio_diario, dias_cobertura_actual, demanda_proyectada, qty_sugerida, qty_ajustada, uom, costo_unitario_estimado, costo_total_linea, proveedor_sugerido_id, ultimo_precio_compra, fecha_ultima_compra, notas, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5521 (class 0 OID 0)
-- Dependencies: 369
-- Name: purchase_suggestion_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_suggestion_lines_id_seq', 1, false);


--
-- TOC entry 5158 (class 0 OID 153323)
-- Dependencies: 370
-- Data for Name: purchase_suggestions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_suggestions (id, folio, sucursal_id, almacen_id, estado, prioridad, origen, total_items, total_estimado, sugerido_en, sugerido_por_user_id, revisado_por_user_id, revisado_en, convertido_a_request_id, convertido_en, dias_analisis, consumo_promedio_calculado, notas, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5522 (class 0 OID 0)
-- Dependencies: 371
-- Name: purchase_suggestions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_suggestions_id_seq', 1, false);


--
-- TOC entry 5160 (class 0 OID 153339)
-- Dependencies: 372
-- Data for Name: purchase_vendor_quote_lines; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_vendor_quote_lines (id, quote_id, request_line_id, item_id, qty_oferta, uom_oferta, precio_unitario, pack_size, pack_uom, monto_total, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5523 (class 0 OID 0)
-- Dependencies: 373
-- Name: purchase_vendor_quote_lines_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_vendor_quote_lines_id_seq', 1, false);


--
-- TOC entry 5162 (class 0 OID 153348)
-- Dependencies: 374
-- Data for Name: purchase_vendor_quotes; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY purchase_vendor_quotes (id, request_id, vendor_id, folio_proveedor, estado, enviada_en, recibida_en, subtotal, descuento, impuestos, total, capturada_por, aprobada_por, aprobada_en, notas, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5524 (class 0 OID 0)
-- Dependencies: 375
-- Name: purchase_vendor_quotes_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('purchase_vendor_quotes_id_seq', 1, false);


--
-- TOC entry 5164 (class 0 OID 153362)
-- Dependencies: 376
-- Data for Name: recalc_log; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recalc_log (id, job_id, step, started_ts, ended_ts, ok, details) FROM stdin;
\.


--
-- TOC entry 5525 (class 0 OID 0)
-- Dependencies: 377
-- Name: recalc_log_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recalc_log_id_seq', 1, false);


--
-- TOC entry 5166 (class 0 OID 153370)
-- Dependencies: 378
-- Data for Name: recepcion_adjuntos; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recepcion_adjuntos (id, recepcion_id, tipo, file_url, notas, uploaded_by, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5526 (class 0 OID 0)
-- Dependencies: 379
-- Name: recepcion_adjuntos_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recepcion_adjuntos_id_seq', 1, false);


--
-- TOC entry 5168 (class 0 OID 153378)
-- Dependencies: 380
-- Data for Name: recepcion_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recepcion_cab (id, sucursal_id, proveedor_id, oc_ref, ts, usuario_id, meta, almacen_id, numero_recepcion, fecha_recepcion, estado, total_presentaciones, total_canonico, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5527 (class 0 OID 0)
-- Dependencies: 381
-- Name: recepcion_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recepcion_cab_id_seq', 1, false);


--
-- TOC entry 5170 (class 0 OID 153389)
-- Dependencies: 382
-- Data for Name: recepcion_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recepcion_det (id, recepcion_id, item_id, bodega_id, qty, um_id, costo_unit, batch_id, temperatura, doc_url, meta, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5528 (class 0 OID 0)
-- Dependencies: 383
-- Name: recepcion_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recepcion_det_id_seq', 1, false);


--
-- TOC entry 5172 (class 0 OID 153399)
-- Dependencies: 384
-- Data for Name: receta; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta (id, codigo, nombre, porciones, pvp_objetivo, activo, meta) FROM stdin;
\.


--
-- TOC entry 5104 (class 0 OID 152957)
-- Dependencies: 307
-- Data for Name: receta_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta_cab (id, nombre_plato, codigo_plato_pos, categoria_plato, porciones_standard, instrucciones_preparacion, tiempo_preparacion_min, costo_standard_porcion, precio_venta_sugerido, activo, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5105 (class 0 OID 152971)
-- Dependencies: 308
-- Data for Name: receta_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta_det (id, receta_version_id, item_id, cantidad, unidad_medida, merma_porcentaje, instrucciones_especificas, orden, created_at) FROM stdin;
\.


--
-- TOC entry 5529 (class 0 OID 0)
-- Dependencies: 385
-- Name: receta_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_det_id_seq', 1, false);


--
-- TOC entry 5530 (class 0 OID 0)
-- Dependencies: 386
-- Name: receta_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_id_seq', 1, false);


--
-- TOC entry 5175 (class 0 OID 153411)
-- Dependencies: 387
-- Data for Name: receta_insumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta_insumo (id, receta_version_id, item_id, cantidad) FROM stdin;
\.


--
-- TOC entry 5531 (class 0 OID 0)
-- Dependencies: 388
-- Name: receta_insumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_insumo_id_seq', 1, false);


--
-- TOC entry 5177 (class 0 OID 153416)
-- Dependencies: 389
-- Data for Name: receta_shadow; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta_shadow (id, codigo_plato_pos, nombre_plato, estado, confianza, total_ventas_analizadas, fecha_primer_venta, fecha_ultima_venta, frecuencia_dias, ingredientes_inferidos, usuario_validador, fecha_validacion, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5532 (class 0 OID 0)
-- Dependencies: 390
-- Name: receta_shadow_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_shadow_id_seq', 1, false);


--
-- TOC entry 5106 (class 0 OID 152982)
-- Dependencies: 309
-- Data for Name: receta_version; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY receta_version (id, receta_id, version, descripcion_cambios, fecha_efectiva, version_publicada, usuario_publicador, fecha_publicacion, created_at) FROM stdin;
\.


--
-- TOC entry 5533 (class 0 OID 0)
-- Dependencies: 391
-- Name: receta_version_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('receta_version_id_seq', 1, false);


--
-- TOC entry 5180 (class 0 OID 153433)
-- Dependencies: 392
-- Data for Name: recipe_cost_history; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_cost_history (id, recipe_id, recipe_version_id, snapshot_at, currency_code, batch_cost, portion_cost, batch_size, yield_portions, notes, created_at) FROM stdin;
\.


--
-- TOC entry 5534 (class 0 OID 0)
-- Dependencies: 393
-- Name: recipe_cost_history_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_cost_history_id_seq', 1, false);


--
-- TOC entry 5182 (class 0 OID 153443)
-- Dependencies: 394
-- Data for Name: recipe_cost_snapshots; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_cost_snapshots (id, recipe_id, snapshot_date, cost_total, cost_per_portion, portions, cost_breakdown, reason, created_by_user_id, created_at) FROM stdin;
\.


--
-- TOC entry 5535 (class 0 OID 0)
-- Dependencies: 395
-- Name: recipe_cost_snapshots_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_cost_snapshots_id_seq', 1, false);


--
-- TOC entry 5184 (class 0 OID 153456)
-- Dependencies: 396
-- Data for Name: recipe_extended_cost_history; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_extended_cost_history (id, recipe_id, snapshot_at, mp_batch_cost, labor_batch_cost, overhead_batch_cost, total_batch_cost, portion_cost, yield_portions, breakdown, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5536 (class 0 OID 0)
-- Dependencies: 397
-- Name: recipe_extended_cost_history_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_extended_cost_history_id_seq', 1, false);


--
-- TOC entry 5186 (class 0 OID 153471)
-- Dependencies: 398
-- Data for Name: recipe_labor_steps; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_labor_steps (id, recipe_id, labor_role_id, nombre, duracion_minutos, costo_manual, orden, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5537 (class 0 OID 0)
-- Dependencies: 399
-- Name: recipe_labor_steps_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_labor_steps_id_seq', 1, false);


--
-- TOC entry 5188 (class 0 OID 153481)
-- Dependencies: 400
-- Data for Name: recipe_overhead_allocations; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_overhead_allocations (id, recipe_id, overhead_id, valor, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5538 (class 0 OID 0)
-- Dependencies: 401
-- Name: recipe_overhead_allocations_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_overhead_allocations_id_seq', 1, false);


--
-- TOC entry 5190 (class 0 OID 153489)
-- Dependencies: 402
-- Data for Name: recipe_version_items; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_version_items (id, recipe_version_id, item_id, qty, uom_receta) FROM stdin;
\.


--
-- TOC entry 5539 (class 0 OID 0)
-- Dependencies: 403
-- Name: recipe_version_items_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_version_items_id_seq', 1, false);


--
-- TOC entry 5192 (class 0 OID 153494)
-- Dependencies: 404
-- Data for Name: recipe_versions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY recipe_versions (id, recipe_id, version_no, notes, valid_from, valid_to, created_at) FROM stdin;
\.


--
-- TOC entry 5540 (class 0 OID 0)
-- Dependencies: 405
-- Name: recipe_versions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('recipe_versions_id_seq', 1, false);


--
-- TOC entry 5194 (class 0 OID 153504)
-- Dependencies: 406
-- Data for Name: replenishment_suggestions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY replenishment_suggestions (id, folio, tipo, prioridad, origen, item_id, sucursal_id, almacen_id, stock_actual, stock_min, stock_max, qty_sugerida, qty_aprobada, uom, consumo_promedio_diario, dias_stock_restante, fecha_agotamiento_estimada, estado, purchase_request_id, production_order_id, sugerido_en, revisado_en, revisado_por, convertido_en, caduca_en, motivo, motivo_rechazo, notas, meta, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5541 (class 0 OID 0)
-- Dependencies: 407
-- Name: replenishment_suggestions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('replenishment_suggestions_id_seq', 1, false);


--
-- TOC entry 5241 (class 0 OID 156906)
-- Dependencies: 481
-- Data for Name: report_definitions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY report_definitions (id, name, slug, category, config, is_system, created_by, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5542 (class 0 OID 0)
-- Dependencies: 480
-- Name: report_definitions_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('report_definitions_id_seq', 1, false);


--
-- TOC entry 5196 (class 0 OID 153525)
-- Dependencies: 408
-- Data for Name: report_favorites; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY report_favorites (id, user_id, report_key, meta, created_at, updated_at) FROM stdin;
9	3	merma_promedio	{"range": "custom", "title": "Merma Promedio"}	2025-11-04 20:43:07-06	2025-11-04 20:43:07-06
\.


--
-- TOC entry 5543 (class 0 OID 0)
-- Dependencies: 409
-- Name: report_favorites_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('report_favorites_id_seq', 9, true);


--
-- TOC entry 5243 (class 0 OID 156920)
-- Dependencies: 483
-- Data for Name: report_runs; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY report_runs (id, report_id, requested_by, status, filters, result_meta, storage_path, queued_at, started_at, finished_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5544 (class 0 OID 0)
-- Dependencies: 482
-- Name: report_runs_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('report_runs_id_seq', 1, false);


--
-- TOC entry 5198 (class 0 OID 153542)
-- Dependencies: 410
-- Data for Name: rol; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY rol (id, codigo, nombre) FROM stdin;
\.


--
-- TOC entry 5545 (class 0 OID 0)
-- Dependencies: 411
-- Name: rol_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('rol_id_seq', 1, false);


--
-- TOC entry 5200 (class 0 OID 153550)
-- Dependencies: 412
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
-- TOC entry 5201 (class 0 OID 153553)
-- Dependencies: 413
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
-- TOC entry 5546 (class 0 OID 0)
-- Dependencies: 414
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('roles_id_seq', 7, true);


--
-- TOC entry 5203 (class 0 OID 153565)
-- Dependencies: 417
-- Data for Name: sessions; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY sessions (id, user_id, ip_address, user_agent, payload, last_activity) FROM stdin;
GlK9bV5CcsailD0MBBAMr0e6dGZLNjZZHKOLlHue	3	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	YTo1OntzOjY6Il90b2tlbiI7czo0MDoicnNpMkRXZmNKc2V5dDVocWZ6SlMxMjFNeGUwZE1ldGRzQUh0YlNDTiI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjQzOiJodHRwOi8vbG9jYWxob3N0L1RlcnJlbmFMYXJhdmVsL2NhamEvY29ydGVzIjtzOjU6InJvdXRlIjtzOjExOiJjYWphLmNvcnRlcyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjM7fQ==	1762479847
7T6jE5YodO8jPCavTf87VkEV9sTg72GIimxrtjnV	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiYlZOT3FZZllsQVcySVdBZ25Hb09NZE1OR0c2RW1NNlFDWGVhdjZPVyI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czo0MzoiaHR0cDovL2xvY2FsaG9zdC9UZXJyZW5hTGFyYXZlbC9jYWphL2NvcnRlcyI7fXM6OToiX3ByZXZpb3VzIjthOjI6e3M6MzoidXJsIjtzOjM3OiJodHRwOi8vbG9jYWxob3N0L1RlcnJlbmFMYXJhdmVsL2xvZ2luIjtzOjU6InJvdXRlIjtzOjU6ImxvZ2luIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==	1762543958
YZVC1L8PxxxLxYkvNUDw8JFuXVxubhn0nN8hMXK5	3	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	YTo0OntzOjY6Il90b2tlbiI7czo0MDoiWGk1Y3BXS1h1SVZVTmV1VUM2QTMxS21EQVY5SzQ2SlJSQXNwMHhwayI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDE6Imh0dHA6Ly9sb2NhbGhvc3QvVGVycmVuYUxhcmF2ZWwvZGFzaGJvYXJkIjtzOjU6InJvdXRlIjtzOjk6ImRhc2hib2FyZCI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjM7fQ==	1762815542
jvIvkr9etwTqsXjB55vxEM72mGcvu27baHZ7BZMV	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	YTozOntzOjY6Il90b2tlbiI7czo0MDoiMGNBOFIwVDh0WjFHTUlwaGtnNjBnOVRqa0pBMGtXYUNUeGRqTmNqWSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mzc6Imh0dHA6Ly9sb2NhbGhvc3QvVGVycmVuYUxhcmF2ZWwvbG9naW4iO3M6NToicm91dGUiO3M6NToibG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19	1762448027
\.


--
-- TOC entry 5204 (class 0 OID 153571)
-- Dependencies: 418
-- Data for Name: sol_prod_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY sol_prod_cab (id, sucursal_id, fecha, estado, solicitada_por, autorizada_por, observaciones, created_at) FROM stdin;
\.


--
-- TOC entry 5547 (class 0 OID 0)
-- Dependencies: 419
-- Name: sol_prod_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('sol_prod_cab_id_seq', 1, false);


--
-- TOC entry 5206 (class 0 OID 153582)
-- Dependencies: 420
-- Data for Name: sol_prod_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY sol_prod_det (id, sol_id, plu, cantidad, cantidad_autorizada, created_at) FROM stdin;
\.


--
-- TOC entry 5548 (class 0 OID 0)
-- Dependencies: 421
-- Name: sol_prod_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('sol_prod_det_id_seq', 1, false);


--
-- TOC entry 5208 (class 0 OID 153588)
-- Dependencies: 422
-- Data for Name: stock_policy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY stock_policy (id, item_id, sucursal_id, almacen_id, min_qty, max_qty, reorder_lote, activo, created_at) FROM stdin;
\.


--
-- TOC entry 5549 (class 0 OID 0)
-- Dependencies: 423
-- Name: stock_policy_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('stock_policy_id_seq', 1, false);


--
-- TOC entry 5210 (class 0 OID 153600)
-- Dependencies: 424
-- Data for Name: sucursal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY sucursal (id, nombre, activo) FROM stdin;
\.


--
-- TOC entry 5211 (class 0 OID 153607)
-- Dependencies: 425
-- Data for Name: sucursal_almacen_terminal; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY sucursal_almacen_terminal (id, sucursal_id, almacen_id, terminal_id, location, descripcion, activo, created_at) FROM stdin;
\.


--
-- TOC entry 5550 (class 0 OID 0)
-- Dependencies: 426
-- Name: sucursal_almacen_terminal_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('sucursal_almacen_terminal_id_seq', 1, false);


--
-- TOC entry 5213 (class 0 OID 153617)
-- Dependencies: 427
-- Data for Name: ticket_det_consumo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY ticket_det_consumo (id, ticket_id, ticket_det_id, item_id, lote_id, qty_canonica, qty_original, uom_original_id, sucursal_id, ref_tipo, ref_id, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5551 (class 0 OID 0)
-- Dependencies: 428
-- Name: ticket_det_consumo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_det_consumo_id_seq', 1, false);


--
-- TOC entry 5215 (class 0 OID 153628)
-- Dependencies: 429
-- Data for Name: ticket_item_modifiers; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY ticket_item_modifiers (id, ticket_id, ticket_item_id, sucursal_id, terminal_id, procesado, fecha_proceso, pos_code, recipe_version_id, precio_extra, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5552 (class 0 OID 0)
-- Dependencies: 430
-- Name: ticket_item_modifiers_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_item_modifiers_id_seq', 1, false);


--
-- TOC entry 5217 (class 0 OID 153635)
-- Dependencies: 431
-- Data for Name: ticket_venta_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY ticket_venta_cab (id, numero_ticket, fecha_venta, sucursal_id, terminal_id, total_venta, estado, created_at) FROM stdin;
\.


--
-- TOC entry 5553 (class 0 OID 0)
-- Dependencies: 432
-- Name: ticket_venta_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_venta_cab_id_seq', 1, false);


--
-- TOC entry 5219 (class 0 OID 153645)
-- Dependencies: 433
-- Data for Name: ticket_venta_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY ticket_venta_det (id, ticket_id, item_id, cantidad, precio_unitario, subtotal, receta_version_id, created_at, receta_shadow_id, reprocesado, version_reproceso, modificadores_aplicados) FROM stdin;
\.


--
-- TOC entry 5554 (class 0 OID 0)
-- Dependencies: 434
-- Name: ticket_venta_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('ticket_venta_det_id_seq', 1, false);


--
-- TOC entry 5221 (class 0 OID 153657)
-- Dependencies: 435
-- Data for Name: transfer_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY transfer_cab (id, origen_almacen_id, destino_almacen_id, estado, creada_por, despachada_por, recibida_por, guia, created_at) FROM stdin;
\.


--
-- TOC entry 5555 (class 0 OID 0)
-- Dependencies: 436
-- Name: transfer_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('transfer_cab_id_seq', 1, false);


--
-- TOC entry 5223 (class 0 OID 153664)
-- Dependencies: 437
-- Data for Name: transfer_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY transfer_det (id, transfer_id, item_id, cantidad, cantidad_despachada, cantidad_recibida, created_at) FROM stdin;
\.


--
-- TOC entry 5556 (class 0 OID 0)
-- Dependencies: 438
-- Name: transfer_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('transfer_det_id_seq', 1, false);


--
-- TOC entry 5225 (class 0 OID 153670)
-- Dependencies: 439
-- Data for Name: traspaso_cab; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY traspaso_cab (id, from_bodega_id, to_bodega_id, ts, usuario_id, meta, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5557 (class 0 OID 0)
-- Dependencies: 440
-- Name: traspaso_cab_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('traspaso_cab_id_seq', 1, false);


--
-- TOC entry 5227 (class 0 OID 153681)
-- Dependencies: 441
-- Data for Name: traspaso_det; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY traspaso_det (id, traspaso_id, item_id, batch_id, qty, um_id, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5558 (class 0 OID 0)
-- Dependencies: 442
-- Name: traspaso_det_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('traspaso_det_id_seq', 1, false);


--
-- TOC entry 5559 (class 0 OID 0)
-- Dependencies: 445
-- Name: unidad_medida_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('unidad_medida_id_seq', 1, false);


--
-- TOC entry 5229 (class 0 OID 153693)
-- Dependencies: 444
-- Data for Name: unidad_medida_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY unidad_medida_legacy (id, codigo, nombre, tipo, es_base, factor_a_base, decimales) FROM stdin;
\.


--
-- TOC entry 5560 (class 0 OID 0)
-- Dependencies: 448
-- Name: unidades_medida_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('unidades_medida_id_seq', 1, false);


--
-- TOC entry 5231 (class 0 OID 153710)
-- Dependencies: 447
-- Data for Name: unidades_medida_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY unidades_medida_legacy (id, codigo, nombre, tipo, categoria, es_base, factor_conversion_base, decimales, created_at) FROM stdin;
\.


--
-- TOC entry 5561 (class 0 OID 0)
-- Dependencies: 451
-- Name: uom_conversion_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('uom_conversion_id_seq', 1, false);


--
-- TOC entry 5233 (class 0 OID 153727)
-- Dependencies: 450
-- Data for Name: uom_conversion_legacy; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY uom_conversion_legacy (id, origen_id, destino_id, factor) FROM stdin;
\.


--
-- TOC entry 5235 (class 0 OID 153734)
-- Dependencies: 452
-- Data for Name: user_roles; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY user_roles (user_id, role_id, assigned_at, assigned_by) FROM stdin;
\.


--
-- TOC entry 5236 (class 0 OID 153739)
-- Dependencies: 453
-- Data for Name: users; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY users (id, username, password_hash, email, nombre_completo, sucursal_id, activo, fecha_ultimo_login, intentos_login, bloqueado_hasta, created_at, updated_at, remember_token) FROM stdin;
3	soporte	$2y$12$ooLJw7RQYdTPJmuISfour.jHXJVXbSsMJqkXHA//UbHRK3FSXsaF6	soporte@terrena.com	Usuario Soporte	SUR	t	\N	0	\N	2025-11-02 12:34:50.954274	2025-11-02 20:03:09	\N
\.


--
-- TOC entry 5562 (class 0 OID 0)
-- Dependencies: 454
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('users_id_seq', 3, true);


--
-- TOC entry 5238 (class 0 OID 153757)
-- Dependencies: 455
-- Data for Name: usuario; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY usuario (id, username, nombre, email, rol_id, activo, password_hash, floreant_user_id, meta, created_at) FROM stdin;
\.


--
-- TOC entry 5563 (class 0 OID 0)
-- Dependencies: 456
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('usuario_id_seq', 1, false);


-- Completed on 2025-11-10 17:11:23

--
-- PostgreSQL database dump complete
--

