const API_BASE_URL = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000';
const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // ms

interface FetchOptions extends RequestInit {
  retries?: number;
  timeout?: number;
}

class ApiError extends Error {
  constructor(
    public status: number,
    public message: string,
    public details?: any
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

export const apiClient = {
  async fetch<T>(
    endpoint: string,
    options: FetchOptions = {}
  ): Promise<T> {
    const {
      retries = MAX_RETRIES,
      timeout = 30000,
      ...fetchOptions
    } = options;

    const url = endpoint.startsWith('http')
      ? endpoint
      : `${API_BASE_URL}${endpoint}`;

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      let lastError: Error | null = null;

      for (let attempt = 0; attempt < retries; attempt++) {
        try {
          const response = await fetch(url, {
            ...fetchOptions,
            signal: controller.signal,
          });

          clearTimeout(timeoutId);

          if (!response.ok) {
            const data = await response.json().catch(() => ({}));
            throw new ApiError(
              response.status,
              data?.message || response.statusText,
              data
            );
          }

          return await response.json();
        } catch (error) {
          lastError = error as Error;

          if (attempt < retries - 1) {
            const delay = RETRY_DELAY * Math.pow(2, attempt);
            await sleep(delay);
          }
        }
      }

      throw lastError || new Error('Unknown error');
    } catch (error) {
      clearTimeout(timeoutId);
      throw error;
    }
  },

  get<T>(endpoint: string, options?: FetchOptions) {
    return this.fetch<T>(endpoint, { ...options, method: 'GET' });
  },

  post<T>(endpoint: string, body?: any, options?: FetchOptions) {
    return this.fetch<T>(endpoint, {
      ...options,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
      body: body ? JSON.stringify(body) : undefined,
    });
  },

  put<T>(endpoint: string, body?: any, options?: FetchOptions) {
    return this.fetch<T>(endpoint, {
      ...options,
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
      body: body ? JSON.stringify(body) : undefined,
    });
  },

  delete<T>(endpoint: string, options?: FetchOptions) {
    return this.fetch<T>(endpoint, { ...options, method: 'DELETE' });
  },
};
