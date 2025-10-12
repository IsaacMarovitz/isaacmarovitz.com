import { Resvg } from "@resvg/resvg-js";
import { readFile } from "node:fs/promises";
import { getCollection, getEntry } from "astro:content";
import satori from "satori";
import { html } from "satori-html";

export async function getStaticPaths() {
    const posts = await getCollection("posts");
    return posts.map((post) => ({
        params: { id: post.id },
    }));
}

export async function GET({ params }: { params: { id: string } }) {
    const post = await getEntry("posts", params.id);
    if (!post) {
        return new Response("Blog post not found", { status: 404 });
    }

    const [boldFont, regularFont, textFont] = await Promise.all([
        readFile("./public/fonts/SF-Pro-Display-Bold.otf"),
        readFile("./public/fonts/SF-Pro-Display-Regular.otf"),
        readFile("./public/fonts/SF-Pro-Text-Regular.otf"),
    ]);

    const { title, description } = post.data;

    const markup= html(`
        <div style="
            display: flex;
            width: 1200px;
            height: 630px;
            padding: 60px;
            box-sizing: border-box;
            align-items: flex-start;
            justify-content: flex-end;
            flex-direction: column;
            color: white;
            background: linear-gradient(to bottom right, #5d0ec0 0%, #8a0194 100%);">
            <div style="
                display: flex;
                font-size: 50px;
                width: 1000px;
                font-family: 'SF Pro Display';
                font-weight: 700;">
                ${title}
            </div>
            <div style="
                display: flex;
                font-size: 25px;
                font-family: 'SF Pro';
                width: 1000px;">
                ${description}
            </div>
        </div>
    `);

    const svg = await satori(markup, {
        width: 1200,
        height: 630,
        fonts: [
            { name: "SF Pro", data: textFont, style: "normal", weight: 400 },
            { name: "SF Pro Display", data: regularFont, style: "normal", weight: 500 },
            { name: "SF Pro Display", data: boldFont, style: "normal", weight: 700 },
        ],
    });

    const resvg = new Resvg(svg);
    const png = resvg.render().asPng();

    return new Response(png.buffer, {
        status: 200,
        headers: {
            "Content-Type": "image/png",
        },
    });
}
