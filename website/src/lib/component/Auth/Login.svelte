<script>
    import { userStore } from '$lib/userStore.js'; // Make sure this path is correct

    let step = 1;
    let cmuEmail = '';
    let otpArray = Array(6).fill('');
    let countdown = 50;
    let timer;

    let emailError = ''; 

    $: isEmailValid = cmuEmail.length > 0;
    $: isOtpComplete = otpArray.join('').length === 6;

    function validateEmail() {
        if (cmuEmail.endsWith('@cmu.ac.th')) {
            emailError = ''; 
            return true;
        } else {
            if (cmuEmail.length > 0) {
                emailError = 'Please use a valid @cmu.ac.th account.'; 
            }
            return false;
        }
    }
    
    $: if (cmuEmail) validateEmail();

    $: formattedTime = String(Math.floor(countdown / 60)).padStart(2, '0') + ':' + String(countdown % 60).padStart(2, '0');

    // Mock backend
    function sendOTP() {
        if (!validateEmail()) {
            return; 
        }
        step = 2;
        startCountdown();
    }

    function startCountdown() {
        countdown = 50;
        clearInterval(timer);
        timer = setInterval(() => {
            if (countdown > 0) countdown--;
            else clearInterval(timer);
        }, 1000);
    }

    function verifyOTP() {
        const otp = otpArray.join('');
        if (otp === '123456') { 
            clearInterval(timer);
            
            const loggedInUser = {
                name: cmuEmail.split('@')[0], // Mock name
                email: cmuEmail,
                role: 'member' // Default role
            };
            
            userStore.set(loggedInUser);
                goto('/map');  

        } else {
            alert('Wrong OTP');
        }
    }

    function resendOTP() {
        startCountdown();
        alert('OTP resent (mock)');
    }

    function handleInput(e, index) {
        const val = e.target.value.replace(/\D/g, '');
        if (!val) {
            otpArray[index] = '';
            return;
        }
        otpArray[index] = val[0];
        let nextIndex = index + 1;
        for (let i = 1; i < val.length && nextIndex < otpArray.length; i++, nextIndex++) {
            otpArray[nextIndex] = val[i];
        }
        if (index < otpArray.length - 1 && val.length > 0) {
            const nextInput = document.getElementById(`otp-${index+1}`);
            nextInput?.focus();
        }
    }

    function handleKeydown(e, index) {
        if (e.key === 'Backspace' && !otpArray[index] && index > 0) {
            const prevInput = document.getElementById(`otp-${index-1}`);
            prevInput?.focus();
        }
    }
</script>

<div class="absolute inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
    <div class="bg-white rounded-2xl w-full max-w-sm p-8 flex flex-col gap-6 shadow-xl text-center">

        <!-- Logo + playful text -->
        <div class="flex flex-col items-center gap-2 mb-2">
            <img src="/logo.svg" alt="Logo" class="h-8 mb-2" />
            <h2 class="text-2xl font-bold ">Welcome Back!</h2>
            <p class="text-gray-500 text-sm">Let’s get you back on the map</p>
        </div>

        {#if step === 1}
            <form on:submit|preventDefault={sendOTP} class="flex flex-col gap-6 text-left">
                
                <div class="flex flex-col gap-1">
                    <label for="email" class="font-medium text-gray-700">CMU Account</label>
                    <input 
                        id="email"
                        type="email" 
                        placeholder="name@cmu.ac.th" 
                        class="input input-bordered w-full" 
                        class:input-error={emailError}
                        bind:value={cmuEmail} 
                        on:input={() => emailError = ''}
                        required
                    />
                    {#if emailError}
                        <p class="text-error text-sm mt-1">{emailError}</p>
                    {/if}
                </div>
                
                <button 
                    type="submit" 
                    class="btn w-full text-white rounded-full"
                    style:background-color={isEmailValid ? '#8F66FF' : ''}
                    style:border-color={isEmailValid ? '#8F66FF' : ''}
                    class:btn-disabled={!isEmailValid}
                    disabled={!isEmailValid}
                >
                    Send OTP
                </button>
            </form>
        {/if}

        {#if step === 2}
            <button class="self-start font-medium text-gray-700 hover:text-black p-0" on:click={() => step = 1}>
                &lt; Back
            </button>
            <form on:submit|preventDefault={verifyOTP} class="flex flex-col gap-6 text-left">
                <div class="flex flex-col gap-2">
                    <label for="email_verify" class="font-medium text-gray-700">CMU Account</label>
                    <input id="email_verify" type="text" class="input input-bordered w-full bg-gray-100" value={cmuEmail} readonly />
                </div>
                <div class="flex flex-col gap-2">
                    <label class="font-medium text-gray-700">One Time Password</label>
                    <div class="flex gap-2 justify-center">
                        {#each otpArray as digit, i}
                            <input
                                id={`otp-${i}`}
                                type="text" 
                                inputmode="numeric"
                                pattern="[0-9]*"
                                maxlength="1" 
                                class="input input-bordered w-12 h-12 text-center text-lg"
                                bind:value={otpArray[i]}
                                on:input={(e) => handleInput(e, i)}
                                on:keydown={(e) => handleKeydown(e, i)}
                                required
                            />
                        {/each}
                    </div>
                </div>
                <div class="flex justify-between items-center -mt-2">
                    <span class="text-sm text-gray-500">{formattedTime}</span>
                    <button type="button" class="btn btn-link p-0 text-sm" on:click={resendOTP} disabled={countdown > 0}>
                        Resend OTP
                    </button>
                </div>
                
                <button 
                    type="submit" 
                    class="btn w-full text-white rounded-full"
                    style:background-color={isOtpComplete ? '#8F66FF' : ''}
                    style:border-color={isOtpComplete ? '#8F66FF' : ''}
                    class:btn-disabled={!isOtpComplete}
                    disabled={!isOtpComplete}
                >
                    LOG IN
                </button>
            </form>
        {/if}
    </div>
</div>
