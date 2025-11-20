import { createClient } from '@supabase/supabase-js';

// Get from environment or .env file
const supabaseUrl = process.env.PUBLIC_SUPABASE_URL || 'YOUR_SUPABASE_URL';
const supabaseKey = process.env.PUBLIC_SUPABASE_ANON_KEY || 'YOUR_SUPABASE_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkSecurityZones() {
    console.log('Checking security_zones table...\n');

    const { data, error, count } = await supabase
        .from('security_zones')
        .select('*', { count: 'exact' });

    if (error) {
        console.error('Error fetching security zones:', error);
        return;
    }

    console.log(`Total security zones: ${count}`);
    console.log('Data:', JSON.stringify(data, null, 2));

    if (!data || data.length === 0) {
        console.log('\n⚠️  No security zones found in database!');
        console.log('You need to add security zone data to the database.');
    } else {
        console.log('\n✅ Security zones found!');
        data.forEach((zone, i) => {
            console.log(`\nZone ${i + 1}:`);
            console.log(`  ID: ${zone.id}`);
            console.log(`  Name: ${zone.name}`);
            console.log(`  Active: ${zone.is_active}`);
            console.log(`  Geometry type: ${zone.geometry?.type}`);
        });
    }
}

checkSecurityZones();
