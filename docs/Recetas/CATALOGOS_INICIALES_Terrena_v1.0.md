# 📦 Catálogo Maestro de Ítems Terrena (Versión 1.0)

Fecha: 2025-10-28
Autor: Sistema UX · SelemTI
Uso: Este catálogo define los insumos estándares del restaurante/cafetería Terrena con nombre genérico, unidad, tipo de inventario y reglas operativas.
Sirve para poblar items en BD y para empezar a capturar Recetas y Subrecetas.

💡 Campos clave (cómo leer las tablas)

Familia
Bloque operativo grande (ej. "Lácteos y Huevo", "Proteínas y Cárnicos", "Desechables / Empaque").

Categoría
Subgrupo dentro de la familia (ej. "Leche", "Queso", "Salsa boneless", "Bebidas frías").

Tipo
Cómo se debe guardar en items.tipo:

MATERIA_PRIMA → Lo compramos y usamos directo (tortilla, jitomate, mayonesa).

ELABORADO → Lo producimos en cocina / producción (salsa verde base, pollo deshebrado).

ENVASADO → Llega listo para vender al cliente sin transformación (Electrolit, Topo Chico, muffin de Costco).

CONSUMIBLE_OPERATIVO → Insumo que no se come, pero hay que controlarlo (vasos, guantes, bolsas de basura).

Ítem
Nombre normalizado (sin marca ni presentación comercial).

UOM
Unidad de inventario base:

KG, G

LT, ML

PZ (pieza)

ROLLO (manojo cilantro)

etc.

Producible
✅ si este ítem se fabrica internamente en producción / mise en place.
❌ si sólo se compra.

Consumible Operativo
✅ si se usa para operar (ej. vaso, bolsa basura), NO va dentro de receta comestible.
❌ si es alimento o ingrediente.

Índice de familias

Lácteos y Huevo

Proteínas y Cárnicos

Verduras Frescas

Frutas Frescas

Abarrotes Secos y Bases

Cafetería / Jarabes / Polvos

Panadería, Pan Salado y Postres

Masas / Tortillas / Pan Base de Operación

Legumbres Preparadas / Untables / Molletes

Salsas, Aderezos y Condimentos

Jugos, Aguas Frescas, Limonadas

Subrecetas Base / Producción (mise en place)

Sopas / Pastas / Caldos

Desayunos / Guarniciones

Bebidas Embotelladas / Refrigeradas

Desechables y Empaque

Limpieza / Operación / Costo Indirecto

