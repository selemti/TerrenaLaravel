--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.0
-- Dumped by pg_dump version 9.5.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

--
-- Data for Name: cash_drawer_reset_history; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY cash_drawer_reset_history (id, reset_time, user_id) FROM stdin;
30	2025-09-15 03:23:15.067	1
31	2025-09-15 03:50:51.958	1
32	2025-09-15 04:44:41.19	7
33	2025-09-15 04:49:33.073	1
34	2025-09-15 05:14:59.653	7
35	2025-09-15 07:11:57.932	1
36	2025-09-15 16:31:37.598	1
37	2025-09-15 20:24:21.418	1
38	2025-09-15 21:48:02.085	1
\.


--
-- Name: cash_drawer_reset_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('cash_drawer_reset_history_id_seq', 38, true);


--
-- Data for Name: custom_payment; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY custom_payment (id, name, required_ref_number, ref_number_field_name) FROM stdin;
1	Tranferencia	t	Nombre
\.


--
-- Name: custom_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('custom_payment_id_seq', 1, true);


--
-- Data for Name: drawer_assigned_history; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY drawer_assigned_history (id, "time", operation, a_user) FROM stdin;
1	2025-08-15 06:00:50.176	ASIGNAR	1
2	2025-08-15 12:21:24.808	ASIGNAR	7
3	2025-08-15 12:55:56.962	CERRAR	7
4	2025-08-15 12:57:34.556	CERRAR	1
5	2025-08-15 13:04:45.032	ASIGNAR	6
6	2025-08-15 13:04:51.516	CERRAR	6
7	2025-08-15 13:33:57.629	ASIGNAR	6
8	2025-08-15 13:40:42.266	CERRAR	6
9	2025-08-15 13:40:59.187	ASIGNAR	6
10	2025-08-15 14:06:24.506	ASIGNAR	6
11	2025-08-15 18:54:46.848	CERRAR	6
12	2025-08-16 08:31:01.765	CERRAR	6
13	2025-08-16 09:30:40.619	ASIGNAR	6
14	2025-08-16 09:43:10.427	ASIGNAR	7
15	2025-08-16 16:58:24.067	CERRAR	6
16	2025-08-16 17:15:10.01	CERRAR	7
17	2025-08-16 17:22:52.894	ASIGNAR	1
18	2025-08-18 08:24:07.202	ASIGNAR	6
19	2025-08-18 08:25:00.513	ASIGNAR	7
20	2025-08-18 18:27:24.265	CERRAR	7
21	2025-08-18 18:46:15.361	CERRAR	6
22	2025-08-19 09:05:22.407	ASIGNAR	6
23	2025-08-19 10:42:04.823	ASIGNAR	8
24	2025-08-19 18:42:43.713	CERRAR	6
25	2025-08-19 18:47:00.868	CERRAR	8
26	2025-08-20 09:10:26.782	ASIGNAR	6
27	2025-08-20 10:39:52.787	ASIGNAR	8
28	2025-08-20 19:11:36.357	CERRAR	6
29	2025-08-20 19:24:21.261	CERRAR	8
30	2025-09-06 12:00:13.49	CERRAR	1
31	2025-09-06 12:00:23.439	ASIGNAR	1
32	2025-09-06 12:02:11.03	CERRAR	1
33	2025-09-06 12:41:25.871	ASIGNAR	1
34	2025-09-08 09:48:29.382	CERRAR	1
35	2025-09-08 09:48:40.857	ASIGNAR	1
36	2025-09-10 12:06:59.291	CERRAR	1
37	2025-09-10 12:07:32.624	ASIGNAR	1
38	2025-09-11 00:26:49.689	CERRAR	1
39	2025-09-11 00:28:52.636	ASIGNAR	1
40	2025-09-12 04:59:12.848	CERRAR	1
41	2025-09-12 04:59:49.617	ASIGNAR	1
42	2025-09-12 19:53:01.416	CERRAR	1
43	2025-09-12 19:53:58.175	ASIGNAR	1
44	2025-09-13 01:43:02.907	CERRAR	1
45	2025-09-13 01:43:23.001	ASIGNAR	1
46	2025-09-14 18:40:29.403	CERRAR	1
47	2025-09-14 20:47:33.978	ASIGNAR	1
48	2025-09-14 20:52:25.525	CERRAR	1
49	2025-09-14 21:01:07.943	ASIGNAR	1
50	2025-09-14 22:39:52.953	CERRAR	1
51	2025-09-14 22:41:33.358	ASIGNAR	1
52	2025-09-14 22:47:21.021	CERRAR	1
53	2025-09-14 23:27:26.917	ASIGNAR	1
54	2025-09-15 02:59:54.308	CERRAR	1
55	2025-09-15 03:00:35.213	ASIGNAR	6
56	2025-09-15 03:05:46.307	CERRAR	6
57	2025-09-15 03:06:45.012	ASIGNAR	1
58	2025-09-15 03:08:07.505	CERRAR	1
59	2025-09-15 03:18:41.726	ASIGNAR	1
60	2025-09-15 03:23:15.124	CERRAR	1
61	2025-09-15 03:37:23.224	ASIGNAR	1
62	2025-09-15 03:50:52.011	CERRAR	1
63	2025-09-15 04:01:12.026	ASIGNAR	7
64	2025-09-15 04:44:41.197	CERRAR	7
65	2025-09-15 04:45:36.901	ASIGNAR	1
66	2025-09-15 04:49:33.073	CERRAR	1
67	2025-09-15 05:06:32.731	ASIGNAR	7
68	2025-09-15 05:14:59.657	CERRAR	7
69	2025-09-15 05:25:22.001	ASIGNAR	1
70	2025-09-15 07:11:57.936	CERRAR	1
71	2025-09-15 16:31:04.476	ASIGNAR	1
72	2025-09-15 16:31:37.598	CERRAR	1
73	2025-09-15 19:51:08.171	ASIGNAR	1
74	2025-09-15 20:24:21.418	CERRAR	1
75	2025-09-15 21:44:00.823	ASIGNAR	1
76	2025-09-15 21:48:02.091	CERRAR	1
\.


--
-- Name: drawer_assigned_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('drawer_assigned_history_id_seq', 76, true);


--
-- Data for Name: drawer_pull_report; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY drawer_pull_report (id, report_time, reg, ticket_count, begin_cash, net_sales, sales_tax, cash_tax, total_revenue, gross_receipts, giftcertreturncount, giftcertreturnamount, giftcertchangeamount, cash_receipt_no, cash_receipt_amount, credit_card_receipt_no, credit_card_receipt_amount, debit_card_receipt_no, debit_card_receipt_amount, refund_receipt_count, refund_amount, receipt_differential, cash_back, cash_tips, charged_tips, tips_paid, tips_differential, pay_out_no, pay_out_amount, drawer_bleed_no, drawer_bleed_amount, drawer_accountable, cash_to_deposit, variance, delivery_charge, totalvoidwst, totalvoid, totaldiscountcount, totaldiscountamount, totaldiscountsales, totaldiscountguest, totaldiscountpartysize, totaldiscountchecksize, totaldiscountpercentage, totaldiscountratio, user_id, terminal_id) FROM stdin;
30	2025-09-15 03:23:14.957	\N	1	1500	135	0	0	135	135	0	0	0	1	135	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	1635	635	0	0	0	0	0	0	0	0	0	0	0	0	1	9939
31	2025-09-15 03:50:51.847	\N	1	0	130	0	0	130	130	0	0	0	1	130	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	130	630	0	0	0	0	0	0	0	0	0	0	0	0	1	9939
32	2025-09-15 04:44:41.096	\N	1	0	180	0	0	180	180	0	0	0	1	180	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	180	680	0	0	0	0	0	0	0	0	0	0	0	0	7	9939
33	2025-09-15 04:49:32.92	\N	4	0	280	0	0	280	280	0	0	0	1	200	1	20	1	35	0	0	25	0	0	0	0	0	0	0	0	0	200	700	0	0	0	0	0	0	0	0	0	0	0	0	1	9939
34	2025-09-15 05:14:59.463	\N	4	0	189	0	0	189	189	0	0	0	1	124	1	10	1	20	0	0	35	0	0	0	0	0	0	0	0	0	124	224	0	0	0	0	0	0	0	0	0	0	0	0	7	9939
35	2025-09-15 07:11:57.763	\N	3	0	158	0	0	158	158	0	0	0	1	55	1	25	1	78	0	0	0	0	0	0	0	0	1	20	1	10	25	525	0	0	0	0	0	0	0	0	0	0	0	0	1	9939
36	2025-09-15 16:31:37.529	\N	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	500	0	0	0	0	0	0	0	0	0	0	0	0	1	9939
37	2025-09-15 20:24:21.208	\N	6	0	445	0	0	445	445	0	0	0	2	115	1	50	1	75	0	0	205	0	0	0	0	0	0	0	0	0	115	315	0	0	0	0	0	0	0	0	0	0	0	0	1	9939
38	2025-09-15 21:48:01.881	\N	5	0	792	0	0	792	792	0	0	0	2	342	1	100	1	150	0	0	200	0	0	0	0	0	0	0	0	0	342	1542	0	0	0	0	1	100	0	1	1	1	0	0	1	9939
\.


