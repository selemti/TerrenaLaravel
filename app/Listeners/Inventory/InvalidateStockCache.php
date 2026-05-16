<?php

namespace App\Listeners\Inventory;

use Illuminate\Support\Facades\Cache;

class InvalidateStockCache
{
    // Fired for both ReceptionPosted and TransferPosted — both invalidate stock state.
    public function handle(object $event): void
    {
        $itemIds = [];

        if (property_exists($event, 'itemIds')) {
            $itemIds = $event->itemIds;
        }

        // Flush warehouse-level stock keys if tagged cache is available.
        // Falls back to a broad flush of the 'stock' tag if items are unknown.
        if (Cache::supportsTags()) {
            $tags = ['stock'];
            foreach ($itemIds as $id) {
                $tags[] = "stock:item:{$id}";
            }
            Cache::tags($tags)->flush();
        } else {
            // Non-taggable drivers (file, database): flush named keys.
            foreach ($itemIds as $id) {
                Cache::forget("stock:item:{$id}");
            }
            Cache::forget('stock:kpis');
        }
    }
}
