import { auth } from '@/lib/auth';

export default auth((req) => {
  const pathname = req.nextUrl.pathname;

  if (pathname.startsWith('/todos') && !req.auth) {
    const url = new URL('/login', req.url);
    url.searchParams.set('callbackUrl', req.url);
    return Response.redirect(url);
  }
});

export const config = {
  matcher: ['/todos/:path*'],
};