--
-- Name: drawer_pull_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('drawer_pull_report_id_seq', 38, true);


--
-- Data for Name: drawer_pull_report_voidtickets; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY drawer_pull_report_voidtickets (dpreport_id, code, reason, hast, quantity, amount) FROM stdin;
\.


--
-- Data for Name: menu_item; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY menu_item (id, name, description, unit_name, translated_name, barcode, buy_price, stock_amount, price, discount_rate, visible, disable_when_stock_amount_is_zero, sort_order, btn_color, text_color, image, show_image_only, fractional_unit, pizza_type, default_sell_portion, group_id, tax_group_id, recepie, pg_id, tax_id) FROM stdin;
66	Agua de Sabor			Agua de Sabor		0	0	25	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	18	\N	\N	\N	\N
60	Agua Embotellada 1 L			Agua Embotellada 1 L		0	0	15	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	18	\N	\N	\N	\N
61	Agua Embotellada 500 ML			Agua Embotellada 500 ML		0	0	10	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	18	\N	\N	\N	\N
43	Americano			Americano		0	0	30	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	14	\N	\N	2	\N
21	Boneless 10 pz			Boneless 10 pz		0	0	110	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	6	\N	\N	1	\N
22	Boneless 17 pz			Boneless 17 pz		0	0	158	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	6	\N	\N	1	\N
20	Boneless 5 pz			Boneless 5 pz		0	0	68	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	6	\N	\N	1	\N
87	CACAHUATE HORNEADO			CACAHUATE HORNEADO		12	0	18	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	66	\N	\N	\N	\N
44	Capuchino			Capuchino		0	0	45	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	14	\N	\N	2	\N
50	CHAI LATTE			CHAI LATTE		0	0	55	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	14	\N	\N	2	\N
69	Cheesecake Frambuesa			Cheesecake Frambuesa		0	0	40	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	21	\N	\N	\N	\N
70	Cheesecake Tortuga			Cheesecake Tortuga		0	0	45	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	21	\N	\N	\N	\N
33	Chilaquiles			Chilaquiles		0	0	50	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	9	\N	\N	1	\N
34	Chilaquiles Terrena			Chilaquiles Terrena		0	0	85	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	9	\N	\N	1	\N
71	Chocoflan			Chocoflan		0	0	35	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	21	\N	\N	\N	\N
51	Chocolatito			Chocolatito		0	0	40	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	16	\N	\N	2	\N
59	Chocomilk			Chocomilk		0	0	35	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	20	\N	\N	1	\N
25	Club Sándwich			Club Sándwich		0	0	60	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	7	\N	\N	1	\N
40	CÓCTEL DE FRUTAS			CÓCTEL DE FRUTAS		0	0	28	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	12	\N	\N	1	\N
41	CÓCTEL PREPARADO			CÓCTEL PREPARADO		0	0	35	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	12	\N	\N	1	\N
26	Cuernito Jamón con Queso			Cuernito Jamón/Queso		0	0	45	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	7	\N	\N	1	\N
65	Electrolit			Electrolit		0	0	30	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	18	\N	\N	\N	\N
6	Empanada			Empanada		0	0	16	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	1	\N	\N	1	\N
9	Enchiladas			Enchiladas		0	0	50	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	2	\N	\N	1	\N
10	Enchiladas Terrena			Enchiladas Terrena		0	0	85	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	2	\N	\N	1	\N
35	Enfrijoladas			Enfrijoladas		0	0	50	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	10	\N	\N	1	\N
11	Enmoladas			Enmoladas		0	0	55	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	2	\N	\N	1	\N
17	Ensalada Atún			Ensalada Atún		0	0	95	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	3	\N	\N	1	\N
18	Ensalada Dulce			Ensalada Dulce		0	0	88	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	3	\N	\N	1	\N
19	Ensalada Pollo			Ensalada Pollo		0	0	95	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	3	\N	\N	1	\N
45	Espresso			Espresso		0	0	20	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	14	\N	\N	2	\N
46	Espresso Cortado			Espresso Cortado		0	0	25	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	14	\N	\N	2	\N
72	Galleta Chispas			Galleta Chispas		0	0	13	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	21	\N	\N	\N	\N
73	Gelatina con Yogurt			Gelatina con Yogurt		0	0	16	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	21	\N	\N	\N	\N
85	GREEN MOUNTAIN BARRA			GREEN MOUNTAIN BARRA		0	0	20	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	66	\N	\N	\N	\N
83	Halls			Halls		15	0	15	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	67	\N	\N	\N	\N
38	Hot Cakes			Hot Cakes		0	0	42	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	11	\N	\N	1	\N
39	Hot Cakes Terrena			Hot Cakes Terrena		0	0	58	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	11	\N	\N	1	\N
29	Huevos al Gusto			Huevos al Gusto		0	0	63	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	8	\N	\N	1	\N
32	Huevos Divorciados			Huevos Divorciados		0	0	65	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	8	\N	\N	1	\N
31	Huevos Rancheros			Huevos Rancheros		0	0	65	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	8	\N	\N	1	\N
28	Huevos Sencillos			Huevos Sencillos		0	0	50	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	8	\N	\N	1	\N
30	Huevos Tirados			Huevos Tirados		0	0	65	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	8	\N	\N	1	\N
54	Jugo Naranja			Jugo Naranja		0	0	35	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	19	\N	\N	1	\N
56	Jugo Verde			Jugo Verde		0	0	35	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	19	\N	\N	1	\N
55	Jugo Zanahoria			Jugo Zanahoria		0	0	35	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	19	\N	\N	1	\N
84	KIRLAND BARRA PROTEINA			KIRLAND BARRA PROTEINA		0	0	20	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	66	\N	\N	\N	\N
47	Latte			Latte		0	0	45	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	14	\N	\N	2	\N
48	Latte Sabor			Latte Sabor		0	0	55	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	14	\N	\N	2	\N
58	Licuado			Licuado		0	0	38	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	20	\N	\N	1	\N
67	Limonada			Limonada		0	0	20	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	18	\N	\N	\N	\N
78	Limonada Mineral			Limonada Mineral		0	0	25	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	18	\N	\N	2	\N
80	MALANGA			MALANGA		0	0	28	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	66	\N	\N	\N	\N
57	Malteada			Malteada		0	0	45	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	20	\N	\N	1	\N
49	Matcha Latte			Matcha Latte		0	0	55	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	14	\N	\N	2	\N
86	MENU DEL DIA 			MENU DEL DIA 		0	0	65	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	4	\N	\N	1	\N
62	Mineral 600 ml			Mineral 600 ml		0	0	22	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	18	\N	\N	\N	\N
63	Mineral Twist 600 ml			Mineral Twist 600 ml		0	0	25	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	18	\N	\N	\N	\N
23	Mollete			Mollete		0	0	45	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	7	\N	\N	1	\N
74	Muffin			Muffin		0	0	25	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	21	\N	\N	\N	\N
68	Naranjada			Naranjada		0	0	20	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	18	\N	\N	\N	\N
79	Naranjada Mineral			Naranjada Mineral		0	0	25	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	18	\N	\N	2	\N
37	Omelette Espinacas & Champiñón			Omelette Espinacas & Champiñón		0	0	85	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	8	\N	\N	1	\N
36	Omelette Jamon & Tocino			Omelette Jamon & Tocino		0	0	82	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	8	\N	\N	1	\N
81	Papas			Papas		0	0	25	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	66	\N	\N	\N	\N
15	Pasta Boloñesa			Pasta Boloñesa		0	0	82	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	4	\N	\N	1	\N
16	Pasta Pomodoro			Pasta Pomodoro		0	0	78	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	4	\N	\N	1	\N
75	Pastel Chocolate Matilda			Pastel Chocolate Matilda		0	0	45	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	21	\N	\N	\N	\N
76	Pastel Zanahoria			Pastel Zanahoria		0	0	45	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	21	\N	\N	\N	\N
77	Pay Limón			Pay Limón		0	0	35	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	21	\N	\N	\N	\N
2	Picada			Picada		0	0	38	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	1	\N	\N	1	\N
8	Picada Terrena			Picada Terrena		0	0	68	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	1	\N	\N	1	\N
82	Platanos			Platanos		0	0	25	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	66	\N	\N	\N	\N
13	Puchero de Pollo			Puchero de Pollo		0	0	50	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	4	\N	\N	1	\N
5	Quesadilla			Quesadilla		0	0	22	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	1	\N	\N	1	\N
24	Sándwich			Sándwich		0	0	45	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	7	\N	\N	1	\N
14	Sopa Azteca			Sopa Azteca		0	0	52	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	4	\N	\N	1	\N
7	Taco de Guisado			Taco de Guisado		0	0	19	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	1	\N	\N	1	\N
3	Taco Dorado			Taco Dorado		0	0	15	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	13	\N	\N	1	\N
42	Tacos de Guisado			Tacos de Guisado		0	0	19	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	13	\N	\N	1	\N
12	Tampiqueña			Tampiqueña		0	0	90	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	2	\N	\N	1	\N
53	Té (Sabores)			Té (Sabores)		0	0	20	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	16	\N	\N	2	\N
52	Té Manzana con Especias			Té Manzana con Especias		0	0	30	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	16	\N	\N	2	\N
64	Topo Chico 600 ml			Topo Chico 600 ml		0	0	25	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	18	\N	\N	\N	\N
27	Torta			Torta		0	0	38	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	7	\N	\N	1	\N
4	Tostadas			Tostadas		0	0	33	0	t	f	9999	-1250856	-16777216	\N	f	f	f	0	1	\N	\N	1	\N
\.


