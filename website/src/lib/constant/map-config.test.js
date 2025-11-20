import { describe, it, expect } from 'vitest';
import { CATEGORY_DISPLAY_NAMES, CATEGORY_STYLES, BLOCKED_MODAL_CONFIG } from './map-config';
import { TrafficCone } from 'lucide-svelte';

describe('map-config', () => {
    describe('CATEGORY_DISPLAY_NAMES', () => {
        it('should have blocked_line in CATEGORY_DISPLAY_NAMES', () => {
            expect(CATEGORY_DISPLAY_NAMES).toHaveProperty('blocked_line');
            expect(CATEGORY_DISPLAY_NAMES.blocked_line).toBe('Road Closed');
        });

        it('should have correct display names for all categories', () => {
            expect(CATEGORY_DISPLAY_NAMES).toEqual({
                accident: 'Accident/Hazard',
                blocked: 'Blocked',
                beware: 'Beware',
                flood: 'Flood',
                send_help: 'Send Help',
                traffic_general: 'Traffic',
                parking: 'Parking',
                events: 'Events',
                map_chat: 'Map Chat',
                lost_found: 'Lost & Found',
                blocked_line: 'Road Closed'
            });
        });
    });

    describe('CATEGORY_STYLES', () => {
        it('should have blocked_line in CATEGORY_STYLES with correct icon', () => {
            expect(CATEGORY_STYLES).toHaveProperty('blocked_line');
            expect(CATEGORY_STYLES.blocked_line.Icon).toBe(TrafficCone);
            expect(CATEGORY_STYLES.blocked_line.bg).toBe('bg-orange-100');
            expect(CATEGORY_STYLES.blocked_line.text).toBe('text-orange-600');
        });

        it('should have style definitions for all categories', () => {
            const categories = Object.keys(CATEGORY_DISPLAY_NAMES);

            categories.forEach(category => {
                const style = CATEGORY_STYLES[category];
                expect(style).toBeDefined();
                expect(style).toHaveProperty('Icon');
                expect(style).toHaveProperty('bg');
                expect(style).toHaveProperty('text');
            });
        });
    });

    describe('BLOCKED_MODAL_CONFIG', () => {
        it('should have correct configuration structure', () => {
            expect(BLOCKED_MODAL_CONFIG).toMatchObject({
                type: 'blocked',
                title: 'Report Blocked Path',
                pointOption: {
                    title: 'Obstacle',
                    description: 'e.g. Fallen tree, Car breakdown'
                },
                lineOption: {
                    title: 'Road Closed',
                    description: 'e.g. Construction, Flooding'
                }
            });

            expect(BLOCKED_MODAL_CONFIG.pointOption).toHaveProperty('Icon');
            expect(BLOCKED_MODAL_CONFIG.lineOption).toHaveProperty('Icon');
        });
    });
});
