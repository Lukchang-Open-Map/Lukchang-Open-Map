import { writable } from 'svelte/store';
import { browser } from '$app/environment';

const getStoredUser = () => {
	if (browser) {
		const storedUser = sessionStorage.getItem('currentUser');
		if (storedUser) {
			return JSON.parse(storedUser);
		}
	}
	return null;
};

const store = writable(getStoredUser());

store.subscribe((value) => {
	if (browser) {
		if (value) {
			sessionStorage.setItem('currentUser', JSON.stringify(value));
		} else {
			sessionStorage.removeItem('currentUser');
		}
	}
});

export const userStore = store;
