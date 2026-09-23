<?php

declare(strict_types=1);

/**
 * Reconstruction of a quota-adjustment import handler.
 *
 * Each import row carries a SKU code, a campaign id and a new quota.
 * The handler resolves the SKU code to product_variants.id ("sku_id"),
 * then has to find the (campaign, SKU) row in campaign_product_variants.
 *
 * With $fixed = false it does what the original code did: it takes sku_id
 * and looks it up as campaign_product_variants.id. That is a different
 * table with a different auto-increment sequence.
 */
final class ImportHandler
{
    public function __construct(
        private PDO $db,
        private bool $fixed,
    ) {
    }

    /** @return array{id:int, campaign_id:int, product_variant_id:int, quota:int} */
    public function resolveRow(string $skuCode, int $campaignId): array
    {
        $skuId = $this->resolveSkuId($skuCode);

        if ($this->fixed) {
            // Look up by the (SKU, campaign) pair. Two keys, correct table semantics.
            $stmt = $this->db->prepare(
                'SELECT * FROM campaign_product_variants
                 WHERE product_variant_id = :sku_id AND campaign_id = :campaign_id'
            );
            $stmt->execute(['sku_id' => $skuId, 'campaign_id' => $campaignId]);
        } else {
            // The bug: CampaignProductVariant::findOrFail($row['sku_id']).
            // sku_id is a product_variants primary key, but it is used as a
            // campaign_product_variants primary key.
            $stmt = $this->db->prepare(
                'SELECT * FROM campaign_product_variants WHERE id = :sku_id'
            );
            $stmt->execute(['sku_id' => $skuId]);
        }

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row === false) {
            throw new RuntimeException("findOrFail: no campaign_product_variants row for sku_id={$skuId}");
        }

        return array_map('intval', $row);
    }

    public function processRow(string $skuCode, int $campaignId, int $newQuota): int
    {
        $row = $this->resolveRow($skuCode, $campaignId);

        $stmt = $this->db->prepare('UPDATE campaign_product_variants SET quota = :q WHERE id = :id');
        $stmt->execute(['q' => $newQuota, 'id' => $row['id']]);

        return $row['id'];
    }

    private function resolveSkuId(string $skuCode): int
    {
        $stmt = $this->db->prepare('SELECT id FROM product_variants WHERE sku_code = :code');
        $stmt->execute(['code' => $skuCode]);
        $id = $stmt->fetchColumn();
        if ($id === false) {
            throw new RuntimeException("unknown SKU code {$skuCode}");
        }

        return (int) $id;
    }
}
