<script>
    import { goto } from '$app/navigation';
    import { userStore } from '$lib/stores/userStore.js';

    let step = 1;
    let cmuEmail = '';
    let otpArray = Array(6).fill('');
    let countdown = 50;
    let timer;

    $: isEmailValid = cmuEmail.endsWith('@cmu.ac.th');
    $: isOtpComplete = otpArray.join('').length === 6;

    function sendOTP() {
        if (!isEmailValid) return;
        step = 2;
        startCountdown();
    }

    function startCountdown() {
        countdown = 50;
        clearInterval(timer);
        timer = setInterval(() => {
            if (countdown > 0) countdown--; else clearInterval(timer);
        }, 1000);
    }

    function verifyOTP() {
        if (otpArray.join('') === '123456') {
            clearInterval(timer);
            let role = 'member';
            if (cmuEmail.startsWith('security')) role = 'security';
            else if (cmuEmail.startsWith('admin')) role = 'admin';

            userStore.set({ name: cmuEmail.split('@')[0], email: cmuEmail, role });

            if (role === 'security') goto('/security');
            else if (role === 'admin') goto('/admin');
            else goto('/');
        } else {
            alert('Wrong OTP');
        }
    }
    
    function handleInput(e, i) {
        const val = e.target.value.replace(/\D/g, '');
        otpArray[i] = val.slice(-1);
        if (val && i < 5) document.getElementById(`otp-${i+1}`)?.focus();
    }
</script>

<div class="absolute inset-0 z-50 flex items-center justify-center bg-black/50 p-4 font-kanit">
    <div class="flex w-full max-w-sm flex-col gap-6 rounded-2xl bg-white p-8 text-center shadow-xl">
        <div class="flex flex-col items-center gap-2">
            <img src="/logo.svg" alt="Logo" class="h-8" />
            <h2 class="text-2xl font-bold">Welcome Back!</h2>
        </div>

        {#if step === 1}
            <form on:submit|preventDefault={sendOTP} class="flex flex-col gap-4">
                <input type="email" placeholder="name@cmu.ac.th" class="input input-bordered w-full" bind:value={cmuEmail} />
                <button class="btn w-full rounded-full bg-[#8F66FF] text-white" disabled={!isEmailValid}>Send OTP</button>
            </form>
        {:else}
             <form on:submit|preventDefault={verifyOTP} class="flex flex-col gap-4">
                <div class="flex justify-center gap-2">
                    {#each otpArray as _, i}
                        <input id="otp-{i}" type="text" class="input input-bordered h-12 w-12 text-center" maxlength="1" bind:value={otpArray[i]} on:input={(e)=>handleInput(e,i)}/>
                    {/each}
                </div>
                <button class="btn w-full rounded-full bg-[#8F66FF] text-white" disabled={!isOtpComplete}>Login</button>
            </form>
        {/if}
    </div>
</div>