--
-- Name: menu_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('menu_item_id_seq', 87, true);


--
-- Data for Name: menu_modifier; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY menu_modifier (id, name, translated_name, price, extra_price, sort_order, btn_color, text_color, enable, fixed_price, print_to_kitchen, section_wise_pricing, pizza_modifier, group_id, tax_id) FROM stdin;
1	Pollo	Pollo	0	0	9999	-1250856	-16777216	f	f	t	f	f	3	2
6	Pollo	Pollo	0	0	9999	-1250856	-16777216	f	f	t	f	f	5	2
7	Jamón	Jamón	0	0	9999	-1250856	-16777216	f	f	t	f	f	5	2
2	Picadillo	Picadillo	0	0	9999	-1250856	-16777216	f	f	t	f	f	3	2
3	Queso	Queso	0	0	9999	-1250856	-16777216	f	f	t	f	f	3	2
4	Pollo	Pollo	0	0	9999	-1250856	-16777216	f	f	t	f	f	4	2
5	Papa	Papa	0	0	9999	-1250856	-16777216	f	f	t	f	f	4	2
8	Maíz	Maíz	0	0	9999	-1250856	-16777216	f	f	t	f	f	6	2
9	Harina	Harina	0	0	9999	-1250856	-16777216	f	f	t	f	f	6	2
10	Jamón	Jamón	0	0	9999	-1250856	-16777216	f	f	t	f	f	7	2
11	Chorizo	Chorizo	3	0	9999	-1250856	-16777216	f	f	t	f	f	7	2
12	Pastor	Pastor	13	0	9999	-1250856	-16777216	f	f	t	f	f	7	2
13	Champiñones	Champiñones	13	0	9999	-1250856	-16777216	f	f	t	f	f	7	2
67	Lechera	Lechera	0	0	9999	-1250856	-16777216	f	f	t	f	f	30	2
14	Verde	Verde	0	0	9999	-1250856	-16777216	f	f	t	f	f	8	2
15	Roja	Roja	0	0	9999	-1250856	-16777216	f	f	t	f	f	8	2
16	Chileseco	Chileseco	0	0	9999	-1250856	-16777216	f	f	t	f	f	8	2
17	Frijoles	Frijoles	0	0	9999	-1250856	-16777216	f	f	t	f	f	8	2
18	Sencilla	Sencilla	0	0	9999	-1250856	-16777216	f	f	t	f	f	9	2
19	Huevo	Huevo	17	0	9999	-1250856	-16777216	f	f	t	f	f	9	2
20	Pollo	Pollo	20	0	9999	-1250856	-16777216	f	f	t	f	f	9	2
21	Chorizo	Chorizo	20	0	9999	-1250856	-16777216	f	f	t	f	f	9	2
27	Roja	Roja	0	0	9999	-1250856	-16777216	f	f	t	f	f	11	2
28	Verde	Verde	0	0	9999	-1250856	-16777216	f	f	t	f	f	11	2
29	Sencillas	Sencillas	0	0	9999	-1250856	-16777216	f	f	t	f	f	12	2
30	Pollo	Pollo	15	0	9999	-1250856	-16777216	f	f	t	f	f	12	2
31	Huevo	Huevo	15	0	9999	-1250856	-16777216	f	f	t	f	f	12	2
32	Jamón	Jamón	18	0	9999	-1250856	-16777216	f	f	t	f	f	12	2
33	Queso de Hebra	Queso de Hebra	18	0	9999	-1250856	-16777216	f	f	t	f	f	12	2
34	Milanesa	Milanesa	0	0	9999	-1250856	-16777216	f	f	t	f	f	13	2
35	Pechuga	Pechuga	0	0	9999	-1250856	-16777216	f	f	t	f	f	13	2
36	Cecina	Cecina	10	0	9999	-1250856	-16777216	f	f	t	f	f	13	2
37	Arrachera	Arrachera	13	0	9999	-1250856	-16777216	f	f	t	f	f	13	2
42	Pechuga	Pechuga	0	0	9999	-1250856	-16777216	f	f	t	f	f	16	2
43	Cecina	Cecina	20	0	9999	-1250856	-16777216	f	f	t	f	f	16	2
44	Arrachera	Arrachera	30	0	9999	-1250856	-16777216	f	f	t	f	f	16	2
45	Milanesa	Milanesa	0	0	9999	-1250856	-16777216	f	f	t	f	f	16	2
46	Estrellado	Estrellado	0	0	9999	-1250856	-16777216	f	f	t	f	f	17	2
47	Revuelto	Revuelto	0	0	9999	-1250856	-16777216	f	f	t	f	f	17	2
50	Cocido	Cocido	0	0	9999	-1250856	-16777216	f	f	t	f	f	18	2
48	Tierno	Tierno	0	0	9999	-1250856	-16777216	f	f	t	f	f	18	2
49	Medio	Medio	0	0	9999	-1250856	-16777216	f	f	t	f	f	18	2
51	Sencillas	Sencillas	0	0	9999	-1250856	-16777216	f	f	t	f	f	19	2
52	Pollo	Pollo	18	0	9999	-1250856	-16777216	f	f	t	f	f	19	2
53	Chorizo	Chorizo	18	0	9999	-1250856	-16777216	f	f	t	f	f	19	2
54	Huevo	Huevo	15	0	9999	-1250856	-16777216	f	f	t	f	f	19	2
55	Roja	Roja	0	0	9999	-1250856	-16777216	f	f	t	f	f	20	2
56	Verde	Verde	0	0	9999	-1250856	-16777216	f	f	t	f	f	20	2
57	Mole	Mole	0	0	9999	-1250856	-16777216	f	f	t	f	f	20	2
58	Huevo	Huevo	15	0	9999	-1250856	-16777216	f	f	t	f	f	21	2
59	Pollo	Pollo	15	0	9999	-1250856	-16777216	f	f	t	f	f	21	2
60	Jamón	Jamón	18	0	9999	-1250856	-16777216	f	f	t	f	f	21	2
61	Queso de Hebra	Queso de Hebra	18	0	9999	-1250856	-16777216	f	f	t	f	f	21	2
62	Milanesa	Milanesa	0	0	9999	-1250856	-16777216	f	f	t	f	f	22	2
63	Pechuga	Pechuga	0	0	9999	-1250856	-16777216	f	f	t	f	f	22	2
64	Pastor	Pastor	0	0	9999	-1250856	-16777216	f	f	t	f	f	22	2
65	Cecina	Cecina	10	0	9999	-1250856	-16777216	f	f	t	f	f	22	2
66	Arrachera	Arrachera	13	0	9999	-1250856	-16777216	f	f	t	f	f	22	2
68	Cajeta	Cajeta	0	0	9999	-1250856	-16777216	f	f	t	f	f	30	2
69	Maple	Maple	0	0	9999	-1250856	-16777216	f	f	t	f	f	30	2
70	Mermelada de Fresa	Mermelada de Fresa	0	0	9999	-1250856	-16777216	f	f	t	f	f	30	2
71	Sencillo	Sencillo	0	0	9999	-1250856	-16777216	f	f	t	f	f	23	2
72	Chorizo	Chorizo	7	0	9999	-1250856	-16777216	f	f	t	f	f	23	2
73	Jamón y Queso	Jamón y Queso	7	0	9999	-1250856	-16777216	f	f	t	f	f	23	2
74	Jamón y Queso	Jamón y Queso	0	0	9999	-1250856	-16777216	f	f	t	f	f	24	2
75	Pollo	Pollo	2	0	9999	-1250856	-16777216	f	f	t	f	f	24	2
76	Pierna	Pierna	5	0	9999	-1250856	-16777216	f	f	t	f	f	24	2
77	Atún	Atún	5	0	9999	-1250856	-16777216	f	f	t	f	f	24	2
81	Pollo	Pollo	0	0	9999	-1250856	-16777216	f	f	t	f	f	25	2
80	Jamón y Queso	Jamón y Queso	0	0	9999	-1250856	-16777216	f	f	t	f	f	25	2
82	Choriqueso	Choriqueso	0	0	9999	-1250856	-16777216	f	f	t	f	f	25	2
83	Huevo	Huevo	0	0	9999	-1250856	-16777216	f	f	t	f	f	25	2
84	Chilaquiles	Chilaquiles	0	0	9999	-1250856	-16777216	f	f	t	f	f	25	2
87	Carga extra Café	Carga extra Café	5	0	9999	-1250856	-16777216	f	f	t	f	f	26	2
39	Huevo	Huevo	13	0	9999	-1250856	-16777216	f	f	t	f	f	14	2
40	Jamón	Jamón	15	0	9999	-1250856	-16777216	f	f	t	f	f	14	2
38	Pollo	Pollo	13	0	9999	-1250856	-16777216	f	f	t	f	f	14	2
88	Chocolate	Chocolate	0	0	9999	-1250856	-16777216	f	f	t	f	f	27	2
79	Pierna	Pierna	7	0	9999	-1250856	-16777216	f	f	t	f	f	25	2
78	Milanesa	Milanesa	7	0	9999	-1250856	-16777216	f	f	t	f	f	25	2
89	Vainilla	Vainilla	0	0	9999	-1250856	-16777216	f	f	t	f	f	27	2
90	Choco-Plátano	Choco-Plátano	0	0	9999	-1250856	-16777216	f	f	t	f	f	28	2
91	Plátano	Plátano	0	0	9999	-1250856	-16777216	f	f	t	f	f	28	2
92	Fresa	Fresa	0	0	9999	-1250856	-16777216	f	f	t	f	f	28	2
93	Frutos rojos	Frutos rojos	4	0	9999	-1250856	-16777216	f	f	t	f	f	28	2
94	Chocolate	Chocolate	0	0	9999	-1250856	-16777216	f	f	t	f	f	29	2
95	Vainilla	Vainilla	0	0	9999	-1250856	-16777216	f	f	t	f	f	29	2
96	2 Picadas	2 Picadas	0	0	9999	-1250856	-16777216	f	f	t	f	f	15	2
97	2 Enchiladas	2 Enchiladas	0	0	9999	-1250856	-16777216	f	f	t	f	f	15	2
98	2 Enmoladas	2 Enmoladas	0	0	9999	-1250856	-16777216	f	f	t	f	f	15	2
99	Jamón	Jamón	0	0	9999	-1250856	-16777216	f	f	t	f	f	31	2
100	Chorizo	Chorizo	0	0	9999	-1250856	-16777216	f	f	t	f	f	31	2
101	A la Mexicana	A la Mexicana	0	0	9999	-1250856	-16777216	f	f	t	f	f	31	2
102	Tocino	Tocino	0	0	9999	-1250856	-16777216	f	f	t	f	f	31	2
103	Ensalada	Ensalada	0	0	9999	-1250856	-16777216	f	f	t	f	f	32	2
104	Verduras	Verduras	0	0	9999	-1250856	-16777216	f	f	t	f	f	32	2
105	Fruta	Fruta	0	0	9999	-1250856	-16777216	f	f	t	f	f	32	2
106	Frijoles	Frijoles	0	0	9999	-1250856	-16777216	f	f	t	f	f	32	2
107	Papa con Chorizo	Papa con Chorizo	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
108	Milanesa	Milanesa	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
109	Pastor	Pastor	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
110	Pollo	Pollo	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
111	Mexicana	Mexicana	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
112	Molida	Molida	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
113	Costilla	Costilla	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
114	Huevo con Jamon	Huevo con Jamon	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
115	Huevo con Chorizo	Huevo con Chorizo	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
116	Rajas	Rajas	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
117	Salchicha	Salchicha	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
118	Carnitas	Carnitas	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
119	Chuleta	Chuleta	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
120	Huevo en Salsa	Huevo en Salsa	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
121	Chicharron	Chicharron	0	0	9999	-1250856	-16777216	f	f	t	f	f	33	2
25	Chorizo	Chorizo	0	0	9999	-1250856	-16777216	f	f	t	f	f	10	2
26	Arrachera	Arrachera	0	0	9999	-1250856	-16777216	f	f	t	f	f	10	2
23	Cecina	Cecina	0	0	9999	-1250856	-16777216	f	f	t	f	f	10	2
24	Pechuga	Pechuga	0	0	9999	-1250856	-16777216	f	f	t	f	f	10	2
22	Milanesa	Milanesa	0	0	9999	-1250856	-16777216	f	f	t	f	f	10	2
122	Sencilla	Sencilla	0	0	9999	-1250856	-16777216	f	f	t	f	f	14	2
41	Queso de Hebra	Queso de Hebra	15	0	9999	-1250856	-16777216	f	f	t	f	f	14	2
123	Caramelo	Caramelo	0	0	9999	-1250856	-16777216	f	f	t	f	f	39	2
124	Cookies & Cream	Cookies & Cream	0	0	9999	-1250856	-16777216	f	f	t	f	f	39	2
125	Crema de Avellana	Crema de Avellana	0	0	9999	-1250856	-16777216	f	f	t	f	f	39	2
126	Crema Irlandesa	Crema Irlandesa	0	0	9999	-1250856	-16777216	f	f	t	f	f	39	2
127	Moka	Moka	0	0	9999	-1250856	-16777216	f	f	t	f	f	39	2
128	Vainilla	Vainilla	0	0	9999	-1250856	-16777216	f	f	t	f	f	39	2
129	Vainilla	Vainilla	0	0	9999	-1250856	-16777216	f	f	t	f	f	40	2
130	Negro	Negro	0	0	9999	-1250856	-16777216	f	f	t	f	f	40	2
131	Verde	Verde	0	0	9999	-1250856	-16777216	f	f	t	f	f	40	2
132	Natrural	Natural	0	0	9999	-1250856	-16777216	f	f	t	f	f	41	2
133	Mineral	Mineral	5	0	9999	-1250856	-16777216	f	f	t	f	f	41	2
134	BBQ	BBQ	0	0	9999	-1250856	-16777216	f	f	t	f	f	34	2
135	Búfalo	Búfalo	0	0	9999	-1250856	-16777216	f	f	t	f	f	34	2
136	Mango-Habanero	Mango-Habanero	0	0	9999	-1250856	-16777216	f	f	t	f	f	34	2
137	Parmesano	Parmesano	0	0	9999	-1250856	-16777216	f	f	t	f	f	34	2
138	Habanero		0	0	9999	-1250856	-16777216	f	f	t	f	f	42	2
139	Chipotle		0	0	9999	-1250856	-16777216	f	f	t	f	f	42	2
140	Fuego		0	0	9999	-1250856	-16777216	f	f	t	f	f	42	2
141	Jalapeño		0	0	9999	-1250856	-16777216	f	f	t	f	f	42	2
142	Especias		0	0	9999	-1250856	-16777216	f	f	t	f	f	42	2
143	Adobadas		0	0	9999	-1250856	-16777216	f	f	t	f	f	42	2
144	Mora azul		0	0	9999	-1250856	-16777216	f	f	t	f	f	\N	2
145	Fresa kiwi		0	0	9999	-1250856	-16777216	f	f	t	f	f	\N	2
146	Naranja mandarina		0	0	9999	-1250856	-16777216	f	f	t	f	f	\N	2
147	Ponche de frutas		0	0	9999	-1250856	-16777216	f	f	t	f	f	\N	2
148	Uva		0	0	9999	-1250856	-16777216	f	f	t	f	f	\N	2
150	Sencillos	Sencillos	0	0	9999	-1250856	-16777216	f	f	t	f	f	21	2
151	Fresa-Kiwi	Fresa-Kiwi	0	0	9999	-1250856	-16777216	f	f	t	f	f	43	2
153	Ponche de Frutas	Ponche de Frutas	0	0	9999	-1250856	-16777216	f	f	t	f	f	43	2
154	Fresa	Fresa	0	0	9999	-1250856	-16777216	f	f	t	f	f	43	2
155	Mora-Azul	Mora-Azul	0	0	9999	-1250856	-16777216	f	f	t	f	f	43	2
152	Naranja-Mandarina	Naranja-Mandarina	0	0	9999	-1250856	-16777216	f	f	t	f	f	43	2
156	C SALADO	C SALADO	0	0	9999	-1250856	-16777216	f	f	t	f	f	47	2
157	C NATURAL	C NATURAL	0	0	9999	-1250856	-16777216	f	f	t	f	f	47	2
158	C SAL Y LIMON	C SAL Y LIMON	0	0	9999	-1250856	-16777216	f	f	t	f	f	47	2
159	C JALAPEÑO	C JALAPEÑO	0	0	9999	-1250856	-16777216	f	f	t	f	f	47	2
160	C QUEXO	C QUEXO	0	0	9999	-1250856	-16777216	f	f	t	f	f	47	2
163	C TOREADOS 	C TOREADOS 	0	0	9999	-1250856	-16777216	f	f	t	f	f	47	2
164	C AJO CON CHILE 	C AJO CON CHILE 	0	0	9999	-1250856	-16777216	f	f	t	f	f	47	2
165	C AL AJO 	C AL AJO 	0	0	9999	-1250856	-16777216	f	f	t	f	f	47	2
161	C HABANERO AMARILLO	C HABANERO AMARILLO	0	0	9999	-1250856	-16777216	f	f	t	f	f	47	2
162	C HABANERO VERDE 	C HABANERO VERDE	0	0	9999	-1250856	-16777216	f	f	t	f	f	47	2
\.


