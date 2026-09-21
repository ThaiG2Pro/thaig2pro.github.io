<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Three write paths, all reading the same shared pool row.
 *
 * Flip LOCKED_READ to move between the two versions of the story:
 *   false → after the refactor, the lock was dropped (the bug)
 *   true  → before the refactor, the read is locked (the fix)
 *
 * The point of the bench is that on sqlite, with a plain behavioural test,
 * both settings look identical.
 */
class StockPoolService
{
    /** false = lock-free read (post-refactor). true = locked read (pre-refactor). */
    public const LOCKED_READ = false;

    public function adjust(string $sku, int $campaignId, int $quantity): void
    {
        $this->allocate($sku, $campaignId, $quantity);
    }

    public function importRow(string $sku, int $campaignId, int $quantity): void
    {
        $this->allocate($sku, $campaignId, $quantity);
    }

    public function transfer(string $sku, int $campaignId, int $quantity): void
    {
        $this->allocate($sku, $campaignId, $quantity);
    }

    private function allocate(string $sku, int $campaignId, int $quantity): void
    {
        $pool = $this->readPool($sku);

        if ($pool === null || ($pool->total - $pool->reserved) < $quantity) {
            throw new RuntimeException("not enough stock for {$sku}");
        }

        DB::table('campaign_allocations')->insert([
            'campaign_id' => $campaignId,
            'sku'         => $sku,
            'quantity'    => $quantity,
        ]);

        DB::table('stock_pools')
            ->where('sku', $sku)
            ->update(['reserved' => $pool->reserved + $quantity]);
    }

    private function readPool(string $sku): ?object
    {
        $query = DB::table('stock_pools')->where('sku', $sku);

        if (self::LOCKED_READ) {
            $query->lockForUpdate();
        }

        return $query->first();
    }
}
