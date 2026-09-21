<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use RuntimeException;
use Tests\TestCase;

/**
 * The decoration.
 *
 * This is the test a reasonable developer writes when QA asks for "concurrency
 * coverage": drive the write paths, assert the pool never oversells. It is green
 * with StockPoolService::LOCKED_READ set to true AND to false — it cannot see the
 * difference, because sqlite discards the lock clause either way.
 *
 * Run it both ways before reading StockPoolLockTest. That contrast is the finding.
 */
class NaiveConcurrencyTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        foreach (explode(';', file_get_contents(__DIR__ . '/schema.sql')) as $statement) {
            if (trim($statement) !== '') {
                DB::statement($statement);
            }
        }
    }

    public function test_two_campaigns_cannot_oversell_the_shared_pool(): void
    {
        $service = new StockPoolService();

        $service->adjust('SKU-A', campaignId: 1, quantity: 60);
        $service->adjust('SKU-A', campaignId: 2, quantity: 40);

        $pool = DB::table('stock_pools')->where('sku', 'SKU-A')->first();

        $this->assertSame(100, (int) $pool->reserved, 'pool oversold');

        $this->expectException(RuntimeException::class);
        $service->adjust('SKU-A', campaignId: 3, quantity: 1);
    }
}