1. LÁCTEOS Y HUEVO
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Lácteos y Huevo	Leche	MATERIA_PRIMA	Leche deslactosada	LT	Leche UHT deslactosada / sin lactosa	❌	❌
Lácteos y Huevo	Leche vegetal	MATERIA_PRIMA	Leche de almendra	LT	Bebida vegetal (sin lactosa)	❌	❌
Lácteos y Huevo	Crema	MATERIA_PRIMA	Crema ácida	LT	Crema ácida tipo mesa / topping para enchiladas	❌	❌
Lácteos y Huevo	Crema	MATERIA_PRIMA	Crema para batir	LT	Crema vegetal para batir (ej. Ambiante)	❌	❌
Lácteos y Huevo	Yogurt	MATERIA_PRIMA	Yogurt natural	KG	Yogurt natural o saborizado para fruta preparada	❌	❌
Lácteos y Huevo	Queso fresco	MATERIA_PRIMA	Queso fresco	KG	Queso fresco tipo ranchero	❌	❌
Lácteos y Huevo	Queso suave	MATERIA_PRIMA	Queso panela	KG	Queso panela firme / cuadritos / topping sopa	❌	❌
Lácteos y Huevo	Queso hebra	MATERIA_PRIMA	Queso de hebra	KG	Queso Oaxaca / quesillo para enchiladas y quesadillas	❌	❌
Lácteos y Huevo	Queso amarillo	MATERIA_PRIMA	Queso manchego	KG	Queso manchego rebanado / americano para tortas	❌	❌
Lácteos y Huevo	Queso maduro	MATERIA_PRIMA	Queso parmesano	KG	Parmesano rallado o en bloque	❌	❌
Lácteos y Huevo	Grasa láctea	MATERIA_PRIMA	Mantequilla	KG	Mantequilla / margarina cocina	❌	❌
Lácteos y Huevo	Proteína huevo	MATERIA_PRIMA	Huevo fresco	PZ	Huevo de gallina mediano	❌	❌
2. PROTEÍNAS Y CÁRNICOS
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Proteínas y Cárnicos	Pollo crudo	MATERIA_PRIMA	Pechuga de pollo cruda	KG	Pechuga natural sin piel / sin hueso	❌	❌
Proteínas y Cárnicos	Pollo preparado	ELABORADO	Pollo deshebrado cocido	KG	Pechuga cocida y desmenuzada lista para servir	✅	❌
Proteínas y Cárnicos	Res	MATERIA_PRIMA	Arrachera	KG	Arrachera marinada / plancha / enchiladas terrena	❌	❌
Proteínas y Cárnicos	Res	MATERIA_PRIMA	Cecina	KG	Cecina / carne salada fileteada	❌	❌
Proteínas y Cárnicos	Res	MATERIA_PRIMA	Milanesa de res	KG	Filete empanizado para milanesa / torta	❌	❌
Proteínas y Cárnicos	Res molida	MATERIA_PRIMA	Carne molida de res	KG	Carne para boloñesa y guisados	❌	❌
Proteínas y Cárnicos	Cerdo	MATERIA_PRIMA	Costilla de cerdo	KG	Costilla carnosa con hueso	❌	❌
Proteínas y Cárnicos	Cerdo	MATERIA_PRIMA	Chuleta ahumada	KG	Chuleta de cerdo ahumada	❌	❌
Proteínas y Cárnicos	Pierna / jamón pierna	MATERIA_PRIMA	Pierna de cerdo cocida	KG	Pierna / jamón pierna para deshebrar	❌	❌
Proteínas y Cárnicos	Pierna preparada	ELABORADO	Pierna deshebrada	KG	Pierna/jamón pierna mechada lista para torta, tostada	✅	❌
Proteínas y Cárnicos	Pastor preparado	ELABORADO	Pastor preparado	KG	Carne al pastor ya guisada	✅	❌
Proteínas y Cárnicos	Embutido crudo	MATERIA_PRIMA	Chorizo fresco	KG	Chorizo rojo o español	❌	❌
Proteínas y Cárnicos	Embutido listo	ELABORADO	Chorizo guisado	KG	Chorizo cocinado, listo para topping/molletes/chilaquiles	✅	❌
Proteínas y Cárnicos	Frío / lonche	MATERIA_PRIMA	Jamón de pavo	KG	Jamón tipo sandwich / club sandwich / sándwich frío	❌	❌
Proteínas y Cárnicos	Frío / lonche	MATERIA_PRIMA	Salami	KG	Salami rebanado	❌	❌
Proteínas y Cárnicos	Salchicha / hot dog	MATERIA_PRIMA	Salchicha tipo hot dog	KG	Salchicha de pavo/res	❌	❌
Proteínas y Cárnicos	Tocino	MATERIA_PRIMA	Tocino	KG	Tocino de cerdo frito / topping desayuno	❌	❌
Proteínas y Cárnicos	Empanizado pollo	MATERIA_PRIMA	Milanesa de pollo empanizada	KG	Pechuga empanizada para milanesa / torta	❌	❌
Proteínas y Cárnicos	Boneless crudo	MATERIA_PRIMA	Pollo boneless crudo	KG	Bites/bone-less empanizado crudo	❌	❌
Proteínas y Cárnicos	Boneless listo	ELABORADO	Boneless fritos listos	KG	Boneless pre-fritos listos para salsear	✅	❌
3. VERDURAS FRESCAS
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Verduras Frescas	Base	MATERIA_PRIMA	Jitomate rojo	KG	Jitomate saladette / rojo	❌	❌
Verduras Frescas	Base	MATERIA_PRIMA	Tomate verde	KG	Tomate verde pelado	❌	❌
Verduras Frescas	Base	MATERIA_PRIMA	Cebolla blanca	KG	Cebolla seca blanca	❌	❌
Verduras Frescas	Base	MATERIA_PRIMA	Cebolla morada	KG	Cebolla morada en julianas para topping	❌	❌
Verduras Frescas	Chile fresco	MATERIA_PRIMA	Chile serrano	KG	Serrano / jalapeño verde	❌	❌
Verduras Frescas	Chile fresco	MATERIA_PRIMA	Chile habanero	KG	Habanero rojo/verde	❌	❌
Verduras Frescas	Chile seco	MATERIA_PRIMA	Chile pasilla seco	KG	Pasilla / chile seco desvenado	❌	❌
Verduras Frescas	Hoja verde	MATERIA_PRIMA	Cilantro	ROLLO	Manojo/rollo de cilantro fresco	❌	❌
Verduras Frescas	Hoja verde	MATERIA_PRIMA	Lechuga romana	KG	Lechuga lavada/fileteada	❌	❌
Verduras Frescas	Hortaliza	MATERIA_PRIMA	Calabaza	KG	Calabacita italiana	❌	❌
Verduras Frescas	Hortaliza	MATERIA_PRIMA	Zanahoria	KG	Zanahoria fresca	❌	❌
Verduras Frescas	Hortaliza	MATERIA_PRIMA	Papa blanca	KG	Papa blanca / cambray	❌	❌
Verduras Frescas	Hortaliza	MATERIA_PRIMA	Pepino	KG	Pepino verde	❌	❌
Verduras Frescas	Hortaliza	MATERIA_PRIMA	Jícama	KG	Jícama fresca	❌	❌
Verduras Frescas	Hortaliza	MATERIA_PRIMA	Col blanca	KG	Col fileteada / repollo	❌	❌
Verduras Frescas	Aromático	MATERIA_PRIMA	Ajo fresco	KG	Cabeza de ajo / diente	❌	❌
Verduras Frescas	Mise en place	ELABORADO	Cebolla fileteada lista	KG	Cebolla fileteada y almacenada lista servicio	✅	❌

