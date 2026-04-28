import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

export const createServiceRoleClient = () =>
  createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

let serverClient: any | null = null;

export const getServiceRoleClient = () => {
  if (!serverClient) {
    serverClient = createServiceRoleClient();
  }
  return serverClient;
};
