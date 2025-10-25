    <?php
  // database/migrations/2025_10_24_120002_alter_purchase_requests_add_fields.php
	use Illuminate\Database\Migrations\Migration;
  use Illuminate\Database\Schema\Blueprint;
  use Illuminate\Support\Facades\Schema;
  use Illuminate\Support\Facades\DB;

  return new class extends Migration
  {
      public function up(): void
      {
          Schema::connection('pgsql')->table('selemti.purchase_requests', function (Blueprint
  $table) {
              $table->date('fecha_requerida')->nullable()
                  ->comment('Fecha límite en que se necesita el material');

              $table->bigInteger('almacen_destino_id')->nullable()
                  ->comment('FK a selemti.cat_almacenes - Dónde se recibirá');

              $table->text('justificacion')->nullable()
                  ->comment('Por qué se solicita (ej: stock bajo, evento especial)');

              $table->boolean('urgente')->default(false)
                  ->comment('Marca de urgencia operativa');

              $table->bigInteger('origen_suggestion_id')->nullable()
                  ->comment('FK a purchase_suggestions - si fue generada automáticamente');

              $table->foreign('almacen_destino_id', 'fk_preq_almacen_destino')
                  ->references('id')
                  ->on('selemti.cat_almacenes')
                  ->onDelete('set null');

              $table->foreign('origen_suggestion_id', 'fk_preq_suggestion')
                  ->references('id')
                  ->on('selemti.purchase_suggestions')
                  ->onDelete('set null');

              $table->index('fecha_requerida', 'idx_preq_fecha_requerida');
              $table->index('urgente', 'idx_preq_urgente');
          });

          DB::statement("COMMENT ON COLUMN selemti.purchase_requests.fecha_requerida IS 'Fecha
  límite operativa'");
          DB::statement("COMMENT ON COLUMN selemti.purchase_requests.almacen_destino_id IS
  'Almacén que recibirá el material'");
      }

      public function down(): void
      {
          Schema::connection('pgsql')->table('selemti.purchase_requests', function (Blueprint
  $table) {
              $table->dropForeign('fk_preq_almacen_destino');
              $table->dropForeign('fk_preq_suggestion');

              $table->dropIndex('idx_preq_fecha_requerida');
              $table->dropIndex('idx_preq_urgente');

              $table->dropColumn([
                  'fecha_requerida',
                  'almacen_destino_id',
                  'justificacion',
                  'urgente',
                  'origen_suggestion_id'
              ]);
          });
      }
  };