Nota: “Cebolla fileteada lista” la incluimos como ELABORADO sólo si efectivamente la dejan en mise en place refrigerada, lista.

4. FRUTAS FRESCAS
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Frutas Frescas	Tropical	MATERIA_PRIMA	Papaya	KG	Papaya madura	❌	❌
Frutas Frescas	Tropical	MATERIA_PRIMA	Melón	KG	Melón chino / cantaloupe	❌	❌
Frutas Frescas	Tropical	MATERIA_PRIMA	Sandía	KG	Sandía roja	❌	❌
Frutas Frescas	Tropical	MATERIA_PRIMA	Piña	KG	Piña pelada	❌	❌
Frutas Frescas	Berries	MATERIA_PRIMA	Fresa fresca	KG	Fresa entera	❌	❌
Frutas Frescas	Berries	MATERIA_PRIMA	Blueberry	KG	Mora azul / arándano	❌	❌
Frutas Frescas	Berries	MATERIA_PRIMA	Frambuesa	KG	Frambuesa roja	❌	❌
Frutas Frescas	Base licuado	MATERIA_PRIMA	Plátano	KG	Plátano tabasco	❌	❌
Frutas Frescas	Base licuado	MATERIA_PRIMA	Manzana	KG	Manzana roja / verde	❌	❌
Frutas Frescas	Base licuado	MATERIA_PRIMA	Pera	KG	Pera de agua	❌	❌
Frutas Frescas	Cítrico	MATERIA_PRIMA	Limón	KG	Limón verde / persa	❌	❌
Frutas Frescas	Cítrico	MATERIA_PRIMA	Naranja para jugo	KG	Naranja dulce	❌	❌
Frutas Frescas	Congelado	MATERIA_PRIMA	Fresa congelada	KG	Fresa IQF congelada	❌	❌
Frutas Frescas	Congelado	MATERIA_PRIMA	Mix frutos rojos congelado	KG	Mezcla frutos rojos congelados	❌	❌
5. ABARROTES SECOS Y BASES
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Abarrotes Secos	Grano seco	MATERIA_PRIMA	Arroz blanco	KG	Arroz granel	❌	❌
Abarrotes Secos	Grano seco	MATERIA_PRIMA	Frijol negro seco	KG	Frijol negro crudo	❌	❌
Abarrotes Secos	Grano seco	MATERIA_PRIMA	Lenteja seca	KG	Lenteja granel	❌	❌
Abarrotes Secos	Grano seco	MATERIA_PRIMA	Garbanzo seco	KG	Garbanzo crudo	❌	❌
Abarrotes Secos	Azúcar	MATERIA_PRIMA	Azúcar estándar	KG	Azúcar blanca refinada	❌	❌
Abarrotes Secos	Harina	MATERIA_PRIMA	Harina de trigo	KG	Harina para hot cakes / panificación	❌	❌
Abarrotes Secos	Pan rallado	MATERIA_PRIMA	Pan molido	KG	Pan molido empanizar	❌	❌
Abarrotes Secos	Pastas secas	MATERIA_PRIMA	Pasta espagueti seca	KG	Espagueti	❌	❌
Abarrotes Secos	Pastas secas	MATERIA_PRIMA	Pasta fetuccine seca	KG	Fettuccine	❌	❌
Abarrotes Secos	Pastas secas	MATERIA_PRIMA	Fideo corto seco	KG	Fideo sopa	❌	❌
Abarrotes Secos	Tomate procesado	MATERIA_PRIMA	Puré / salsa de tomate	KG	Puré o salsa de tomate en bolsa o lata	❌	❌
Abarrotes Secos	Endulzantes	MATERIA_PRIMA	Leche condensada	KG	“Lechera” para hot cakes / postres	❌	❌
Abarrotes Secos	Endulzantes	MATERIA_PRIMA	Cajeta / dulce de leche	KG	Cajeta para hot cakes	❌	❌
Abarrotes Secos	Jarabes dulce	MATERIA_PRIMA	Jarabe tipo maple	LT	Jarabe maple / miel de maple	❌	❌
Abarrotes Secos	Miel	MATERIA_PRIMA	Miel de abeja	LT	Miel natural	❌	❌
Abarrotes Secos	Aderezos fríos	MATERIA_PRIMA	Mayonesa	KG	Mayonesa food service	❌	❌
Abarrotes Secos	Aderezos fríos	MATERIA_PRIMA	Catsup	LT	Salsa catsup tipo Heinz	❌	❌
Abarrotes Secos	Aderezos fríos	MATERIA_PRIMA	Mostaza amarilla	LT	Mostaza tipo French’s	❌	❌
Abarrotes Secos	Aderezo ensalada	MATERIA_PRIMA	Aderezo ranch comercial	LT	Ranch listo (cuando se usa directo)	❌	❌
Abarrotes Secos	Aceites	MATERIA_PRIMA	Aceite vegetal	LT	Aceite de cocina / freír	❌	❌
Abarrotes Secos	Aceites	MATERIA_PRIMA	Aceite de oliva	LT	Aceite de oliva para cocina / pasta	❌	❌
Abarrotes Secos	Snacks salados	ENVASADO	Papas fritas listas	PZ	Papas fritas congeladas listas para hornear/freír	❌	❌
Abarrotes Secos	Confitería	ENVASADO	Chicle / menta	PZ	Chicles, chicletas	❌	❌
Abarrotes Secos	Dulce untables	MATERIA_PRIMA	Crema de avellana	KG	Crema tipo Nutella	❌	❌
Abarrotes Secos	Granola / cereal	MATERIA_PRIMA	Granola	KG	Granola para fruta con yogurt	❌	❌
Abarrotes Secos	Sal / Sazonadores	MATERIA_PRIMA	Sal fina	KG	Sal estándar	❌	❌
Abarrotes Secos	Sazonadores	MATERIA_PRIMA	Mezcla ajo / finas hierbas	KG	Ajo con finas hierbas (McCormick u otro)	❌	❌
Abarrotes Secos	Especias secas	MATERIA_PRIMA	Orégano seco	KG	Orégano hoja seca	❌	❌
Abarrotes Secos	Especias secas	MATERIA_PRIMA	Tomillo seco	KG	Tomillo seco	❌	❌
Abarrotes Secos	Semillas	MATERIA_PRIMA	Ajonjolí	KG	Ajonjolí natural	❌	❌
Abarrotes Secos	Caldos / consomé	MATERIA_PRIMA	Caldo de pollo en polvo	KG	Caldo concentrado tipo consomé	❌	❌
6. CAFETERÍA / JARABES / POLVOS / BARRA FRÍA
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Cafetería	Café	MATERIA_PRIMA	Café molido espresso	KG	Café espresso para americano, latte, cappuccino	❌	❌
Cafetería	Café soluble	MATERIA_PRIMA	Café soluble	KG	Café instantáneo (ej. nescafé clásico)	❌	❌
Cafetería	Jarabes sabor latte	MATERIA_PRIMA	Jarabe caramelo	LT	Sabor caramelo	❌	❌
Cafetería	Jarabes sabor latte	MATERIA_PRIMA	Jarabe vainilla	LT	Sabor vainilla	❌	❌
Cafetería	Jarabes sabor latte	MATERIA_PRIMA	Jarabe avellana	LT	Sabor crema de avellana	❌	❌
Cafetería	Jarabes sabor latte	MATERIA_PRIMA	Jarabe crema irlandesa	LT	Irish cream	❌	❌
Cafetería	Polvo base latte	MATERIA_PRIMA	Base matcha latte	KG	Matcha endulzada lista	❌	❌
Cafetería	Polvo base latte	MATERIA_PRIMA	Base taro latte	KG	Polvo taro	❌	❌
Cafetería	Polvo base latte	MATERIA_PRIMA	Base chai latte	KG	Chai vainilla / chai negro	❌	❌
Cafetería	Polvo frappé	MATERIA_PRIMA	Base frappé vainilla	KG	Base frappé vainilla / cookies & cream	❌	❌
Cafetería	Polvo frappé	MATERIA_PRIMA	Base frappé moka / moka blanco	KG	Base frappé moka, moka blanco	❌	❌
Cafetería	Polvo chocolate	MATERIA_PRIMA	Chocolate en polvo	KG	Chocolate tipo Nesquik / chocolatito	❌	❌
Cafetería	Concentrado bebida	MATERIA_PRIMA	Concentrado horchata	LT	Base de horchata lista (p.ej. garrafa “La Deliciosa”)	❌	❌
Cafetería	Toppings bebida	MATERIA_PRIMA	Crema batida lista	LT	Crema batida (puede venir lista o se hace con sifón y CO₂)	✅	❌
Cafetería	Toppings bebida	MATERIA_PRIMA	Sirope caramelo topping	LT	Salsa espesa caramelo para vaso/frappé	❌	❌
Cafetería	Toppings bebida	MATERIA_PRIMA	Sirope chocolate topping	LT	Salsa espesa chocolate	❌	❌
Cafetería	Toppings bebida	MATERIA_PRIMA	Galleta tipo Oreo	PZ	Galleta / topping para frappé cookies & cream	❌	❌
Cafetería	Hielo	MATERIA_PRIMA	Hielo alimenticio	KG	Hielo grado alimenticio para bebidas frías	❌	❌
Cafetería	Gasificación crema	CONSUMIBLE_OPERATIVO	Cápsula CO₂ crema batida	PZ	Cartucho para sifón de crema batida	❌	✅
Cafetería	Té	MATERIA_PRIMA	Té en bolsita / té suelto	PZ	Té manzana, especias, etc.	❌	❌
7. PANADERÍA, PAN SALADO Y POSTRES
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Panadería Salada	Pan torta	MATERIA_PRIMA	Telera	PZ	Pan blanco tipo torta / telera	❌	❌
Panadería Salada	Pan bolillo	MATERIA_PRIMA	Bolillo	PZ	Pan blanco bolillo usado en molletes	❌	❌
Panadería Salada	Baguette	MATERIA_PRIMA	Pan baguette	PZ	Pan baguette para sándwich estilo baguette	❌	❌
Panadería Salada	Hot dog	MATERIA_PRIMA	Pan hot dog	PZ	Pan hot dog	❌	❌
Panadería Dulce	Bollería	MATERIA_PRIMA	Cuernito / croissant	PZ	Pan hojaldrado para “cuernito jamón queso”	❌	❌
Panadería Dulce	Bollería	MATERIA_PRIMA	Pan de muerto	PZ	Pan de temporada	❌	❌
Panadería Dulce	Muffin	ENVASADO	Muffin vainilla	PZ	Muffin sabor vainilla	❌	❌
Panadería Dulce	Muffin	ENVASADO	Muffin chocolate	PZ	Muffin sabor chocolate	❌	❌
Postres	Vitrina rebanado	ENVASADO	Pastel chocolate	PZ	Rebanada pastel tipo “Matilda”	❌	❌
Postres	Vitrina rebanado	ENVASADO	Pay de limón	PZ	Rebanada pay limón	❌	❌
Postres	Vitrina rebanado	ENVASADO	Cheesecake frambuesa	PZ	Rebanada cheesecake frambuesa	❌	❌
Postres	Vitrina rebanado	ENVASADO	Chocoflan	PZ	Rebanada chocoflan	❌	❌
Postres	Galleta	ENVASADO	Galleta chispas chocolate	PZ	Galleta individual	❌	❌
Postres	Postre preparado	ELABORADO	Gelatina con yogurt	PZ	Vasito gelatina + yogurt + fruta	✅	❌
Toppings Dulces	Untable dulce	MATERIA_PRIMA	Crema de avellana	KG	Crema tipo Nutella	❌	❌
Toppings Dulces	Mermelada	MATERIA_PRIMA	Mermelada de frutos rojos	KG	Para hot cakes, pan tostado, postres	❌	❌
Toppings Dulces	Jarabe	MATERIA_PRIMA	Jarabe tipo maple	LT	Jarabe para hot cakes	❌	❌
Toppings Dulces	Dulce lácteo	MATERIA_PRIMA	Leche condensada	KG	“Lechera” para hot cakes	❌	❌
Toppings Dulces	Dulce lácteo	MATERIA_PRIMA	Cajeta / dulce de leche	KG	Cajeta para hot cakes / waffles	❌	❌
Toppings Dulces	Crunch	MATERIA_PRIMA	Granola	KG	Granola para fruta preparada	❌	❌
8. MASAS / TORTILLAS / PAN BASE DE OPERACIÓN
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Base de Maíz / Harina	Tortilla maíz	MATERIA_PRIMA	Tortilla de maíz	KG	Tortilla para enchiladas, chilaquiles, tacos dorados	❌	❌
Base de Maíz / Harina	Tortilla harina	MATERIA_PRIMA	Tortilla de harina	PZ	Tortilla grande para quesadilla/harina, burrito	❌	❌
Base de Maíz / Harina	Totopo / chilaquiles	ELABORADO	Totopo frito	KG	Triángulos de tortilla frita (base chilaquiles, sopa azteca)	✅	❌
Base de Pan	Telera	MATERIA_PRIMA	Telera	PZ	Pan torta	❌	❌
Base de Pan	Bolillo	MATERIA_PRIMA	Bolillo	PZ	Pan bolillo / mollete	❌	❌
Base de Pan	Baguette	MATERIA_PRIMA	Pan baguette	PZ	Pan estilo baguette	❌	❌
Base de Pan	Hot dog	MATERIA_PRIMA	Pan hot dog	PZ	Pan hot dog	❌	❌
Base de Maíz / Harina	Tostada dorada	ELABORADO / MP	Tostada frita	PZ	Tortilla dorada crujiente para “Tostadas”	✅ / ❌*	❌

