import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  // The following matcher runs middleware on all routes
  // except static assets.
  matcher: [
    "/",
    "/(api(?!/socket)|trpc)(.*)",
    "/((?!.*\\..*|_next|api/socket).*?)",
  ],
};
