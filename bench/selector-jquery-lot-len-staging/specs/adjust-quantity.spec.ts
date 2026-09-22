import { test, expect, Page } from '@playwright/test';
import * as path from 'path';

// This is the spec file that was never written. It is one file, and it opens the
// modal, clicks Increase, and asserts what goes over the wire.
const PAGE = 'file://' + path.resolve(__dirname, '..', 'index.html');
const url = (broken: 0 | 1, naive: 0 | 1) => `${PAGE}?broken=${broken}&naive=${naive}`;

async function submitIncrease(page: Page, qty: string) {
  await page.fill('#increase_quantity', qty);
  await page.click('#submit');
}

const wire = async (page: Page) => JSON.parse((await page.textContent('#wire'))!);

test.describe('bug 1 — the selector matches zero elements', () => {
  test('broken selector: an Increase of 5 is submitted as a Decrease of 0', async ({ page }) => {
    await page.goto(url(1, 1));

    // Sanity: the selector in the code is valid, it just matches nothing.
    const matched = await page.evaluate(() =>
      (window as any).jQuery('#adjustmentTabContent .nav-link.active').length
    );
    expect(matched).toBe(0);

    await submitIncrease(page, '5');
    expect(await wire(page)).toEqual({ adjustment_type: 'decrease', decrease_quantity: 0 });
    expect(JSON.parse((await page.textContent('#response'))!).status).toBe(422);
  });

  test('fixed selector: the same click submits an Increase of 5', async ({ page }) => {
    await page.goto(url(0, 1));

    const matched = await page.evaluate(() =>
      (window as any).jQuery('#adjustmentTabs .nav-link.active').length
    );
    expect(matched).toBe(1);

    await submitIncrease(page, '5');
    expect(await wire(page)).toEqual({ adjustment_type: 'increase', increase_quantity: 5 });
  });
});

test.describe('bug 2 — the error renders into zero pixels', () => {
  // This is the finding of the post. Both assertions below describe the SAME run.
  // The first is the assertion a developer would write to check error handling,
  // and it passes. The second is what the operator experiences.
  test('naive rendering: the message is in the DOM and invisible', async ({ page }) => {
    await page.goto(url(1, 1));
    await submitIncrease(page, '5');

    const message = page.locator('.field-error');

    // "Did we render the server's error?" — green.
    await expect(message).toHaveCount(1);
    await expect(message).toHaveText('The quantity must be at least 1.');

    // What the operator saw.
    await expect(message).toBeHidden();
    expect(await message.boundingBox()).toBeNull();

    // It landed inside the pane that is not on screen.
    await expect(message.locator('xpath=ancestor::div[@id="pane-decrease"]')).toHaveCount(1);
    await expect(page.locator('#pane-decrease')).toHaveCSS('display', 'none');

    // And there is no other channel for it.
    await expect(page.locator('#fallback-alert')).toHaveCount(0);
  });

  test('visibility-aware rendering: the same 422 reaches the operator', async ({ page }) => {
    await page.goto(url(1, 0));
    await submitIncrease(page, '5');

    const alert = page.locator('#fallback-alert');
    await expect(alert).toBeVisible();
    await expect(alert).toHaveText('The quantity must be at least 1.');

    // Exclusivity: the message appears in the fallback OR inline, never both.
    await expect(page.locator('.field-error')).toHaveCount(0);
  });

  test('naive rendering is fine when the field is on screen', async ({ page }) => {
    await page.goto(url(0, 1)); // fixed selector, stock is 3, ask for 5
    await submitIncrease(page, '5');

    const message = page.locator('.field-error');
    await expect(message).toBeVisible();
    await expect(message).toHaveText('Only 3 units are available.');
  });
});

test.describe('the cost of the fallback box', () => {
  test('the shared alert pushes the form down when it appears', async ({ page }) => {
    await page.goto(url(1, 0));

    const tabs = page.locator('#adjustmentTabs');
    const before = (await tabs.boundingBox())!.y;

    await submitIncrease(page, '5');
    await expect(page.locator('#fallback-alert')).toBeVisible();

    const after = (await tabs.boundingBox())!.y;
    expect(after).toBeGreaterThan(before);
    console.log(`form moved down ${Math.round(after - before)}px`);
  });
});