* Si compras la tostada hecha → MATERIA_PRIMA. Si la fríes tú → ELABORADO.

9. LEGUMBRES PREPARADAS / UNTABLES / MOLLETES
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Legumbres Preparadas	Frijol guarnición	ELABORADO	Frijoles refritos base	KG	Frijol cocido + manteca, listo para molletes / guarnición	✅	❌
Legumbres Preparadas	Frijol caldoso	ELABORADO	Frijol de olla	KG	Frijoles cocidos con caldo	✅	❌
Legumbres Preparadas	Salsa enfrijolada	ELABORADO	Salsa de frijol para enfrijoladas	KG	Frijol licuado más fluido para bañar tortilla	✅	❌
Untables salados	Grasa pan	MATERIA_PRIMA	Mantequilla / margarina	KG	Untar pan, hot cakes, terminar huevo	❌	❌
Untables salados	Aderezo cremoso	ELABORADO	Salsa parmesano ranch	LT	Ranch + parmesano (boneless parmesano)	✅	❌
Untables dulces	Cremas dulces	MATERIA_PRIMA	Crema de avellana	KG	Tipo Nutella	❌	❌
Untables dulces	Mermelada	MATERIA_PRIMA	Mermelada de frutos rojos	KG	Para pan tostado, hot cakes, cuernito dulce	❌	❌
Untables dulces	Cajeta	MATERIA_PRIMA	Cajeta / dulce de leche	KG	Hot cakes / hot cakes terrena	❌	❌
Untables dulces	Jarabe dulce	MATERIA_PRIMA	Jarabe tipo maple	LT	Topping hot cakes	❌	❌
Untables dulces	Leche condensada	MATERIA_PRIMA	Leche condensada	KG	“Lechera”	❌	❌
Toppings desayuno	Crunch	MATERIA_PRIMA	Granola	KG	Para fruta preparada / yogurt + granola + miel	❌	❌
Toppings desayuno	Dulce natural	MATERIA_PRIMA	Miel de abeja	LT	Miel natural	❌	❌
10. SALSAS, ADEREZOS Y CONDIMENTOS
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Salsas Comerciales	Picante mesa	MATERIA_PRIMA	Salsa valentina	LT	Salsa picante comercial	❌	❌
Salsas Comerciales	Chamoy / dulce	MATERIA_PRIMA	Chamoy líquido	LT	Chamoy tipo Chilerito	❌	❌
Salsas Comerciales	Buffalo	MATERIA_PRIMA	Salsa buffalo	LT	Salsa búfalo para boneless	❌	❌
Salsas Comerciales	BBQ	MATERIA_PRIMA	Salsa BBQ	LT	Salsa BBQ para boneless	❌	❌
Salsas Especiales	Mango-habanero	ELABORADO	Salsa mango-habanero	LT	Salsa dulce/picante para boneless mango-habanero	✅	❌
Salsas Especiales	Parmesano ranch	ELABORADO	Salsa parmesano ranch	LT	Ranch + parmesano para boneless parmesano	✅	❌
Salsas Especiales	Aderezo ranch listo	MATERIA_PRIMA	Aderezo ranch comercial	LT	Ranch comprado (si se usa tal cual)	❌	❌
Salsas Base	Pico de gallo	ELABORADO	Pico de gallo	KG	Tomate, cebolla, cilantro, limón	✅	❌
Salsas Base	Guacamole / aguacate	ELABORADO	Salsa de aguacate / guacamole	KG	Aguacate + cilantro + limón (si lo usas en tacos/tostadas)	✅	❌
Condimentos Mesa	Ketchup	MATERIA_PRIMA	Catsup	LT	Catsup	❌	❌
Condimentos Mesa	Mostaza	MATERIA_PRIMA	Mostaza amarilla	LT	Mostaza para hot dog / sándwich	❌	❌
Condimentos Mesa	Mayonesa	MATERIA_PRIMA	Mayonesa	KG	Mayonesa para torta / club sandwich	❌	❌
11. JUGOS, AGUAS FRESCAS, LIMONADAS, NARANJADAS
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Bebidas Naturales	Jugo naranja	ELABORADO	Jugo de naranja exprimido	LT	Naranja natural exprimida	✅	❌
Bebidas Naturales	Jugo zanahoria	ELABORADO	Jugo de zanahoria	LT	Zanahoria licuada	✅	❌
Bebidas Naturales	Jugo verde	ELABORADO	Jugo verde base	LT	Verde (pepino, piña, limón, etc.)	✅	❌
Bebidas Naturales	Agua fresca	ELABORADO / MP	Agua fresca sabor	LT	Agua de sabor tipo horchata / jamaica / etc.	✅ / ❌*	❌
Bebidas Naturales	Limonada	ELABORADO	Base limonada	LT	Limón + agua + endulzante	✅	❌
Bebidas Naturales	Naranjada	ELABORADO	Base naranjada	LT	Jugo naranja + agua	✅	❌
Bebidas Naturales	Mineralizada	ELABORADO	Limonada mineral	LT	Base limonada + agua mineral	✅	❌
Bebidas Naturales	Mineralizada	ELABORADO	Naranjada mineral	LT	Base naranjada + agua mineral	✅	❌