--
-- Data for Name: menu_modifier_group; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY menu_modifier_group (id, name, translated_name, enabled, exclusived, required) FROM stdin;
3	Relleno Empanada		f	f	f
4	Relleno Taco Dorado		f	f	f
5	Topping Tostada		f	f	f
6	Tortilla Quesadilla		f	f	f
7	Proteína Quesadilla		f	f	f
8	Salsa Picada		f	f	f
9	Proteína Picada		f	f	f
11	Salsa Enchiladas		f	f	f
12	Proteína Enchiladas Rellenas		f	f	f
13	Proteína Enchiladas Terrena		f	f	f
14	Proteína Enmoladas Rellenas		f	f	f
15	Opción Tampiqueña		f	f	f
16	Proteína Tampiqueña		f	f	f
17	Huevos – Tipo		f	f	f
18	Huevos – Término		f	f	f
19	Proteína Enfrijoladas		f	f	f
20	Salsa Chilaquiles		f	f	f
21	Proteína Chilaquiles		f	f	f
22	Proteína Chilaquiles Terrena		f	f	f
23	Proteína Mollete		f	f	f
24	Proteína Sándwich		f	f	f
25	Proteína Torta		f	f	f
26	Carga extra Café		f	f	f
27	Sabor Malteada		f	f	f
28	Sabor Licuado		f	f	f
29	Sabor Muffin		f	f	f
30	Topping Hot Cakes	Topping Hot Cakes	f	f	f
31	Proteína Huevo	Proteína Huevo	f	f	f
32	Guarnición Omelette	Guarnición Omelette	f	f	f
33	Tacos de Guisado	Tacos de Guisado	f	f	f
10	Proteína Picada Terrena	Proteína Picada Terrena	f	f	f
34	Salsas Boneless	Salsas Boneless	f	f	f
35	Proteína Enchilada	Proteína Enchilada	f	f	f
36	Complemento Huevo	Complemento Huevo	f	f	f
37	Extra Hot Cakes	Extra Hot Cakes	f	f	f
38	Relleno Taco Mañanero	Relleno Taco Mañanero	f	f	f
39	Sabor Latte	Sabor Latte	f	f	f
40	Sabor Chai Latte	Sabor Chai Latte	f	f	f
41	Opción Limonada / Naranjada	Opción Limonada / Naranjada	f	f	f
42	Sabor malanga		f	f	f
44	Sabor cacahuate		f	f	f
45	Sabor proteina		f	f	f
46	Sabor halls	Sabor halls	f	f	f
43	Sabor electrolit	Sabor electrolit	f	f	f
47	CACAHUATES HORNEADOS 		f	f	f
\.


