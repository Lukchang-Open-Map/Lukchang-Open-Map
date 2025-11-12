<script>
  // 1. Import the store
  import { userStore } from '$lib/userStore.js'; 

  // 2. Import your components
  import Login from '$lib/component/Login.svelte';
  import Map from '$lib/component/Map.svelte';

</script>

<div class="relative h-screen w-full">
  <Map />

  {#if !$userStore}
    <Login />
  {/if}
</div>