* Si usas la horchata comercial tipo “La Deliciosa”, entonces se puede cargar como MATERIA_PRIMA y servir directo.

12. SUBRECETAS BASE / PRODUCCIÓN (Mise en place)

Estas son las IMPORTANTES. Se fabrican en cocina/producción, se guardan como lote, y luego las recetas de venta las consumen. Sin estas no puedes costear ni descontar.

Familia	Categoría	Tipo	Ítem	UOM	Descripción / Uso principal	Producible	Consumible Operativo
Subreceta Base	Salsa roja	ELABORADO	Salsa Roja Base	KG	Salsa roja casera (enchiladas, chilaquiles, huevos rancheros)	✅	❌
Subreceta Base	Salsa verde	ELABORADO	Salsa Verde Base	KG	Salsa verde casera (enchiladas, chilaquiles, picadas)	✅	❌
Subreceta Base	Chile seco	ELABORADO	Salsa Chile Seco	KG	Salsa de chile pasilla/chile seco para picadas	✅	❌
Subreceta Base	Mole	ELABORADO	Mole Base Listo	KG	Mole listo para enmoladas / chilaquiles de mole	✅ / ❌*	❌
Subreceta Base	Legumbre base	ELABORADO	Frijoles Refritos	KG	Frijol cocido + manteca listo	✅	❌
Subreceta Base	Legumbre suave	ELABORADO	Frijol de olla	KG	Frijoles cocidos con caldo	✅	❌
Subreceta Base	Proteína ready	ELABORADO	Pollo Deshebrado Cocido	KG	Pechuga cocida y desmenuzada	✅	❌
Subreceta Base	Proteína ready	ELABORADO	Pierna Deshebrada	KG	Pierna / jamón pierna mechada para tortas / tostadas	✅	❌
Subreceta Base	Proteína ready	ELABORADO	Pastor Preparado	KG	Carne tipo pastor lista para taco, quesadilla, torta	✅	❌
Subreceta Base	Guarnición	ELABORADO	Pico de Gallo	KG	Tomate, cebolla, cilantro, limón	✅	❌
Subreceta Base	Guarnición	ELABORADO	Totopos Fritos	KG	Tortilla frita triangular base chilaquiles/sopa azteca	✅	❌
Subreceta Base	Boneless / Salsas	ELABORADO	Salsa Mango-Habanero	LT	Salsa dulce/picante para boneless	✅	❌
Subreceta Base	Boneless / Salsas	ELABORADO	Salsa Parmesano Ranch	LT	Ranch + parmesano / boneless parmesano	✅	❌
Subreceta Base	Boneless / Salsas	MATERIA_PRIMA	Salsa Buffalo	LT	Salsa búfalo comercial (si no se ajusta en cocina)	❌	❌
Subreceta Base	Boneless / Salsas	MATERIA_PRIMA	Salsa BBQ	LT	Salsa BBQ comercial (si no se ajusta en cocina)	❌	❌

