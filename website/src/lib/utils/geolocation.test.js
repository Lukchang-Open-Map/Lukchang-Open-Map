import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { getUserLocation } from './geolocation';

describe('getUserLocation', () => {
    const mockGeolocation = {
        getCurrentPosition: vi.fn()
    };

    beforeEach(() => {
        global.navigator.geolocation = mockGeolocation;
    });

    afterEach(() => {
        vi.clearAllMocks();
    });

    it('should resolve with coordinates when successful', async () => {
        const mockPosition = {
            coords: {
                latitude: 18.8,
                longitude: 98.95
            }
        };

        mockGeolocation.getCurrentPosition.mockImplementation((success) => success(mockPosition));

        const result = await getUserLocation();
        expect(result).toEqual({ latitude: 18.8, longitude: 98.95 });
    });

    it('should reject with error when permission denied', async () => {
        const mockError = {
            code: 1, // PERMISSION_DENIED
            PERMISSION_DENIED: 1
        };

        mockGeolocation.getCurrentPosition.mockImplementation((success, error) => error(mockError));

        await expect(getUserLocation()).rejects.toThrow('User denied the request for Geolocation.');
    });

    it('should reject with error when position unavailable', async () => {
        const mockError = {
            code: 2, // POSITION_UNAVAILABLE
            POSITION_UNAVAILABLE: 2
        };

        mockGeolocation.getCurrentPosition.mockImplementation((success, error) => error(mockError));

        await expect(getUserLocation()).rejects.toThrow('Location information is unavailable.');
    });

    it('should reject with error when timeout', async () => {
        const mockError = {
            code: 3, // TIMEOUT
            TIMEOUT: 3
        };

        mockGeolocation.getCurrentPosition.mockImplementation((success, error) => error(mockError));

        await expect(getUserLocation()).rejects.toThrow('The request to get user location timed out.');
    });

    it('should reject when geolocation is not supported', async () => {
        delete global.navigator.geolocation;
        await expect(getUserLocation()).rejects.toThrow('Geolocation is not supported by your browser');
    });
});
