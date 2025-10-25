  <?php
  // database/migrations/2025_10_24_120001_create_purchase_suggestion_lines_table.php

  use Illuminate\Database\Migrations\Migration;
  use Illuminate\Database\Schema\Blueprint;
  use Illuminate\Support\Facades\Schema;
  use Illuminate\Support\Facades\DB;

  return new class extends Migration
  {
      public function up(): void
      {
          Schema::connection('pgsql')->create('selemti.purchase_suggestion_lines', function
  (Blueprint $table) {
              $table->bigIncrements('id');
              $table->bigInteger('suggestion_id')->comment('FK a purchase_suggestions');
              $table->string('item_id', 20)->comment('FK a selemti.items.id (VARCHAR!)');

              $table->decimal('stock_actual', 18, 6)->default(0);
              $table->decimal('stock_min', 18, 6);
              $table->decimal('stock_max', 18, 6);
              $table->decimal('reorder_point', 18, 6)->nullable();

              $table->decimal('consumo_promedio_diario', 18, 6)->default(0);
              $table->integer('dias_cobertura_actual')->default(0)
                  ->comment('Días de stock restante al ritmo actual');
              $table->decimal('demanda_proyectada', 18, 6)->default(0)
                  ->comment('Consumo esperado en próximos N días');

              $table->decimal('qty_sugerida', 18, 6)
                  ->comment('Cantidad calculada automáticamente');
              $table->decimal('qty_ajustada', 18, 6)->nullable()
                  ->comment('Cantidad modificada manualmente por usuario');
              $table->string('uom', 10)->comment('Unidad de medida');

              $table->decimal('costo_unitario_estimado', 18, 6)->nullable();
              $table->decimal('costo_total_linea', 18, 2)->nullable();

              $table->bigInteger('proveedor_sugerido_id')->nullable()
                  ->comment('FK a selemti.cat_proveedores.id');
              $table->decimal('ultimo_precio_compra', 18, 6)->nullable();
              $table->date('fecha_ultima_compra')->nullable();

              $table->text('notas')->nullable();

              $table->timestamps();

              $table->foreign('suggestion_id', 'fk_psuggline_suggestion')
                  ->references('id')
                  ->on('selemti.purchase_suggestions')
                  ->onDelete('cascade');

              $table->foreign('item_id', 'fk_psuggline_item')
                  ->references('id')
                  ->on('selemti.items')
                  ->onDelete('restrict');

              $table->foreign('proveedor_sugerido_id', 'fk_psuggline_proveedor')
                  ->references('id')
                  ->on('selemti.cat_proveedores')
                  ->onDelete('set null');

              $table->unique(['suggestion_id', 'item_id'], 'uq_psuggline_suggestion_item');

              $table->index('suggestion_id', 'idx_psuggline_suggestion');
              $table->index('item_id', 'idx_psuggline_item');
          });

          DB::statement("COMMENT ON TABLE selemti.purchase_suggestion_lines IS 'Detalle de items
  en cada sugerencia de compra'");
      }

      public function down(): void
      {
          Schema::connection('pgsql')->dropIfExists('selemti.purchase_suggestion_lines');
      }
  };