--
-- Name: menu_modifier_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('menu_modifier_group_id_seq', 47, true);


--
-- Name: menu_modifier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('menu_modifier_id_seq', 165, true);


--
-- Data for Name: payout_reasons; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY payout_reasons (id, reason) FROM stdin;
\.


--
-- Name: payout_reasons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('payout_reasons_id_seq', 1, false);


--
-- Data for Name: payout_recepients; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY payout_recepients (id, name) FROM stdin;
\.


--
-- Name: payout_recepients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('payout_recepients_id_seq', 1, false);


--
-- Data for Name: terminal; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY terminal (id, name, terminal_key, opening_balance, current_balance, has_cash_drawer, in_use, active, location, floor_id, assigned_user) FROM stdin;
301	301	bbd1d074-edf2-413f-bffc-20445966ff98	0	0	t	f	f	\N	0	\N
1090	Terminal 1090	f3b8703b-219e-4043-b8ee-20a4f3befe70	0	0	t	f	f	\N	0	\N
1091	Terminal 1091	d7dc0821-bdb4-468f-8b35-56f595a1affb	0	0	t	f	f	\N	0	\N
101	101	4e8a4290-b76c-444c-a37d-efe85b38968e	0	0	t	f	f	Principal	0	\N
102	102	dd332e72-2063-4355-9eaf-f17e1993b11c	0	0	t	f	f	Principal	0	\N
9939	Terminal 9939	073e81ee-ee1f-4de4-808f-498bee09fc1f	0	0	t	f	f	SelemTI	0	\N
\.


--
-- Data for Name: ticket_discount; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY ticket_discount (id, discount_id, name, type, auto_apply, minimum_amount, value, ticket_id) FROM stdin;
10	6	Rector	1	f	100	100	1020
\.


--
-- Name: ticket_discount_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('ticket_discount_id_seq', 10, true);