* Mole puede ser comprado listo (MATERIA_PRIMA) o se puede “ajustar” en cocina (entonces ELABORADO). Lo dejamos como ELABORADO porque tu menú ofrece “chilaquiles de mole” y “enmoladas”, entonces conviene tratarlo como batch controlable con caducidad.

13. SOPAS / PASTAS / CALDOS
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Fondos y Caldos	Caldo base	ELABORADO	Caldo de pollo base	LT	Fondo de pollo casero (puchero, arroz, salsas)	✅	❌
Fondos y Caldos	Caldo rojo	ELABORADO	Caldo rojo / caldo jitomate	LT	Base tomate-especia para sopa azteca / caldo de tortilla	✅	❌
Fondos y Caldos	Pasta guiso	ELABORADO	Salsa boloñesa	KG	Carne molida + tomate + especia para pasta boloñesa	✅	❌
Fondos y Caldos	Pasta guiso	ELABORADO	Salsa pomodoro	KG	Tomate, ajo, aceite oliva, especias	✅	❌
Fondos y Caldos	Pasta cocida	ELABORADO	Pasta fetuccine cocida	KG	Fettuccine hervido listo para salsear	✅	❌
Fondos y Caldos	Topping sopa	ELABORADO	Tiras de tortilla frita	KG	Tortilla frita en tiras para sopa azteca	✅	❌
14. DESAYUNOS / GUARNICIONES

