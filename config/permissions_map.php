<?php

return [
    'Inventario' => [
        ['perm' => 'inventory.view',                     'label' => 'Ver inventario',                          'desc' => 'Consultar stock, lotes y movimientos.'],
        ['perm' => 'inventory.items.manage',             'label' => 'Gestionar catálogo de ítems',              'desc' => 'Crear/editar artículos y sus datos maestros.'],
        ['perm' => 'inventory.prices.manage',            'label' => 'Gestionar precios de inventario',          'desc' => 'Actualizar costos base y listas de precios.'],
        ['perm' => 'inventory.receivings.manage',        'label' => 'Capturar recepciones',                     'desc' => 'Registrar recepciones previas a la aprobación.'],
        ['perm' => 'inventory.receptions.validate',      'label' => 'Validar recepciones',                      'desc' => 'Aplicar validaciones previas a aprobación.'],
        ['perm' => 'inventory.receptions.override_tolerance', 'label' => 'Autorizar fuera de tolerancia',      'desc' => 'Permitir variaciones superiores a las reglas.'],
        ['perm' => 'inventory.receptions.post',          'label' => 'Postear recepciones de compra',            'desc' => 'Dar entrada definitiva de proveedor al almacén.'],
        ['perm' => 'inventory.moves.manage',             'label' => 'Ajustar inventario manual',                'desc' => 'Capturar ajustes manuales de existencias.'],
        ['perm' => 'inventory.counts.manage',            'label' => 'Hacer conteos físicos',                    'desc' => 'Iniciar y validar conteos cíclicos o generales.'],
        ['perm' => 'inventory.lots.view',                'label' => 'Ver lotes y caducidades',                  'desc' => 'Consultar detalle de lotes y fechas de expiro.'],
        ['perm' => 'inventory.transfers.approve',        'label' => 'Aprobar transferencias',                   'desc' => 'Autorizar movimientos internos antes del envío.'],
        ['perm' => 'inventory.transfers.ship',           'label' => 'Marcar transferencia como enviada',        'desc' => 'Sucursal origen confirma que ya salió.'],
        ['perm' => 'inventory.transfers.receive',        'label' => 'Marcar transferencia como recibida',       'desc' => 'Sucursal destino confirma que llegó.'],
        ['perm' => 'inventory.transfers.post',           'label' => 'Cerrar transferencia',                     'desc' => 'Impactar inventario final de la transferencia.'],
        ['perm' => 'can_manage_purchasing',              'label' => 'Acceso módulo Inventario/Compras',         'desc' => 'Ingresar a pantallas operativas de inventario y compras.'],
    ],

    'Compras / Reposición' => [
        ['perm' => 'purchasing.view',                    'label' => 'Ver compras y sugerencias',                'desc' => 'Consultar órdenes y sugerencias de compra.'],
        ['perm' => 'purchasing.manage',                  'label' => 'Gestionar compras',                        'desc' => 'Crear, editar y autorizar órdenes de compra.'],
        ['perm' => 'vendors.view',                       'label' => 'Ver proveedores',                          'desc' => 'Consultar catálogo de proveedores y datos clave.'],
        ['perm' => 'vendors.manage',                     'label' => 'Gestionar proveedores',                    'desc' => 'Crear o actualizar proveedores y sus condiciones.'],
    ],

    'Caja Chica' => [
        ['perm' => 'cashfund.view',                      'label' => 'Ver caja chica',                           'desc' => 'Consultar movimientos y arqueos de caja chica.'],
        ['perm' => 'cashfund.manage',                    'label' => 'Operar caja chica',                        'desc' => 'Abrir fondo, registrar egresos y cerrar arqueos.'],
    ],

    'Recetas / Costos / Producción' => [
        ['perm' => 'recipes.view',                       'label' => 'Ver recetarios',                           'desc' => 'Consultar recetas e insumos asociados.'],
        ['perm' => 'recipes.manage',                     'label' => 'Editar recetas',                           'desc' => 'Modificar ingredientes o pasos de preparación.'],
        ['perm' => 'recipes.costs.view',                 'label' => 'Ver costos de recetas',                    'desc' => 'Analizar costos teóricos y reales de recetas.'],
        ['perm' => 'recipes.production.manage',          'label' => 'Gestionar producción',                     'desc' => 'Controlar batches de cocina y merma interna.'],
        ['perm' => 'production.manage',                  'label' => 'Postear producción interna',               'desc' => 'Dar de alta producción hacia inventario.'],
        ['perm' => 'can_view_recipe_dashboard',          'label' => 'Ver dashboard de recetas y costos',        'desc' => 'Acceder a panel de costos teóricos y mermas.'],
        ['perm' => 'can_modify_recipe',                  'label' => 'Ajustar recetas desde auditoría',          'desc' => 'Cambiar recetas desde flujos operativos especiales.'],
        ['perm' => 'can_edit_production_order',          'label' => 'Editar órdenes de producción',             'desc' => 'Modificar batches en ejecución antes de postear.'],
        ['perm' => 'menu.engineering.view',              'label' => 'Ver ingeniería de menú',                   'desc' => 'Analizar desempeño de menú y productos clave.'],
        ['perm' => 'menu.engineering.manage',            'label' => 'Gestionar ingeniería de menú',             'desc' => 'Configurar estrategias y ajustes de menú.'],
    ],

    'POS / Auditoría de tickets' => [
        ['perm' => 'can_reprocess_sales',                'label' => 'Reprocesar / revertir tickets POS',        'desc' => 'Corregir ventas históricas con evidencia y motivo.'],
        ['perm' => 'pos.sync.manage',                    'label' => 'Gestionar sincronización POS',            'desc' => 'Forzar reprocesos o resincronizaciones especiales.'],
    ],

    'Reportes / KPIs' => [
        ['perm' => 'reports.view',                       'label' => 'Ver reportes y KPIs',                      'desc' => 'Dashboards de ventas, inventario y operación.'],
        ['perm' => 'reports.manage',                     'label' => 'Configurar reportes',                      'desc' => 'Gestionar parámetros y accesos de reportes.'],
    ],

    'Alertas operativas' => [
        ['perm' => 'alerts.view',                        'label' => 'Ver alertas',                               'desc' => 'Visualizar alertas operativas activas.'],
        ['perm' => 'alerts.manage',                      'label' => 'Gestionar alertas',                         'desc' => 'Atender, cerrar o reasignar alertas.'],
        ['perm' => 'alerts.assign',                      'label' => 'Asignar alertas',                           'desc' => 'Derivar alertas a responsables específicos.'],
    ],

    'Cocina / KDS' => [
        ['perm' => 'kitchen.view_kds',                   'label' => 'Ver KDS cocina',                           'desc' => 'Acceder al tablero de órdenes en cocina.'],
    ],

    'Administración del sistema' => [
        ['perm' => 'people.view',                        'label' => 'Ver personal',                             'desc' => 'Consultar datos básicos de colaboradores.'],
        ['perm' => 'people.users.manage',                'label' => 'Gestionar usuarios',                       'desc' => 'Crear usuarios y restablecer contraseñas.'],
        ['perm' => 'people.roles.manage',                'label' => 'Gestionar plantillas de acceso',           'desc' => 'Crear o editar plantillas (roles) de permisos.'],
        ['perm' => 'people.permissions.manage',          'label' => 'Asignar permisos especiales',              'desc' => 'Otorgar excepciones temporales a usuarios.'],
        ['perm' => 'admin.access',                       'label' => 'Acceso administración avanzada',           'desc' => 'Configuraciones internas, monitoreo y auditoría.'],
    ],
];
