import { describe, it, expect } from 'vitest';
import { CATEGORY_DISPLAY_NAMES, CATEGORY_STYLES } from './map-config';
import { TrafficCone } from 'lucide-svelte';

describe('map-config', () => {
    it('should have blocked_line in CATEGORY_DISPLAY_NAMES', () => {
        expect(CATEGORY_DISPLAY_NAMES).toHaveProperty('blocked_line');
        expect(CATEGORY_DISPLAY_NAMES.blocked_line).toBe('Road Closed');
    });

    it('should have blocked_line in CATEGORY_STYLES with correct icon', () => {
        expect(CATEGORY_STYLES).toHaveProperty('blocked_line');
        expect(CATEGORY_STYLES.blocked_line.Icon).toBe(TrafficCone);
        expect(CATEGORY_STYLES.blocked_line.bg).toBe('bg-orange-100');
        expect(CATEGORY_STYLES.blocked_line.text).toBe('text-orange-600');
    });
});
