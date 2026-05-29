import type { APIRoute } from "astro";

export const prerender = true;

export const GET: APIRoute = () => {
    const did = "did:plc:ftdxrg5uqrtusxxoyqocrecq";
    const rkey = "isaacmarovitz.com";

    const atUri = `at://${did}/site.standard.publication/${rkey}`;

    return new Response(atUri, {
        status: 200,
        headers: {
            "Content-Type": "text/plain; charset=utf-8",
            "Cache-Control": "public, max-age=31536000, immutable",
        },
    });
};
