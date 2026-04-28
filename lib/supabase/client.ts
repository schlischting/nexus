import { createBrowserClient } from '@supabase/ssr';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const createClient = () =>
  createBrowserClient(supabaseUrl, supabaseAnonKey);

let client: ReturnType<typeof createBrowserClient> | null = null;

export const getClient = () => {
  if (!client) {
    client = createClient();
  }
  return client;
};

export const getAuthUser = async () => {
  const supabase = getClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  return user;
};
