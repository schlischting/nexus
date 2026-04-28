import { getServiceRoleClient } from '@/lib/supabase/server';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    const supabase = getServiceRoleClient();

    if (!supabase) {
      return NextResponse.json(
        { error: 'Service unavailable' },
        { status: 503 }
      );
    }

    const authHeader = request.headers.get('authorization');

    if (!authHeader) {
      return NextResponse.json(
        { error: 'Missing authorization header' },
        { status: 401 }
      );
    }

    const token = authHeader.replace('Bearer ', '');

    // Verify token and get user
    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data.user) {
      return NextResponse.json(
        { error: 'Invalid token' },
        { status: 401 }
      );
    }

    // Get user profile
    const { data: profileData } = await supabase
      .from('user_filiais')
      .select('perfil')
      .eq('user_id', data.user.id)
      .single() as any;

    // Get user filiais
    const { data: filiaisData } = await supabase
      .from('user_filiais_cnpj')
      .select('filial_cnpj')
      .eq('user_id', data.user.id) as any;

    return NextResponse.json({
      user: {
        id: data.user.id,
        email: data.user.email,
      },
      perfil: (profileData as any)?.perfil || 'operador_filial',
      filiais: ((filiaisData || []) as any[]).map((f: any) => f.filial_cnpj),
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