Estas guarniciones salen todo el día en tu carta de desayuno (“Guarnición: Ensalada / Verduras / Fruta / Frijoles”).

Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Guarniciones	Verdura cocida	ELABORADO	Verduras salteadas mixtas	KG	Calabaza, zanahoria, cebolla salteadas para omelette	✅	❌
Guarniciones	Ensalada fresca	ELABORADO	Ensalada básica guarnición	KG	Lechuga, jitomate, pepino, aderezo ligero	✅	❌
Guarniciones	Fruta picada	ELABORADO	Fruta picada guarnición	KG	Fruta mixta lista (melón, sandía, papaya, fresa...)	✅	❌
Guarniciones	Legumbre guarnición	ELABORADO	Frijoles refritos (guarnición)	KG	Porción refritos que acompaña huevos, chilaquiles	✅	❌

Nota: “Fruta picada guarnición” no es lo mismo que “porción cóctel de frutas grande” que vendes como ítem; pero físicamente es el mismo batch. En inventario es el mismo ítem (fruta picada lista), sólo cambian las porciones.

15. BEBIDAS EMBOTELLADAS / REFRIGERADAS
Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Bebidas Embotelladas	Agua natural	ENVASADO	Agua embotellada 500 ml	PZ	Botella agua natural 500 ml	❌	❌
Bebidas Embotelladas	Agua natural	ENVASADO	Agua embotellada 1 L	PZ	Botella agua natural 1 L	❌	❌
Bebidas Embotelladas	Agua mineral	ENVASADO	Agua mineral 600 ml	PZ	Agua mineral natural	❌	❌
Bebidas Embotelladas	Agua mineral	ENVASADO	Agua mineral sabor cítrico	PZ	Agua mineral con sabor (“twist”)	❌	❌
Bebidas Embotelladas	Suero oral	ENVASADO	Bebida hidratante tipo suero	PZ	Electrolit sabores (fresa, naranja, mora azul, kiwi…)	❌	❌
Bebidas Embotelladas	Mineral premium	ENVASADO	Topo Chico	PZ	Agua mineral embotellada premium	❌	❌
16. DESECHABLES Y EMPAQUE