--
-- Data for Name: ticket_item; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY ticket_item (id, item_id, item_count, item_quantity, item_name, item_unit_name, group_name, category_name, item_price, item_tax_rate, sub_total, sub_total_without_modifiers, discount, tax_amount, tax_amount_without_modifiers, total_price, total_price_without_modifiers, beverage, inventory_handled, print_to_kitchen, treat_as_seat, seat_number, fractional_unit, has_modiiers, printed_to_kitchen, status, stock_amount_adjusted, pizza_type, size_modifier_id, ticket_id, pg_id, pizza_section_mode) FROM stdin;
1736	61	1	0	Agua Embotellada 500 ML	\N	REFRESCANTES	BEBIDAS FRÍAS	10	0	10	10	0	0	0	10	10	t	f	f	f	0	f	f	f	\N	t	f	\N	1005	\N	0
1726	48	1	0	Latte Sabor	\N	CAFÉ	BEBIDAS CALIENTES	55	0	55	55	0	0	0	55	55	t	f	f	f	0	f	t	t	\N	t	f	\N	999	2	0
1727	60	9	0	Agua Embotellada 1 L	\N	REFRESCANTES	BEBIDAS FRÍAS	15	0	135	135	0	0	0	135	135	t	f	f	f	0	f	f	f	\N	t	f	\N	999	\N	0
1715	50	1	0	CHAI LATTE	\N	CAFÉ	BEBIDAS CALIENTES	55	0	55	55	0	0	0	55	55	t	f	f	f	0	f	t	t	\N	t	f	\N	996	2	0
1745	81	1	0	Papas	\N	SNACKS	OTROS	25	0	25	25	0	0	0	25	25	f	f	t	f	0	f	f	t	Ready	t	f	\N	1009	\N	0
1746	82	1	0	Platanos	\N	SNACKS	OTROS	25	0	25	25	0	0	0	25	25	f	f	t	f	0	f	f	t	Ready	t	f	\N	1009	\N	0
1717	46	1	0	Espresso Cortado	\N	CAFÉ	BEBIDAS CALIENTES	25	0	25	25	0	0	0	25	25	t	f	f	f	0	f	t	f	\N	t	f	\N	997	2	0
1718	49	1	0	Matcha Latte	\N	CAFÉ	BEBIDAS CALIENTES	55	0	55	55	0	0	0	55	55	t	f	f	f	0	f	t	f	\N	t	f	\N	997	2	0
1719	46	1	0	Espresso Cortado	\N	CAFÉ	BEBIDAS CALIENTES	25	0	25	25	0	0	0	25	25	t	f	f	f	0	f	t	f	\N	t	f	\N	997	2	0
1720	46	1	0	Espresso Cortado	\N	CAFÉ	BEBIDAS CALIENTES	25	0	25	25	0	0	0	25	25	t	f	f	f	0	f	t	f	\N	t	f	\N	997	2	0
1728	61	1	0	Agua Embotellada 500 ML	\N	REFRESCANTES	BEBIDAS FRÍAS	10	0	10	10	0	0	0	10	10	t	f	f	f	0	f	f	f	\N	t	f	\N	999	\N	0
1729	68	1	0	Naranjada	\N	REFRESCANTES	BEBIDAS FRÍAS	20	0	20	20	0	0	0	20	20	t	f	f	f	0	f	f	f	\N	t	f	\N	1000	\N	0
1721	50	1	0	CHAI LATTE	\N	CAFÉ	BEBIDAS CALIENTES	55	0	55	55	0	0	0	55	55	t	f	f	f	0	f	t	t	\N	t	f	\N	998	2	0
1722	48	1	0	Latte Sabor	\N	CAFÉ	BEBIDAS CALIENTES	55	0	55	55	0	0	0	55	55	t	f	f	f	0	f	t	t	\N	t	f	\N	998	2	0
1723	66	1	0	Agua de Sabor	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	25	25	0	0	0	25	25	t	f	f	f	0	f	f	f	\N	t	f	\N	998	\N	0
1724	68	1	0	Naranjada	\N	REFRESCANTES	BEBIDAS FRÍAS	20	0	20	20	0	0	0	20	20	t	f	f	f	0	f	f	f	\N	t	f	\N	998	\N	0
1725	63	1	0	Mineral Twist 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	25	25	0	0	0	25	25	t	f	f	f	0	f	f	f	\N	t	f	\N	998	\N	0
1730	68	1	0	Naranjada	\N	REFRESCANTES	BEBIDAS FRÍAS	20	0	20	20	0	0	0	20	20	t	f	f	f	0	f	f	f	\N	t	f	\N	1001	\N	0
1731	60	1	0	Agua Embotellada 1 L	\N	REFRESCANTES	BEBIDAS FRÍAS	15	0	15	15	0	0	0	15	15	t	f	f	f	0	f	f	f	\N	t	f	\N	1001	\N	0
1732	63	1	0	Mineral Twist 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	25	25	0	0	0	25	25	t	f	f	f	0	f	f	f	\N	t	f	\N	1002	\N	0
1733	61	1	0	Agua Embotellada 500 ML	\N	REFRESCANTES	BEBIDAS FRÍAS	10	0	10	10	0	0	0	10	10	t	f	f	f	0	f	f	f	\N	t	f	\N	1003	\N	0
1734	68	1	0	Naranjada	\N	REFRESCANTES	BEBIDAS FRÍAS	20	0	20	20	0	0	0	20	20	t	f	f	f	0	f	f	f	\N	t	f	\N	1004	\N	0
1735	78	1	0	Limonada Mineral	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	25	25	0	0	0	25	25	t	f	f	f	0	f	f	f	\N	t	f	\N	1005	2	0
1743	50	1	0	CHAI LATTE	\N	CAFÉ	BEBIDAS CALIENTES	55	0	55	55	0	0	0	55	55	t	f	f	f	0	f	t	t	\N	t	f	\N	1007	2	0
1748	66	4	0	Agua de Sabor	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	100	100	0	0	0	100	100	t	f	f	f	0	f	f	f	\N	t	f	\N	1010	\N	0
1747	80	1	0	MALANGA	\N	SNACKS	OTROS	28	0	28	28	0	0	0	28	28	f	f	t	f	0	f	f	t	Ready	t	f	\N	1009	\N	0
1737	60	1	0	Agua Embotellada 1 L	\N	REFRESCANTES	BEBIDAS FRÍAS	15	0	15	15	0	0	0	15	15	t	f	f	f	0	f	f	f	\N	t	f	\N	1006	\N	0
1738	68	1	0	Naranjada	\N	REFRESCANTES	BEBIDAS FRÍAS	20	0	20	20	8	0	0	12	12	t	f	f	f	0	f	f	f	\N	t	f	\N	1006	\N	0
1739	66	1	0	Agua de Sabor	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	25	25	0	0	0	25	25	t	f	f	f	0	f	f	f	\N	t	f	\N	1006	\N	0
1740	63	1	0	Mineral Twist 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	25	25	0	0	0	25	25	t	f	f	f	0	f	f	f	\N	t	f	\N	1006	\N	0
1741	64	1	0	Topo Chico 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	25	25	0	0	0	25	25	t	f	f	f	0	f	f	f	\N	t	f	\N	1006	\N	0
1742	62	1	0	Mineral 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	22	0	22	22	0	0	0	22	22	t	f	f	f	0	f	f	f	\N	t	f	\N	1006	\N	0
1744	81	1	0	Papas	\N	SNACKS	OTROS	25	0	25	25	0	0	0	25	25	f	f	t	f	0	f	f	t	Ready	t	f	\N	1008	\N	0
1714	47	1	0	Latte	\N	CAFÉ	BEBIDAS CALIENTES	45	0	45	45	0	0	0	45	45	t	f	f	f	0	f	f	f	\N	t	f	\N	996	2	0
1716	77	1	0	Pay Limón	\N	POSTRES	POSTRES	35	0	35	35	0	0	0	35	35	f	f	t	f	0	f	f	t	Ready	t	f	\N	996	\N	0
1749	64	2	0	Topo Chico 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	50	50	0	0	0	50	50	t	f	f	f	0	f	f	f	\N	t	f	\N	1011	\N	0
1750	63	3	0	Mineral Twist 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	75	75	0	0	0	75	75	t	f	f	f	0	f	f	f	\N	t	f	\N	1012	\N	0
1751	63	1	0	Mineral Twist 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	25	25	10	0	0	15	15	t	f	f	f	0	f	f	f	\N	t	f	\N	1013	\N	0
1752	63	5	0	Mineral Twist 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	125	125	0	0	0	125	125	t	f	f	f	0	f	f	f	\N	t	f	\N	1014	\N	0
1753	46	1	0	Espresso Cortado	\N	CAFÉ	BEBIDAS CALIENTES	25	0	25	25	0	0	0	25	25	t	f	f	f	0	f	t	t	\N	t	f	\N	1015	2	0
1754	48	1	0	Latte Sabor	\N	CAFÉ	BEBIDAS CALIENTES	55	0	55	55	0	0	0	55	55	t	f	f	f	0	f	t	t	\N	t	f	\N	1015	2	0
1755	60	7	0	Agua Embotellada 1 L	\N	REFRESCANTES	BEBIDAS FRÍAS	15	0	105	105	0	0	0	105	105	t	f	f	f	0	f	f	f	\N	t	f	\N	1016	\N	0
1756	63	4	0	Mineral Twist 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	100	100	0	0	0	100	100	t	f	f	f	0	f	f	f	\N	t	f	\N	1017	\N	0
1757	64	6	0	Topo Chico 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	150	150	0	0	0	150	150	t	f	f	f	0	f	f	f	\N	t	f	\N	1018	\N	0
1758	64	8	0	Topo Chico 600 ml	\N	REFRESCANTES	BEBIDAS FRÍAS	25	0	200	200	0	0	0	200	200	t	f	f	f	0	f	f	f	\N	t	f	\N	1019	\N	0
1759	80	5	0	MALANGA	\N	SNACKS	OTROS	28	0	140	140	0	0	0	140	140	f	f	t	f	0	f	f	t	\N	t	f	\N	1020	\N	0
1760	81	1	0	Papas	\N	SNACKS	OTROS	25	0	25	25	0	0	0	25	25	f	f	t	f	0	f	f	t	\N	t	f	\N	1020	\N	0
1761	82	9	0	Platanos	\N	SNACKS	OTROS	25	0	225	225	0	0	0	225	225	f	f	t	f	0	f	f	t	\N	t	f	\N	1021	\N	0
1762	85	1	0	GREEN MOUNTAIN BARRA	\N	SNACKS	OTROS	20	0	20	20	8	0	0	12	12	f	f	t	f	0	f	f	t	\N	t	f	\N	1021	\N	0
\.


