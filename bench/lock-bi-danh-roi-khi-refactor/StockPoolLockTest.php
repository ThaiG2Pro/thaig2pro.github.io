<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Support\Facades\DB;

/**
 * The red test. Run it against the pre-refactor service (locked read) and the
 * post-refactor service (lock-free read) and it separates them.
 *
 * Without ForcesLockSyntax it passes for BOTH — that is the whole point.
 */
class StockPoolLockTest extends TestCase
{
    use ForcesLockSyntax;

    /**
     * Build the schema directly instead of using RefreshDatabase: this bench
     * ships a schema.sql, not a migrations/ directory, so there is nothing for
     * RefreshDatabase to run. Each test boots a fresh sqlite :memory: database.
     */
    protected function setUp(): void
    {
        parent::setUp();

        foreach (explode(';', file_get_contents(__DIR__ . '/schema.sql')) as $statement) {
            if (trim($statement) !== '') {
                DB::statement($statement);
            }
        }
    }

    private function service(): StockPoolService
    {
        return new StockPoolService();
    }

    /** @dataProvider writePaths */
    public function test_every_write_path_reads_the_pool_under_a_row_lock(string $path): void
    {
        $this->makeLockVisible();

        $sql = $this->captureSql(function () use ($path) {
            $this->service()->{$path}('SKU-A', campaignId: 1, quantity: 5);
        });

        $poolReads = array_filter(
            $sql,
            fn ($q) => str_contains($q, 'from "stock_pools"') && str_contains($q, 'select')
        );

        $this->assertNotEmpty($poolReads, "no pool read observed on path {$path}");

        foreach ($poolReads as $q) {
            $this->assertStringContainsString(
                '/* for update */',
                $q,
                "pool read on path {$path} is not locked:\n{$q}"
            );
        }
    }

    public static function writePaths(): array
    {
        return [
            'single adjustment' => ['adjust'],
            'bulk import row'   => ['importRow'],
            'campaign transfer' => ['transfer'],
        ];
    }
}