Estos son CRÍTICOS para costo real y para que no te quedes sin poder vender en take-out.
Se controlan como inventario. Se descargan:

vía modificador POS “Para llevar” (charola, cubiertos, servilleta, vasito salsa, etc.), o

vía consumo operativo (si los usas internos).

Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Desechables / Empaque	Bebidas calientes	CONSUMIBLE_OPERATIVO	Vaso caliente 12 oz	PZ	Vaso cartón café caliente	❌	✅
Desechables / Empaque	Bebidas calientes	CONSUMIBLE_OPERATIVO	Tapa vaso caliente	PZ	Tapa sorbible vaso caliente	❌	✅
Desechables / Empaque	Bebidas frías	CONSUMIBLE_OPERATIVO	Vaso frío 16 oz	PZ	Vaso PET para iced latte / frappé	❌	✅
Desechables / Empaque	Bebidas frías	CONSUMIBLE_OPERATIVO	Tapa domo 16 oz	PZ	Tapa domo frappé	❌	✅
Desechables / Empaque	Bebidas frías	CONSUMIBLE_OPERATIVO	Popote	PZ	Popote desechable / compostable	❌	✅
Desechables / Empaque	Comida caliente	CONSUMIBLE_OPERATIVO	Charola comida caliente	PZ	Contenedor térmico con tapa para enchiladas/chilaquiles/boneless	❌	✅
Desechables / Empaque	Salsa individual	CONSUMIBLE_OPERATIVO	Vasito salsa con tapa	PZ	Contenedor 1-2 oz para salsa o aderezo	❌	✅
Desechables / Empaque	Servicio cubiertos	CONSUMIBLE_OPERATIVO	Cubiertos desechables	PZ	Kit tenedor/cuchillo/cuchara	❌	✅
Desechables / Empaque	Servicio	CONSUMIBLE_OPERATIVO	Servilleta desechable	PZ	Servilleta cliente	❌	✅
Desechables / Empaque	Entrega	CONSUMIBLE_OPERATIVO	Bolsa para llevar chica	PZ	Bolsa individual	❌	✅
Desechables / Empaque	Entrega	CONSUMIBLE_OPERATIVO	Bolsa para llevar grande	PZ	Bolsa para varios contenedores	❌	✅
17. LIMPIEZA / OPERACIÓN / COSTO INDIRECTO

Estos NO se venden, no son merma, pero sí deben salir de inventario, vía movimiento operativo (ej. CONSUMO_OPERATIVO al cierre de turno).

Familia	Categoría	Tipo	Ítem	UOM	Descripción	Producible	Consumible Operativo
Limpieza y Operación	Sanitización	CONSUMIBLE_OPERATIVO	Desinfectante de cocina	LT	Sanitizante grado alimenticio	❌	✅
Limpieza y Operación	Lavado utensilios	CONSUMIBLE_OPERATIVO	Jabón para trastes	LT	Detergente vajilla	❌	✅
Limpieza y Operación	Implementos	CONSUMIBLE_OPERATIVO	Fibra / esponja cocina	PZ	Esponja, fibra verde	❌	✅
Limpieza y Operación	EPP	CONSUMIBLE_OPERATIVO	Guantes desechables	PZ	Guantes nitrilo / látex	❌	✅
Limpieza y Operación	Residuos	CONSUMIBLE_OPERATIVO	Bolsa basura negra	PZ	Bolsa grande negra	❌	✅
Limpieza y Operación	Residuos	CONSUMIBLE_OPERATIVO	Bolsa basura blanca	PZ	Bolsa cocina / prep	❌	✅
Limpieza y Operación	Etiquetado	CONSUMIBLE_OPERATIVO	Etiqueta / cinta rotulado	PZ	Etiquetas de lote, fecha de producción	❌	✅
Limpieza y Operación	Conservación	CONSUMIBLE_OPERATIVO	Film plástico / aluminio	PZ	Film y/o papel aluminio para cubrir gastronorm	❌	✅
Limpieza y Operación	Barra café	CONSUMIBLE_OPERATIVO	Cápsula CO₂ crema batida	PZ	Carga de sifón crema batida	❌	✅