--
-- Name: ticket_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('ticket_item_id_seq', 1762, true);


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY transactions (id, payment_type, global_id, transaction_time, amount, tips_amount, tips_exceed_amount, tender_amount, transaction_type, custom_payment_name, custom_payment_ref, custom_payment_field_name, payment_sub_type, captured, voided, authorizable, card_holder_name, card_number, card_auth_code, card_type, card_transaction_id, card_merchant_gateway, card_reader, card_aid, card_arqc, card_ext_data, gift_cert_number, gift_cert_face_value, gift_cert_paid_amount, gift_cert_cash_back_amount, drawer_resetted, note, terminal_id, ticket_id, user_id, payout_reason_id, payout_recepient_id) FROM stdin;
979	CASH	gjy1758621025705	2025-09-15 03:37:49.171	130	0	0	200	CREDIT	\N	\N	\N	CASH	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	997	1	\N	\N
980	CASH	quq1758878292542	2025-09-15 04:01:40.532	180	0	0	180	CREDIT	\N	\N	\N	CASH	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	998	7	\N	\N
984	CUSTOM_PAYMENT	kzz1759176928268	2025-09-15 04:47:23.011	25	0	0	25	CREDIT	Tranferencia	333	Nombre	CUSTOM PAYMENT	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1002	7	\N	\N
983	DEBIT_CARD	rny1754955660247	2025-09-15 04:47:11.88	35	0	0	35	CREDIT	\N	\N	\N	VISA	t	f	t	\N	\N	34	VISA	\N	\N	EXTERNAL_TERMINAL	\N	\N	\N	\N	0	0	0	t	\N	9939	1001	7	\N	\N
982	CREDIT_CARD	sof1756674630612	2025-09-15 04:46:44.339	20	0	0	20	CREDIT	\N	\N	\N	MASTER CARD	t	f	t	\N	\N	3	MASTER CARD	\N	\N	EXTERNAL_TERMINAL	\N	\N	\N	\N	0	0	0	t	\N	9939	1000	7	\N	\N
981	CASH	dfl1759651155964	2025-09-15 04:46:20.343	200	0	0	200	CREDIT	\N	\N	\N	CASH	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	999	7	\N	\N
988	CASH	rwt1757305379851	2025-09-15 05:09:03.621	124	0	0	124	CREDIT	\N	\N	\N	CASH	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1006	7	\N	\N
987	CUSTOM_PAYMENT	kpd1758119119567	2025-09-15 05:07:38.341	35	0	0	35	CREDIT	Tranferencia	4444	Nombre	CUSTOM PAYMENT	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1005	7	\N	\N
986	DEBIT_CARD	tii1759568030646	2025-09-15 05:07:22.853	20	0	0	20	CREDIT	\N	\N	\N	VISA	t	f	t	\N	\N	y	VISA	\N	\N	EXTERNAL_TERMINAL	\N	\N	\N	\N	0	0	0	t	\N	9939	1004	7	\N	\N
985	CREDIT_CARD	lnq1759180703154	2025-09-15 05:07:14.56	10	0	0	10	CREDIT	\N	\N	\N	AMEX	t	f	t	\N	\N	4	AMEX	\N	\N	EXTERNAL_TERMINAL	\N	\N	\N	\N	0	0	0	t	\N	9939	1003	7	\N	\N
993	DEBIT_CARD	npy1759095390939	2025-09-15 05:26:57.37	78	0	0	78	CREDIT	\N	\N	\N	VISA	t	f	t	\N	\N	7	VISA	\N	\N	EXTERNAL_TERMINAL	\N	\N	\N	\N	0	0	0	t	\N	9939	1009	1	\N	\N
992	CREDIT_CARD	ogj1758517995549	2025-09-15 05:26:33.415	25	0	0	25	CREDIT	\N	\N	\N	MASTER CARD	t	f	t	\N	\N	4	MASTER CARD	\N	\N	EXTERNAL_TERMINAL	\N	\N	\N	\N	0	0	0	t	\N	9939	1008	1	\N	\N
978	CASH	irs1756615382813	2025-09-15 03:18:47.314	135	0	0	135	CREDIT	\N	\N	\N	CASH	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	996	1	\N	\N
991	PAY_OUT	vdq1758004100789	2025-09-15 05:25:59.288	20	0	0	0	DEBIT	\N	\N	\N	CASH	f	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t		9939	\N	1	\N	\N
990	CASH_DROP	uju1760493785106	2025-09-15 05:25:43.944	10	0	0	0	CREDIT	\N	\N	\N	CASH	f	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	\N	1	\N	\N
989	CASH	rho1755764039518	2025-09-15 05:25:30.591	55	0	0	55	CREDIT	\N	\N	\N	CASH	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1007	1	\N	\N
1004	CASH	xsm1763397376836	2025-09-15 21:45:18.856	0	0	0	0	CREDIT	\N	\N	\N	CASH	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1020	1	\N	\N
1005	CASH	nku1760255851474	2025-09-15 21:45:51.764	237	0	0	237	CREDIT	\N	\N	\N	CASH	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1021	1	\N	\N
1000	CASH	ara1760093059342	2025-09-15 21:44:23.163	105	0	0	105	CREDIT	\N	\N	\N	CASH	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1016	1	\N	\N
994	CASH	lhk1759187772455	2025-09-15 19:57:33.464	100	0	0	100	CREDIT	\N	\N	\N	CASH	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1010	1	\N	\N
995	CREDIT_CARD	gvv1757208108996	2025-09-15 19:57:45.826	50	0	0	50	CREDIT	\N	\N	\N	AMEX	t	f	t	\N	\N	50	AMEX	\N	\N	EXTERNAL_TERMINAL	\N	\N	\N	\N	0	0	0	t	\N	9939	1011	1	\N	\N
996	DEBIT_CARD	mkt1759522180891	2025-09-15 19:58:13.452	75	0	0	75	CREDIT	\N	\N	\N	VISA	t	f	t	\N	\N	yy	VISA	\N	\N	EXTERNAL_TERMINAL	\N	\N	\N	\N	0	0	0	t	\N	9939	1012	1	\N	\N
997	CASH	wck1758619161633	2025-09-15 19:58:36.336	15	0	0	15	CREDIT	\N	\N	\N	CASH	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1013	1	\N	\N
998	CUSTOM_PAYMENT	xoi1761621612033	2025-09-15 19:58:53.434	125	0	0	125	CREDIT	Tranferencia	tavo	Nombre	CUSTOM PAYMENT	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1014	1	\N	\N
999	CUSTOM_PAYMENT	jhk1757993670627	2025-09-15 19:59:56.766	80	0	0	80	CREDIT	Tranferencia	4	Nombre	CUSTOM PAYMENT	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1015	1	\N	\N
1001	CREDIT_CARD	euj1756880644760	2025-09-15 21:44:36.675	100	0	0	100	CREDIT	\N	\N	\N	AMEX	t	f	t	\N	\N	44	AMEX	\N	\N	EXTERNAL_TERMINAL	\N	\N	\N	\N	0	0	0	t	\N	9939	1017	1	\N	\N
1002	DEBIT_CARD	gth1758129400597	2025-09-15 21:44:47.202	150	0	0	150	CREDIT	\N	\N	\N	VISA	t	f	t	\N	\N	777	VISA	\N	\N	EXTERNAL_TERMINAL	\N	\N	\N	\N	0	0	0	t	\N	9939	1018	1	\N	\N
1003	CUSTOM_PAYMENT	lhn1755030494363	2025-09-15 21:45:02.429	200	0	0	200	CREDIT	Tranferencia	ttt	Nombre	CUSTOM PAYMENT	t	f	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	0	0	0	t	\N	9939	1019	1	\N	\N
\.


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('transactions_id_seq', 1005, true);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY users (auto_id, user_id, user_pass, first_name, last_name, ssn, cost_per_hour, clocked_in, last_clock_in_time, last_clock_out_time, phone_no, is_driver, available_for_delivery, active, shift_id, currentterminal, n_user_type) FROM stdin;
9	20101	1988	Isabella	Fernández Román 		0	f	\N	\N		f	f	t	\N	\N	3
11	30101	230519	juan david	marinez tejeda		0	f	\N	\N		f	f	t	\N	\N	3
8	10100	2334	JOSE	HUESCA		0	t	2025-08-15 10:23:30.265	\N		f	f	t	1	102	2
7	10102	2222	Aldo Abraham 	Martinez Tejeda		0	t	2025-08-15 10:24:29.199	\N		f	f	t	1	102	3
10	20102	268405	Alexis Manuel	Ramirez Grajales		0	t	2025-08-15 12:33:16.846	\N		f	f	t	1	102	3
1	123	1111	Admin	System	123	0	t	2025-08-15 12:40:32.601	\N	\N	f	f	t	1	101	1
6	10101	211920	Jose Eumir 	Rodriguez Rranco		0	t	2025-08-15 10:58:16.273	\N		f	f	t	1	102	2
\.


--
-- Name: users_auto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('users_auto_id_seq', 11, true);


--
-- Data for Name: void_reasons; Type: TABLE DATA; Schema: public; Owner: floreant
--

COPY void_reasons (id, reason_text) FROM stdin;
1	rr
\.


--
-- Name: void_reasons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: floreant
--

SELECT pg_catalog.setval('void_reasons_id_seq', 1, true);


SET search_path = selemti, pg_catalog;

