const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
require('dotenv').config({ path: '/mnt/c/All-projects/2026/Otaku_verse/.env' });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

async function fixAnimes() {
  const { data, error } = await supabase.from('questions').select('id, anime');
  if (error) {
    console.error(error);
    return;
  }

  for (let q of data) {
    const lowerAnime = q.anime.toLowerCase();
    if (q.anime !== lowerAnime) {
      await supabase.from('questions').update({ anime: lowerAnime }).eq('id', q.id);
    }
  }
  console.log("Anime cases fixed in Supabase!");
}
fixAnimes();
