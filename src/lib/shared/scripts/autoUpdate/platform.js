export function getPlatform(navigator) {
	if (
		/iPad|iPhone|iPod/i.test(navigator.userAgent) ||
		(navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
	)
		return 'ios';
	return /android/i.test(navigator.userAgent) ? 'android' : 'desktop';
}