--
-- Data for Name: postcorte; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY postcorte (id, sesion_id, sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo, sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas, creado_en, creado_por, notas) FROM stdin;
1	28	0.00	1500.00	1500.00	A_FAVOR	0.00	2.00	2.00	A_FAVOR	2025-09-15 19:49:37.527543-05	1	
2	29	0.00	315.00	315.00	A_FAVOR	0.00	125.00	125.00	A_FAVOR	2025-09-15 20:24:50.069671-05	1	
3	28	0.00	1500.00	1500.00	A_FAVOR	0.00	2.00	2.00	A_FAVOR	2025-09-15 20:30:09.694346-05	1	
4	28	0.00	1500.00	1500.00	A_FAVOR	0.00	2.00	2.00	A_FAVOR	2025-09-15 20:53:56.50664-05	1	
5	28	0.00	1500.00	1500.00	A_FAVOR	0.00	2.00	2.00	A_FAVOR	2025-09-15 20:54:13.141123-05	1	
6	30	0.00	1542.00	1542.00	A_FAVOR	0.00	250.00	250.00	A_FAVOR	2025-09-15 21:48:59.372951-05	1	
\.


--
-- Name: postcorte_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('postcorte_id_seq', 6, true);


--
-- Data for Name: precorte; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY precorte (id, sesion_id, declarado_efectivo, declarado_otros, estatus, creado_en, creado_por, ip_cliente, notas) FROM stdin;
14	22	0.00	0.00	ENVIADO	2025-09-15 03:23:17.715304-05	\N	\N	\N
15	23	0.00	0.00	ENVIADO	2025-09-15 03:37:28.341676-05	\N	\N	\N
16	24	0.00	0.00	ENVIADO	2025-09-15 04:01:17.388065-05	\N	\N	\N
17	25	0.00	0.00	ENVIADO	2025-09-15 04:45:42.429012-05	\N	\N	\N
18	26	0.00	0.00	ENVIADO	2025-09-15 05:08:08.522708-05	\N	\N	\N
19	27	188.00	103.00	ENVIADO	2025-09-15 05:49:08.979568-05	\N	\N	Prueba
20	28	1500.00	3.00	ENVIADO	2025-09-15 16:31:08.394322-05	\N	\N	\N
21	29	315.00	330.00	ENVIADO	2025-09-15 19:51:13.139291-05	\N	\N	\N
22	30	1542.00	450.00	ENVIADO	2025-09-15 21:46:24.518123-05	\N	\N	\N
\.


--
-- Data for Name: precorte_efectivo; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY precorte_efectivo (id, precorte_id, denominacion, cantidad, subtotal) FROM stdin;
41	14	1000.00	1	1000.00
42	14	500.00	1	500.00
43	15	1000.00	2	2000.00
44	15	200.00	2	400.00
45	16	500.00	1	500.00
46	16	100.00	1	100.00
47	16	20.00	1	20.00
48	16	10.00	1	10.00
49	16	50.00	1	50.00
50	17	500.00	1	500.00
51	17	200.00	1	200.00
52	18	100.00	1	100.00
53	18	50.00	2	100.00
54	18	20.00	1	20.00
55	18	2.00	2	4.00
84	19	100.00	1	100.00
85	19	50.00	1	50.00
86	19	20.00	1	20.00
87	19	10.00	1	10.00
88	19	2.00	1	2.00
89	19	5.00	1	5.00
90	19	1.00	1	1.00
91	20	1000.00	1	1000.00
92	20	500.00	1	500.00
93	21	200.00	1	200.00
94	21	100.00	1	100.00
95	21	10.00	1	10.00
96	21	5.00	1	5.00
97	22	1000.00	1	1000.00
98	22	500.00	1	500.00
99	22	20.00	2	40.00
100	22	2.00	1	2.00
\.


--
-- Name: precorte_efectivo_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('precorte_efectivo_id_seq', 100, true);


--
-- Name: precorte_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('precorte_id_seq', 22, true);


--
-- Data for Name: precorte_otros; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY precorte_otros (id, precorte_id, tipo, monto, referencia, evidencia_url, notas, creado_en) FROM stdin;
34	14	CREDITO	0.00	\N	\N	\N	2025-09-15 03:23:34.135319-05
35	14	DEBITO	0.00	\N	\N	\N	2025-09-15 03:23:34.135319-05
36	14	TRANSFER	0.00	\N	\N	\N	2025-09-15 03:23:34.135319-05
37	15	CREDITO	0.00	\N	\N	\N	2025-09-15 03:38:23.376297-05
38	15	DEBITO	0.00	\N	\N	\N	2025-09-15 03:38:23.376297-05
39	15	TRANSFER	0.00	\N	\N	\N	2025-09-15 03:38:23.376297-05
40	16	CREDITO	0.00	\N	\N	\N	2025-09-15 04:02:21.933151-05
41	16	DEBITO	0.00	\N	\N	\N	2025-09-15 04:02:21.933151-05
42	16	TRANSFER	0.00	\N	\N	\N	2025-09-15 04:02:21.933151-05
43	17	CREDITO	20.00	\N	\N	\N	2025-09-15 04:49:23.782207-05
44	17	DEBITO	35.00	\N	\N	\N	2025-09-15 04:49:23.782207-05
45	17	TRANSFER	25.00	\N	\N	\N	2025-09-15 04:49:23.782207-05
46	18	CREDITO	10.00	\N	\N	\N	2025-09-15 05:12:35.908008-05
47	18	DEBITO	20.00	\N	\N	\N	2025-09-15 05:12:35.908008-05
48	18	TRANSFER	35.00	\N	\N	\N	2025-09-15 05:12:35.908008-05
57	19	CREDITO	25.00	\N	\N	Prueba	2025-09-15 07:08:29.172838-05
58	19	DEBITO	78.00	\N	\N	Prueba	2025-09-15 07:08:29.172838-05
59	20	CREDITO	1.00	\N	\N		2025-09-15 16:31:23.200203-05
60	20	DEBITO	1.00	\N	\N		2025-09-15 16:31:23.200203-05
61	20	TRANSFER	1.00	\N	\N		2025-09-15 16:31:23.200203-05
62	21	CREDITO	50.00	\N	\N		2025-09-15 20:01:47.781826-05
63	21	DEBITO	75.00	\N	\N		2025-09-15 20:01:47.781826-05
64	21	TRANSFER	205.00	\N	\N		2025-09-15 20:01:47.781826-05
65	22	CREDITO	100.00	\N	\N		2025-09-15 21:47:44.57108-05
66	22	DEBITO	150.00	\N	\N		2025-09-15 21:47:44.57108-05
67	22	TRANSFER	200.00	\N	\N		2025-09-15 21:47:44.57108-05
\.


--
-- Name: precorte_otros_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('precorte_otros_id_seq', 67, true);


--
-- Data for Name: sesion_cajon; Type: TABLE DATA; Schema: selemti; Owner: postgres
--

COPY sesion_cajon (id, sucursal, terminal_id, terminal_nombre, cajero_usuario_id, apertura_ts, cierre_ts, estatus, opening_float, closing_float, dah_evento_id) FROM stdin;
22	SelemTI	9939	Terminal 9939	1	2025-09-15 03:18:41.728633-05	2025-09-15 03:23:15.124-05	LISTO_PARA_CORTE	500.00	635.00	60
23	SelemTI	9939	Terminal 9939	1	2025-09-15 03:37:23.228183-05	2025-09-15 03:50:52.011-05	LISTO_PARA_CORTE	500.00	630.00	62
24	SelemTI	9939	Terminal 9939	7	2025-09-15 04:01:12.032433-05	2025-09-15 04:44:41.197-05	LISTO_PARA_CORTE	500.00	680.00	64
25	SelemTI	9939	Terminal 9939	1	2025-09-15 04:45:36.902844-05	2025-09-15 04:49:33.073-05	LISTO_PARA_CORTE	500.00	700.00	66
26	SelemTI	9939	Terminal 9939	7	2025-09-15 05:06:32.732674-05	2025-09-15 05:14:59.657-05	LISTO_PARA_CORTE	100.00	224.00	68
27	SelemTI	9939	Terminal 9939	1	2025-09-15 05:25:22.002894-05	2025-09-15 07:11:57.936-05	LISTO_PARA_CORTE	500.00	525.00	70
28	SelemTI	9939	Terminal 9939	1	2025-09-15 16:31:04.478021-05	2025-09-15 16:31:37.598-05	LISTO_PARA_CORTE	500.00	500.00	72
29	SelemTI	9939	Terminal 9939	1	2025-09-15 19:51:08.172155-05	2025-09-15 20:24:21.418-05	LISTO_PARA_CORTE	200.00	315.00	74
30	SelemTI	9939	Terminal 9939	1	2025-09-15 21:44:00.824475-05	2025-09-15 21:48:02.091-05	LISTO_PARA_CORTE	1200.00	1542.00	76
\.


--
-- Name: sesion_cajon_id_seq; Type: SEQUENCE SET; Schema: selemti; Owner: postgres
--

SELECT pg_catalog.setval('sesion_cajon_id_seq', 30, true);


--
-- PostgreSQL database dump complete
--

