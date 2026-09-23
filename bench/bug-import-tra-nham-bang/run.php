<?php

declare(strict_types=1);

/**
 * Usage: php run.php broken|fixed
 *
 * Exit code is 0 when every test in this run passed, 1 otherwise.
 * run.sh calls this twice and checks that the pattern of results matches
 * what the post claims.
 */

require __DIR__ . '/ImportHandler.php';

$mode = $argv[1] ?? '';
if (!in_array($mode, ['broken', 'fixed'], true)) {
    fwrite(STDERR, "usage: php run.php broken|fixed\n");
    exit(2);
}
$fixed = $mode === 'fixed';

function freshDb(): PDO
{
    $db = new PDO('sqlite::memory:');
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $sql = preg_replace('/^\s*--.*$/m', '', file_get_contents(__DIR__ . '/schema.sql'));
    foreach (explode(';', $sql) as $statement) {
        if (trim($statement) !== '') {
            $db->exec($statement);
        }
    }
    return $db;
}

function seed(PDO $db, string $table, array $row): int
{
    $cols = implode(', ', array_keys($row));
    $params = implode(', ', array_map(fn ($k) => ":$k", array_keys($row)));
    $db->prepare("INSERT INTO {$table} ({$cols}) VALUES ({$params})")->execute($row);
    return (int) $db->lastInsertId();
}

function quotaOf(PDO $db, int $cpvId): int
{
    $stmt = $db->prepare('SELECT quota FROM campaign_product_variants WHERE id = :id');
    $stmt->execute(['id' => $cpvId]);
    return (int) $stmt->fetchColumn();
}

$results = [];
function check(string $name, callable $fn): void
{
    global $results;
    try {
        $fn();
        $results[] = [true, $name];
        echo "  ✓  {$name}\n";
    } catch (Throwable $e) {
        $results[] = [false, $name];
        echo "  ✘  {$name}\n       {$e->getMessage()}\n";
    }
}
function assertSame(mixed $expected, mixed $actual, string $what): void
{
    if ($expected !== $actual) {
        throw new RuntimeException("{$what}: expected " . var_export($expected, true) . ", got " . var_export($actual, true));
    }
}
function assertNotSame(mixed $unexpected, mixed $actual, string $what): void
{
    if ($unexpected === $actual) {
        throw new RuntimeException("{$what}: must not be " . var_export($unexpected, true) . ", but it is");
    }
}

echo "Import lookup — mode: " . strtoupper($mode) . "\n\n";

// ---------------------------------------------------------------------------
// Test 1 — the test a reasonable developer writes first.
// One SKU, one campaign, one quota row. Every table has exactly one row, so
// product_variants.id == campaign_product_variants.id == 1. The wrong lookup
// lands on the right row by coincidence. This test is green in BOTH modes.
// ---------------------------------------------------------------------------
check('test 1 — one SKU in one campaign: quota is updated', function () use ($fixed) {
    $db = freshDb();
    $skuId      = seed($db, 'product_variants', ['sku_code' => 'SKU-A']);
    $campaignId = seed($db, 'campaigns', ['name' => 'Campaign A']);
    $cpvId      = seed($db, 'campaign_product_variants', [
        'campaign_id' => $campaignId, 'product_variant_id' => $skuId, 'quota' => 10,
    ]);

    (new ImportHandler($db, $fixed))->processRow('SKU-A', $campaignId, 50);

    assertSame(50, quotaOf($db, $cpvId), 'quota of the (SKU-A, Campaign A) row');
});

// ---------------------------------------------------------------------------
// Test 2 — the regression test that separates the two implementations.
// One SKU in two campaigns. The SKU's id is 1; campaign B's quota row is
// id 2. Adjust campaign B. The broken lookup takes sku_id = 1 and loads
// campaign_product_variants row 1 — which is campaign A's row.
// ---------------------------------------------------------------------------
check('test 2 — one SKU in two campaigns: adjusting B resolves B\'s row, not A\'s', function () use ($fixed) {
    $db = freshDb();
    $skuId = seed($db, 'product_variants', ['sku_code' => 'SKU-A']);
    $campA = seed($db, 'campaigns', ['name' => 'Campaign A']);
    $campB = seed($db, 'campaigns', ['name' => 'Campaign B']);
    $cpvA  = seed($db, 'campaign_product_variants', ['campaign_id' => $campA, 'product_variant_id' => $skuId, 'quota' => 10]);
    $cpvB  = seed($db, 'campaign_product_variants', ['campaign_id' => $campB, 'product_variant_id' => $skuId, 'quota' => 20]);

    $handler = new ImportHandler($db, $fixed);

    // (a) resolution — this is what the real regression test asserts
    $resolved = $handler->resolveRow('SKU-A', $campB);
    assertSame($cpvB, $resolved['id'], 'resolved row id');
    assertSame($campB, $resolved['campaign_id'], 'resolved row campaign');
    assertNotSame($skuId, $resolved['id'], 'resolved row id vs SKU id');

    // (b) the write — the gap the post names: the real test stops at (a)
    $handler->processRow('SKU-A', $campB, 50);
    assertSame(50, quotaOf($db, $cpvB), 'quota of campaign B after import');
    assertSame(10, quotaOf($db, $cpvA), 'quota of campaign A after import (must be untouched)');
});

$passed = count(array_filter($results, fn ($r) => $r[0]));
$failed = count($results) - $passed;
echo "\n{$passed} passed, {$failed} failed\n";
exit($failed === 0 ? 0 : 1);
