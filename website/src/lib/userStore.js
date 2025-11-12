// src/lib/userStore.js
import { writable } from 'svelte/store';
// 1. Import 'browser' from SvelteKit's environment
import { browser } from '$app/environment';

const getStoredUser = () => {
  // 2. Only run this code if we are in the browser
  if (browser) {
    const storedUser = sessionStorage.getItem('currentUser');
    if (storedUser) {
      return JSON.parse(storedUser);
    }
  }
  return null;
};

// 3. Initialize the store (this is safe)
const store = writable(getStoredUser());

// 4. Update sessionStorage only in the browser
store.subscribe(value => {
  if (browser) {
    if (value) {
      sessionStorage.setItem('currentUser', JSON.stringify(value));
    } else {
      sessionStorage.removeItem('currentUser');
    }
  }
});

export const userStore = store;