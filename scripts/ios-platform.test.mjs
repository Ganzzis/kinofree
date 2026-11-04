import assert from 'node:assert/strict';
import test from 'node:test';
import { getPlatform } from '../src/lib/shared/scripts/autoUpdate/platform.js';

for (const [name, userAgent, platform, maxTouchPoints, expected] of [
	['iPhone', 'Mozilla iPhone', 'iPhone', 5, 'ios'],
	['iPad desktop mode', 'Mozilla Macintosh', 'MacIntel', 5, 'ios'],
	['Android', 'Mozilla Android', 'Linux', 5, 'android'],
	['Windows', 'Mozilla Windows', 'Win32', 0, 'desktop'],
	['macOS', 'Mozilla Macintosh', 'MacIntel', 0, 'desktop']
]) {
	test(name, () => {
		assert.equal(getPlatform({ userAgent, platform, maxTouchPoints }), expected);
	});
}
